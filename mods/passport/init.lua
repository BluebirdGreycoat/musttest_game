
-- This mod provides an item which enables players to teleport to registered locations without the need of a teleporter.
-- This item doubles as the means by which the server control scripts decide which playerfiles to delete and which to keep.

passport = passport or {}
passport.recalls = passport.recalls or {}
passport.players = passport.players or {}
passport.registered_players = passport.registered_players or {} -- Cache of registered players.
passport.keyed_players = passport.keyed_players or {}
passport.modpath = minetest.get_modpath("passport")



local PASSPORT_TELEPORT_RANGE = 3000 -- 3 Kilometers.

minetest.register_privilege("recall", {
  description = "Player can request a teleport back to the city.",
  give_to_singleplayer = false,
})



function passport.is_passport(name)
	if name == "passport:passport" then
		return true
	end
	if name == "passport:passport_adv" then
		return true
	end

	return false
end



-- Public API function. Other mods are expected to register recall locations.
passport.register_recall = function(recalldef)
    local name = recalldef.name
    local position = recalldef.position
    local min_dist = recalldef.min_dist
    local on_success = recalldef.on_success
    local on_failure = recalldef.on_failure
    local tname = recalldef.codename
    local suppress = recalldef.suppress
    local idx = #(passport.recalls) + 1
    local code = "v" .. idx .. ""
    passport.recalls[idx] = {
      name = name,
      position = position,
      code = code,
      on_success = on_success,
      min_dist = min_dist,
      on_failure = on_failure,
      tname = tname,
      suppress = suppress,
    }
end



passport.compose_formspec = function(pname)
  local buttons = ""
  
  local i = 1
  for k, v in pairs(passport.recalls) do
    local n = v.name
    local c = v.code
    buttons = buttons .. "button_exit[6," .. i .. ";3,1;" .. c .. ";" .. n .. "]"
    i = i + 1
  end
  
  local boolecho = 'true'
  local echo = chat_echo.get_echo(pname)
  if echo == true then boolecho = 'true' end
  if echo == false then boolecho = 'false' end
  
  local boolparticle = 'true'
  local particle = default.particles_enabled_for(pname)
  if particle == true then boolparticle = 'true' end
  if particle == false then boolparticle = 'false' end

  local formspec = "size[10,7]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    "label[1,0.0;Registered citizens can teleport to any of the colony's recall locations.]" ..
    "label[1,0.4;Server topic: https://forum.minetest.net/viewtopic.php?f=10&t=16087]" ..
    buttons ..
    "button_exit[1,1;2,1;exit;Close]" ..
    "button_exit[3,1;2,1;mapfix;Fix Map]" ..
    "button[3,2;2,1;email;E-Mail]" ..
    "button[1,2;2,1;survivalist;Survivalist]" ..
    "button[1,3;2,1;rename;Nickname]" ..
		"button[3,3;2,1;chatfilter;Chat Filter]" ..
    
    "checkbox[1,4.2;toggleparticles;Enable Particles;" ..
      boolparticle .. "]" ..
    "checkbox[1,4.8;togglechat;Enable Chat Echoing;" ..
      boolecho .. "]" ..
    "label[1,5.6;Server Name: Must Test]" ..
    "label[1,6.0;Server Address: arklegacy.duckdns.org]" ..
    "label[1,6.4;Server Port: 30000]"

	for i=1, 7, 1 do
		local name = "xdecor:ivy"
		if i == 1 then
			name = "passport:passport_adv"
		elseif i == 7 then
			name = "default:sword_steel"
		end

		formspec = formspec .. "item_image[0," .. i-1 .. ";1,1;" .. name .. "]"
		formspec = formspec .. "item_image[9," .. i-1 .. ";1,1;" .. name .. "]"
	end
  
  return formspec
end



passport.show_formspec = function(pname)
  local formspec = passport.compose_formspec(pname)
  minetest.show_formspec(pname, "passport:passport", formspec)
end



passport.on_use = function(itemstack, user, pointed)
  if user and user:is_player() then
    passport.show_formspec(user:get_player_name())
  end
  return itemstack
end

passport.on_use_simple = function(itemstack, user, pointed)
  if user and user:is_player() then
		minetest.chat_send_player(user:get_player_name(),
			"# Server: This awkward chunk of reflective metal seems to mock you, " ..
			"yet remains strangely inert. Perhaps it can be upgraded?")
  end
  return itemstack
end



passport.on_receive_fields = function(player, formname, fields)
  if formname ~= "passport:passport" then return end
  
  local pname = player:get_player_name()
  
  if fields.mapfix then
    mapfix.command(pname, "")
    return true
  end
  
  if fields.email then
    mailgui.show_formspec(pname)
    return true
  end

	if fields.chatfilter then
		chat_controls.show_formspec(pname)
		return true
	end
  
  if fields.survivalist then
    survivalist.show_formspec(pname)
    return true
  end

	if fields.rename then
		rename.show_formspec(pname)
		return true
	end
  
  if fields.togglechat then
    if fields.togglechat == 'true' then
      chat_echo.set_echo(pname, true)
    elseif fields.togglechat == 'false' then
      chat_echo.set_echo(pname, false)
    end
    passport.show_formspec(pname) -- Reshow formspec.
    return true
  end
  
  if fields.toggleparticles then
    if fields.toggleparticles == 'true' then
      default.enable_particles_for(pname, true)
    elseif fields.toggleparticles == 'false' then
      default.enable_particles_for(pname, false)
    end
    passport.show_formspec(pname) -- Reshow formspec.
    return true
  end

  for k, v in pairs(passport.recalls) do
    local c = v.code
    if fields[c] then
      if not minetest.check_player_privs(pname, {recall=true}) then
        minetest.chat_send_player(pname, "# Server: You are not authorized to request transport.")
				easyvend.sound_error(pname)
        return true
      end
  
      passport.attempt_teleport(player, v)
      return true
    end
  end
  
  return true
end



passport.attempt_teleport = function(player, data)
  local pp = player:get_pos()
  local nn = player:get_player_name()
  local tg = data.position(player)

	if rc.current_realm_at_pos(tg) ~= rc.current_realm_at_pos(pp) then
		minetest.chat_send_player(nn, "# Server: Beacon signal is in another dimension!")
		-- Wrong realm.
		return
	end
  
  for k, v in pairs(passport.recalls) do
    if v.suppress then
      if v.suppress(nn) then
        minetest.chat_send_player(nn, "# Server: Beacon signal is suppressed and cannot be triangulated.")
				easyvend.sound_error(nn)
        return -- Someone suppressed the ability to teleport.
      end
    end
  end
  
  for k, v in pairs(passport.recalls) do
    if vector.distance(pp, v.position(player)) < v.min_dist then
      if data.on_failure then data.on_failure(nn, "too_close", v.tname) end
      minetest.chat_send_player(nn, "# Server: You are too close to a nearby beacon signal.")
			easyvend.sound_error(nn)
      return -- To close to a beacon.
    end
  end
  
  if vector.distance(pp, tg) > PASSPORT_TELEPORT_RANGE then
    if data.on_failure then data.on_failure(nn, "too_far", data.tname) end
		local dist = math.floor(vector.distance(pp, tg))
    minetest.chat_send_player(nn, "# Server: Beacon signal is too weak. You are out of range: distance " .. dist/1000 .. " kilometers.")
		easyvend.sound_error(nn)
    return -- To far from requested beacon.
  end
  
  if passport.players[nn] then
    if data.on_failure then data.on_failure(nn, "in_progress", data.tname) end
    minetest.chat_send_player(nn, "# Server: Signal triangulation already underway; stand by.")
    return -- Teleport already in progress.
  end
  
  -- Everything satisfied. Let's teleport!
  local dist = vector.distance(pp, tg)
  local time = math.ceil(math.sqrt(dist / 10))
  
  minetest.chat_send_player(nn, "# Server: Recall beacon signal requires " .. time .. " seconds to triangulate; please hold still.")
  passport.players[nn] = true
	local pos = vector.add(tg, {x=math.random(-2, 2), y=0, z=math.random(-2, 2)})
  minetest.after(time, passport.do_teleport, nn, pp, pos, data.on_success)
end



-- Called from minetest.after() to actually execute a teleport.
passport.do_teleport = function(name, start_pos, target_pos, func)
  passport.players[name] = nil
  local player = minetest.get_player_by_name(name)
  if player and player:is_player() then

		if sheriff.player_punished(name) then
			if sheriff.punish_probability(name) then
				sheriff.punish_player(name)
				return
			end
		end

    if vector.distance(player:getpos(), start_pos) < 0.1 then
			local fwrap = function(...)
				minetest.chat_send_player(name, "# Server: Transport successful.")
				portal_sickness.on_use_portal(name)
				return func(...)
			end
			preload_tp.preload_and_teleport(name, target_pos, 32, nil, func, name, false)
      --if func then func(name) end
    else
      minetest.chat_send_player(name, "# Server: Unable to accurately triangulate beacon position! Aborted.")
			easyvend.sound_error(name)
    end
  end
end



function passport.exec_spawn(name, param)
	local player = minetest.get_player_by_name(name)
	if not player then return false end
	local pos = vector.round(player:get_pos())
	if jail.suppress(name) then
		return true
	end
	local target = randspawn.get_respawn_pos(pos)
	if vector.distance(pos, target) < 20 then
		minetest.chat_send_player(name, "# Server: Too close to the spawnpoint!")
		easyvend.sound_error(name)
		return true
	end
	if sheriff.player_punished(name) then
		if sheriff.punish_probability(name) then
			sheriff.punish_player(name)
			return true
		end
	end
	if vector.distance(pos, target) <= 256 then
		randspawn.reposition_player(name, pos)

		minetest.after(1, function()
			minetest.chat_send_player(name, "# Server: You have been returned to the spawnpoint.")
			portal_sickness.on_use_portal(name)
		end)
	else
		minetest.chat_send_player(name, "# Server: You are too far from the spawnpoint! You need a Key of Citizenship to teleport from farther.")
		easyvend.sound_error(name)
	end
	return true
end



if not passport.registered then
  -- Obtain modstorage.
  passport.modstorage = minetest.get_mod_storage()
  
  -- Keep this in inventory to prevent deletion.
  minetest.register_craftitem("passport:passport", {
    description = "Proof Of Citizenship\n\n" ..
			"Keep this in your MAIN inventory at ALL times!\n" ..
			"This preserves your Account during server purge.\n" ..
			"It cannot be stolen or lost by dying.",
    inventory_image = "default_bronze_block.png^default_tool_steelpick.png",
		stack_max = 1,
    on_use = function(...) return passport.on_use_simple(...) end,
  })

  -- Keep this in inventory to prevent deletion.
  minetest.register_craftitem("passport:passport_adv", {
    description = "Key Of Citizenship\n\n" ..
			"Keep this in your MAIN inventory at ALL times!\n" ..
			"This preserves your Account during server purge.\n" ..
			"It cannot be stolen or lost by dying.",
    inventory_image = "adv_passport.png",
		stack_max = 1,
    on_use = function(...) return passport.on_use(...) end,
  })

  minetest.register_craft({
    output = 'passport:passport 1',
    recipe = {
      {'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
    },
  })
  
  minetest.register_craft({
    output = 'passport:passport_adv 1',
    recipe = {
      {'mese_crystals:zentamine', 'passport:passport', 'mese_crystals:zentamine'},
      {'techcrafts:control_logic_unit', 'quartz:quartz_crystal_piece', 'techcrafts:control_logic_unit'},
      {'dusts:diamond_shard', 'techcrafts:control_logic_unit', 'default:obsidian_shard'},
    },
  })

  minetest.register_on_player_receive_fields(function(...) return passport.on_receive_fields(...) end)
  minetest.register_alias("command_tokens:live_preserver", "passport:passport")
  
  -- It's very common for servers to have a /spawn command. This one is limited.
  minetest.register_chatcommand("spawn", {
    params = "",
    description = "Teleport the player back to the spawnpoint. This only works within 256 meters of spawn.",
    privs = {recall=true},
    func = function(...)
			return passport.exec_spawn(...)
    end,
  })

  -- Let players used to using /recall know that gameplay has changed in this respect.
  minetest.register_chatcommand("recall", {
    params = "",
    description = "Teleport the player back to the spawnpoint. This only works within 256 meters of spawn.",
    privs = {recall=true},
    func = function(...)
			return passport.exec_spawn(...)
    end,
  })

	minetest.register_on_leaveplayer(function(...)
		return passport.on_leaveplayer(...)
	end)

  passport.registered = true
end



-- This function may be called serveral times on player-login and other times.
-- We cache the result on first call.
passport.player_registered = function(pname)
	-- Read cache if available.
	local registered = passport.registered_players[pname]
	if type(registered) ~= "nil" then
		return registered
	end

  local player = minetest.get_player_by_name(pname)
  if player and player:is_player() then
    local inv = player:get_inventory()
    if inv then
			if inv:contains_item("main", "passport:passport") or inv:contains_item("main", "passport:passport_adv") then
				passport.registered_players[pname] = true -- Cache for next time.
				return true
			else
				passport.registered_players[pname] = false -- Cache for next time.
				return false
			end
    end
  end

	-- Return false, but don't cache the value -- we could not confirm it!
  return false
end

-- This checks (and caches the result!) of whether the player has a KEY OF CITIZENSHIP.
passport.player_has_key = function(pname)
	-- Read cache if available.
	local keyed = passport.keyed_players[pname]
	if type(keyed) ~= "nil" then
		return keyed
	end

  local player = minetest.get_player_by_name(pname)
  if player and player:is_player() then
    local inv = player:get_inventory()
    if inv then
			if inv:contains_item("main", "passport:passport_adv") then
				passport.keyed_players[pname] = true -- Cache for next time.
				return true
			else
				passport.keyed_players[pname] = false -- Cache for next time.
				return false
			end
    end
  end

	-- Return false, but don't cache the value -- we could not confirm it!
  return false
end



function passport.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()

	-- Remove cache of player registration.
	passport.registered_players[pname] = nil
	passport.keyed_players[pname] = nil
end



if minetest.get_modpath("reload") then
  local c = "passport:core"
  local f = passport.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end

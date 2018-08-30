
-- This mod provides an item which enables players to teleport to registered locations without the need of a teleporter.
-- This item doubles as the means by which the server control scripts decide which playerfiles to delete and which to keep.

passport = passport or {}
passport.recalls = passport.recalls or {}
passport.players = passport.players or {}
passport.registered_players = passport.registered_players or {} -- Cache of registered players.
passport.modpath = minetest.get_modpath("passport")



local PASSPORT_TELEPORT_RANGE = 3000 -- 3 Kilometers.

minetest.register_privilege("recall", {
  description = "Player can request a teleport back to the city.",
  give_to_singleplayer = false,
})



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
    buttons = buttons .. "button_exit[5," .. i .. ";3,1;" .. c .. ";" .. n .. "]"
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

  local formspec = "size[8,7]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    "label[0,0.0;Registered citizens can teleport to any of the colony's recall locations.]" ..
    "label[0,0.4;Server topic: https://forum.minetest.net/viewtopic.php?f=10&t=16087]" ..
    --"label[0,0.4;This costs 1 gold ingot.]" ..
    buttons ..
    "button_exit[0,1;2,1;exit;Close]" ..
    "button_exit[2,1;2,1;mapfix;Fix Map]" ..
    "button[2,2;2,1;email;E-Mail]" ..
    "button[0,2;2,1;survivalist;Survivalist]" ..
    "button[0,3;2,1;rename;Nickname]" ..
		"button[2,3;2,1;chatfilter;Chat Filter]" ..
    
    "checkbox[0,4.2;toggleparticles;Enable Particles;" ..
      boolparticle .. "]" ..
    "checkbox[0,4.8;togglechat;Enable Chat Echoing;" ..
      boolecho .. "]" ..
    "label[0,5.6;Server Name: Must Test]" ..
    "label[0,6.0;Server Address: arklegacy.duckdns.org]" ..
    "label[0,6.4;Server Port: 30000]"
  
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



passport.on_receive_fields = function(player, formname, fields)
  if formname ~= "passport:passport" then return end
  
  local pname = player:get_player_name()
  
  if fields.mapfix then
    mapfix.do_command(pname, "")
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
    if vector.distance(player:getpos(), start_pos) < 0.1 then
			local fwrap = function(...)
				minetest.chat_send_player(name, "# Server: Transport successful.")
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
	if vector.distance(pos, target) <= 256 then
		randspawn.reposition_player(name, pos)
		minetest.after(1, function()
			minetest.chat_send_player(name, "# Server: You have been returned to the spawnpoint.")
		end)
	else
		minetest.chat_send_player(name, "# Server: You are too far from the spawnpoint! You need a PoC to teleport from farther.")
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
    inventory_image = "default_bronze_block.png",
		stack_max = 1,
    on_use = function(...) return passport.on_use(...) end,
  })

  minetest.register_craft({
    output = 'passport:passport 1',
    recipe = {
      {'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
    },
  })
  
  minetest.register_on_player_receive_fields(function(...) return passport.on_receive_fields(...) end)
  minetest.register_alias("command_tokens:live_preserver", "passport:passport")
  
  -- It's very common for servers to have a /spawn command, so let players know that this server doesn't use it.
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

  passport.registered = true
end



-- This function might get called serveral times on player-login, or at other times.
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
    if inv:contains_item("main", "passport:passport") then
			passport.registered_players[pname] = true -- Cache for next time.
      return true
    end
  end
	passport.registered_players[pname] = false -- Cache for next time.
  return false
end



if minetest.get_modpath("reload") then
  local c = "passport:core"
  local f = passport.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end

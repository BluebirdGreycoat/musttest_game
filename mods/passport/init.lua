
-- This mod provides an item which enables players to teleport to registered locations without the need of a teleporter.
-- This item doubles as the means by which the server control scripts decide which playerfiles to delete and which to keep.

if not minetest.global_exists("passport") then passport = {} end
passport.recalls = passport.recalls or {}
passport.players = passport.players or {}
passport.player_recalls = passport.player_recalls or {}
passport.registered_players = passport.registered_players or {} -- Cache of registered players.
passport.keyed_players = passport.keyed_players or {}
passport.modpath = minetest.get_modpath("passport")

-- List of players with open keys.
-- On formspec close, playername should be removed and close-sound played.
passport.open_keys = passport.open_keys or {}

-- Localize for performance.
local F = minetest.formspec_escape   
  local vector_distance = vector.distance
   local vector_round = vector.round
	  local vector_add = vector.add
	local math_floor = math.floor
 local math_random = math.random



local PASSPORT_TELEPORT_RANGE = 750

minetest.register_privilege("recall", {
  description = "Player can request a teleport to nearby recall beacons.",
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



-- Public API function. Only used by jail mod.
passport.register_recall = function(recalldef)
    local name = recalldef.name
    local position = recalldef.position
    local min_dist = recalldef.min_dist
    local on_success = recalldef.on_success
    local on_failure = recalldef.on_failure
    local tname = recalldef.codename
    local suppress = recalldef.suppress
    local idx = #(passport.recalls) + 1
    local code = "z" .. idx .. ""
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



function passport.beacons_to_recalls(beacons)
	local recalls = {}
	for k, v in ipairs(beacons) do
		local idx = #recalls + 1
		local real_label = rc.pos_to_string(v.pos)
		if v.name ~= nil and v.name ~= "" then
			real_label = v.name
		end
    recalls[idx] = {
      name = real_label,
      position = function() return vector_add(v.pos, {x=0, y=1, z=0}) end,
      code = "v" .. idx .. "",
      min_dist = 30,
    }
	end
	return recalls
end



passport.compose_formspec = function(pname)
  local buttons = ""
  
  local i = 1
  for k, v in pairs(passport.recalls) do
    local n = F(v.name)
    local c = v.code
		if v.tname == "jail:jail" then
			buttons = buttons .. "button_exit[3,5.7;2,1;" .. c .. ";" .. n .. "]"
		else
			buttons = buttons .. "button_exit[6," .. (i-0.3) .. ";3,1;" .. c .. ";" .. n .. "]"
			i = i + 1
		end
  end

	local pref = minetest.get_player_by_name(pname)
	local beacons = {}
	if pref then
		local player_pos = pref:get_pos()
		-- Shall return an empty table if there are no beacons.
		beacons = teleports.nearest_beacons_to_position(player_pos, 6, 1000)
	end
	passport.player_recalls[pname] = passport.beacons_to_recalls(beacons)
  
  local h = 1
  for k, v in ipairs(passport.player_recalls[pname]) do
    local n = F(v.name)
    local c = v.code
		buttons = buttons .. "button_exit[6," .. (h-0.3) .. ";3,1;" .. c .. ";" .. n .. "]"
		h = h + 1
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
		"label[1,0.0;Key of Citizenship Interface]" ..
		"label[6,0.0;Recalls Nearby (" .. #beacons .. ")]" ..
    buttons ..
    "button_exit[1,5.7;2,1;exit;Close]" ..
    "button_exit[1,2.7;2,1;mapfix;Fix Map]" ..
    "button[3,0.7;2,1;email;Mail]" ..
    "button[1,1.7;2,1;survivalist;Survivalist]" ..
    "button[3,1.7;2,1;rename;Nickname]" ..
		"button[3,2.7;2,1;chatfilter;Chat Filter]" ..
		"button[1,0.7;2,1;marker;Markers]" ..

		"tooltip[email;Hold 'E' while using the Key to access directly.]" ..
		"tooltip[marker;Hold 'sneak' while using the Key to access directly.]" ..
    
    "checkbox[3,5.0;togglechat;Text Echo;" ..
      boolecho .. "]" ..
    "checkbox[1,5.0;toggleparticles;Particles;" ..
      boolparticle .. "]" ..

		"tooltip[togglechat;" .. 
				"Toggle whether the server should echo your chat back to your client.\n" ..
				"Newer clients should keep this checked.]" ..
		"tooltip[toggleparticles;" .. 
				"Toggle whether the server should send game-enhancing particle effects to your client.\n" ..
				"Sometimes these are purely for visual effect, sometimes they have gameplay meaning...]"

	-- Special abilities are revoked for cheaters.
	if not sheriff.is_cheater(pname) then
		local admin = gdac.player_is_admin(pname)

		if survivalist.player_beat_cave_challenge(pname) or admin then
			formspec = formspec .. "button[1,3.7;2,1;jaunt;Jaunt]"
		end

		if survivalist.player_beat_nether_challenge(pname) or admin then
			if cloaking.is_cloaked(pname) then
				formspec = formspec .. "button[3,3.7;2,1;cloak;Uncloak]"
			else
				formspec = formspec .. "button[3,3.7;2,1;cloak;Cloak]"
			end
		end
	end

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

	local status_info = {}

	if pref then
		local player_pos = pref:get_pos()
		local city_info = city_block.city_info(player_pos)

		if city_info then
			if city_info.pvp_arena then
				status_info[#status_info + 1] = "Dueling Arena"
			else
				status_info[#status_info + 1] = "Lawful Zone"
			end

			local count = 0
			local targets = minetest.get_connected_players()
			for k, v in ipairs(targets) do
				-- Ignore admin, don't count self.
				if not gdac.player_is_admin(v) and v ~= pref then
					local tpos = v:get_pos()
					-- Ignore far, ignore dead.
					if vector_distance(player_pos, tpos) < 100 and v:get_hp() > 0 then
						count = count + 1
					end
				end
			end

			status_info[#status_info + 1] = (count .. " nearby")
		end
	end

	if cloaking.is_cloaked(pname) then
		status_info[#status_info + 1] = "Cloaked"
	elseif player_labels.query_nametag_onoff(pname) == false then
		status_info[#status_info + 1] = "Name OFF"
	end

	local scale = 500

	status_info[#status_info + 1] = tostring(math_floor(pref:get_hp() / scale) .. " HP")
	status_info[#status_info + 1] = tostring("Respawns: " .. beds.get_respawn_count(pname))

	-- Status info.
	formspec = formspec .. "label[1,6.6;Status: " .. F(table.concat(status_info, " | ")) .. "]"
  
  return formspec
end



passport.show_formspec = function(pname)
  local formspec = passport.compose_formspec(pname)
  minetest.show_formspec(pname, "passport:passport", formspec)
end



passport.on_use = function(itemstack, user, pointed)
	local changed = false

  if user and user:is_player() then
		local pname = user:get_player_name()

		-- Check (and if needed, set) owner.
		local meta = itemstack:get_meta()
		local owner = meta:get_string("owner")
		if owner == "" then
			owner = pname

			-- Store owner and data of activation.
			meta:set_string("owner", owner)
			meta:set_int("date", os.time())

			minetest.after(3, function()
				minetest.chat_send_player(pname, "# Server: A newly initialized Key of Citizenship begins to emit a soft blue glow.")
			end)

			changed = true
		end

		-- Initialize data if not set.
		if meta:get_int("date") == 0 then
			meta:set_int("date", os.time())

			changed = true
		end

		if owner ~= pname then
			minetest.chat_send_player(pname, "# Server: This Key was initialized by someone else! You cannot access it.")
			easyvend.sound_error(pname)
			return
		end

		-- Record number of uses.
		meta:set_int("uses", meta:get_int("uses") + 1)
		changed = true

		local control = user:get_player_control()
		if control.sneak then
			marker.show_formspec(pname)
		elseif control.aux1 then
			mailgui.show_formspec(pname)
		else
			-- Show KoC interface.
			passport.show_formspec(pname)
		end
		passport.open_keys[pname] = true
		local ppos = user:get_pos()
		minetest.after(0, ambiance.sound_play, "fancy_chime1", ppos, 1.0, 20, "", false)
  end

	if changed then
		return itemstack
	end
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

	if fields.marker then
		marker.show_formspec(pname)
		return true
	end

	if fields.jaunt and survivalist.player_beat_cave_challenge(pname) then
		-- Jaunt code performs its own security validation.
		jaunt.show_formspec(pname)
		return true
	end
  
	if fields.cloak and survivalist.player_beat_nether_challenge(pname) then
		-- Security check to make sure player can use this feature.
		if not passport.player_has_key(pname) then
			return true
		end
		if not survivalist.player_beat_nether_challenge(pname) then
			return true
		end

		-- Cloaking ability is revoked for cheaters.
		if sheriff.is_cheater(pname) then
			return true
		end

		cloaking.toggle_cloak(pname)
		passport.show_formspec(pname) -- Reshow formspec.
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

	if passport.player_recalls[pname] then
		for k, v in ipairs(passport.player_recalls[pname]) do
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
	end
  
	for k, v in ipairs(passport.recalls) do
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
  local tg = data.position(player) -- May return nil.
	local recalls = passport.player_recalls[nn]

	if not recalls then
		minetest.chat_send_player(nn, "# Server: No data associated with beacon signal.")
		return
	end

	if not tg then
		minetest.chat_send_player(nn, "# Server: Beacon does not provide position data. Aborting.")
		return
	end

	if rc.current_realm_at_pos(tg) ~= rc.current_realm_at_pos(pp) then
		minetest.chat_send_player(nn, "# Server: Beacon signal is in another dimension!")
		-- Wrong realm.
		return
	end
  
  for k, v in ipairs(recalls) do
    if v.suppress then
      if v.suppress(nn) then
        minetest.chat_send_player(nn, "# Server: Beacon signal is jammed and cannot be triangulated.")
				easyvend.sound_error(nn)
        return -- Someone suppressed the ability to teleport.
      end
    end
  end
  
	-- Is player too close to custom (player-built) recalls?
  for k, v in ipairs(recalls) do
		local vpp = v.position(player) -- May return nil.
		if vpp then
			if vector_distance(pp, vpp) < v.min_dist then
				if data.on_failure then data.on_failure(nn, "too_close", v.tname) end
				minetest.chat_send_player(nn, "# Server: You are too close to a nearby beacon signal.")
				easyvend.sound_error(nn)
				return -- Too close to a beacon.
			end
		end
  end
  
	-- Is player too close to builtin (server) recalls?
  for k, v in ipairs(passport.recalls) do
		local vpp = v.position(player) -- May return nil.
		if vpp then
			if vector_distance(pp, vpp) < v.min_dist then
				if data.on_failure then data.on_failure(nn, "too_close", v.tname) end
				minetest.chat_send_player(nn, "# Server: You are too close to a nearby beacon signal.")
				easyvend.sound_error(nn)
				return -- Too close to a beacon.
			end
		end
  end

  if vector_distance(pp, tg) > PASSPORT_TELEPORT_RANGE then
    if data.on_failure then data.on_failure(nn, "too_far", data.tname) end
		local dist = math_floor(vector_distance(pp, tg))
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
  local dist = vector_distance(pp, tg)
  local time = math.ceil(math.sqrt(dist / 10))
  
  minetest.chat_send_player(nn, "# Server: Recall beacon signal requires " .. time .. " seconds to triangulate; please hold still.")
  passport.players[nn] = true
	local pos = vector.add(tg, {x=math_random(-1, 1), y=0, z=math_random(-1, 1)})
  minetest.after(time, passport.do_teleport, nn, pp, pos, data.on_success)
end



-- Called from minetest.after() to actually execute a teleport.
passport.do_teleport = function(name, start_pos, target_pos, func)
  passport.players[name] = nil
  local player = minetest.get_player_by_name(name)
  if player and player:is_player() then

		if sheriff.is_cheater(name) then
			if sheriff.punish_probability(name) then
				sheriff.punish_player(name)
				return
			end
		end

    if vector_distance(player:get_pos(), start_pos) < 0.1 then
			preload_tp.execute({
				player_name = name,
				target_position = target_pos,
				emerge_radius = 32,
				post_teleport_callback = func,
				callback_param = name,
				send_blocks = true,
				particle_effects = true,
			})
    else
      minetest.chat_send_player(name, "# Server: Unable to accurately triangulate beacon position! Aborted.")
			easyvend.sound_error(name)
    end
  end
end



function passport.exec_spawn(name, param)
	if passport.player_has_key(name) then
		minetest.chat_send_player(name, "# Server: This command is newbies-only.")
		easyvend.sound_error(name)
		return true
	end

	if default.player_attached[name] then
		minetest.chat_send_player(name, "# Server: Cannot teleport to spawn while attached.")
		easyvend.sound_error(name)
		return true
	end

	local player = minetest.get_player_by_name(name)
	if not player then return false end
	local pos = vector_round(player:get_pos())
	if jail.suppress(name) then
		return true
	end
	local target = randspawn.get_respawn_pos(pos, name)
	if vector_distance(pos, target) < 10 then
		minetest.chat_send_player(name, "# Server: Too close to the spawnpoint!")
		easyvend.sound_error(name)
		return true
	end
	if sheriff.is_cheater(name) then
		if sheriff.punish_probability(name) then
			sheriff.punish_player(name)
			return true
		end
	end
	if vector_distance(pos, target) <= 256 then
		randspawn.reposition_player(name, pos)

		minetest.after(1, function()
			minetest.chat_send_player(name, "# Server: You have been returned to the spawnpoint.")
			minetest.chat_send_player(name, "# Server: Warning: this command functions as a crutch for new players.")
			minetest.chat_send_player(name, "# Server: It will not be available once you leave the Outback!")
			portal_sickness.on_use_portal(name)
		end)
	else
		minetest.chat_send_player(name, "# Server: You are too far from the spawnpoint!")
		easyvend.sound_error(name)
	end
	return true
end



function passport.award_cash(pname, player)
	local inv = player:get_inventory()
	if not inv then
		return
	end

	local cash_stack = ItemStack("currency:minegeld_20 10")
	local prot_stack = ItemStack("protector:protect3")

	local cash_left = inv:add_item("main", cash_stack)
	local prot_left = inv:add_item("main", prot_stack)

	minetest.chat_send_player(pname,
		core.get_color_escape_sequence("#ffff00") ..
		"# Server: Bank notice - As this is the first recorded time you have obtained a PoC, the Colony grants you 200 minegeld.")

	if cash_left:is_empty() and prot_left:is_empty() then
		minetest.chat_send_player(pname,
			core.get_color_escape_sequence("#ffff00") ..
			"# Server: The cash has been directly added to your inventory. Trade wisely and well, Adventurer!")
	else
		local pos = vector_round(player:get_pos())
		pos.y = pos.y + 1

		if not cash_left:is_empty() then
			minetest.add_item(pos, cash_left)
		end
		if not prot_left:is_empty() then
			minetest.add_item(pos, prot_left)
		end

		minetest.chat_send_player(pname,
			core.get_color_escape_sequence("#ffff00") ..
			"# Server: The cash could not be added to your inventory (no space). Check near your position for drops.")
	end
end



function passport.on_craft(itemstack, player, old_craft_grid, craft_inv)
	local name = itemstack:get_name()
	if name == "passport:passport_adv" then
		local pname = player:get_player_name()
		local meta = itemstack:get_meta()

		-- Store owner and data of activation.
		meta:set_string("owner", pname)
		meta:set_int("date", os.time())

		minetest.after(3, function()
			minetest.chat_send_player(pname,
				"# Server: A newly fashioned Key of Citizenship emits a soft blue glow mere moments after its crafter finishes the device.")
		end)

		-- Add this user to the VPN whitelist.
		-- VPN-based blocking is for new players and hit-&-run trolls, not established players (even if they do turn out to be trouble)!
		anti_vpn.whitelist_player(pname, true)

		-- Clear cache of player registration.
		passport.keyed_players[pname] = nil
		passport.registered_players[pname] = nil
	elseif name == "passport:passport" then
		-- Check if this is the first time this player has crafted a PoC.
		local pname = player:get_player_name()
		local meta = passport.modstorage

		local key = pname .. ":crafted_poc"
		if meta:get_int(key) == 0 then
			meta:set_int(key, 1)

			passport.award_cash(pname, player)
		end

		-- Clear cache of player registration.
		passport.keyed_players[pname] = nil
		passport.registered_players[pname] = nil
	end
end



if not passport.registered then
  -- Obtain modstorage.
  passport.modstorage = minetest.get_mod_storage()
  
  -- Keep this in inventory to prevent deletion.
  minetest.register_craftitem("passport:passport", {
    description = "Proof of Citizenship\n\n" ..
			"Keep this in your MAIN inventory at ALL times!\n" ..
			"This preserves your Account during server purge - it cannot be stolen or lost by dying.\n" ..
			"Can be later upgraded into the KEY, which grants many abilities.",
    inventory_image = "default_bronze_block.png^default_tool_steelpick.png",
		stack_max = 1,
    on_use = function(...) return passport.on_use_simple(...) end,
		on_drop = function(itemstack, dropper, pos) return itemstack end,
  })

  -- Keep this in inventory to prevent deletion.
  minetest.register_craftitem("passport:passport_adv", {
    description = "Key of Citizenship\n\n" ..
			"Keep this in your MAIN inventory at ALL times!\n" ..
			"This preserves your Account during server purge.\n" ..
			"It cannot be stolen or lost by dying.",
    inventory_image = "adv_passport.png",
		stack_max = 1,
    on_use = function(...) return passport.on_use(...) end,
		on_drop = function(itemstack, dropper, pos) return itemstack end,
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
      {'default:mese_crystal_fragment', 'passport:passport', 'quartz:quartz_crystal_piece'},
      {'techcrafts:control_logic_unit', 'battery:battery', 'techcrafts:control_logic_unit'},
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

	minetest.register_on_craft(function(...) passport.on_craft(...) end)

  passport.registered = true
end



-- This function may be called serveral times on player-login and other times.
-- We cache the result on first call.
passport.player_registered = function(pname)
	local all_players = passport.registered_players

	-- Read cache if available.
	local registered = all_players[pname]
	if registered ~= nil then
		return registered
	end

  local player = minetest.get_player_by_name(pname)
  if player and player:is_player() then
    local inv = player:get_inventory()
    if inv then
			if inv:contains_item("main", "passport:passport") or inv:contains_item("main", "passport:passport_adv") then
				all_players[pname] = true -- Cache for next time.
				return true
			else
				all_players[pname] = false -- Cache for next time.
				return false
			end
    end
  end

	-- Return false, but don't cache the value -- we could not confirm it!
  return false
end

-- This checks (and caches the result!) of whether the player has a KEY OF CITIZENSHIP.
-- Second param is optional, may be nil.
passport.player_has_key = function(pname, player)
	local all_players = passport.keyed_players

	-- Read cache if available.
	local keyed = all_players[pname]
	if keyed ~= nil then
		return keyed
	end

  local pref = player or minetest.get_player_by_name(pname)
  if pref then
    local inv = pref:get_inventory()
    if inv then
			if inv:contains_item("main", "passport:passport_adv") then
				all_players[pname] = true -- Cache for next time.
				return true
			else
				all_players[pname] = false -- Cache for next time.
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



function passport.inventory_action(player, action, inventory, inventory_info)
	local pname = player:get_player_name()

	if action == "put" or action == "take" then
		local sname = inventory_info.stack:get_name()
		if sname == "passport:passport_adv" then
			-- Clear cache.
			passport.keyed_players[pname] = nil
		end
	elseif action == "move" then
		local movedstack = player:get_inventory():get_stack(inventory_info.to_list, inventory_info.to_index)
		local sname = movedstack:get_name()
		if sname == "passport:passport_adv" then
			-- Clear cache.
			passport.keyed_players[pname] = nil
		end
	end
end



if minetest.get_modpath("reload") then
	minetest.register_on_player_inventory_action(function(...)
		return passport.inventory_action(...) end)

  local c = "passport:core"
  local f = passport.modpath .. "/init.lua"
  if not reload.file_registered(c) then
    reload.register_file(c, f, false)
  end
end

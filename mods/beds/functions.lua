
beds = beds or {}

-- Reloadable file.
if not beds.run_functions_once then
	local c = "beds:functions"
	local f = beds.modpath .. "/functions.lua"
	reload.register_file(c, f, false)

	beds.run_functions_once = true
end

local pi = math.pi
--local player_in_bed = 0
local enable_respawn = true



local count_players_in_bed = function()
    local count = 0
    for k, v in pairs(beds.player) do
        local nobeds = minetest.check_player_privs(k, {nobeds=true})

				-- Ignore AFK folks.
				if afk_removal.is_afk(k) then
					nobeds = true
				end

				local registered = passport.player_registered(k)
        if not nobeds and registered then
            count = count + 1
        end
    end
    return count
end



local get_participating_players = function()
    local players = minetest.get_connected_players()
    local outp = {}
    for k, v in ipairs(players) do
				local pname = v:get_player_name()
        local nobeds = minetest.check_player_privs(v, {nobeds=true})

				-- Ignore AFK folks.
				if afk_removal.is_afk(pname) then
					nobeds = true
				end

				local registered = passport.player_registered(pname)
        if not nobeds and registered then
            outp[#outp+1] = v
        end
    end
    return outp
end



local function get_look_yaw(pos)
	local n = minetest.get_node(pos)
	if n.param2 == 1 then
		return pi / 2, n.param2
	elseif n.param2 == 3 then
		return -pi / 2, n.param2
	elseif n.param2 == 0 then
		return pi, n.param2
	else
		return 0, n.param2
	end
end



local function is_night_skip_enabled()
	local tod = minetest.get_timeofday()
	if tod > 0.2 and tod < 0.805 then
		-- Consider nobody in beds during daytime.
		return false
	end

	local enable_night_skip = minetest.setting_getbool("enable_bed_night_skip")
	if enable_night_skip == nil then
		enable_night_skip = true
	end
	return enable_night_skip
end



local function check_in_beds()
	local in_bed = beds.player
	local players = get_participating_players()

	for n, player in ipairs(players) do
		local name = player:get_player_name()
		if not in_bed[name] then
			return false
		end
	end

	return #players > 0
end



local function lay_down(player, pos, bed_pos, state, skip)
	local name = player:get_player_name()
	local hud_flags = player:hud_get_flags()

	if not player or not name then
		return
	end

	-- stand up
	if state ~= nil and not state then
		local p = beds.pos[name] or nil
		if beds.player[name] ~= nil then
			beds.player[name] = nil
			--player_in_bed = player_in_bed - 1
		end
		-- skip here to prevent sending player specific changes (used for leaving players)
		if skip then
			return
		end
		if p then
			player:set_pos(p)
		end

		-- physics, eye_offset, etc
		player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		player:set_look_horizontal(math.random(1, 180) / 100)
		default.player_attached[name] = false
		player:set_physics_override(1, 1, 1)
		hud_flags.wielditem = true
		default.player_set_animation(player, "stand" , 30)

	-- lay down
	else
		beds.player[name] = 1
		beds.pos[name] = pos
		--player_in_bed = player_in_bed + 1

		-- physics, eye_offset, etc
		player:set_eye_offset({x = 0, y = -13, z = 0}, {x = 0, y = 0, z = 0})
		local yaw, param2 = get_look_yaw(bed_pos)
		player:set_look_horizontal(yaw)
		local dir = minetest.facedir_to_dir(param2)
		local p = {x = bed_pos.x + dir.x / 2, y = bed_pos.y, z = bed_pos.z + dir.z / 2}
		player:set_physics_override(0, 0, 0)
		player:set_pos(p)
		default.player_attached[name] = true
		hud_flags.wielditem = false
		default.player_set_animation(player, "lay" , 0)
	end

	player:hud_set_flags(hud_flags)
end



local function update_formspecs(finished)
	local ges = #get_participating_players()
	local form_n
    local ppl_in_bed = count_players_in_bed()
    local is_majority = (ges / 2) < ppl_in_bed

    if finished then
        form_n = beds.formspec .. "label[2.7,11;Good morning.]"
    else
        form_n = beds.formspec .. "label[2.2,11;" .. tostring(ppl_in_bed) ..
            " of " .. tostring(ges) .. " players are in bed.]"
        if is_majority and is_night_skip_enabled() then
            form_n = form_n .. "button_exit[2,8;4,0.75;force;Force Night Skip]"
        end
    end

    for name,_ in pairs(beds.player) do
        minetest.show_formspec(name, "beds:detatched_formspec", form_n)
    end
end



function beds.kick_players()
	for name, _ in pairs(beds.player) do
		local player = minetest.get_player_by_name(name)
		lay_down(player, nil, nil, false)
	end
end



function beds.kick_one_player(name)
    local player = minetest.get_player_by_name(name)
    if player and player:is_player() then
        if beds.player[name] ~= nil then
            beds.player[name] = nil
            lay_down(player, nil, nil, false)
            update_formspecs(false)
            return true
        end
    end
end



function beds.skip_night()
	minetest.set_timeofday(0.23)
  
  -- This assumes that players aren't kicked out of beds until after this function runs.
  for k, v in pairs(beds.player) do
    local pname = k
    -- HUD update is ignored if minetest.after() isn't used?
    -- Oh well. A little delay is nice, too.
    minetest.after(0.5, function()
      local player = minetest.get_player_by_name(pname)
      if player then
        -- Heal player 4 HP, but not if the player is dead.
        if player:get_hp() > 0 then
          player:set_hp(player:get_hp() + 4)
        end
        -- Increase player's hunger.
        hunger.increase_hunger(player, 6)

				-- Refill stamina.
				sprint.set_stamina(player, SPRINT_STAMINA)

				-- Notify portal sickness mod.
				--minetest.chat_send_player("MustTest", "# Server: <" .. rename.gpn(pname) .. ">!")
				portal_sickness.on_use_bed(pname)
      end
    end)
  end
end



function beds.report_respawn_status(name)
	--minetest.chat_send_player("MustTest", "# Server: Respawn report!")
	local good = false
	local pos = beds.spawn[name]
  if pos then
		local spawncount = beds.storage:get_int(name .. ":count")
    if spawncount > 0 then
			minetest.chat_send_player(name,
				"# Server: Your home position currently set in the " .. rc.realm_description_at_pos(pos) .. " @ " ..
				rc.pos_to_string(pos) .. " has " .. spawncount .. " respawn(s) left.")
			good = true
		end
	end
	if not good then
		minetest.chat_send_player(name, "# Server: You currently have no home/respawn position set.")
	end
end

local function node_blocks_bed(nn)
  if nn == "air" then return false end

  if string.find(nn, "ladder") or
			string.find(nn, "torch") or
			string.find(nn, "memorandum") then
    return false
  end

  local def = minetest.reg_ns_nodes[nn]
  if def then
    local dt = def.drawtype
    local pt2 = def.paramtype2
    if dt == "airlike" or
       dt == "signlike" or
       dt == "torchlike" or
       dt == "raillike" or
       dt == "plantlike" or
       (dt == "nodebox" and pt2 == "wallmounted") then
      return false
    end
  end

	-- All stairs nodes block bed respawning.
  return true
end

function beds.is_valid_bed_spawn(pos)
	local n1 = minetest.get_node(vector.add(pos, {x=0, y=1, z=0}))
	local n2 = minetest.get_node(vector.add(pos, {x=0, y=2, z=0}))

	if node_blocks_bed(n1.name) or node_blocks_bed(n2.name) then
		return false
	end

	return true
end



function beds.on_rightclick(pos, player)
	pos = vector.round(pos)
  local name = player:get_player_name()
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string("owner") or ""

	-- Not while attached to something else!
	if default.player_attached[name] then
		return
	end
	if player:get_hp() == 0 then
		return
	end

	-- Protection check only needed if bed is not explicitly public.
	if owner ~= "server" then
		if minetest.test_protection(pos, name) then
			minetest.chat_send_player(name, "# Server: You cannot steal that bed!")
			return
		end
	end
  
  if owner == "" then
		-- If bed has no owner, clicker takes ownership.
		local dname = rename.gpn(name)
    meta:set_string("owner", name)
		meta:set_string("rename", dname)
		meta:mark_as_private({"owner", "rename"})
    meta:set_string("infotext", "Bed (Owned by <" .. dname .. ">!)")
	elseif owner == "server" then
		-- Nothing needed so far.
		-- If owner is server, then bed is public and player may use it.
		-- But respawn position must not be set here.
  elseif owner ~= name then
    minetest.chat_send_player(name, "# Server: You cannot sleep here, this bed is not yours!")
    return
  end

	if beds.monsters_nearby(pos, player) then
		minetest.chat_send_player(name, "# Server: You cannot sleep now, there are monsters nearby!")
		beds.report_respawn_status(name)
		return
	end

	if not beds.is_valid_bed_spawn(pos) then
		minetest.chat_send_player(name, "# Server: You cannot use this bed, there is not enough space above it to respawn!")
		beds.report_respawn_status(name)
		return
	end
  
	local ppos = player:getpos()
	local tod = minetest.get_timeofday()

	-- Player can sleep in bed anytime in the nether.
	if ppos.y > -25000 then
		if tod > 0.2 and tod < 0.805 then
			if beds.player[name] then
				lay_down(player, nil, nil, false)
			end
			minetest.chat_send_player(name, "# Server: You can only sleep at night.")
			beds.report_respawn_status(name)
			return
		end
	end

	-- move to bed
	if not beds.player[name] then
		lay_down(player, ppos, pos)

		-- If the bed is public, then player doesn't sethome here, and respawn count is not changed.
		if owner ~= "server" then
			beds.set_spawn(vector.round(pos), name)

			-- Sleeping in a bed refreshes the respawn count for this player.
			-- The player will respawn at this bed as long as their count is
			-- greater than 0.
			local spawncount = 8
			beds.storage:set_int(name .. ":count", spawncount)

			minetest.chat_send_player(name, "# Server: You will respawn in your bed at " .. rc.pos_to_namestr(pos) .. " up to " .. spawncount .. " times.")
			minetest.chat_send_player(name, "# Server: Afterward you will need to sleep again to refresh your respawn position.")
			minetest.chat_send_player(name, "# Server: You may safely dig your previous bed, if you had one set.")
			if survivalist.game_in_progress(name) then
				minetest.chat_send_player(name, "# Server: If you die during the Survival Challenge you will respawn here instead of failing the Challenge.")
			end
		else
			minetest.chat_send_player(name, "# Server: This bed is public, you cannot set-home here.")
		end
	else
		lay_down(player, nil, nil, false)
	end

	update_formspecs(false)

	-- skip the night and let all players stand up
	if check_in_beds() then
		minetest.after(2, function()
            update_formspecs(is_night_skip_enabled())
			if is_night_skip_enabled() then
				beds.skip_night()
				beds.kick_players()
			end
		end)
	end
end



function beds.has_respawn_bed(pname)
	if beds.spawn[pname] then
		return true
	end
end



function beds.clear_player_spawn(pname)
	beds.spawn[pname] = nil
	beds.save_spawns()
end



-- respawn player at bed if enabled and valid position is found
function beds.on_respawnplayer(player)
	local name = player:get_player_name()
	local pos = beds.spawn[name]
	if pos then
		-- Don't preload area, that could allow a cheat.
		-- Update player's position immediately, without delay.
		wield3d.on_teleport()
		player:set_pos(pos)

		-- If player dies in a realm and their bed is in another, then they may
		-- change realms that way.
		rc.notify_realm_update(player, pos)

		local spawncount = beds.storage:get_int(name .. ":count")
		if spawncount <= 1 then
			beds.spawn[name] = nil
			minetest.chat_send_player(name, "# Server: Warning, your bed respawn position is lost! Sleep again to renew it.")
			beds.save_spawns()
		else
			spawncount = spawncount - 1
			beds.storage:set_int(name .. ":count", spawncount)
			minetest.chat_send_player(name, "# Server: " .. spawncount .. " respawn(s) left for that bed!")
		end

		ambiance.sound_play("respawn", pos, 1.0, 10)
	else
		-- If the death position is not known, assume they died in the Abyss.
		local death_pos = rc.static_spawn("abyss")
		if bones.last_known_death_locations[name] then
			death_pos = bones.last_known_death_locations[name]
		end
		-- Tests show that `on_respawnplayer` is only called for existing players
		-- that die and respawn, NOT for newly-joined players!

		--minetest.chat_send_all("death at " .. minetest.pos_to_string(death_pos))
		--minetest.after(1, function() minetest.chat_send_all("on_respawnplayer was called!") end)

		-- Shall place player in the Outback, ALWAYS.
		randspawn.reposition_player(name, death_pos)

		-- If player died in a realm other than the abyss, then give them initial
		-- stuff upon respawning there.
		if rc.current_realm_at_pos(death_pos) ~= "abyss" then
			give_initial_stuff.give(player)
		end
	end

	return true -- Disable regular player placement.
end



function beds.on_joinplayer(player)
	local name = player:get_player_name()
	beds.player[name] = nil
	if check_in_beds() then
		update_formspecs(is_night_skip_enabled())
		if is_night_skip_enabled() then
			beds.skip_night()
			beds.kick_players()
		end
	else
		update_formspecs(false)
	end
end



function beds.on_leaveplayer(player)
	-- Bugfix: if player leaves game while dead, and in bed,
	-- resurrect them. Maybe this avoids issues with ppl logging in dead
	-- and unable to do anything?
	local name = player:get_player_name()

	-- Note: although a player who knows about this code could theoretically
	-- use it to cheat, the cheat is not game-breaking because they would respawn
	-- in their bed anyway.
	if beds.player[name] then
		if player:get_hp() == 0 then
			player:set_hp(1)
		end
	end

	lay_down(player, nil, nil, false, true)
	beds.player[name] = nil
	-- Wrapping this in minetest.after() is necessary.
	minetest.after(0, function()
		if check_in_beds() then
			update_formspecs(is_night_skip_enabled())
			if is_night_skip_enabled() then
				beds.skip_night()
				beds.kick_players()
			end
		else
			update_formspecs(false)
		end
	end)
end



function beds.on_player_receive_fields(player, formname, fields)
	if formname ~= "beds:detatched_formspec" then
		return
	end

	-- Because "Force night skip" button is a button_exit, it will set fields.quit
	-- and lay_down call will change value of player_in_bed, so it must be taken
	-- earlier.
	local pib = count_players_in_bed()
	local ges = get_participating_players()
	local is_majority = ((#ges) / 2) < pib

	if (fields.quit or fields.leave) and not fields.force then
		lay_down(player, nil, nil, false)
		update_formspecs(false)

		portal_sickness.check_sick(player:get_player_name())
	end

	if fields.force then
		if is_majority and is_night_skip_enabled() then
			update_formspecs(true)
			beds.skip_night()
			beds.kick_players()
		else
			update_formspecs(false)
		end
	end
end



-- Detect nearby monsters.
function beds.monsters_nearby(pos, player)
	-- `pos` is the position of the bed.
	-- `player` is the person trying to sleep in a bed.
	local ents = minetest.get_objects_inside_radius(pos, 10)
	for k, v in ipairs(ents) do
		if not v:is_player() then
			local tb = v:get_luaentity()
			if tb and tb.mob then
				if tb.type and tb.type == "monster" then
					-- Found monster in radius.
					return true
				end
			end
		end
	end
end

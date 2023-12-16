
if not minetest.global_exists("beds") then beds = {} end

-- Localize for performance.
local vector_round = vector.round
local math_random = math.random



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
				if afk.is_afk(k) then
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
				if afk.is_afk(pname) then
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

	local enable_night_skip = minetest.settings:get_bool("enable_bed_night_skip")
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
		player:set_look_horizontal(math_random(1, 180) / 100)
		default.player_attached[name] = false
		player:set_physics_override({speed = 1, jump = 1})
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
		local p = {
			x = bed_pos.x + dir.x / 2,
			y = bed_pos.y + 0.5,
			z = bed_pos.z + dir.z / 2,
		}
		player:set_physics_override({speed = 0, jump = 0})
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



function beds.spawn_monsters_near(pos)
	pos = vector.round(pos)

	local minp = vector.offset(pos, -5, -2, -5)
	local maxp = vector.offset(pos, 5, 2, 5)
	local air = minetest.find_nodes_in_area(minp, maxp, "air")

	-- This will almost never happen.
	if not air or #air == 0 then
		return
	end

	local count = math.random(1, 5)

	for k = 1, count do
		local target = air[math.random(1, #air)]
		mob_spawn.spawn_mob_at(target, "stoneman:stoneman")
	end
end



-- This function runs after a successful night skip, for each bed that was used
-- for sleeping.
function beds.check_monsters_accessible(pos)
	pos = vector.round(pos)

	local minp = vector.offset(pos, -30, -10, -30)
	local maxp = vector.offset(pos, 30, 10, 30)
	local air = minetest.find_nodes_in_area(minp, maxp, "air")

	-- This will almost never happen.
	if not air or #air == 0 then
		return
	end

	local function find_ground(pos)
		local p2 = vector.offset(pos, 0, -1, 0)
		local n2 = minetest.get_node(p2)
		local count = 0
		while n2.name == "air" and count < 16 do
			pos = p2
			p2 = vector.offset(pos, 0, -1, 0)
			n2 = minetest.get_node(p2)
			count = count + 1
		end
		return pos
	end

	local startpos = find_ground(air[math.random(1, #air)])

	local count = 0
	while vector.distance(pos, startpos) < 20 and count < 30 do
		startpos = find_ground(air[math.random(1, #air)])
		count = count + 1
	end

	-- If start pos is too close, path could be starting in the same room.
	-- This is not allowed.
	if vector.distance(pos, startpos) < 20 then
		return
	end

	local path = minetest.find_path(startpos, pos, 16, 5, 5)
	if path then
		--minetest.chat_send_player("MustTest", "Path exists.")
		return true
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
					local hp_max = player:get_properties().hp_max
          player:set_hp(player:get_hp() + (hp_max * 0.2))
        end

        -- Increase player's hunger.
        hunger.increase_hunger(player, 6)

				-- Refill stamina.
				sprint.set_stamina(player, SPRINT_STAMINA)

				-- Notify portal sickness mod.
				--minetest.chat_send_player("MustTest", "# Server: <" .. rename.gpn(pname) .. ">!")
				portal_sickness.on_use_bed(pname)

				--[[
				local pos = vector.round(utility.get_middle_pos(player:get_pos()))
				if beds.check_monsters_accessible(pos) then
					beds.spawn_monsters_near(pos)
				end
				--]]
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



function beds.get_respawn_count(pname)
	local pos = beds.spawn[pname]
  if pos then
		local spawncount = beds.storage:get_int(pname .. ":count")
    if spawncount > 0 then
			return spawncount
		end
	end
	return 0
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
	pos = vector_round(pos)
  local name = player:get_player_name()
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string("owner") or ""

	-- Not while attached to something else!
	if default.player_attached[name] or player:get_attach() then
		return
	end
	if player:get_hp() == 0 then
		return
	end

	-- Check if player is moving.
	if vector.length(player:get_velocity()) > 0.001 then
		minetest.chat_send_player(name, "# Server: Stop moving before going to bed!")
		return
	end

  if owner == "" then
		-- If bed has no owner, and pos is not protected, player takes ownership.
		-- Note: this is to prevent player from taking ownership of an unowned bed
		-- in an area protected by someone else.
		if minetest.test_protection(pos, name) then
			minetest.chat_send_player(name, "# Server: You cannot take ownership of this bed due to protection.")
			return
		else
			local dname = rename.gpn(name)
			meta:set_string("owner", name)
			meta:set_string("rename", dname)
			meta:mark_as_private({"owner", "rename"})
			meta:set_string("infotext", "Bed (Owned by <" .. dname .. ">!)")
		end
	elseif owner == "server" then
		-- If owner is server, then bed is public and player may sleep here.
		-- But respawn position must not be set here.
		local others = minetest.get_connected_players()

		-- Check if bed is occupied.
		for k, v in ipairs(others) do
			if v:get_player_name() ~= name then
				if vector.distance(v:get_pos(), pos) < 0.75 then
					minetest.chat_send_player(name, "# Server: This bed is already occupied!")
					return
				end
			end
		end
  elseif owner ~= name then
    minetest.chat_send_player(name, "# Server: You cannot sleep here, this bed is not yours!")
    return
  end

	-- Otherwise, if bed is public OR the bed is owned by the player, then they
	-- are allowed to sleep, even if the bed is protected by someone else (and the
	-- protector wasn't shared, e.g., basic protection).

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
  
	local ppos = player:get_pos()
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
			beds.set_spawn(vector_round(pos), name)

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



function beds.get_respawn_pos_or_nil(pname)
	return beds.spawn[pname]
end



function beds.clear_player_spawn(pname)
	beds.spawn[pname] = nil
	beds.save_spawns()
end



function beds.set_player_spawn(pname, pos)
	beds.spawn[pname] = pos
	beds.save_spawns()
end



-- Respawn player at bed if enabled and valid position is found.
-- Note: this can also be called from /emergency_recall.
function beds.on_respawnplayer(player)
	local name = player:get_player_name()
	local player_meta = player:get_meta()
	local pos = beds.spawn[name]

	-- Record the last respawn time.
	player_meta:set_string("last_respawn_time", tostring(os.time()))

	-- If the player died in MIDFELD, behave as if they don't have a bed, and send
	-- them to the OUTBACK. If they die in the outback after this flag is set, they'll
	-- keep respawning in the outback until they use the gate (bypassing their bed),
	-- at which point the outback gate will send them back to MIDFELD instead of the
	-- overworld.
	--
	-- Note: the point of this convoluted logic is to prevent player from being
	-- able to use flame staffs to cheese their way out of a Survival Challenge.
	-- The issue is that dying in MIDFELD is supposed to be an official means of
	-- re-entering the Outback (without losing your bed). But since that is the
	-- case, I need to make sure that if the player enters the Outback in that way,
	-- that they cannot leave the Outback EXCEPT by returning to MIDFELD.
	if player:get_meta():get_int("abyss_return_midfeld") == 1 then
		-- Unless player's bed is actually IN MIDFELD, in which case just clear the
		-- flag and respawn in their bed.
		if pos and rc.current_realm_at_pos(pos) == "midfeld" then
			-- Respawn in your bed in Midfeld, and clear the flag.
			player:get_meta():set_int("abyss_return_midfeld", 0)
		elseif pos and rc.current_realm_at_pos(pos) == "abyss" then
			-- Do nothing, respawn in the Outback in your bed.
			-- But don't clear the flag.
		else
			-- Respawn in the Outback as if a new player.
			pos = nil
		end
	end

	if pos then
		-- Don't preload area, that could allow a cheat.
		-- Update player's position immediately, without delay.
		wield3d.on_teleport()

		-- If player dies in a realm and their bed is in another, then they may
		-- change realms that way.
		rc.notify_realm_update(player, pos)
		player:set_pos(pos)

		local spawncount = beds.storage:get_int(name .. ":count")
		if spawncount <= 1 then
			beds.spawn[name] = nil
			beds.save_spawns()

			chat_core.alert_player_sound(name)
			local RED = core.get_color_escape_sequence("#ff0000")
			minetest.chat_send_player(name, RED .. "# Server: Warning! Your respawn position is lost!")
		else
			spawncount = spawncount - 1
			beds.storage:set_int(name .. ":count", spawncount)

			if spawncount > 1 then
				minetest.chat_send_player(name, "# Server: " .. spawncount .. " respawns left for that bed.")
			else
				chat_core.alert_player_sound(name)
				local RED = core.get_color_escape_sequence("#ff0000")
				minetest.chat_send_player(name, RED .. "# Server: Alert! Only 1 respawn left for that bed!")
			end
		end

		ambiance.sound_play("respawn", pos, 1.0, 10)
	else
		local death_pos = minetest.string_to_pos(player_meta:get_string("last_death_pos"))

		-- If the death position is not known, assume they died in the Abyss.
		-- This should normally never happen.
		if not death_pos then
			death_pos = rc.static_spawn("abyss")
		end

		-- Tests show that `on_respawnplayer` is only called for existing players
		-- that die and respawn, NOT for newly-joined players!
		--minetest.chat_send_all("death at " .. minetest.pos_to_string(death_pos))
		--minetest.after(1, function() minetest.chat_send_all("on_respawnplayer was called!") end)

		-- Shall place player in the Outback, ALWAYS.
		randspawn.reposition_player(name, death_pos)

		-- If player died in a realm other than the abyss, then give them initial
		-- stuff upon respawning there.
		--
		-- Update: no, this allows an exploit to get lots of noob stuff quickly.
		-- Make them work for their keep!
		--
		-- Update #2: I obviously can't read my own code; this only applied if
		-- player died OUTSIDE the Outback. Putting it back. If you die OUTSIDE the
		-- outback, of course you should get the initial stuff. Initial stuff is
		-- only to be withheld from players who die INSIDE the Outback (b/c in that
		-- case it would be very easy to stack noob items).
		---[[
		if rc.current_realm_at_pos(death_pos) ~= "abyss" then
			give_initial_stuff.give(player)
		end
		--]]
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

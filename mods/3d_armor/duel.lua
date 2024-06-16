
local vector_round = vector.round
local vector_distance = vector.distance
local math_random = math.random

armor.dueling_players = armor.dueling_players or {}
local dueling_players = armor.dueling_players
local ACTIVE_DUEL_PUNCH = nil

-- For best duels, these numbers should be the same.
-- This is just a max size for an arena. You can make smaller, just don't mark
-- the whole area as part of the arena. Minimum size is 1 city block.
local PUBLIC_BED_DISTANCE = 256
local OPPONENT_DISTANCE = 256
local DUEL_MAX_RADIUS = 256

local SPAWN_SAFE_ZONE = 5
local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")

local DUEL_MELEE_STRINGS = {
	"<loser> lost a duel.",
	"<loser> got owned.",
	"<winner> defeated <loser> in a duel.",
	"<loser> lost to <winner>.",
	"<loser> was beat by <winner> in combat!",
	"<winner> crushed <loser> in combat!",
	"<winner> crushed <loser> in a duel.",
	"<winner> totally owned <loser>.",
	"<winner> won a duel with <loser>.",
	"<winner> dealt out a whopping drubbing.",
	"<loser> got <l_himself> a severe drubbing.",
	"<winner> beat <loser> in honorable combat!",
	"<winner> bested <loser>.",
	"<loser> got a royal walloping from <winner>.",
	"<loser> got trashed in a duel by <winner>.",
	"<winner> trashed <loser> in a duel.",
	"<loser> got some major hurt from <winner>.",
	"<winner> gave out a royal swatting to <loser>.",
}

local DUEL_ARROW_STRINGS = {
	"<loser> didn't get out of the way of <winner>'s flying projectile.",
	"<loser> never saw it coming.",
	"<loser> faced down <winner>'s artillery and lost.",
	"<winner> used <loser> for ranged target practice.",
}

local DUEL_STOMP_STRINGS = {
	"<winner> stomped on <loser>'s head.",
	"<loser> was flattened.",
	"<loser> was flattened by <winner>.",
	"<loser> got a taste of jackboot.",
	"<winner> used <loser> to cushion <w_his> fall.",
	"<loser> got <l_himself> some pancaking by <winner>'s boots of steel.",
	"<winner> smashed <loser> into the earth.",
}

local DUEL_SUICIDE_STRINGS = {
	"<loser> killed <l_himself>.",
	"<loser> got a taste of <l_his> own medicine.",
	"<loser> got on the wrong end of <l_his> own weapon.",
	"<loser> suicided.",
	"<loser> ended <l_himself>.",
	"<loser> won a fight with <l_himself>.",
	"<loser> died like a noob: harm self-inflicted.",
	"<loser> self-terminated.",
	"<loser> died: incompetence.",
	"<loser> perished: weapon misuse.",
	"<loser> died: couldn't take what <l_he> dished out.",
}

function armor.hud_update(player, duel_data)
	player:hud_change(duel_data.hud[2], "text",
		"Participants: " .. #(armor.get_likely_opponents(player, duel_data.start_pos)))
end

-- Check whether player is in bounds to duel, and end duel if necessary.
function armor.check_bounds(pname)
	if dueling_players[pname] then
		local pref = minetest.get_player_by_name(pname)

		-- Player left the game unexpectedly.
		if not pref then
			dueling_players[pname] = nil
			minetest.chat_send_all(SHOUT_COLOR .. "# Server: <" .. rename.gpn(pname) .. "> has ended their participation in a duel.")
			return
		end

		local player_pos = vector_round(pref:get_pos())

		local data = dueling_players[pname]
		local in_arena = (city_block:in_pvp_arena(player_pos) and
			minetest.test_protection(player_pos, ""))

		armor.hud_update(pref, data)

		if vector_distance(data.start_pos, player_pos) > DUEL_MAX_RADIUS or not in_arena then
			if vector_distance(data.start_pos, player_pos) < (DUEL_MAX_RADIUS + 50) then
				-- Player is slightly out of bounds. Warn them to return.

				if data.out_of_bounds >= 30 then
					-- Player has been out of bounds for 30 seconds.
					armor.end_duel(pref)
					return
				end

				data.out_of_bounds = data.out_of_bounds + 1
				minetest.chat_send_player(pname, "# Server: Return to the combat zone! (" .. (30 - data.out_of_bounds) .. ").")
			else
				-- Player has completely left the duel area (teleport?) End duel immediately.
				armor.end_duel(pref)
				return
			end
		elseif vector_distance(data.start_pos, player_pos) <= DUEL_MAX_RADIUS and in_arena then
			data.out_of_bounds = 0
		end

		-- Check again.
		minetest.after(1, function() armor.check_bounds(pname) end)
	end
end

-- Call this when a player begins to duel.
function armor.add_dueling_player(player, duel_pos)
	local pname = player:get_player_name()

	if dueling_players[pname] then
		return
	end

	local yoff = 18

	local hud1 = player:hud_add({
		type = "text",
		position = {x=1.00, y=0.30},
		alignment = {x=-1, y=1},
		text = "PvP: Dueling!",
		number = 0xFFFFFF,
		size = {x=1, y=1},
		offset = {x=-16, y=yoff*1},
	})

	local hud2 = player:hud_add({
		type = "text",
		position = {x=1.00, y=0.30},
		alignment = {x=-1, y=1},
		text = "Participants: " .. #(armor.get_likely_opponents(player, duel_pos)),
		number = 0xFFFFFF,
		size = {x=1, y=1},
		offset = {x=-16, y=yoff*2},
	})

	local hud3 = player:hud_add({
		type = "text",
		position = {x=1.00, y=0.30},
		alignment = {x=-1, y=1},
		text = "Spawnpoints: " .. #(armor.get_public_spawns(duel_pos)),
		number = 0xFFFFFF,
		size = {x=1, y=1},
		offset = {x=-16, y=yoff*3},
	})

	local cb = city_block.get_block(duel_pos)
	local arena_name = ""
	if cb.area_name and cb.area_name ~= "" then
		arena_name = cb.area_name
	end
	local hud4 = player:hud_add({
		type = "text",
		position = {x=1.00, y=0.30},
		alignment = {x=-1, y=1},
		text = "Arena: " .. arena_name,
		number = 0xFFFFFF,
		size = {x=1, y=1},
		offset = {x=-16, y=yoff*0},
	})

	local hud5 = player:hud_add({
		type = "waypoint",
		name = "Arena Marker",
		number = 0xFFFFFF,
		world_pos = duel_pos,
	})

	local beds = {}
	local spawns = armor.get_public_spawns(duel_pos)
	for k = 1, #spawns do
		local id = player:hud_add({
			type = "waypoint",
			name = "Respawn Point",
			number = 0xFFFFFF,
			world_pos = spawns[k],
			precision = 0,
		})
		beds[#beds + 1] = id
	end

	dueling_players[pname] = {
		start_time = os.time(),
		start_pos = duel_pos,
		out_of_bounds = 0,
		hud = {hud1, hud2, hud3, hud4, hud5, beds},
	}

	minetest.chat_send_all(SHOUT_COLOR .. "# Server: <" .. rename.gpn(pname) .. "> has agreed to participate in a duel!")
	chat_core.alert_player_sound(pname)
	minetest.after(1, function() armor.check_bounds(pname) end)

	return true
end

-- End current duel if one in progress.
function armor.end_duel(player)
	local pname = player:get_player_name()
	if dueling_players[pname] then
		local data = dueling_players[pname]

		if data.hud then
			for k = 1, #data.hud do
				if type(data.hud[k]) == "table" then
					for j = 1, #data.hud[k] do
						player:hud_remove(data.hud[k][j])
					end
				else
					player:hud_remove(data.hud[k])
				end
			end
		end

		data.hud = nil
		dueling_players[pname] = nil

		minetest.chat_send_all(SHOUT_COLOR .. "# Server: <" .. rename.gpn(pname) .. "> has ended their participation in a duel.")
		chat_core.alert_player_sound(pname)
	end
end

-- Get nearby players, not admins, not self.
function armor.get_likely_opponents(player, pos)
	local targets = {}
	local pname = player:get_player_name()
	local players = minetest.get_connected_players()

	for k = 1, #players do
		local pref = players[k]
		if not gdac.player_is_admin(pref) then
			if pname ~= pref:get_player_name() then
				if vector_distance(pos, pref:get_pos()) < OPPONENT_DISTANCE then
					-- The player needs to have signaled their intent to duel.
					if dueling_players[pref:get_player_name()] then
						targets[#targets + 1] = pref
					end
				end
			end
		end
	end

	-- Sort opponents, nearest players first.
	table.sort(targets,
		function(a, b)
			local d1 = vector_distance(a:get_pos(), pos)
			local d2 = vector_distance(b:get_pos(), pos)
			return d1 < d2
		end)

	return targets
end

-- Get nearby public spawns IN a PvP zone.
function armor.get_public_spawns(pos)
	local targets = {}
	local spawns = beds.nearest_public_spawns(pos, 5, PUBLIC_BED_DISTANCE)

	for k = 1, #spawns do
		-- Only include public spawns which are in a PvP arena.
		if city_block:in_pvp_arena(spawns[k]) then
			targets[#targets + 1] = spawns[k]
		end
	end

	-- Already sorted by distance.
	return targets
end

local function print_message(victim, punch_info)
	local killer = minetest.get_player_by_name(punch_info.hitter)
	local pname = victim:get_player_name()
	local kname = killer:get_player_name()
	local spamkey = "duel:" .. pname .. ":" .. kname

	if pname == punch_info.victim and kname == punch_info.hitter then
	if not spam.test_key(spamkey) then
		local msg

		if pname == kname then
			msg = DUEL_SUICIDE_STRINGS[math_random(1, #DUEL_SUICIDE_STRINGS)]
		elseif punch_info.stomp then
			msg = DUEL_STOMP_STRINGS[math_random(1, #DUEL_STOMP_STRINGS)]
		elseif punch_info.arrow then
			msg = DUEL_ARROW_STRINGS[math_random(1, #DUEL_ARROW_STRINGS)]
		else
			msg = DUEL_MELEE_STRINGS[math_random(1, #DUEL_MELEE_STRINGS)]
		end

		-- I can hear the snowflakes screaming "sexist" rn LOL.
		-- This is like holy water on a vampire!
		local psex = skins.get_gender_strings(pname)
		local ksex = skins.get_gender_strings(kname)

		msg = msg:gsub("<loser>", "<" .. rename.gpn(pname) .. ">")
		msg = msg:gsub("<winner>", "<" .. rename.gpn(kname) .. ">")

		msg = string.gsub(msg, "<w_himself>", ksex.himself)
		msg = string.gsub(msg, "<w_his>", ksex.his)
		msg = string.gsub(msg, "<w_him>", ksex.him)
		msg = string.gsub(msg, "<w_he>", ksex.he)

		msg = string.gsub(msg, "<l_himself>", psex.himself)
		msg = string.gsub(msg, "<l_his>", psex.his)
		msg = string.gsub(msg, "<l_him>", psex.him)
		msg = string.gsub(msg, "<l_he>", psex.he)

		if string.find(msg, "<w>") then
			local hitter = minetest.get_player_by_name(kname)
			if hitter then
				local wield = hitter:get_wielded_item()
				local def = minetest.registered_items[wield:get_name()]
				local meta = wield:get_meta()
				local description = meta:get_string("description")
				if description ~= "" then
					msg = string.gsub(msg, "<w>", "'" .. utility.get_short_desc(description):trim() .. "'")
				elseif def and def.description then
					local str = utility.get_short_desc(def.description)
					if str == "" then
						str = "Potato Fist"
					end
					msg = string.gsub(msg, "<w>", str)
				end
			end
		end

		minetest.chat_send_all("# Server: " .. msg)
		spam.mark_key(spamkey, 10)
	end
	end
end

local function heal_player(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

  local hp_max = pova.get_active_modifier(pref, "properties").hp_max
	pref:set_hp(hp_max, {reason="heal_command"})
	sprint.set_stamina(pref, SPRINT_STAMINA)
	bones.nohack.on_respawnplayer(pref)

	minetest.chat_send_player(pname, "# Server: You respawned.")
end

local function respawn_victim(player, respawn_pos)
	local pname = player:get_player_name()
	local duel_info = dueling_players[pname]
	duel_info.no_respawn_protection = nil

	preload_tp.execute({
		player_name = pname,
		target_position = respawn_pos,
		emerge_radius = 32,

		post_teleport_callback = function()
			ambiance.sound_play("respawn", respawn_pos, 0.5, 10)
			minetest.after(1, heal_player, pname)
		end,

		force_teleport = true,
		send_blocks = false,
		particle_effects = false,
	})
end

local function spawn_bones(pos, pname, hname)
	pos = vector_round(pos)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local data = dueling_players[pname]
	if not data then
		return
	end

	-- Prevent placing bones near any of the public spawns.
	local spawns = armor.get_public_spawns(data.start_pos)
	for k = 1, #spawns do
		if vector_distance(pos, spawns[k]) < SPAWN_SAFE_ZONE then
			return
		end
	end

	pos = armor.find_ground_by_raycast(pos, pref)
	if minetest.get_node(pos).name == "air" then
		minetest.set_node(pos, {name="bones:bones_type2", param2=math_random(0, 3)})
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext",
			"Duel: <" .. rename.gpn(pname) .. ">'s bones.\n" ..
			"Slain by <" .. rename.gpn(hname) .. ">.")
		meta:set_int("protection_cancel", 1)
		meta:mark_as_private("protection_cancel")
	end
end

local function spawn_bones_after(pos, pname, hname)
	minetest.after(0, spawn_bones, pos, pname, hname)
end

local function debug_print(msg)
	--minetest.chat_send_all(msg)
end

-- Cityblock punch handler uses this to check if a player should receive any
-- damage at all. This is somewhat like jails, where brawling is not allowed.
function armor.have_dueling_respawn_protection(player, hitter)
	local pname = player:get_player_name()
	local hname = hitter:get_player_name()
	local player_pos = vector_round(player:get_pos())

	if dueling_players[pname] and dueling_players[hname] then
		local duel_info = dueling_players[pname]

		-- Hitter is punching, disable their respawn protection.
		dueling_players[hname].no_respawn_protection = true
		debug_print('respawn protection canceled for: ' .. hname)

		-- Shortcut if respawn protection is already disabled for this player.
		if duel_info.no_respawn_protection then
			debug_print('no respawn protection: ' .. pname)
			return
		end

		local spawns = armor.get_public_spawns(duel_info.start_pos)

		-- Prevent damage to player if they're in a spawn area.
		for k = 1, #spawns do
			if vector_distance(player_pos, spawns[k]) < SPAWN_SAFE_ZONE then
				local key = "duel:spawnprotection:" .. pname
				if not spam.test_key(key) then
					minetest.chat_send_player(pname, "# Server: You were hit, but it reflected off your respawn protection.")
					spam.mark_key(key, 2)
				end
				return true
			end
		end
	end
end

-- Called from the armor HP-change code only if player would die.
function armor.handle_pvp_arena_death(hp_change, player)
	local pname = player:get_player_name()
	local player_pos = vector_round(player:get_pos())
	debug_print('pos: ' .. minetest.pos_to_string(player_pos) .. ': ' .. pname)

	-- Player must have signaled their intent to duel.
	if dueling_players[pname] then
		debug_print('dead player is dueling: ' .. pname)
		local duel_info = dueling_players[pname]

		-- PvP arena must be marked and protected.
		if city_block:in_pvp_arena(player_pos) then
			debug_print('in pvp arena: ' .. pname)
			if minetest.test_protection(player_pos, "") then
				debug_print('is_protected: ' .. pname)

				local opponents = armor.get_likely_opponents(player, duel_info.start_pos)
				local spawns = armor.get_public_spawns(duel_info.start_pos)

				debug_print('opponents: ' .. #opponents .. ': ' .. pname)
				debug_print('spawns: ' .. #spawns .. ': ' .. pname)

				-- Get notified punch info (from cityblock punch handler callback).
				-- Set global punch info to nil so we don't mistakenly use stale data later.
				local punch_info = ACTIVE_DUEL_PUNCH
				ACTIVE_DUEL_PUNCH = nil

				debug_print('punch info: ' .. dump(punch_info) .. ': ' .. pname)

				-- There must be nearby opponents and nearby spawns.
				-- No opponents == no duel, no spawns == not valid arena.
				if #opponents > 0 and #spawns > 0 and punch_info then
					-- The hitter must also be in the duel.
					-- PvP arenas are not meant to be used as defense against bastards!
					-- Duels are between friends, or frenemies.
					local hitter_is_dueling = false
					if punch_info.hitter and dueling_players[punch_info.hitter] then
						hitter_is_dueling = true
					end

					if hitter_is_dueling then
						-- If player has only 1 HP, they were already "dead" as far as we're concerned.
						if player:get_hp() > 1 then
							debug_print('handling duel death: ' .. pname)

							-- Death sound needs to play before we respawn the player.
							coresounds.play_death_sound(player, pname)

							-- We MUST wait until next server step to spawn bones, because
							-- bones cancel protection, which would confuse the arena code and
							-- cause the player to die a real death! This can happen if two or
							-- more players die at the exact same time in the same spot
							-- (e.g., murder-suicide with a TNT arrow).
							spawn_bones_after(player_pos, pname, punch_info.hitter)

							-- Send taunt.
							print_message(player, punch_info)

							-- Send victim to a respawn point.
							respawn_victim(player, spawns[math_random(1, #spawns)])
						end

						debug_print('preventing real death: ' .. pname)

						-- Prevent real death, and all its consequences.
						-- Player will be fully healed after they teleport to a public spawn.
						-- Note: if player HP is 1, this should return 0 (no hp change allowed).
						if player:get_hp() <= 1 then
							return 0
						end
						return -(player:get_hp() - 1)
					end
				end
			else
				debug_print('NOT PROTECTED: ' .. pname)
			end
		end
		-- Player is dueling, but arena checks didn't pass.
	end

	-- Otherwise, do not interfere with normal damage to player.
	return hp_change
end



-- Used to query if this location is a valid combat arena.
function armor.is_valid_arena(pos)
	pos = vector_round(pos)
	if city_block:in_pvp_arena(pos) then
		if minetest.test_protection(pos, "") then
			if #(armor.get_public_spawns(pos)) >= 2 then
				return true
			end
		end
	end
end



-- Called by the cityblock punch handler.
function armor.notify_duel_punch(victim_name, hitter_name, stomp_flag, ranged_flag)
	ACTIVE_DUEL_PUNCH = {
		victim = victim_name,
		hitter = hitter_name,
		stomp = stomp_flag,
		arrow = ranged_flag,
	}
end

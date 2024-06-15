
local vector_round = vector.round
local vector_distance = vector.distance
local math_random = math.random

armor.dueling_players = armor.dueling_players or {}
local dueling_players = armor.dueling_players

local PUBLIC_BED_DISTANCE = 150
local OPPONENT_DISTANCE = 75
local DUEL_MAX_RADIUS = 256

local DUEL_DEFEAT_STRINGS = {
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
	"<loser> got themselves a severe drubbing.",
	"<winner> beat <loser> in honorable combat!",
	"<winner> bested <loser>.",
	"<loser> got a royal walloping from <winner>.",
	"<loser> got trashed in a duel by <winner>.",
	"<winner> trashed <loser> in a duel.",
	"<loser> got some major hurt from <winner>.",
	"<winner> gave out a royal swatting to <loser>.",
}

-- Check whether player is in bounds to duel, and end duel if necessary.
local function check_bounds(pname)
	if dueling_players[pname] then
		local pref = minetest.get_player_by_name(pname)

		-- Player left the game unexpectedly.
		if not pref then
			dueling_players[pname] = nil
			return
		end

		local player_pos = vector_round(pref:get_pos())

		local data = dueling_players[pname]
		local in_arena = (city_block:in_pvp_arena(player_pos) and
			minetest.test_protection(player_pos, ""))

		if vector_distance(data.start_pos, player_pos) > DUEL_MAX_RADIUS or not in_arena then
			if vector_distance(data.start_pos, player_pos) < (DUEL_MAX_RADIUS + 50) then
				-- Player is slightly out of bounds. Warn them to return.

				if data.out_of_bounds >= 30 then
					-- Player has been out of bounds for 30 seconds.
					armor.end_duel(pref)
					return
				end

				data.out_of_bounds = data.out_of_bounds + 1
				minetest.chat_send_player(pname, "# Server: Return to the duel! (" .. (30 - data.out_of_bounds) .. ").")
			else
				-- Player has completely left the duel area (teleport?) End duel immediately.
				armor.end_duel(pref)
				return
			end
		elseif vector_distance(data.start_pos, player_pos) <= DUEL_MAX_RADIUS and in_arena then
			data.out_of_bounds = 0
		end

		-- Check again.
		minetest.after(1, check_bounds, pname)
	end
end

-- Call this when a player begins to duel.
function armor.add_dueling_player(player)
	local pname = player:get_player_name()

	if dueling_players[pname] then
		return
	end

	dueling_players[pname] = {
		start_time = os.time(),
		start_pos = vector_round(player:get_pos()),
		out_of_bounds = 0,
	}

	minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> has agreed to duel!")
	minetest.after(1, check_bounds, pname)

	return true
end

-- End current duel if one in progress.
function armor.end_duel(player)
	local pname = player:get_player_name()
	if dueling_players[pname] then
		dueling_players[pname] = nil
		minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> has ended the duel.")
	end
end

-- Get nearby players, not admins, not self.
local function get_likely_opponents(player, pos)
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
local function get_public_spawns(pos)
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

local function print_message(victim, killer)
	local pname = victim:get_player_name()
	local kname = killer:get_player_name()
	local spamkey = "duel:" .. pname .. ":" .. kname

	if not spam.test_key(spamkey) then
		local msg = DUEL_DEFEAT_STRINGS[math_random(1, #DUEL_DEFEAT_STRINGS)]
		msg = msg:gsub("<loser>", "<" .. rename.gpn(pname) .. ">")
		msg = msg:gsub("<winner>", "<" .. rename.gpn(kname) .. ">")
		minetest.chat_send_all("# Server: " .. msg)
		spam.mark_key(spamkey, 10)
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

	minetest.chat_send_player(pname, "# Server: You respawned.")
end

local function respawn_victim(player, respawn_pos)
	local pname = player:get_player_name()
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

local function spawn_bones(player)
	local pname = player:get_player_name()
	local pos = vector_round(player:get_pos())
	if minetest.get_node(pos).name == "air" then
		minetest.set_node(pos, {name="bones:bones_type2", param2=math_random(0, 3)})
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Duel: <" .. rename.gpn(pname) .. ">'s bones.")
		meta:set_int("protection_cancel", 1)
		meta:mark_as_private("protection_cancel")
	end
end

-- Called from the armor HP-change code only if player would die.
function armor.handle_pvp_arena_death(hp_change, player)
	local pname = player:get_player_name()
	local player_pos = vector_round(player:get_pos())

	-- Player must have signaled their intent to duel.
	if dueling_players[pname] then
		--minetest.chat_send_all('dead player is dueling')
		local duel_info = dueling_players[pname]

		-- PvP arena must be marked and protected.
		if city_block:in_pvp_arena(player_pos) then
			--minetest.chat_send_all('in pvp arena')
			if minetest.test_protection(player_pos, "") then
				--minetest.chat_send_all('is_protected')

				local opponents = get_likely_opponents(player, player_pos)
				local spawns = get_public_spawns(duel_info.start_pos)

				--minetest.chat_send_all('opponents: ' .. #opponents)
				--minetest.chat_send_all('spawns: ' .. #spawns)

				-- There must be nearby opponents and nearby spawns.
				-- No opponents == no duel, no spawns == not valid arena.
				if #opponents > 0 and #spawns > 0 then
					-- Death sound needs to play before we respawn the player.
					coresounds.play_death_sound(player, pname)
					spawn_bones(player)

					-- The nearest opponent was probably the killer.
					print_message(player, opponents[1])

					-- Send victim to a respawn point.
					respawn_victim(player, spawns[math_random(1, #spawns)])

					--minetest.chat_send_all('preventing real death')

					-- Prevent real death, and all its consequences.
					-- Player will be fully healed after they teleport to a public spawn.
					return -(player:get_hp() - 1)
				end
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
			if #(get_public_spawns(pos)) > 0 then
				return true
			end
		end
	end
end



-- Called by the cityblock punch handler.
function armor.notify_duel_punch(victim_name, hitter_name, stomp_flag, ranged_flag)
end

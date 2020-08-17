
-- For the future:
-- Reduce checks if the server is laggy (globalstep is slowed down).
-- * Requires: a reliable way to determine current server lag.
-- Increase checks on a player if others report them for cheating.
-- * Requires: a reliable way for players to report cheaters that is not
-- * trivially open to abuse.

ac = ac or {}
ac.modpath = minetest.get_modpath("ac")
ac.wpath = minetest.get_worldpath()
ac.players = ac.players or {} -- Per-player data for this session ONLY.

-- Random delay to first check on player's first join (this session).
ac.initial_delay_min = 1
ac.initial_delay_max = 20

-- Default (base) random delay between player checks.
ac.default_delay_min = 5
ac.default_delay_max = 30

-- Random time to decrease between checks for players in city areas.
ac.city_reduce_min = 1
ac.city_reduce_max = 20

-- Random time to add between checks for players in outlands.
ac.outland_increase_min = 5
ac.outland_increase_max = 30

-- The average amounts of accumulated suspicion per session considered low/high.
-- Average suspicion is calculated by total suspicion ever recorded, divided by
-- number of clean sessions in which no suspicion was recorded (for that player).
ac.low_average_suspicion = 5
ac.high_average_suspicion = 20

-- Random time to decrease between checks for players with high avg suspicion.
ac.high_suspicion_reduce_min = 1
ac.high_suspicion_reduce_max = 10

-- Random time to add between checks for players with low suspicion.
ac.low_suspicion_increase_min = 1
ac.low_suspicion_increase_max = 10

-- Once accumulated suspicion for a single session (not including total suspicion
-- over all sessions) exceeds this amount, player is registered as a confirmed
-- cheater. Note that the player will not automatically be registered as a cheater
-- if they merely have high avg suspicion over multiple sessions.
ac.cheat_registration_threshold = 50

ac.admin_name = "MustTest"

-- Open logfile if not already opened.
if not ac.logfile then
	-- Open file in append mode.
	ac.logfile = io.open(ac.wpath .. "/ac.txt", "a")
end

-- Open mod storage if not already opened.
if not ac.storage then
	ac.storage = minetest.get_mod_storage()
end

function ac.get_suspicion_count(pname)
	if ac.players[pname] then
		if ac.players[pname].suspicion_count then
			-- Must be a non-negative integer.
			return ac.players[pname].suspicion_count
		end
	end
	return 0
end

-- Get timestamp of the last time a cheat was detected by the standard checking
-- function (and its confirmation spawns), not including cheats detected along a
-- path.
function ac.get_last_cheat_time(pname)
	if ac.players[pname] then
		if ac.players[pname].last_cheat_time then
			return ac.players[pname].last_cheat_time
		end
	end
	return 0
end

function ac.get_total_suspicion(pname)
	if ac.players[pname] then
		local cs = ac.get_suspicion_count(pname)

		if ac.players[pname].total_suspicion then
			-- Must be a non-negative integer.
			return ac.players[pname].total_suspicion + cs
		end

		local k = pname .. ":total_suspicion"
		local ts = ac.storage:get_int(k)
		ac.players[pname].total_suspicion = ts
		return ts + cs
	else
		local cs = ac.get_suspicion_count(pname)

		local k = pname .. ":total_suspicion"
		local ts = ac.storage:get_int(k)
		ac.players[pname] = {total_suspicion=ts}
		return ts + cs
	end
	return 0
end

function ac.get_clean_sessions(pname)
	if ac.players[pname] then
		if ac.players[pname].clean_sessions then
			-- Must be a non-negative integer.
			return ac.players[pname].clean_sessions
		end

		local k = pname .. ":clean_sessions"
		local cc = ac.storage:get_int(k)
		ac.players[pname].clean_sessions = cc
		return cc
	else
		local k = pname .. ":clean_sessions"
		local cc = ac.storage:get_int(k)
		ac.players[pname] = {clean_sessions=cc}
		return cc
	end
	return 0
end

function ac.get_position_at_last_check_or_nil(pname)
	if ac.players[pname] then
		if ac.players[pname].last_pos then
			return ac.players[pname].last_pos
		end
	end
end

-- Log to file.
function ac.log_suspicious_act(pname, pos, time, act)
	local s = pname .. "|" .. act .. "|" .. time .. "|" ..
		math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z) ..
		"|" .. ac.get_suspicion_count(pname) .. "\n"
	ac.logfile:write(s)
	ac.logfile:flush()
end

-- Record in current session memory.
-- Note: this may be called out of sequence! Therefore we shouldn't use current
-- time or player's current position.
function ac.record_suspicious_act(pname, time, act)
	local pdata = ac.players[pname]
	if not pdata then
		ac.players[pname] = {}
		pdata = ac.players[pname]
	end

	-- Increment suspicion count.
	pdata.suspicion_count = (pdata.suspicion_count or 0) + 1

	if act == "fly" then
		pdata.fly_count = (pdata.fly_count or 0) + 1
	elseif act == "clip" then
		pdata.clip_count = (pdata.clip_count or 0) + 1
	end

	-- This is used for recording the most recent last time when a cheat was
	-- detected by the cheat-confirmation functions. This should be nil when we're
	-- checking a path, as that is considered "a separate feature". Cheats detected
	-- along a path should all be considered part of the same "instance" of cheating,
	-- so we don't record timestamps in that case.
	if time ~= nil then
		pdata.last_cheat_time = time
	end
end

-- Report to admin (if logged in).
function ac.report_suspicious_act(pname, pos, act)
	local pref = minetest.get_player_by_name(ac.admin_name)
	if pref then
		minetest.chat_send_player(ac.admin_name,
			"# Server: <" .. rename.gpn(pname) ..
			"> caught in suspicious activity: '" .. act .. "' at " ..
			rc.pos_to_namestr(pos) .. ". Suspicion: " ..
			ac.get_suspicion_count(pname) .. ".")
	end
end

function ac.record_player_position(pname, pos)
	local pdata = ac.players[pname]
	if not pdata then
		ac.players[pname] = {}
		pdata = ac.players[pname]
	end

	-- This is for recording the position of the player when they were last
	-- checked by the standard check function. Thus, if the standard check func
	-- detects a possible cheat, following sub-checks that get spawned via
	-- minetest.after() can refer back to the player's position at the first
	-- check.
	pdata.last_pos = pos
end

-- This function is the main "brain" of the AC logic (for fly cheaters).
-- It must be as accurate as possible for a given position!
function ac.is_flying(pos)
	-- We assume that the input position is rounded to nearest integer.
	local under = vector.add(pos, {x=0, y=-1, z=0})
	local node = minetest.get_node(under)

	-- If non-air below this position, then player is probably not flying.
	if node.name ~= "air" then return false end

	-- Check up to 2 meters below player, and 1 meter all around.
	-- Fly cheaters tend to be pretty blatent in their cheating,
	-- and I want to avoid logging players who do a lot of jumping.
	local minp = {x=pos.x-1, y=pos.y-2, z=pos.z-1}
	local maxp = {x=pos.x+1, y=pos.y+0, z=pos.z+1}

	local tb = minetest.find_nodes_in_area(minp, maxp, "air")
	if #tb >= 27 then
		-- If all nodes under player are air, then player is not supported.
		return true
	end

	-- Not flying.
	return false
end

local is_solid_dt = function(dt)
	if dt == "normal" then
		return true
	elseif dt == "glasslike" then
		return true
	elseif dt == "glasslike_framed" then
		return true
	elseif dt == "glasslike_framed_optional" then
		return true
	elseif dt == "allfaces" then
		return true
	elseif dt == "allfaces_optional" then
		return true
	end
end

-- This function is the main "brain" of the AC logic (for noclip cheaters).
-- It must be as accurate as possible for a given position!
function ac.is_clipping(pos)
	-- We assume that the input position is rounded to nearest integer.
	local under = vector.add(pos, {x=0, y=-1, z=0})
	local above = vector.add(pos, {x=0, y=1, z=0})

	local n1 = minetest.get_node(under)
	local n2 = minetest.get_node(pos)
	local n3 = minetest.get_node(above)

	if n1.name ~= "air" and n2.name ~= "air" and n3.name ~= "air" then
		local d1 = minetest.reg_ns_nodes[n1.name]
		local d2 = minetest.reg_ns_nodes[n2.name]
		local d3 = minetest.reg_ns_nodes[n3.name]

		-- One of the nodes is a stairsplus node, or similar.
		if not d1 or not d2 or not d3 then
			return false
		end

		-- Check if all three nodes are solid, walkable nodes.
		if d1.walkable and d2.walkable and d3.walkable then
			local d1d = d1.drawtype
			local d2d = d2.drawtype
			local d3d = d3.drawtype
			if is_solid_dt(d1d) and is_solid_dt(d2d) and is_solid_dt(d3d) then
				return true
			end
		end
	end

	-- Not clipping.
	return false
end

function ac.check_prior_position(pname, pos, time, act)
	local cheat = false

	if act == "fly" then
		if ac.is_flying(pos) then cheat = true end
	elseif act == "clip" then
		if ac.is_clipping(pos) then cheat = true end
	end

	if cheat then
		ac.record_suspicious_act(pname, nil, act) -- Record in current session memory.
		ac.report_suspicious_act(pname, pos, act) -- Report to admin (if logged in).
		ac.log_suspicious_act(pname, pos, time, act) -- Log to file.
	end
end

function ac.check_prior_path(pname, act)
	-- Get prior known locations for this player.
	-- Locations should be provided in order, with timestamps.
	local path = ap.get_position_list(pname)

	-- Spread checking of the path out over a few seconds.
	for i=1, #path, 1 do
		local t = path[i]
		local delay = (math.random(1, 300) / 300) -- Get fractional random number.
		minetest.after(delay, ac.check_prior_position, pname, vector.round(t.pos), t.time, act)
	end
end

function ac.confirm_flying(pname, last_pos)
	-- Check if player still logged on.
	-- This function is designed to be called from minetest.after right after an
	-- initial trigger of suspicion, to try and confirm it.
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local pos = vector.round(pref:get_pos())
		-- If player is falling at least somewhat quickly, then they aren't flying.
		if pos.y < (last_pos.y - 1) then return end

		-- If player stopped flying, then it might have been a false-positive.
		if not ac.is_flying(pos) then return end

		local time = os.time()
		local prevtime = ac.get_last_cheat_time(pname)

		-- If we reach here then the player is still flying!
		ac.record_suspicious_act(pname, time, "fly") -- Record in current session memory.
		ac.report_suspicious_act(pname, pos, "fly") -- Report to admin (if logged in).
		ac.log_suspicious_act(pname, pos, time, "fly") -- Log to file.

		-- Register as confirmed cheater if suspicion for this session exceeds threshold.
		local ts = ac.get_suspicion_count(pname)
		if ts > ac.cheat_registration_threshold then
			if not sheriff.is_cheater(pname) then
				sheriff.register_cheater(pname)
			end
		end

		-- Check the player's prior path if we haven't done so recently.
		if (time - prevtime) > ap.get_record_time() then
			ac.check_prior_path(pname, "fly")
		end
	end
end

function ac.confirm_clipping(pname, last_pos)
	-- Check if player still logged on.
	-- This function is designed to be called from minetest.after right after an
	-- initial trigger of suspicion, to try and confirm it.
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local pos = vector.round(pref:get_pos())

		-- If player stopped clipping, then it might have been a false-positive.
		if not ac.is_clipping(pos) then return end

		local time = os.time()
		local prevtime = ac.get_last_cheat_time(pname)

		-- If we reach here then the player is still clipping!
		ac.record_suspicious_act(pname, time, "clip") -- Record in current session memory.
		ac.report_suspicious_act(pname, pos, "clip") -- Report to admin (if logged in).
		ac.log_suspicious_act(pname, pos, time, "clip") -- Log to file.

		-- Register as confirmed cheater if suspicion for this session exceeds threshold.
		local ts = ac.get_suspicion_count(pname)
		if ts > ac.cheat_registration_threshold then
			if not sheriff.is_cheater(pname) then
				sheriff.register_cheater(pname)
			end
		end

		-- Check the player's prior path if we haven't done so recently.
		if (time - prevtime) > ap.get_record_time() then
			ac.check_prior_path(pname, "clip")
		end
	end
end

function ac.do_standard_check(pname, pref)
	--minetest.chat_send_player(pname, "# Server: Check player!")
	local pos = vector.round(pref:get_pos())

	if ac.is_flying(pos) then
		-- Check again in a moment.
		local delay = math.random(1, 3)
		minetest.after(delay, ac.confirm_flying, pname, pos)
	end

	if ac.is_clipping(pos) then
		-- Check again in a moment.
		local delay = math.random(1, 3)
		minetest.after(delay, ac.confirm_clipping, pname, pos)
	end
end

function ac.nearby_player_count(pname, pref)
	local p1 = pref:get_pos()
	local players = minetest.get_connected_players()
	local count = 0
	for k, v in ipairs(players) do
		if v:get_player_name() ~= pname then
			local p2 = v:get_pos()
			if vector.distance(p1, p2) < 75 then
				count = count + 1
			end
		end
	end
	return count
end

function ac.check_player(pname)
	-- If this player is already a registered cheater, don't bother checking them
	-- for further cheats. Unless such checks ought to trigger immediate punishments
	-- when failed, it's probably a waste of resources.
	if sheriff.is_cheater(pname) then
		return
	end

	-- Check if player still logged in.
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local pp = pref:get_pos()

		-- Don't bother performing checks for dead players.
		if pref:get_hp() > 0 then
			local op = ac.get_position_at_last_check_or_nil(pname)
			-- Don't bother checking player if they haven't moved.
			if not op or vector.distance(pp, op) > 1 then
				-- Don't check players in the Outback.
				if rc.current_realm_at_pos(pp) ~= "abyss" then
					ac.record_player_position(pname, pp)
					ac.do_standard_check(pname, pref)
				end
			end
		end

		-- Check this player again after some delay.
		-- Reduce time to next check if player has some suspicion on them.
		local delay = math.random(ac.default_delay_min, ac.default_delay_max)
		delay = delay - ac.get_suspicion_count(pname)

		if city_block:in_city(pp) then
			-- Decrease time to next check if the position is within the city.
			delay = delay - math.random(ac.city_reduce_min, ac.city_reduce_max)
		elseif not city_block:in_no_leecher_zone(pp) then
			-- Increase time to next check if the position is in the outlands.
			delay = delay + math.random(ac.outland_increase_min, ac.outland_increase_max)
		end

		-- Increase time between standard checks if many players are logged in.
		local players = minetest.get_connected_players()
		delay = delay + ((#players) - 1) * 4

		-- Increase time to next standard check if player has little recorded
		-- suspicion generated from prior sessions. Decrease time to next check if
		-- player's average suspicion levels seem to be high.
		local total_suspicion = ac.get_total_suspicion(pname)
		local clean_sessions = ac.get_clean_sessions(pname)
		if clean_sessions < 1 then clean_sessions = 1 end
		local avg_suspicion = total_suspicion / clean_sessions

		if avg_suspicion < ac.low_average_suspicion then
			delay = delay + math.random(ac.low_suspicion_increase_min, ac.low_suspicion_increase_max)
		elseif avg_suspicion > ac.high_average_suspicion then
			delay = delay - math.random(ac.high_suspicion_reduce_min, ac.high_suspicion_reduce_max)
		end

		-- Reduce time to next check if player is near others.
		local others = ac.nearby_player_count(pname, pref)
		if others > 0 then
			delay = delay - math.random(0, others * 10)
		end

		-- Schedule check not less than 1 second future.
		if delay < 1 then delay = 1 end
		minetest.after(delay, ac.check_player, pname)
	end
end

function ac.on_joinplayer(pref)
	local pname = pref:get_player_name()

	-- Do not perform AC checks for admin player.
	if gdac.player_is_admin(pname) then return end

	local delay = math.random(ac.initial_delay_min, ac.initial_delay_max)

	-- Reduce time to next check if they have some suspicion on them.
	delay = delay - ac.get_suspicion_count(pname)
	if delay < 1 then delay = 1 end

	-- Schedule check.
	minetest.after(delay, ac.check_player, pname)
end

function ac.on_shutdown()
	-- On session shutdown (usually nightly) record overall clean/dirty status for
	-- registered players.
	for pname, pdata in pairs(ac.players) do
		if passport.player_registered(pname) then
			local suspicion = ac.get_suspicion_count(pname)
			if suspicion == 0 then
				local k1 = pname .. ":clean_sessions"
				local k2 = pname .. ":last_session_dirty"
				local cc = ac.storage:get_int(k1)
				cc = cc + 1
				ac.storage:set_int(k1, cc)
				ac.storage:set_int(k2, 0) -- The last session (this one) was clean.
			else
				local k1 = pname .. ":dirty_sessions"
				local k2 = pname .. ":last_session_dirty"
				local k3 = pname .. ":total_suspicion"
				local dd = ac.storage:get_int(k1)
				dd = dd + 1
				ac.storage:set_int(k1, dd)
				ac.storage:set_int(k2, 1) -- The last session (this one) was dirty.

				-- Add suspicion count from this session to the permanent total for this
				-- player.
				local ts = ac.storage:get_int(k3)
				ts = ts + ac.get_suspicion_count(pname)
				ac.storage:set_int(k3, ts)
			end
		end
	end
end

if not ac.registered then
	minetest.register_on_joinplayer(function(...)
		ac.on_joinplayer(...)
	end)

	minetest.register_on_shutdown(function(...)
		ac.on_shutdown(...)
	end)

	local c = "ac:core"
	local f = ac.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ac.registered = true
end

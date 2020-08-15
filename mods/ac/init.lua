
-- For the future:
-- Greatly increase time between checks for players who never trigger suspicion.
-- Increase checks for players in city areas.
-- Reduce checks if the server is laggy (globalstep is slowed down).
-- Reduce checks if many players are logged in.
-- Increase checks on a player if others report them for cheating.
-- Reduce checks for players far from city areas.

ac = ac or {}
ac.modpath = minetest.get_modpath("ac")
ac.wpath = minetest.get_worldpath()
ac.players = ac.players or {} -- Per-player data for this session ONLY.
ac.initial_delay_min = 1
ac.initial_delay_max = 20
ac.default_delay_min = 5
ac.default_delay_max = 30
ac.admin_name = "MustTest"

-- Open logfile if not already opened.
if not ac.logfile then
	-- Open file in append mode.
	ac.logfile = io.open(ac.wpath .. "/ac.txt", "a")
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

function ac.get_position_at_last_check_or_nil(pname)
	if ac.players[pname] then
		if ac.players[pname].last_pos then
			return ac.players[pname].last_pos
		end
	end
end

-- Log to file.
function ac.log_suspicious_act(pname, pos, act)
	local s = pname .. "|" .. act .. "|" .. os.time() .. "|" ..
		math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z) ..
		"|" .. ac.get_suspicion_count(pname) .. "\n"
	ac.logfile:write(s)
	ac.logfile:flush()
end

-- Record in current session memory.
function ac.record_suspicious_act(pname, act)
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

		-- If we reach here then the player is still flying!
		ac.record_suspicious_act(pname, "fly") -- Record in current session memory.
		ac.report_suspicious_act(pname, pos, "fly") -- Report to admin (if logged in).
		ac.log_suspicious_act(pname, pos, "fly") -- Log to file.
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
end

function ac.check_player(pname)
	-- Check if player still logged in.
	local pref = minetest.get_player_by_name(pname)
	if pref then
		-- Don't bother performing checks for dead players.
		if pref:get_hp() > 0 then
			local op = ac.get_position_at_last_check_or_nil(pname)
			local pp = pref:get_pos()
			-- Don't bother checking player if they haven't moved.
			if not op or vector.distance(pp, op) > 1 then
				ac.record_player_position(pname, pp)
				ac.do_standard_check(pname, pref)
			end
		end

		-- Check this player again after some delay.
		-- Reduce time to next check if they have some suspicion on them.
		local delay = math.random(ac.default_delay_min, ac.default_delay_max)
		delay = delay - ac.get_suspicion_count(pname)
		if delay < 1 then delay = 1 end
		minetest.after(delay, ac.check_player, pname)
	end
end

function ac.on_joinplayer(pref)
	local pname = pref:get_player_name()
	local delay = math.random(ac.initial_delay_min, ac.initial_delay_max)

	-- Reduce time to next check if they have some suspicion on them.
	delay = delay - ac.get_suspicion_count(pname)
	if delay < 1 then delay = 1 end

	-- Schedule check.
	minetest.after(delay, ac.check_player, pname)
end

if not ac.registered then
	minetest.register_on_joinplayer(function(...)
		ac.on_joinplayer(...)
	end)

	local c = "ac:core"
	local f = ac.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ac.registered = true
end

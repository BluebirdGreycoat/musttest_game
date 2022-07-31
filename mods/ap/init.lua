
ap = ap or {}
ap.modpath = ap.modpath or minetest.get_modpath("ap")
ap.players = ap.players or {}

-- Number of seconds to keep track of player's reported positions.
-- This must be at least 1 (though such a small value is NOT useful).
ap.record_time = 60*10

-- Localize vector.distance() for performance.
local vector_distance = vector.distance

function ap.get_record_time()
	return ap.record_time
end

function ap.update_players()
	local players = minetest.get_connected_players()
	for i=1, #players, 1 do
		local pref = players[i]
		local p = pref:get_pos() -- Note: position is NOT rounded.
		local t = ap.players[pref:get_player_name()].positions

		-- Don't add position to list of last recorded positions if the player
		-- hasn't moved since last time.
		local add = true
		if #t > 0 then
			local op = t[#t].pos
			if vector_distance(op, p) < 1 then
				add = false
			end
		end

		-- Insert position into player's record (for this session) and remove old
		-- entries from the beginning.
		if add then
			table.insert(t, {pos=p, time=os.time()})
			if #t > ap.record_time then
				table.remove(t, 1)
			end
		end
	end
end

-- Returns a list of positions for this player in the last few seconds,
-- or an empty table if that player wasn't loaded.
-- Each entry is a table in the format {pos, time}.
function ap.get_position_list(pname)
	return ap.players[pname].positions or {}
end

function ap.on_joinplayer(pref)
	ap.players[pref:get_player_name()] = {
		positions = {},
	}
end

function ap.on_leaveplayer(pref)
	ap.players[pref:get_player_name()] = nil
end

local time = 0
function ap.global_step(dtime)
	time = time + dtime
	if time < 1 then return end
	time = 0

	ap.update_players()
end

if not ap.registered then
	local c = "ap:core"
	local f = ap.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	minetest.register_on_joinplayer(function(...)
		ap.on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...)
		ap.on_leaveplayer(...) end)
	minetest.register_globalstep(function(...)
		ap.global_step(...) end)

	ap.registered = true
end

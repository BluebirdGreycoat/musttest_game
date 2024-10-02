
if not minetest.global_exists("ap") then ap = {} end
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
		local pname = pref:get_player_name()
		local p = pref:get_pos() -- Note: position is NOT rounded.
		local t = ap.players[pname].positions

		-- Don't add position to list of last recorded positions if the player
		-- hasn't moved since last time.
		local add = true
		if #t > 0 then
			local op = t[#t].pos
			if vector_distance(op, p) < 0.5 then
				add = false
			end
		end

		-- Insert position into player's record (for this session) and remove old
		-- entries from the beginning.
		if add then
			table.insert(t, {
				pos = p,
				time = os.time(),

				-- Node names.
				snode = sky.get_last_walked_node(pname),
				wnode = sky.get_last_walked_nodeabove(pname),
			})

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
	local data = ap.players[pname]
	if not data then return {} end
	return data.positions or {}
end

function ap.on_joinplayer(pref)
	-- Don't erase evidence.
	local pname = pref:get_player_name()
	if not ap.players[pname] then
		ap.players[pname] = {
			positions = {},
		}
	end
	ap.players[pname].join_time = os.time()
	ap.players[pname].exit_time = nil
end

function ap.on_leaveplayer(pref)
	-- Don't erase evidence right away.
	local pname = pref:get_player_name()
	ap.players[pname].exit_time = os.time()

	minetest.after(ap.get_record_time() + 5, function()
		local data = ap.players[pname]
		if data then
			if data.exit_time and data.exit_time <= (os.time() - ap.get_record_time()) then
				ap.players[pname] = nil
			end
		end
	end)
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

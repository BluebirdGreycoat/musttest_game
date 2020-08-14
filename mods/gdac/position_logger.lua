
gdac.position_logger_path = minetest.get_worldpath() .. "/positions.txt"
gdac.position_logger_players = gdac.position_logger_players or {}

function gdac.position_logger_record(pname, pos, time)
	-- Record format: player|20,190,-4|489128934
	local s = pname .. "|" ..
		math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z) .. "|" ..
		time .. "\n"
	gdac.position_logger_file:write(s)
end

local time = 0
function gdac.position_logger_step(dtime)
	time = time + dtime
	if time < 1 then
		return
	end
	time = 0

	local players = minetest.get_connected_players()
	for i=1, #players, 1 do
		local pref = players[i]
		local pname = pref:get_player_name()
		local prev_pos = gdac.position_logger_players[pname]
		local pos = pref:get_pos()

		if not prev_pos or vector.distance(prev_pos, pos) >= 1 then
			local time = os.time()
			gdac.position_logger_record(pname, pos, time)
		end

		gdac.position_logger_players[pname] = pos
	end
end

-- Code which runs only once per session.
if not gdac.position_logger_registered then
	-- Open log file.
	gdac.position_logger_file = io.open(gdac.position_logger_path, "a")

	-- Register globalstep function.
	minetest.register_globalstep(function(...)
		return gdac.position_logger_step(...)
	end)

	gdac.position_logger_registered = true
end

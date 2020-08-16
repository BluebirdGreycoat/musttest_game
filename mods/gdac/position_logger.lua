
--[[
gdac.position_logger_path = minetest.get_worldpath() .. "/positions.txt"
gdac.position_logger_players = gdac.position_logger_players or {}

function gdac.position_logger_record(pname, pos, time, attached, sneak, sprint, jump)
	local s = pname .. "|" ..
		math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z) .. "|" ..
		time .. "|" .. attached .. "|" .. sneak .. "|" .. sprint .. "|" .. jump .. "\n"
	gdac.position_logger_file:write(s)
end

local yes_attached = "attached"
local not_attached = "detached"
local yes_sneak = "sneaking"
local not_sneak = "no_sneak"
local yes_sprint = "running"
local not_sprint = "not_run"
local yes_jump = "jumping"
local not_jump = "no_jump"

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

		if not gdac.player_is_admin(pname) then
			local prev_pos = gdac.position_logger_players[pname]
			local pos = pref:get_pos()

			if not prev_pos or vector.distance(prev_pos, pos) >= 1 then
				local ctrl = pref:get_player_control()

				local sneak = not_sneak
				local attach = not_attached
				local sprint = not_sprint
				local jump = not_jump

				if ctrl.sneak then
					sneak = yes_sneak
				end
				if ctrl.aux1 then
					sprint = yes_sprint
				end
				if ctrl.jump then
					jump = yes_jump
				end
				if default.player_attached[pname] then
					attach = yes_attached
				end

				local time = os.time()
				gdac.position_logger_record(pname, pos, time, attach, sneak, sprint, jump)
			end

			gdac.position_logger_players[pname] = pos
		end
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
--]]



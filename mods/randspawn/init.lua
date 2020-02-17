
randspawn = randspawn or {}
randspawn.modpath = minetest.get_modpath("randspawn")

function randspawn.check_spawn_reset()
	local meta = randspawn.modstorage
	local stime = meta:get_string("spawn_reset_timer")

	-- If timestamp is missing, then initialize it.
	-- Outback reset will be schedualed after the timeout.
	if not stime or stime == "" then
		local time = os.time()
		local days = 60*60*24*math.random(7, 31)
		time = time + days
		stime = tostring(time)
		meta:set_string("spawn_reset_timer", stime)

		-- Find a new spawn point.
		randspawn.find_new_spawn()
		return
	end

	local now = os.time()
	local later = tonumber(stime) -- Time of future reset (or initialization).

	if now >= later then
		later = later + 60*60*24*math.random(7, 31)
		stime = tostring(later)
		meta:set_string("spawn_reset_timer", stime)

		-- Find a new spawn point.
		randspawn.find_new_spawn()
	end
end
minetest.after(0, function() randspawn.check_spawn_reset() end)



-- Used by the calendar item.
function randspawn.get_spawn_reset_timeout()
	local meta = randspawn.modstorage
	local stime = meta:get_string("spawn_reset_timer")

	local later = tonumber(stime)
	local now = os.time()
	local diff = later - now

	if diff < 0 then diff = 0 end
	return diff
end



local function callback(blockpos, action, calls_remaining, param)
	-- We don't do anything until the last callback.
	if calls_remaining ~= 0 then
		return
	end

	-- Check if there was an error on the LAST call.
	-- Note: this will usually fail if the area to emerge intersects the map edge.
	-- But usually we don't try to do that, here.
	if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
		return
	end

	local pos = param.pos

	-- Start at sea level and check upwards 200 meters to find ground.
	for y = -10, 200, 1 do
		pos.y = y
		local nu = minetest.get_node(pos)
		pos.y = y + 1
		local na = minetest.get_node(pos)

		-- Exit if map not loaded.
		if nu.name == "ignore" or na.name == "ignore" then
			break
		end

		if na.name == "air" and (nu.name == "default:snow" or nu.name == "default:ice") then
			pos.y = pos.y + 1
			serveressentials.update_exit_location(pos)
			return
		end
	end

	-- We didn't find a suitable spawn location. Try again shortly.
	minetest.after(60, function() randspawn.find_new_spawn() end)
end

function randspawn.find_new_spawn()
	-- Call `serveressentials.update_exit_location()` once we have a new spawnpoint.
	local pos = {x=math.random(-6000, 6000), y=0, z=math.random(-6000, 6000)}

	local minp = vector.add(pos, {x=-7, y=-7, z=-7})
	local maxp = vector.add(pos, {x=7, y=200, z=7})

	minetest.emerge_area(minp, maxp, callback, {pos=table.copy(pos)})
end



-- Central square.
--local fallback_pos = {x=0, y=-7, z=0}

--[[
local ab = {
	{pos = {x=0, y=-7, z=0}, name="Central Plaza"}, -- Central.
	{pos = {x=0, y=-7, z=198}, name="North Quarter"}, -- North.
	{pos = {x=198, y=-7, z=0}, name="East Quarter"}, -- East.
	{pos = {x=0, y=-7, z=-198}, name="South Quarter"}, -- South.
	{pos = {x=-198, y=-7, z=0}, name="West Quarter"}, -- West.
}

local positions = {
	[1]=ab[2],
	[2]=ab[3],
	[3]=ab[4],
	[4]=ab[5],
	[5]=ab[2],
	[6]=ab[3],
	[7]=ab[4],
	[8]=ab[5],
	[9]=ab[2],
	[10]=ab[3],
	[11]=ab[4],
	[12]=ab[5],
}
--]]

local function get_respawn_position(death_pos)
	-- Regardless of where player dies, if they have no bed,
	-- then they respawn in the outback. Note that a player may lose their bed if
	-- killed by another player outside of the city.
	return rc.static_spawn("abyss")

	--[[
	-- If player died in the abyss they respawn in the abyss.
	local rn = rc.current_realm_at_pos(death_pos)
	if rn == "abyss" or rn == "" then
		return rc.static_spawn("abyss")
	end
	if rn == "channelwood" or rn == "jarkati" then
		return rc.static_spawn("abyss")
	end

	-- Otherwise player is in the overworld, caverns, or netherealms.
	-- They respawn in one of the cities.

	local tb = os.date("*t")
	local m = tb.month
	if positions[m] and tb.wday ~= 7 and tb.wday ~= 1 then
		local pos = vector.new(positions[m].pos)
		-- If player dies in the nether they respawn in the Nether City.
		if death_pos.y < -25000 then
			pos.y = -30793
		end
		--minetest.chat_send_all("respawn at " .. minetest.pos_to_string(pos))
		return pos
	else
		return fallback_pos
	end
	--]]
end
randspawn.get_respawn_pos = get_respawn_position

-- Note: this is also called from the /spawn chatcommand,
-- but only after validation passes (distance, etc.).
randspawn.reposition_player = function(pname, death_pos)
	local player = minetest.get_player_by_name(pname)
	if player then
		-- Ensure teleport is forced, to prevent a cheat.
		local pos = get_respawn_position(death_pos)
		pos = vector.add(pos, {x=math.random(-2, 2), y=0, z=math.random(-2, 2)})
		preload_tp.preload_and_teleport(pname, pos, 32, nil,
			function()
				ambiance.sound_play("respawn", pos, 0.5, 10)
			end, nil, true)
	end
end

--[[
function randspawn.on_newplayer(player)
	local pname = player:get_player_name()
	local fake_dpos = rc.static_spawn("abyss")
	minetest.after(0.1, function()
		randspawn.reposition_player(pname, fake_dpos)
	end)
end
--]]

-- The calendar item calls this to report the location of the current spawnpoint.
function randspawn.get_spawn_name()
	local s = serveressentials.get_current_exit_location()
	local p = minetest.string_to_pos(s)
	if p then
		return rc.pos_to_namestr(p)
	end

	return "Unknown Location"

	--[[
	local tb = os.date("*t")
	local m = tb.month
	if positions[m] and tb.wday ~= 7 and tb.wday ~= 1 then
		return positions[m].name
	else
		return "Central Plaza"
	end
	--]]
end



if not randspawn.run_once then
	-- Reloadable.
	local file = randspawn.modpath .. "/init.lua"
	local name = "randspawn:core"
	reload.register_file(name, file, false)

	--[[
	minetest.register_on_newplayer(function(...)
		return randspawn.on_newplayer(...)
	end)
	--]]

	randspawn.modstorage = minetest.get_mod_storage()
	randspawn.run_once = true
end

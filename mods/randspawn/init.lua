
if not minetest.global_exists("randspawn") then randspawn = {} end
randspawn.modpath = minetest.get_modpath("randspawn")

-- Localize for performance.
local math_random = math.random

-- After the Outback gateway exit coordinates are changed, this is the min and
-- max number of days until it changes again.
randspawn.min_days = 10
randspawn.max_days = 90



function randspawn.check_spawn_reset()
	local meta = randspawn.modstorage
	local stime = meta:get_string("spawn_reset_timer")

	-- If timestamp is missing, then initialize it.
	-- Outback reset will be schedualed after the timeout.
	if not stime or stime == "" then
		local time = os.time()
		local days = 60*60*24*math_random(randspawn.min_days, randspawn.max_days)
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
		later = later + 60*60*24*math_random(randspawn.min_days, randspawn.max_days)
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
	local get_node = minetest.get_node

	-- Start at sea level and check upwards 200 meters to find ground.
	for y = -10, 200, 1 do
		pos.y = y
		local nu = get_node(pos)
		pos.y = y + 1
		local na = get_node(pos)

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
	local pos = {x=math_random(-6000, 6000), y=0, z=math_random(-6000, 6000)}

	local minp = vector.add(pos, {x=-7, y=-7, z=-7})
	local maxp = vector.add(pos, {x=7, y=200, z=7})

	minetest.emerge_area(minp, maxp, callback, {pos=table.copy(pos)})
end



-- This function shall ALWAYS return the Outback's static_spawn!
local function get_respawn_position(invoke_pos, pname)
	-- Regardless of where player dies, if they have no bed,
	-- then they respawn in the outback. Note that a player may lose their bed if
	-- killed by another player outside of the city.
	return rc.static_spawn("abyss")
end
randspawn.get_respawn_pos = get_respawn_position



-- Note: this is also called from the /spawn chatcommand,
-- but only after validation passes (distance, etc.).
-- This API shall place player at the Outback's static_spawn, ALWAYS.
randspawn.reposition_player = function(pname, death_pos)
	local player = minetest.get_player_by_name(pname)
	if player then
		-- Ensure teleport is forced, to prevent a cheat.
		local pos = get_respawn_position(death_pos, pname)
		pos = vector.add(pos, {x=math_random(-2, 2), y=0, z=math_random(-2, 2)})

		preload_tp.execute({
			player_name = pname,
			target_position = pos,
			emerge_radius = 32,

			post_teleport_callback = function()
				ambiance.sound_play("respawn", pos, 0.5, 10)
			end,

			force_teleport = true,
			send_blocks = false,
			particle_effects = true,
		})
	end
end



-- The calendar item calls this to report the location of the current spawnpoint.
function randspawn.get_spawn_name()
	local s = serveressentials.get_current_exit_location()
	local p = minetest.string_to_pos(s)
	if p then
		return rc.pos_to_namestr(p)
	end

	return "Unknown Location"
end



if not randspawn.run_once then
	-- Reloadable.
	local file = randspawn.modpath .. "/init.lua"
	local name = "randspawn:core"
	reload.register_file(name, file, false)

	randspawn.modstorage = minetest.get_mod_storage()
	randspawn.run_once = true
end

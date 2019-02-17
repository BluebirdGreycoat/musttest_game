
mob_spawn = mob_spawn or {}
mob_spawn.modpath = minetest.get_modpath("mob_spawn")

mob_spawn.registered = mob_spawn.registered or {}
mob_spawn.players = mob_spawn.players or {}

-- May be adjusted @ runtime.
mob_spawn.server_step = 10
mob_spawn.enable_reports = false

local function report(mob, msg)
	if mob_spawn.enable_reports then
		minetest.chat_send_player("MustTest", "[" .. mob .. "]: " .. msg)
	end
end



-- API function, for registering a mob's spawning data.
function mob_spawn.register_spawn(data)
	local tb = {}

	-- Name of the mob.
	tb.name = data.name or ""

	-- Terrain scanning parameters.
	tb.node_skip = data.node_skip or 10
	tb.node_jitter = data.node_jitter or 10
	tb.node_names = data.nodes or {"default:stone"}
	tb.spawn_radius = data.spawn_radius or 50
	tb.air_offset = data.air_offset or 1
	tb.flyswim = data.flyswim or "ground"

	-- Min and max duration before mob can be spawned again, after a spawn failure.
	-- Smaller values attempt to respawn mobs more frequently, but with more load.
	-- Note: saturation time only applies if there are already too many mobs.
	tb.saturation_time_min = data.saturation_time_min or 60*1
	tb.saturation_time_max = data.saturation_time_max or 60*10

	-- Min and max delay before next mob spawn, after a successfull spawn.
	tb.success_time_min = data.success_time_min or 1
	tb.success_time_max = data.success_time_max or 60

	-- Must be 1 or greater.
	tb.spawn_chance = data.spawn_chance or 10

	-- How many attempts allowed to spawn this mob per iteration?
	tb.max_spawns_per_run = data.max_spawns_per_run or 10

	-- Does mob want day, night, or doesn't care?
	-- If true, mob only spawns in daytime. False means only spawn at night.
	-- If nil, mob may spawn at any time.
	tb.day_toggle = data.day_toggle or nil

	-- How many mobs to spawn at once?
	-- This determines how many mobs spawn, when all other checks pass.
	tb.min_count = data.min_count or 1
	tb.max_count = data.max_count or 3

	-- How many mobs of the same kind may exist in the local area?
	-- Max number of mobs of the *same type* which may spawn in the same local area.
	tb.mob_limit = data.mob_limit or 3

	-- Max number of mobs (of any kind) in local area for this mob?
	-- Mob will not spawn if there are too many mobs of *any* type in local area.
	tb.absolute_mob_limit = data.absolute_mob_limit or 10

	-- What is the radius of the mob's local area?
	-- What radius to use, when checking for other mobs or players.
	tb.mob_range = data.mob_range or 30

	-- Mob's light requirements?
	-- Mob will not spawn if light is too bright or too dark.
	tb.min_light = data.min_light or 0
	tb.max_light = data.max_light or default.LIGHT_MAX

	-- Mob's desired elevation?
	-- Registered mob will not spawn above or below these bounds.
	tb.min_height = data.min_height or -31000
	tb.max_height = data.max_height or 31000

	-- Amount of vertical airspace needed for spawning?
	-- Need at least this many vertical air nodes.
	tb.clearance = data.clearance or 2

	-- Min and max ranges from player before spawning is possible?
	-- Mobs will not spawn if player too far or too close to spawn point.
	tb.player_min_range = data.player_min_range or 10
	tb.player_max_range = data.player_max_range or 50

	-- Store the data. We use an indexed array.
	-- This allows the same mob to have multiple spawn registrations.
	local registered = mob_spawn.registered
	registered[#registered+1] = tb
end

function mob_spawn.reinit_player(pname)
	local players = mob_spawn.players
	-- This is an indexed array.
	local registered = mob_spawn.registered
	local random = math.random

	players[pname] = {}

	for k, v in pairs(registered) do
		players[pname][k] = {
			-- Initial interval. Wait this long before trying to spawn this mob again.
			interval = random(v.success_time_min, v.success_time_max)
		}
	end
end

-- Load mob spawning data.
dofile(mob_spawn.modpath .. "/data.lua")



-- Return 'true' if volume is only a single material.
local function check_space(minp, maxp, material)
	local positions, counts = minetest.find_nodes_in_area(minp, maxp, material)

	-- Compute number of nodes that can fit in volume.
	local x = (maxp.x - minp.x) + 1
	local y = (maxp.y - minp.y) + 1
	local z = (maxp.z - minp.z) + 1
	local t = x * y * z
	if counts[material] >= t then
		return true
	end
end

-- May modify argument as output value.
-- Search both upward and downward (starting from air) to find a non-air node.
local function try_locate_ground(pos)
	pos = {x=pos.x, y=pos.y, z=pos.z}
	local get_node = minetest.get_node
	local s = get_node(pos).name
	local c = 1

	if s == "air" then

		-- Search downward.
		while s == "air" do
			if c > 2 then
				return false
			end
			pos.y = pos.y - 1
			c = c + 1
			s = get_node(pos).name
		end

		-- Found non-air. Leave position pointing at non-air node.
		return true, pos

	elseif s ~= "air" then

		-- Search upward.
		while s ~= "air" do
			if c > 2 then
				return false
			end
			pos.y = pos.y + 1
			c = c + 1
			s = get_node(pos).name
		end

		-- Found air. Set position to point to non-air below.
		pos.y = pos.y - 1
		return true, pos

	end

	::cancel::
	return false
end

-- Use for flying/swimming mobs.
local function search_flyswim(pos, step, radius, jitter, nodes, offset, height)
	local random = math.random
	local floor = math.floor
	local get_node = minetest.get_node

	jitter = floor(jitter)
	radius = floor(radius)
	step = floor(step)
	offset = floor(offset)

	-- Height along the Y-axis is halved to reduce the amount of node checks.
	local minx = floor(pos.x - radius      )
	local miny = floor(pos.y - (radius / 2))
	local minz = floor(pos.z - radius      )
	local maxx = floor(pos.x + radius      )
	local maxy = floor(pos.y + (radius / 2))
	local maxz = floor(pos.z + radius      )

	local results = {}
	local gp = {x=0, y=0, z=0}
	local sp = {x=0, y=0, z=0}

	for x = minx, maxx, step do
	for y = miny, maxy, step do
	for z = minz, maxz, step do

		gp.x = x + random(-jitter, jitter)
		gp.y = y + random(-jitter, jitter)
		gp.z = z + random(-jitter, jitter)

		local bw = get_node(gp).name

		for i = 1, #nodes do
			if bw == nodes[i] then
				-- A volume of radius 1 should just check 1 node.
				local r = height - 1
				if check_space(vector.subtract(gp, r), vector.add(gp, r), bw) then
					results[#results+1] = table.copy(gp)
					break
				end
			end
		end

	end
	end
	end

	return results
end

-- Use for ground/surface mobs.
local function search_terrain(pos, step, radius, jitter, nodes, offset, height)
	local random = math.random
	local floor = math.floor
	local get_node = minetest.get_node

	jitter = floor(jitter)
	radius = floor(radius)
	step = floor(step)
	offset = floor(offset)

	-- Height along the Y-axis is halved to reduce the amount of node checks.
	local minx = floor(pos.x - radius      )
	local miny = floor(pos.y - (radius / 2))
	local minz = floor(pos.z - radius      )
	local maxx = floor(pos.x + radius      )
	local maxy = floor(pos.y + (radius / 2))
	local maxz = floor(pos.z + radius      )

	local results = {}
	local gp = {x=0, y=0, z=0}
	local sp = {x=0, y=0, z=0}

	for x = minx, maxx, step do
	for y = miny, maxy, step do
	for z = minz, maxz, step do

		gp.x = x + random(-jitter, jitter)
		gp.y = y + random(-jitter, jitter)
		gp.z = z + random(-jitter, jitter)

		local success, np = try_locate_ground(gp)

		if success then
			local bw = get_node(np).name

			for i = 1, #nodes do
				if bw == nodes[i] then
					if check_space(vector.add(np, {x=0, y=offset, z=0}), vector.add(np, {x=0, y=offset+(height-1), z=0}), bw) then
						results[#results+1] = {x=np.x, y=np.y+offset, z=np.z}
						break
					end
				end
			end
		end

	end
	end
	end

	return results
end



local function execute_spawners()
	local players = mob_spawn.players
	-- This is an indexed array.
	local mobdefs = mob_spawn.registered
	local step = mob_spawn.server_step
	local random = math.random

	-- For each player online.
	for pname, k in pairs(players) do
		-- For each mobtype defined.
		for index, mdef in ipairs(mobdefs) do
			local pmdata = players[pname][index]
			if pmdata.interval == 0 then
				local mname = mdef.name
				local count, saturated = mob_spawn.spawn_mobs(pname, index)
				if count > 0 then
					-- Mobs were spawned. Spawn more mobs soon.
					-- Set the wait timer to expire in a bit.
					pmdata.interval = random(mdef.success_time_min, mdef.success_time_max)
					report(mname, "Spawned " .. count .. "!")
				else
					if saturated then
						-- No mobs spawned. Bad environment or area saturated, wait a while.
						-- Reset the wait timer.
						-- Use random duration to prevent thundering herd.
						pmdata.interval = random(mdef.saturation_time_min, mdef.saturation_time_max)
						report(mname, "Mob saturated!")
					else
						pmdata.interval = random(mdef.success_time_min, mdef.success_time_max)
					end
				end
			else
				-- Decrease time remaining until this mob can be spawned again.
				local int = pmdata.interval
				int = int - step
				if int < 0 then
					int = 0
				end
				pmdata.interval = int
			end
		end
	end
end



local time = 0
local step = mob_spawn.server_step

-- Called from the MT engine.
function mob_spawn.on_globalstep(dtime)
	time = time + dtime
	if time < step then
		return
	end
	time = 0

	execute_spawners()
end

-- Count how many mobs exist in a given area with a radius.
-- Returns [mob count], [abs mob count]
function mob_spawn.check_population(mname, spos, radius)
	-- Count mobs in mob range.
	-- We can do this check just for the center position, instead of for each point.
	local mob_count = 0
	local abs_count = 0

	local entities = minetest.get_objects_inside_radius(spos, radius)

	for j = 1, #entities do
		local entity = entities[j]
		if not entity:is_player() then
			local ref = entity:get_luaentity()
			if ref then
				if ref.name == mname then
					mob_count = mob_count + 1
				end
				if ref.mob then
					-- Absolute mob count.
					abs_count = abs_count + 1
				end
			end
		end
	end

	return mob_count, abs_count
end

-- API function. Spawns mobs around a player, if possible.
-- Returns [num mobs spawned], [saturated|nil]
function mob_spawn.spawn_mobs(pname, index)
	local player = minetest.get_player_by_name(pname)
	if not player then
		return 0
	end

	local mdef = mob_spawn.registered[index]
	if not mdef then
		return 0
	end

	local random = math.random

	-- Mobs have a 1 in X chance of spawning on this cycle.
	if random(1, mdef.spawn_chance) ~= 1 then
		return 0
	end

	-- Get mob's name.
	local mname = mdef.name

	if mname == "iceman:iceman" then
		if not snow.should_spawn_icemen() then
			return 0
		end
	end

	-- Can mob spawn at this time of day?
	local daynight = mdef.day_toggle

	-- If toggle set to nil then ignore day/night check.
	if daynight ~= nil then
		local tod = (minetest.get_timeofday() or 0) * 24000

		if tod > 4500 and tod < 19500 then
			-- Daylight, but mob wants night.
			if daynight == false then
				report(mname, "Mob wants night time!")
				return 0
			end
		else
			-- Night time but mob wants day.
			if daynight == true then
				report(mname, "Mob wants day time!")
				return 0
			end
		end
	end

	local spos = vector.round(player:get_pos())

	-- Check if height levels are ok.
	-- We only bother checking the center point.
	local max_height = mdef.max_height
	local min_height = mdef.min_height
	if spos.y > max_height or spos.y < min_height then
		report(mname, "Bad elevation!")
		return 0
	end

	-- Mobs rarely spawn in the colonies. They keep killing the noobs!
	if vector.distance(spos, {x=0, y=0, z=0}) < 100 then
		if random(1, 10) < 10 then
			return 0
		end
	elseif vector.distance(spos, {x=0, y=-30790, z=0}) < 100 then
		if random(1, 10) < 10 then
			return 0
		end
	end

	local get_node = minetest.get_node
	local pi = math.pi
	local vector_new = vector.new
	local vector_add = vector.add
	local add_entity = minetest.add_entity

	local attempts = mdef.max_spawns_per_run
	local max_light = mdef.max_light
	local min_light = mdef.min_light
	local mob_range = mdef.mob_range
	local mob_limit = mdef.mob_limit
	local abs_limit = mdef.absolute_mob_limit
	local player_min_range = mdef.player_min_range
	local player_max_range = mdef.player_max_range
	local min_count = mdef.min_count
	local max_count = mdef.max_count
	local clearance = mdef.clearance

	local players = minetest.get_connected_players()

	local step = mdef.node_skip
	local radius = mdef.spawn_radius
	local jitter = mdef.node_jitter
	local names = mdef.node_names
	local offset = mdef.air_offset

	-- Find potential spawn points around player location.
	local points

	if mdef.flyswim == "ground" then
		points = search_terrain(spos, step, radius, jitter, names, offset, clearance)
	elseif mdef.flyswim == "flyswim" then
		points = search_flyswim(spos, step, radius, jitter, names, offset, clearance)
	end
	report(mname, "Found " .. #points .. " spawn point(s) @ " .. minetest.pos_to_string(spos) .. "!")

	-- Prevent a crash when accessing the array later.
	if #points < 1 then
		return 0
	end

	-- Record number of mobs successfully spawned.
	local mobs_spawned = 0
	local mobs_saturated

	for i = 1, attempts do
		-- Pick a random point for each spawn attempt. Prevents bunching.
		local pos = points[random(1, #points)]
		report(mname, "Attempting to spawn mob @ " .. minetest.pos_to_string(pos) .. "!")

		-- Count mobs in mob range.
		-- Don't spawn mob if there are already too many mobs in area.
		local mob_count, abs_count = mob_spawn.check_population(mname, pos, mob_range)
		if mob_count >= mob_limit or abs_count >= abs_limit then
			mobs_saturated = true
			goto next_spawn
		end

		-- Check if light level is ok.
		-- We perform this check for each possible position.
		local light = minetest.get_node_light(pos)
		if not light or light > max_light or light < min_light then
			report(mname, "Bad light level!")
			goto next_spawn
		end

    -- Find nearest player.
    local nearest_dist = player_max_range + 1
    for j = 1, #players do
			local p = players[j]:get_pos()
			local d = vector.distance(pos, p)
			if d < nearest_dist then
				nearest_dist = d
			end
    end

    -- Don't spawn if too near player or too far.
    if nearest_dist < player_min_range or nearest_dist > player_max_range then
			report(mname, "Player too near or player too far!")
			goto next_spawn
		end

		-- Spawn a random number of mobs.
		local num_to_spawn = random(min_count, max_count)
    for i = 1, num_to_spawn, 1 do
			-- Slightly randomize horizontal positioning.
			local p2 = {x=random(-5, 5)/10, y=0.5, z=random(-5, 5)/10}
			local mob = add_entity(vector_add(pos, p2), mname)
			if mob then
				local ent = mob:get_luaentity()
				if ent then
					-- Adjust the chance to use pathfinding on a per-entity basis.
					if ent.pathfinding and ent.pathfinding ~= 0 then
						local chance = ent.instance_pathfinding_chance or {100, 100}
						local res = math.random(1, chance[2])
						--minetest.chat_send_player("MustTest", "Chance: " .. res .. " of " .. chance[1] .. " in " .. chance[2])
						if res > chance[1] then
							--minetest.chat_send_player("MustTest", "Mob will not pathfind!")
							ent.pathfinding = 0
						end
					end
					mob:setyaw((random(0, 360) - 180) / 180 * pi)
					mobs_spawned = mobs_spawned + 1
					report(mname, "Successfully spawned a mob!")
				else
					mob:remove()
				end
			end
    end

		::next_spawn::
	end

	return mobs_spawned, mobs_saturated
end



function mob_spawn.on_joinplayer(player)
	local pname = player:get_player_name()
	mob_spawn.reinit_player(pname)
end

function mob_spawn.on_leaveplayer(player)
	mob_spawn.players[player:get_player_name()] = nil
end



if not mob_spawn.run_once then
	minetest.register_globalstep(function(...)
		mob_spawn.on_globalstep(...)
	end)

	minetest.register_on_joinplayer(function(...)
		return mob_spawn.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return mob_spawn.on_leaveplayer(...)
	end)

	local c = "mob_spawn:core"
	local f = mob_spawn.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	mob_spawn.run_once = true
end


local random = math.random
local pi = math.pi
local node_ok = mobs.node_ok



local attempt_spawn_mob = function(pos, moblimit, mobrange, daynight, miny, maxy, name, minl, maxl, prange_min, prange_max, minc, maxc, spawn_height, absolute_mob_limit)
	-- If toggle set to nil then ignore day/night check.
	if daynight ~= nil then
		local tod = (minetest.get_timeofday() or 0) * 24000

		if tod > 4500 and tod < 19500 then
			-- Daylight, but mob wants night.
			if daynight == false then
				return
			end
		else
			-- Night time but mob wants day.
			if daynight == true then
				return
			end
		end
	end

	-- Spawn above node.
	pos.y = pos.y + 1
    
    -- Check if height levels are ok.
    if pos.y > maxy or pos.y < miny then return end

	-- Check if light level is ok.
	local light = minetest.get_node_light(pos)
	if not light or light > maxl or light < minl then return end

    -- Count mobs in mob range.
    local mobcount = 0
    local absmobcount = 0
	local objs = minetest.get_objects_inside_radius(pos, mobrange)
	for n = 1, #objs do
        local obj = objs[n]
		if not obj:is_player() then
            local ref = obj:get_luaentity()
            if ref then
                if ref.name == name then mobcount = mobcount + 1 end
                if ref.mob then absmobcount = absmobcount + 1 end
            end
		end
	end
    
    -- Don't spawn mob if there are already too many entities in area.
    if mobcount > moblimit then return end
    if absmobcount > absolute_mob_limit then return end
    
    -- Find nearest player.
    local neardist = prange_max+1
    local players = minetest.get_connected_players()
    for n = 1, #players do
        local ref = players[n]
        local p = ref:getpos()
        local d = vector.distance(pos, p)
        if d < neardist then neardist = d end
    end
    
    -- Don't spawn if too near player or if too far.
    if neardist < prange_min or neardist > prange_max then return end

	-- Are we spawning inside solid nodes?
    for i = 1, spawn_height, 1 do
        local p = {x=pos.x, y=(pos.y+i)-1, z=pos.z}
        if minetest.registered_nodes[node_ok(p).name].walkable == true then return end
    end

	-- Spawn mob half block higher than ground.
	pos.y = pos.y + 0.5
    for i = minc, maxc do
        local mob = minetest.add_entity(pos, name)
        if mob then
            mob:setyaw((random(0, 360) - 180) / 180 * pi)
        end
    end
end



mobs.register_spawn = function(def)
	-- The new mob spawning registration function.
	-- Mobs are spawned with a special algorithm that doesn't use ABMs.
	mob_spawn.register_spawn(def)
end



-- Kept because certain mobs (like the griefer) NEED AMB spawn behavior.
mobs.register_spawn_abm = function(def)
	-- Name of mob.
	local name = def.name

	-- Min/max light allowed.
	local minl = def.min_light or 0
	local maxl = def.max_light or default.LIGHT_MAX

	-- Min/max elevations.
	local miny = def.min_height or -31000
	local maxy = def.max_height or 31000

	-- Min/max amount of mobs to spawn.
	local minc = def.min_count or 1
	local maxc = def.max_count or 1

	-- Mob count limit and scanning range.
	local moblimit = def.mob_limit or 3
	local mobrange = def.mob_range or 20
	local absolute_mob_limit = def.absolute_mob_limit or 5

	-- True to spawn only at daytime. False to spawn only at night.
	local daynight = def.day_toggle -- May be nil.

	-- Min/max allowed ranges to nearest player.
	local prange_min = def.player_min_range or 6
	local prange_max = def.player_max_range or 20

	-- Height of mob. Don't spawn if not enough head-space.
	local spawn_height = def.spawn_height or 2

	minetest.register_abm({
    label = "Mob Spawner",
		nodenames = def.nodes,
		neighbors = {"air"},
		interval = def.interval * default.ABM_TIMER_MULTIPLIER,
		chance = def.chance * default.ABM_CHANCE_MULTIPLIER,
		catch_up = false,

		action = function(pos)
			-- Is sending things as arguments instead of a table any faster?
			attempt_spawn_mob(pos, moblimit, mobrange, daynight, miny, maxy, name, minl, maxl, prange_min, prange_max, minc, maxc, spawn_height, absolute_mob_limit)
		end
	})
end

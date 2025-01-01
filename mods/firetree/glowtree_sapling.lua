
-- Localize for performance.
local random = math.random



local SAPLING_TIME_MIN = 10*60
local SAPLING_TIME_MAX = 15*60

-- DVD, you'll need to change the X,Y,Z positions to make the treeschems center on the sapling.
local GLOWTREE_SCHEMATICS = {
	{file="xen_tree1.mts", pos={x=0, y=0, z=0}},
    {file="xen_tree2.mts", pos={x=0, y=0, z=0}},
  	{file="xen_tree3.mts", pos={x=0, y=0, z=0}},
	{file="xen_tree4.mts", pos={x=0, y=0, z=0}},
	{file="xen_tree5.mts", pos={x=0, y=0, z=0}},
	{file="xen_tree6.mts", pos={x=0, y=0, z=0}},
	{file="xen_tree7.mts", pos={x=0, y=0, z=0}},
}

-- List of nodes the glowtree can grow (from sapling) on.
local MAY_GROW_ON = {
	["sw:teststone1_open"] = true,
}



local function can_grow(pos)
	-- Glowtree does not grow in other dimensions.
	if pos.y < 13500 or pos.y > 15150 then
		return false
	end

	-- Reduced chance to grow if cold/ice nearby.
	local below = {x=pos.x, y=pos.y-1, z=pos.z}
	local cold = minetest.find_nodes_in_area(vector.subtract(below, 3), vector.add(below, 3), "group:cold")
	if #cold > random(0, 196) then
		return false
	end

	-- Node below can't be IGNORE.
	local node_under = minetest.get_node_or_nil(below)
	if not node_under then
		return false
	end

	-- Only allowed to grow on naturally occuring open spaces in Xen.
	if not MAY_GROW_ON[node_under.name] then
		return false
	end

	-- Must have enough light.
	local light_level = minetest.get_node_light(pos)
	if not light_level or light_level < 11 then
		return false
	end

	return true
end



local function on_place(itemstack, placer, pointed_thing)
	local n = "firetree:luminoustreesapling"
	-- This box is unusually big because I don't know what the schematic dimensions are.
	local minp = {x=-16, y=-8, z=-16}
	local maxp = {x=16, y=32, z=16}
	itemstack = default.sapling_on_place(itemstack, placer, pointed_thing, n, minp, maxp, 4)
	return itemstack
end



local function on_construct(pos)
	minetest.get_node_timer(pos):start(random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
end



local function on_timer(pos, elapsed)
	if not can_grow(pos) then
		minetest.get_node_timer(pos):start(random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
		return
	end

	minetest.set_node(pos, {name='air'}) -- Remove sapling first.
	local directory = sw.modpath .. "/schems/"
	local data = GLOWTREE_SCHEMATICS[random(#GLOWTREE_SCHEMATICS)]
	local path = directory .. data.file
	local target = vector.add(pos, data.pos)
	local flags = "place_center_x,place_center_z"
	minetest.place_schematic(target, path, "random", nil, false, flags)
end



-- Make functions available outside this file.
firetree.on_glowtree_timer = on_timer
firetree.on_glowtree_place = on_place
firetree.on_glowtree_construct = on_construct

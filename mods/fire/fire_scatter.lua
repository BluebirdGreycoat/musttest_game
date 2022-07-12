
local math_random = math.random

function fire.scatter_flame_in_area(minp, maxp, coverage)
	local flames = {}

	local targets = minetest.find_nodes_in_area(minp, maxp, "air")
	if #targets == 0 then
		return flames
	end

	for idx = 1, #targets, 1 do
		if math_random(0, 100) < coverage then
			local pos = targets[idx]
			minetest.set_node(pos, {name="fire:basic_flame"})
			flames[#flames + 1] = pos
		end
	end

	return flames
end

function fire.scatter_flame_in_area_over_ground(minp, maxp, coverage)
	local flames = {}

	-- Adjust max Y up 1 node (because we need to check node-above for each pos).
	maxp = vector.add(maxp, {x=0, y=1, z=0})

	local voxel = VoxelManip()
	local emin, emax = voxel:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local data = voxel:get_data()

	local c_air = minetest.get_content_id("air")

	-- Will store the positions of ground nodes.
	local targets = {}

	for x = minp.x, maxp.x, 1 do
		for y = minp.y, (maxp.y - 1), 1 do
			for z = minp.z, maxp.z, 1 do
				local v1 = area:index(x, y, z)
				local v2 = area:index(x, y + 1, z)
				local d1 = data[v1]
				local d2 = data[v2]
				if d1 ~= c_air and d2 == c_air then
					targets[#targets + 1] = {x=x, y=y+1, z=z}
				end
			end
		end
	end

	if #targets == 0 then
		return flames
	end

	for idx = 1, #targets, 1 do
		if math_random(0, 100) < coverage then
			local pos = targets[idx]
			minetest.set_node(pos, {name="fire:basic_flame"})
			flames[#flames + 1] = pos
		end
	end

	return flames
end

function fire.scatter_flame_around(pos, radius, coverage)
	local minp = vector.add(pos, {x=-radius, y=-radius, z=-radius})
	local maxp = vector.add(pos, {x=radius, y=radius, z=radius})
	return fire.scatter_flame_in_area(minp, maxp, coverage)
end

function fire.scatter_flame_around_over_ground(pos, radius, coverage)
	local minp = vector.add(pos, {x=-radius, y=-radius, z=-radius})
	local maxp = vector.add(pos, {x=radius, y=radius, z=radius})
	return fire.scatter_flame_in_area_over_ground(minp, maxp, coverage)
end

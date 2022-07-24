
local cache = {}



local function is_walkable(cid)
	local cached = cache[cid]
	if cached ~= nil then return cached end

	local n = minetest.get_name_from_content_id(cid)
	local d = minetest.registered_nodes[n]
	if not d then return nil end

	cache[cid] = (d.walkable == true)

	return (d.walkable == true)
end



function hb4.find_walkable_in_area_under_unwalkable(minp, maxp)
	-- Adjust max Y up 1 node (because we need to check node-above for each pos).
	maxp = vector.add(maxp, {x=0, y=1, z=0})

	local voxel = VoxelManip()
	local emin, emax = voxel:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local data = voxel:get_data()

	-- Will store the positions of ground nodes.
	local targets = {}

	for x = minp.x, maxp.x, 1 do
		for y = minp.y, (maxp.y - 1), 1 do
			for z = minp.z, maxp.z, 1 do
				local v1 = area:index(x, y, z)
				local v2 = area:index(x, y + 1, z)
				local d1 = data[v1]
				local d2 = data[v2]

				local w1 = is_walkable(d1)
				local w2 = is_walkable(d2)

				-- A nil return means the node is undefined.

				if w1 == true and w2 == false then
					targets[#targets + 1] = {x=x, y=y+1, z=z}
				end
			end
		end
	end

	return targets
end

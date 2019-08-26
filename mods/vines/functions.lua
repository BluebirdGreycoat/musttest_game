
local c_air = minetest.get_content_id("air")

vines.destroy_rope_starting = function(p, targetnode, bottomnode, topnode)
	local n = minetest.get_node(p).name
	if n ~= targetnode and n ~= bottomnode then
		return
	end

	local y1 = p.y
	local tab = {}
	local i = 1
	while n == targetnode do
		--print("test2")
		tab[i] = p
		i = i+1
		p.y = p.y-1
		n = minetest.get_node(p).name
	end
	--print("test10")
	if n == bottomnode then
		tab[i] = p
	end
	local y0 = p.y
	--print("test5")
	local manip = minetest.get_voxel_manip()
	local p0 = {x=p.x, y=y0,   z=p.z}
	local p1 = {x=p.x, y=y0+1, z=p.z}
	local p2 = {x=p.x, y=y1,   z=p.z}
	local pos1, pos2 = manip:read_from_map(p0, p2)
	local area = VoxelArea:new({MinEdge=pos1, MaxEdge=pos2})
	local nodes = manip:get_data()
	--print("test6")
	--print(minetest.pos_to_string(p1) .. ", " .. minetest.pos_to_string(p2))
	for i in area:iterp(utility.sort_positions(p1, p2)) do
		nodes[i] = c_air
		--print("doing " .. i)
	end
	--print("test11")
	nodes[area:indexp(p0)] = minetest.get_content_id(topnode)
	--print("test7")
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map() -- <— this takes time
	--print("test8")
	local timer = minetest.get_node_timer( p0 )
	timer:start( 1 )
	--print("test9")
end

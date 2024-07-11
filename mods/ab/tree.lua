
local function acacia_fixup(pos)
	local n1 = minetest.get_node(pos)
	if n1.name == "basictrees:acacia_trunk" and n1.param2 >= 0 and n1.param2 <= 3 then
		--minetest.chat_send_all('test2')
		local n2 = minetest.get_node(vector.add(pos, {x=0,y=-1,z=0}))
		if n2.name == "air" then
			local positions = {
				{pos={x=pos.x-1, y=pos.y-1, z=pos.z-1}, node={name="basictrees:acacia_branch", param2=22}},
				{pos={x=pos.x-1, y=pos.y-1, z=pos.z+1}, node={name="basictrees:acacia_branch", param2=21}},
				{pos={x=pos.x+1, y=pos.y-1, z=pos.z-1}, node={name="basictrees:acacia_branch", param2=23}},
				{pos={x=pos.x+1, y=pos.y-1, z=pos.z+1}, node={name="basictrees:acacia_branch", param2=20}},
			}
			for k, v in ipairs(positions) do
				local n3 = minetest.get_node(v.pos)
				--minetest.chat_send_all("test")
				if n3.name == "basictrees:acacia_trunk" and n3.param2 >= 0 and n3.param2 <= 3  then
					minetest.set_node(vector.add(pos, {x=0,y=-1,z=0}), v.node)
					break
				end
			end
		end
	end
end



local function fix_acacia_tree(minp, maxp)
	if not minetest.registered_nodes["basictrees:acacia_branch"] then return end

	for x = minp.x, maxp.x, 1 do
		for y = minp.y, maxp.y, 1 do
			for z = minp.z, maxp.z, 1 do
				acacia_fixup({x=x, y=y, z=z})
			end
		end
	end
end



function ab.place_acacia_tree(vm, pos)
	local relpos = {x=-4, y=0, z=-4}
	local rMINP = {x=-4, y=0, z=-4}
	local rMAXP = {x=4, y=6, z=4}
	local path = ab.modpath .. "/tree.mts"
	minetest.place_schematic_on_vmanip(vm, vector.add(pos, relpos), path, "random", nil, false)
	fix_acacia_tree(vector.add(pos, rMINP), vector.add(pos, rMAXP))
	minetest.set_node(pos, {name="default:dirt"})
end

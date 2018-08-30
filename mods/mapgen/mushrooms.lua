
local find_surface = function(xz, b, t)
	for j=b, t, 1 do
		local p1 = {x=xz.x, y=j, z=xz.z}
		local p2 = {x=xz.x, y=j+1, z=xz.z}
		local n1 = minetest.get_node(p1).name
		local n2 = minetest.get_node(p2).name
		if n2 == 'air' and n1 == 'default:stone' then
			return p2, p1
		end
	end
end

mapgen.generate_mushrooms = function(minp, maxp, seed)
	if maxp.y < -128 or minp.y > 20 then
		return
	end


	local pr = PseudoRandom(seed + 9488)
	local count = pr:next(1, 5)

	for j=1, count, 1 do
		local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
		local pos, posb = find_surface(xz, minp.y, maxp.y)

		if pos then
			if pr:next(1, 2) == 1 then
				minetest.set_node(pos, {name="flowers:mushroom_red"})
			else
				minetest.set_node(pos, {name="flowers:mushroom_brown"})
			end
			minetest.set_node(posb, {name="default:mossycobble"})
		end
	end
end








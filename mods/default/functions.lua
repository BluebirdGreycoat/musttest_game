
function default.has_magma_fuel(pos)
	local minp = vector.add(pos, {x=-1, y=-1, z=-1})
	local maxp = vector.add(pos, {x=1, y=-1, z=1})

	local nodepositions =
		minetest.find_nodes_in_area(minp, maxp, "lbrim:lava_source")

	if #nodepositions == 9 then
		return true
	end
end


local FURNACE_NAMES = {
	["cobble_furnace:inactive"] = true,
	["cobble_furnace:active"] = true,
	["redstone_furnace:inactive"] = true,
	["redstone_furnace:active"] = true,
}

function default.has_magma_fuel(pos)
	local node = minetest.get_node(pos)
	local under = vector.add(pos, {x=0, y=-1, z=0})
	local count = 0

	-- Allow furnaces to be stacked up to 10 high.
	while FURNACE_NAMES[minetest.get_node(under).name] and count < 10 do
		under = vector.add(under, {x=0, y=-1, z=0})
		count = count + 1
	end

	local minp = vector.add(under, {x=-1, y=0, z=-1})
	local maxp = vector.add(under, {x=1, y=0, z=1})

	local nodepositions =
		minetest.find_nodes_in_area(minp, maxp, "lbrim:lava_source")

	if #nodepositions == 9 then
		return true
	end
end

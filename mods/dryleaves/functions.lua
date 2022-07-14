
local math_random = math.random

-- Note: this function assumes it is only executed at mapgen time. It bypasses
-- node callbacks!
function dryleaves.replace_leaves(minp, maxp, coverage)
	local leaves = {}
	if #dryleaves.list == 0 then
		return leaves
	end

	local targets = minetest.find_nodes_in_area(minp, maxp, "group:leaves")
	if #targets == 0 then
		return leaves
	end

	for idx = 1, #targets, 1 do
		if math_random(0, 100) < coverage then
			local pos = targets[idx]
			local leaf = dryleaves.list[math_random(1, #dryleaves.list)]
			-- There is no need to run callbacks.
			minetest.swap_node(pos, {name=leaf})
			leaves[#leaves + 1] = pos
		end
	end

	return leaves
end

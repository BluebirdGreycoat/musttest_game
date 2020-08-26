
-- Localize for performance.
local vector_add = vector.add
local set_node = minetest.set_node
local spawner_node = {name="pm:spawner"}

function pm.on_nodespawner_construct(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(5.0)
end

function pm.on_nodespawner_timer(pos, elapsed)
	pm.spawn_random_wisp(pos)
end

-- Called by the Jarkati mapgen when a candidate vent is placed.
function pm.on_wisp_vent_place(pos)
	local minp = vector_add(pos, -3)
	local maxp = vector_add(pos, 3)

	local positions = minetest.find_nodes_in_area_under_air(minp, maxp, "default:gravel")

	local n = #positions
	for i=1, n, 1 do
		local p = positions[i]
		p.y = p.y + 1
		set_node(p, spawner_node)
	end
end


-- Localize for performance.
local vector_add = vector.add
local set_node = minetest.set_node
local get_node = minetest.get_node
local remove_node = minetest.remove_node
local math_random = math.random
local spawner_node = {name="pm:spawner"}

function pm.on_nodespawner_construct(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(5.0)
end

function pm.on_nodespawner_destruct(pos)
	local pos = minetest.find_node_near(pos, 1, "air")
	if pos then
		-- Wisp avenges nest with its life!
		pm.spawn_wisp(pos, "boom")
	end
end

function pm.on_nodespawner_timer(pos, elapsed)
	pos.y = pos.y - 1
	local n = get_node(pos)
	pos.y = pos.y + 1
	if n.name == "default:gravel" then
		pm.spawn_random_wisp(pos)
	else
		remove_node(pos)
	end
end

-- Called by the Jarkati mapgen when a candidate vent is placed.
function pm.on_wisp_vent_place(pos)
	-- Wisp nests are very rare!
	if math_random(1, 100) == 1 then
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
end

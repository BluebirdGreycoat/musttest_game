
-- Localize for performance.
local vector_add = vector.add
local set_node = minetest.set_node
local get_node = minetest.get_node
local remove_node = minetest.remove_node
local math_random = math.random
local spawner_node = {name="pm:spawner"}
local quartz_node = {name="pm:quartz_ore"}

function pm.on_nodespawner_construct(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(math_random(100, 500)/100)
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
		-- Storing a metadata cookie ensures we only build the nest once, even if
		-- this timer function is called again.
		local meta = minetest.get_meta(pos)
		if meta:get_int("nest_built") ~= 1 then
			pm.spawn_wisp(pos, "nest_guard")
			pm.spawn_wisp(pos, "nest_worker")
			meta:set_int("nest_built", 1)
			meta:mark_as_private("nest_built")
		end

		-- Keep calling this timer function.
		-- This allows us to add extra behavior later.
		local timer = minetest.get_node_timer(pos)
		timer:start(10.0)
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
			p.y = p.y - 2
			set_node(p, quartz_node)
		end
	end
end

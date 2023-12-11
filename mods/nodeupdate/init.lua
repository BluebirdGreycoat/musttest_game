
if not minetest.global_exists("_nodeupdate") then _nodeupdate = {} end
_nodeupdate.modpath = minetest.get_modpath("nodeupdate")

-- Localize for performance.
local math_random = math.random

local get_node = core.get_node
local get_node_drops = core.get_node_drops
local get_item_group = core.get_item_group
local get_node_or_nil = core.get_node_or_nil
local all_nodes = minetest.registered_nodes
local add_item = core.add_item
local remove_node = core.remove_node



-- Drop a node as an entity.
function _nodeupdate.drop_node_as_entity(pos)
	local node = get_node(pos)
	if node.name == "air" then
		return
	end
	local def = all_nodes[node.name]
	if def and def.groups then
		local ig = (def.groups.immovable or 0)
		if ig > 0 then
			return
		end
	end
	-- This function takes both nodetables and nodenames.
	-- Pass nodenames, because passing a nodetable gives wrong results.
	local drops = get_node_drops(node.name, "")

	for _, item in pairs(drops) do
		local p = {
			x = pos.x + math_random()/2 - 0.25,
			y = pos.y + math_random()/2 - 0.25,
			z = pos.z + math_random()/2 - 0.25,
		}
		add_item(p, item)
	end
	remove_node(pos)
end



-- Spawn particles.
function _nodeupdate.spawn_particles(pos, node)
	ambiance.particles_on_dig(pos, node)
end
local spawn_particles = _nodeupdate.spawn_particles



if not _nodeupdate.run_once then
	local c = "nodeupdate:core"
	local f = _nodeupdate.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	_nodeupdate.run_once = true
end

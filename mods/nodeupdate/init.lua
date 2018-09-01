
_nodeupdate = _nodeupdate or {}
_nodeupdate.modpath = minetest.get_modpath("nodeupdate")

-- Grab old update function and save it.
if not _nodeupdate.old_update then
	_nodeupdate.old_update = core.check_single_for_falling
end
local old_nodeupdate = _nodeupdate.old_update

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
	--minetest.chat_send_player("MustTest", dump(drops))
	for _, item in pairs(drops) do
		local p = {
			x = pos.x + math.random()/2 - 0.25,
			y = pos.y + math.random()/2 - 0.25,
			z = pos.z + math.random()/2 - 0.25,
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



-- Override core function.
core.check_single_for_falling = function(p)
	local n = get_node(p)

	-- Handle hanging nodes.
	if get_item_group(n.name, "hanging_node") ~= 0 then
		local p2 = {x=p.x, y=p.y+1, z=p.z}
		local n2 = get_node_or_nil(p2)
		if n2 and n2.name == "air" then
			remove_node(p)
			-- Pass node name, because passing a node table gives wrong results.
			for _, item in pairs(get_node_drops(n.name, "")) do
				local pos = {
						x = p.x + math.random()/2 - 0.25,
						y = p.y + math.random()/2 - 0.25,
						z = p.z + math.random()/2 - 0.25,
				}
				add_item(pos, item)
			end
			spawn_particles(p, n)
			return true
		end
	end
  
	-- Fallback to builtin function.
	local spawned = old_nodeupdate(p)
	if spawned then
		--minetest.chat_send_player("MustTest", "# Server: Spawned particles!")
		spawn_particles(p, n)
	end
	return spawned
end



if not _nodeupdate.run_once then
	local c = "nodeupdate:core"
	local f = _nodeupdate.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	_nodeupdate.run_once = true
end

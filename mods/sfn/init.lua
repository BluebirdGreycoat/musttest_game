
if not minetest.global_exists("sfn") then sfn = {} end
sfn.modpath = minetest.get_modpath("sfn")

-- Localize for performance.
local vector_round = vector.round
local math_random = math.random



sfn.drop_node = function(pos)
	return core.spawn_falling_node(pos)
end


-- Return TRUE if the node is supported in some special, custom fashion.
function sfn.check_clump_fall_special(pos, node)
	local nodename = node.name
	local ndef = minetest.registered_nodes[nodename]
	if not ndef then return end

	local groups = ndef.groups or {}

	-- Stairs, slabs, microblocks, etc. supported if at least one full block is next to them.
	local stair = groups.stair_node or 0
	if stair ~= 0 then
		local p = {
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+1},
			{x=pos.x, y=pos.y, z=pos.z-1},
		}
		for k, v in ipairs(p) do
			local def2 = minetest.registered_nodes[minetest.get_node(v).name]
			if def2 then
				if def2.drawtype == "normal" then
					return true
				end
			end
		end
	end

	-- Tree trunks are supported if there is an adjacent connecting trunk.
	local tree = groups.tree or 0
	if tree ~= 0 and ndef.paramtype2 == "facedir" then
		local dir = minetest.facedir_to_dir(node.param2)

		-- Back node.
		local node2 = minetest.get_node(vector.add(pos, dir))
		if node2.name == nodename and node2.param2 == node.param2 then
			return true
		end

		-- Front node.
		node2 = minetest.get_node(vector.subtract(pos, dir))
		if node2.name == nodename and node2.param2 == node.param2 then
			return true
		end
	end
end



if not sfn.run_once then
	local c = "sfn:core"
	local f = sfn.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sfn.run_once = true
end



-- Used in W-E luatransform updates.
function sfn.update_node(pos)
	pos = vector_round(pos)
	local node = minetest.get_node(pos)
	if node.name == "glowstone:glowstone" then
		local positions = {
			{x=pos.x, y=pos.y+1, z=pos.z},
			{x=pos.x+1, y=pos.y+1, z=pos.z},
			{x=pos.x-1, y=pos.y+1, z=pos.z},
			{x=pos.x, y=pos.y+1, z=pos.z+1},
			{x=pos.x, y=pos.y+1, z=pos.z-1},
		}
		for k, v in ipairs(positions) do
			local n = minetest.get_node(v)
			if n.name == "air" then
				minetest.set_node(v, {name="stairs:slab_default_glass_1", param2=math_random(0, 3)})
			end
		end
	end

	--[[
	pos = vector_round(pos)
	local node = minetest.get_node(pos)
	if node.name == "rackstone:brick" then
		if math_random(1, 6) == 1 then
			node.name = "rackstone:redrack_block"
			minetest.swap_node(pos, node)
		end
	end
	--]]

	--[[
	pos = vector_round(pos)
	local node = minetest.get_node(pos)
	if node.name == "glowstone:glowstone" then
		local dirs = {
			{x=pos.x+1, y=pos.y, z=pos.z, p=1},
			{x=pos.x-1, y=pos.y, z=pos.z, p=3},
			{x=pos.x, y=pos.y, z=pos.z+1, p=0},
			{x=pos.x, y=pos.y, z=pos.z-1, p=2},
		}
		for k, v in ipairs(dirs) do
			local brick = minetest.get_node(v)
			local air = minetest.get_node({x=v.x, y=v.y+1, z=v.z})
			if brick.name == "rackstone:brick" and air.name == "air" then
				minetest.set_node(v, {name="stairs:stair_rackstone_brick2", param2=v.p})
			end
		end
	end
	--]]
end




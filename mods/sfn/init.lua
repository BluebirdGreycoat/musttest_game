
sfn = sfn or {}
sfn.modpath = minetest.get_modpath("sfn")



sfn.spawn_falling_node = function(pos, node, meta)
	ambiance.particles_on_dig(pos, node)
  local obj = minetest.add_entity(pos, "__builtin:falling_node")
  if obj then
    obj:get_luaentity():set_node(node, meta)
  end
end

sfn.drop_node = function(pos)
	local node = minetest.get_node(pos)
	if string.find(node.name, "flowing") then
		-- Do not treat flowing liquid as a falling node. Looks ugly.
		return
	end
	if node.name ~= "air" and node.name ~= "ignore" then
		if minetest.get_item_group(node.name, "immovable") == 0 then
			local meta = minetest.get_meta(pos):to_table()
			minetest.remove_node(pos)
			sfn.spawn_falling_node(pos, node, meta)
			return true -- Success.
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
	pos = vector.round(pos)
	local node = minetest.get_node(pos)
	if node.name == "rackstone:brick" then
		if math.random(1, 6) == 1 then
			node.name = "rackstone:redrack_block"
			minetest.swap_node(pos, node)
		end
	end

	--[[
	pos = vector.round(pos)
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




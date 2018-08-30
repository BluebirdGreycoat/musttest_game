
key = key or {}
key.modpath = minetest.get_modpath("key")



minetest.register_tool("key:skeleton", {
	description = "Skeleton Key",
	inventory_image = "key_skeleton.png",
	groups = {key = 1},
    
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = pointed_thing.under
    local node = minetest.get_node(pos)

		if not node then
			return itemstack
		end

		local on_skeleton_key_use = minetest.registered_nodes[node.name].on_skeleton_key_use
		if on_skeleton_key_use then
			-- make a new key secret in case the node callback needs it
			local random = math.random
			local newsecret = string.format(
				"%04x%04x%04x%04x",
				random(2^16) - 1, random(2^16) - 1,
				random(2^16) - 1, random(2^16) - 1)

			local secret, _, _ = on_skeleton_key_use(pos, user, newsecret)

			if secret then
				-- finish and return the new key
				itemstack:take_item()
				itemstack:add_item("key:key")
				local meta = itemstack:get_meta()
        meta:set_string("secret", secret)
        meta:set_string("description", "Key to <"..rename.gpn(user:get_player_name())..">'s "
          ..minetest.registered_nodes[node.name].description .. " @ " ..
          minetest.pos_to_string(vector.round(pos)))
				return itemstack
			end
		end
		return nil
	end
})



minetest.register_tool("key:key", {
	description = "Key",
	inventory_image = "key_key.png",
	groups = {key = 1, not_in_creative_inventory = 1},
	stack_max = 1,
    
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local def = minetest.registered_nodes[node.name]
		if def and def.on_rightclick and
				not (placer and placer:get_player_control().sneak) then
			return def.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = pointed_thing.under
		node = minetest.get_node(pos)

		if not node or node.name == "ignore" then
			return itemstack
		end

		local ndef = minetest.registered_nodes[node.name]
		if not ndef then
			return itemstack
		end

		local on_key_use = ndef.on_key_use
		if on_key_use then
			on_key_use(pos, placer)
		end

    return nil
  end,
})

minetest.register_alias("default:key", "key:key")



minetest.register_craft({
	output = 'key:skeleton',
	recipe = {
		{'default:gold_ingot'},
	}
})



minetest.register_craft({
	type = 'cooking',
	output = 'default:gold_ingot',
	recipe = 'key:skeleton',
	cooktime = 5,
})



minetest.register_craft({
	type = 'cooking',
	output = 'default:gold_ingot',
	recipe = 'key:key',
	cooktime = 5,
})


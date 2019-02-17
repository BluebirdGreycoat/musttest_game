
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

		local ndef = minetest.reg_ns_nodes[node.name]
		if not ndef then
			return itemstack
		end

		local on_skeleton_key_use = ndef.on_skeleton_key_use
		if on_skeleton_key_use then
			-- make a new key secret in case the node callback needs it
			local random = math.random
			local newsecret = string.format(
				"%04x%04x%04x%04x",
				random(2^16) - 1, random(2^16) - 1,
				random(2^16) - 1, random(2^16) - 1)

			local secret, _, owner = on_skeleton_key_use(pos, user, newsecret)

			if secret and owner then
				-- finish and return the new key
				itemstack:take_item()
				itemstack:add_item("key:key")
				local meta = itemstack:get_meta()
        meta:set_string("secret", secret)
        meta:set_string("description", "Key to <" .. rename.gpn(owner) .. ">'s " ..
					utility.get_short_desc(ndef.description) .. " @ " ..
					rc.pos_to_namestr(vector.round(pos)))
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
		local def = minetest.reg_ns_nodes[node.name]
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

		local ndef = minetest.reg_ns_nodes[node.name]
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


-- note: there is a bug somewhere that allows two forged keys to be copied, which doesn't make sense.
-- this bug exists in the official minetest_game, too, but not with books (even though the book code is almost the same).
-- the bug remains regardless of whether the following code is commented out.
---[[
minetest.register_craft({
	type = "shapeless",
	output = "key:key",
	recipe = {"key:skeleton", "key:key"}
})

key.on_craft = function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= "key:key" then
		return
	end

	local original
	local index
	for i = 1, player:get_inventory():get_size("craft") do
		if old_craft_grid[i]:get_name() == "key:key" then
			original = old_craft_grid[i]
			index = i
		end
	end
	if not original then
		return
	end
	local copymeta = original:get_meta():to_table()
	-- copy of the key held by player's mouse cursor
	itemstack:get_meta():from_table(copymeta)
	-- put the key with metadata back in the craft grid
	craft_inv:set_stack("craft", index, original)
end

minetest.register_on_craft(function(...) key.on_craft(...) end)
--]]

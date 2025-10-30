
if not minetest.global_exists("key") then key = {} end
key.modpath = minetest.get_modpath("key")

-- Localize for performance.
local vector_round = vector.round

key.on_craft = function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() == "key:key" then
		local pname = player:get_player_name()
		-- Permit copying a key.
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
		minetest.chat_send_player(pname, "# Server: Key copied!")
	elseif itemstack:get_name() == "key:chain" then
		local pname = player:get_player_name()
		-- Special: add a key to a keychain, leave key in craft-grid and return new keychain.
		local key_original
		local key_index
		local chain_original
		local chain_index
		for i = 1, player:get_inventory():get_size("craft") do
			if old_craft_grid[i]:get_name() == "key:key" then
				key_original = old_craft_grid[i]
				key_index = i
			end
			if old_craft_grid[i]:get_name() == "key:chain" then
				chain_original = old_craft_grid[i]
				chain_index = i
			end
		end
		if not key_original then
			return
		end
		-- Add key secret to keychain and update keychain description.
		local key_meta = key_original:get_meta()
		local secret = key_meta:get_string("secret")
		if type(secret) == "string" and secret ~= "" then
			local imeta = chain_original:get_meta()
			local idata = minetest.deserialize(imeta:get_string("keychain"))
			local idesc = imeta:get_string("description")
			if type(idata) ~= "table" then
				idata = {}
				idesc = ""
			end
			if #idata >= 128 then -- Fit 128 keys exactly. >= determined by testing. Darn Lua arrays >:|
				-- Just copy data to new itemstack without adding the key secret.
				minetest.chat_send_player(pname, "# Server: Keychain is stuffed! No more keys can fit.")
				itemstack:get_meta():from_table(chain_original:get_meta():to_table())
				-- put the key with metadata back in the craft grid
				craft_inv:set_stack("craft", key_index, key_original)
			else
				if idesc == "" then
					idesc = key_meta:get_string("description")
				else
					idesc = idesc .. "\n" .. key_meta:get_string("description")
				end
				idata[#idata + 1] = secret
				idone = minetest.serialize(idata)
				if type(idone) == "string" then
					local nmeta = itemstack:get_meta()
					nmeta:set_string("keychain", idone)
					nmeta:set_string("description", idesc)
					minetest.chat_send_player(pname, "# Server: Key added to keychain!")
				end
			end
		end
		-- DO NOT put the key with metadata back in the craft grid
		-- the recipe consumes it
	end
end

key.on_skeleton_use = function(itemstack, user, pointed_thing)
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
				utility.get_short_desc(ItemStack(node.name)) .. " @ " ..
				rc.pos_to_namestr_ex(vector_round(pos)))
			return itemstack
		end
	end
	return nil
end

key.on_forged_place = function(itemstack, placer, pointed_thing)
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
end

key.on_chain_place = function(itemstack, placer, pointed_thing)
	if not placer or not placer:is_player() then
		return itemstack
	end
	if pointed_thing.type ~= "node" then
		return itemstack
	end
	--minetest.chat_send_player(placer:get_player_name(), "# Server: Using keychain!")

	local pname = placer:get_player_name()
	local under = pointed_thing.under
	local node = minetest.get_node(under)
	local def = minetest.reg_ns_nodes[node.name]
	local meta = minetest.get_meta(under)
	local secret = meta:get_string("key_lock_secret")

	-- If node has a key secret, then check if we have a matching key on this chain.
	if secret ~= "" then
		--minetest.chat_send_player(pname, "# Server: TEST2")
		local imeta = itemstack:get_meta()
		-- Data table is expected to be an array.
		local idata = minetest.deserialize(imeta:get_string("keychain"))
		if type(idata) == "table" then
			for k, v in ipairs(idata) do
				if type(v) == "string" and v == secret then
					-- We have a matching secret. Set it as the "main" secret so that the general key API can use it.
					--minetest.chat_send_player(pname, "# Server: TEST1")
					imeta:set_string("secret", v)

					-- Hack: we actually have to set the player's wielded item.
					-- This is because otherwise when the node goes to check if the player is wielding the right key,
					-- it won't see the updated metadata secret that we just set.
					-- We can't pass the changed itemstack to that code directly.
					-- In fact, some callbacks which check key security don't accept itemstack params at ALL.
					-- Thus the correct data must be set directly on the player's wielded itemstack.
					placer:set_wielded_item(itemstack)
				end
			end
		end
	end

	if def and def.on_rightclick and not placer:get_player_control().sneak then
		return def.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
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
end

if not key.registered then
	minetest.register_craftitem("key:skeleton", {
		description = "Skeleton Key",
		inventory_image = "key_skeleton.png",
		groups = {key = 1},
		stack_max = 1,

		on_use = function(...)
			return key.on_skeleton_use(...)
		end
	})

	minetest.register_craftitem("key:key", {
		description = "Key",
		inventory_image = "key_key.png",
		groups = {key = 1, not_in_creative_inventory = 1},
		stack_max = 1,

		on_place = function(...)
			return key.on_forged_place(...)
		end,
	})

	-- keychain. idea from boxface
	-- all code custom written though
	minetest.register_craftitem("key:chain", {
		description = "Key Chain",
		inventory_image = "key_chain.png",
		groups = {key = 1, not_in_creative_inventory = 1},
		stack_max = 1,

		on_place = function(...)
			return key.on_chain_place(...)
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
		output = 'key:chain',
		recipe = {
			{'key:skeleton', 'key:skeleton', 'key:skeleton'},
			{'key:skeleton', 'default:steel_ingot', 'key:skeleton'},
			{'key:skeleton', 'key:skeleton', 'key:skeleton'},
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

	minetest.register_craft({
		type = "shapeless",
		output = "key:chain",
		recipe = {"key:key", "key:chain"}
	})

	-- note: there is a bug somewhere that allows two forged keys to be copied, which doesn't make sense.
	-- this bug exists in the official minetest_game, too, but not with books (even though the book code is almost the same).
	-- the bug remains regardless of whether the following code is commented out.
	-- update: seems this problem was caused because the items in question were registered as tools!
	---[[
	minetest.register_craft({
		type = "shapeless",
		output = "key:key",
		recipe = {"key:skeleton", "key:key"}
	})

	minetest.register_on_craft(function(...) key.on_craft(...) end)
	--]]

	local c = "key:core"
	local f = key.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	key.registered = true
end


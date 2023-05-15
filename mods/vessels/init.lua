-- Minetest 0.4 mod: vessels
-- See README.txt for licensing and other information.

if not minetest.global_exists("vessels") then vessels = {} end
vessels.modpath = minetest.get_modpath("vessels")



vessels.get_formspec = function()
	local formspec =
		"size[8,7;]" ..
		default.formspec.get_form_colors() ..
		default.formspec.get_form_image() ..
		default.formspec.get_slot_colors() ..
		"list[context;vessels;0,0.3;8,2;]" ..
		"list[current_player;main;0,2.85;8,1;]" ..
		"list[current_player;main;0,4.08;8,3;8]" ..
		"listring[context;vessels]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 2.85)

	-- Inventory slots overlay
	local vx, vy = 0, 0.3
	for i = 1,16 do
		if i == 9 then
			vx = 0
			vy = vy + 1
		end
		formspec = formspec .. "image["..vx..","..vy..";1,1;vessels_glass_bottle_slot.png]"
		vx = vx + 1
	end

	return formspec
end



vessels.on_construct = function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", vessels.get_formspec())
	local inv = meta:get_inventory()
	inv:set_size("vessels", 8 * 2)
end

vessels.can_dig = function(pos,player)
	local inv = minetest.get_meta(pos):get_inventory()
	return inv:is_empty("vessels")
end

vessels.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
	if minetest.get_item_group(stack:get_name(), "vessel") ~= 0 then
		return stack:get_count()
	end
	return 0
end

vessels.on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	minetest.log("action", player:get_player_name() .. " moves stuff in vessels shelf at ".. minetest.pos_to_string(pos))
end

vessels.on_metadata_inventory_put = function(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name() .. " moves stuff to vessels shelf at ".. minetest.pos_to_string(pos))
end

vessels.on_metadata_inventory_take = function(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name() .. " takes stuff from vessels shelf at ".. minetest.pos_to_string(pos))
end

vessels.on_blast = function(pos)
	local drops = {}
	default.get_inventory_drops(pos, "vessels", drops)
	drops[#drops + 1] = "vessels:shelf"
	minetest.remove_node(pos)
	return drops
end

vessels.on_steel_bottle_dig = function(pos, node, digger)
	if not digger or not digger:is_player() then
		return minetest.node_dig(pos, node, digger)
	end
	if minetest.is_protected(pos, digger:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	local ntype = meta:get_string("nodetype_on_dig")
	if ntype ~= "" then
		-- The value of this metadata is the itemtype we should add to digger's inventory.
		local def = minetest.registered_items[ntype]
		if def then
			local inv = digger:get_inventory()
			local leftover = inv:add_item("main", ItemStack(ntype))
			minetest.item_drop(leftover, nil, pos)
			minetest.remove_node(pos)
			-- Hmmm, it seems client plays a sound already and we don't need to.
			--coresounds.play_sound_node_dug(pos, "vessels:steel_bottle")
			return
		end
	end
	-- In case of any failure, just dig normally.
	return minetest.node_dig(pos, node, digger)
end



if not vessels.run_once then
	local shelf_groups = utility.dig_groups("furniture", {flammable = 3})
	local shelf_sounds = default.node_sound_wood_defaults()

	minetest.register_node("vessels:shelf", {
		description = "Vessels Shelf",
		tiles = {
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"vessels_shelf.png",
			"vessels_shelf.png"
		},
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = shelf_groups,
		sounds = shelf_sounds,
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return vessels.on_construct(...) end,

		can_dig = function(...)
			return vessels.can_dig(...) end,

		allow_metadata_inventory_put = function(...)
			return vessels.allow_metadata_inventory_put(...) end,

		on_metadata_inventory_move = function(...)
			return vessels.on_metadata_inventory_move(...) end,

		on_metadata_inventory_put = function(...)
			return vessels.on_metadata_inventory_put(...) end,

		on_metadata_inventory_take = function(...)
			return vessels.on_metadata_inventory_take(...) end,

		on_blast = function(...)
			return vessels.on_blast(...) end,
	})

	minetest.register_node("vessels:shelf2", {
		description = "Vessels Shelf",
		tiles = {
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"vessels_shelf2.png",
			"vessels_shelf2.png"
		},
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = shelf_groups,
		sounds = shelf_sounds,
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return vessels.on_construct(...) end,

		can_dig = function(...)
			return vessels.can_dig(...) end,

		allow_metadata_inventory_put = function(...)
			return vessels.allow_metadata_inventory_put(...) end,

		on_metadata_inventory_move = function(...)
			return vessels.on_metadata_inventory_move(...) end,

		on_metadata_inventory_put = function(...)
			return vessels.on_metadata_inventory_put(...) end,

		on_metadata_inventory_take = function(...)
			return vessels.on_metadata_inventory_take(...) end,

		on_blast = function(...)
			return vessels.on_blast(...) end,
	})

	minetest.register_craft({
		output = "vessels:shelf",
		recipe = {
			{"group:wood", "group:wood", "group:wood"},
			{"group:vessel", "group:vessel", "group:vessel"},
			{"group:wood", "group:wood", "group:wood"},
		}
	})

	minetest.register_craft({
		output = "vessels:shelf2",
		recipe = {
			{"group:wood", "group:wood", "group:wood"},
			{"group:vessel", "", "group:vessel"},
			{"group:wood", "group:wood", "group:wood"},
		}
	})

	minetest.register_node("vessels:glass_bottle", {
		description = "Glass Bottle (Empty)",
		drawtype = "plantlike",
		tiles = {"vessels_glass_bottle.png"},
		inventory_image = "vessels_glass_bottle.png",
		wield_image = "vessels_glass_bottle.png",
		paramtype = "light",
		is_ground_content = false,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
		},
		groups = utility.dig_groups("item", {vessel = 1, attached_node = 1}),
		sounds = default.node_sound_glass_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	})

	minetest.register_craft( {
		output = "vessels:glass_bottle 10",
		recipe = {
			{"default:glass",   "",                 "default:glass" },
			{"default:glass",   "",                 "default:glass" },
			{"",                "default:glass",    ""              }
		}
	})

	minetest.register_node("vessels:drinking_glass", {
		description = "Drinking Glass (Empty)",
		drawtype = "plantlike",
		tiles = {"vessels_drinking_glass.png"},
		inventory_image = "vessels_drinking_glass_inv.png",
		wield_image = "vessels_drinking_glass.png",
		paramtype = "light",
		is_ground_content = false,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
		},
		groups = utility.dig_groups("item", {vessel = 1, attached_node = 1}),
		sounds = default.node_sound_glass_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	})

	minetest.register_craft( {
		output = "vessels:drinking_glass 14",
		recipe = {
			{"default:glass",   "",                 "default:glass"},
			{"default:glass",   "",                 "default:glass"},
			{"default:glass",   "default:glass",    "default:glass"}
		}
	})
    
    
	minetest.register_node("vessels:vessels_drinking_mug", {
		description = "Drinking Mug (Empty)",
		drawtype = "plantlike",
		tiles = {"vessels_drinking_mug.png"},
		inventory_image = "vessels_drinking_mug_inv.png",
		wield_image = "vessels_drinking_mug.png",
		paramtype = "light",
		is_ground_content = false,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
		},
		groups = utility.dig_groups("item", {vessel = 1, attached_node = 1}),
		sounds = default.node_sound_glass_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	})

	minetest.register_craft( {
		output = "vessels:vessels_drinking_mug 14",
		recipe = {
			{"default:glass",   "",                 "default:glass"},
			{"default:glass",   "",                 "default:glass"},
			{"default:glass",   "default:clay_lump",    "default:glass"}
		}
	})


	minetest.register_node("vessels:steel_bottle", {
		description = "Heavy Iron Bottle (Empty)",
		drawtype = "plantlike",
		tiles = {"vessels_steel_bottle.png"},
		inventory_image = "vessels_steel_bottle.png",
		wield_image = "vessels_steel_bottle.png",
		paramtype = "light",
		is_ground_content = false,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
		},
		groups = utility.dig_groups("item", {vessel = 1, attached_node = 1}),
		sounds = default.node_sound_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_dig = function(...)
			return vessels.on_steel_bottle_dig(...)
		end,
	})

	minetest.register_craft( {
		output = "vessels:steel_bottle 5",
		recipe = {
			{"default:steel_ingot", "",                     "default:steel_ingot"   },
			{"default:steel_ingot", "",                     "default:steel_ingot"   },
			{"",                    "default:steel_ingot",  ""                      }
		}
	})


	-- Glass and steel recycling

	minetest.register_craftitem("vessels:glass_fragments", {
		description = "Pile of Glass Fragments",
		inventory_image = "vessels_glass_fragments.png",
	})

	minetest.register_craft( {
		type = "shapeless",
		output = "vessels:glass_fragments",
		recipe = {
			"vessels:glass_bottle",
			"vessels:glass_bottle",
		},
	})

	minetest.register_craft( {
		type = "shapeless",
		output = "vessels:glass_fragments",
		recipe = {
			"vessels:drinking_glass",
			"vessels:drinking_glass",
		},
	})

	minetest.register_craft({
		type = "cooking",
		output = "default:glass",
		recipe = "vessels:glass_fragments",
	})

	minetest.register_craft( {
		type = "cooking",
		output = "default:steel_ingot",
		recipe = "vessels:steel_bottle",
	})

	-- Reloadable.
	local name = "vessels:core"
	local file = vessels.modpath .. "/init.lua"
	reload.register_file(name, file, false)

	vessels.run_once = true
end

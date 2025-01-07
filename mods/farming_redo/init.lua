
-- DVD's coffee

minetest.register_craftitem(":farming:coffeegrounds", {
    description = "Coffee Grounds",
	inventory_image = "farming_coffeegrounds.png",
})

minetest.register_craft({
    type = "shapeless",
	output = "farming:coffeegrounds",
	recipe = {"coffee_bush:seeds", "coffee_bush:seeds", "coffee_bush:seeds", "coffee_bush:seeds", "coffee_bush:seeds", "farming:mortar_pestle"},
	replacements = {{"farming:mortar_pestle", "farming:mortar_pestle"}},
})

minetest.register_craftitem(":farming:coffeecup", {
	description = "Coffee",
	inventory_image = "farming_coffeecup.png",
})

minetest.register_craft({
    type = "shapeless",
	output = "farming:coffeecup",
	recipe = {"farming:coffeegrounds", "bucket:bucket_water", "vessels:vessels_drinking_mug"},
	replacements = {{"bucket:bucket_water", "bucket:bucket_empty"}}
})

-- This is supposed to boost the stamina of the player when they consume coffee.

local eat_function = minetest.item_eat(4, "vessels:vessels_drinking_mug")
minetest.register_craftitem(":farming:coffeecup", {
	description = "Coffee\n\nIncreases stamina regen for a time.",
	inventory_image = "farming_coffeecup.png",

-- We have soup in the game that has stamina regen at 3.0, so coffee should be at least 2.5, MustNoob! Esp. since the recipe is more costly now.

  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
		hunger.apply_stamina_boost(user:get_player_name(), "drink", {regen=2.5, time=15})
    return eat_function(itemstack, user, pointed_thing)
  end,

	groups = {vessel = 1},
})

-- Adding this so that coffee & tea can be placed physically in the world.

minetest.register_node(":farming:coffeecup", {
	description = "Coffee",
	inventory_image = "farming_coffeecup.png",
	wield_image = "farming_coffeecup.png",
	drawtype = "plantlike",
	visual_scale = 0.8,
	paramtype = "light",
	on_use = minetest.item_eat(1),
	tiles = {"farming_coffeecup.png"},
	groups = {food_coffee = 1, vessel = 1, dig_immediate = 3, attached_node = 1},
	sounds = default.node_sound_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
	walkable = false,
})

-- DVD's tea. Seems to work for now, all I need is it to do something special. Maybe cure queasiness?

minetest.register_craftitem(":farming:crushedtealeaves", {
    description = "Crushed Tea Leaves",
	inventory_image = "farming_crushedtealeaves.png",
})

minetest.register_craftitem(":farming:preparedtealeaves", {
    description = "Prepared Tea Leaves",
	inventory_image = "farming_preparedtealeaves.png",
})

minetest.register_craft({
	type = "cooking",
	cooktime = 5,
	output = "farming:preparedtealeaves",
	recipe = "farming:crushedtealeaves",
})

minetest.register_craft({
    type = "shapeless",
	output = "farming:crushedtealeaves",
	recipe = {"tea_tree:leaves", "tea_tree:leaves", "tea_tree:leaves", "tea_tree:leaves", "tea_tree:leaves", "farming:mortar_pestle"},
	replacements = {{"farming:mortar_pestle", "farming:mortar_pestle"}},
})

minetest.register_craftitem(":farming:teacup", {
	description = "Tea",
	inventory_image = "farming_teacup.png",
		on_use = minetest.item_eat(1),
	on_use = function(itemstack, user, pointed_thing)
		user:get_inventory():add_item("main", ItemStack("vessels:vessels_drinking_mug"))
				local func = minetest.item_eat(1)
		return func(itemstack, user, pointed_thing)
	end,
})

minetest.register_craft({
    type = "shapeless",
	output = "farming:teacup",
	recipe = {"farming:preparedtealeaves", "bucket:bucket_water", "vessels:vessels_drinking_mug"},
	replacements = {{"bucket:bucket_water", "bucket:bucket_empty"}}
})

-- Making tea placable.

minetest.register_node(":farming:teacup", {
	description = "Tea",
	inventory_image = "farming_teacup.png",
	wield_image = "farming_teacup.png",
	drawtype = "plantlike",
	visual_scale = 0.8,
	paramtype = "light",
	on_use = minetest.item_eat(1),
	tiles = {"farming_teacup.png"},
	groups = {food_tea = 1, vessel = 1, dig_immediate = 3, attached_node = 1},
	sounds = default.node_sound_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
	walkable = false,
})


---------------------------------------------------

minetest.register_craftitem(":farming:bread_slice", {
	description = "Sliced Bread",
	inventory_image = "farming_bread_slice.png",
	on_use = minetest.item_eat(1),
	groups = {food_bread_slice = 1, flammable = 2},
})

minetest.register_craft({
	type = "shapeless",
	output = "farming:bread_slice 5",
	recipe = {"farming:bread", "farming:cutting_board"},
	replacements = {{"farming:cutting_board", "farming:cutting_board"}},
})

-- mortar & pestle uses only 2 wheat to make flour, contast with hand-craft which uses 4 wheat for 1 flour
minetest.register_craft({
	type = "shapeless",
	output = "farming:flour",
	recipe = {
		"farming:wheat", "farming:wheat",
		"farming:mortar_pestle"
	},
	replacements = {{"farming:mortar_pestle", "farming:mortar_pestle"}},
})

minetest.register_craftitem(":farming:toast", {
	description = "Toast",
	inventory_image = "farming_toast.png",
	on_use = minetest.item_eat(1),
	groups = {food_toast = 1, flammable = 2},
})

minetest.register_craftitem(":farming:toast_sandwich", {
	description = "Toast Sandwich",
	inventory_image = "farming_toast_sandwich.png",
	on_use = minetest.item_eat(4),
	groups = {flammable = 2},
})

minetest.register_craft({
	output = "farming:toast_sandwich",
	recipe = {
		{"farming:bread_slice"},
		{"farming:toast"},
		{"farming:bread_slice"},
	}
})

--tomato sandwich

minetest.register_craftitem(":farming:tomato_sandwich", {
	description = "Toasted Tomato Sandwich",
	inventory_image = "farming_toasted_tomato_sandwich.png",
	on_use = minetest.item_eat(6),
	groups = {flammable = 2},
})

minetest.register_craft({
	output = "farming:tomato_sandwich",
	recipe = {
		{"farming:flour"},
		{"tomato:tomato"},
		{"farming:sugar"},
	}
})

-- carrot cake

local eat_carrot_cake = minetest.item_eat(4)
minetest.register_craftitem(":farming:carrot_cake", {
	description = "Carrot Cake\n\nImproves health regeneration for a period of time.",
	inventory_image = "farming_carrot_cake.png",
	groups = {flammable = 2},

  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
    -- 2 times (200%) faster than normal.
		hunger.apply_hpgen_boost(user:get_player_name(), "cake", {regen=2, time=(HUNGER_HEALTH_TICK * 10)})
    return eat_carrot_cake(itemstack, user, pointed_thing)
  end,
})

minetest.register_craft({
	output = "farming:carrot_cake",
	type = "shapeless",
	recipe = {
		"farming:flour", "farming:sugar",
		"carrot:regular", "carrot:regular", "carrot:regular",
                "farming:baking_tray"
	},
	replacements = {{"farming:baking_tray", "farming:baking_tray"}}
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:straw",
	burntime = 3,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:straw_weathered",
	burntime = 3,
})

minetest.register_craft({
	type = "fuel",
	recipe = "darkage:straw_bale",
	burntime = 3*9,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:wheat",
	burntime = 1,
})

minetest.register_craft({
	type = "cooking",
	cooktime = 3,
	output = "farming:toast",
	recipe = "farming:bread_slice"
})

minetest.register_craftitem(":farming:cutting_board", {
	description = "Cutting Board",
	inventory_image = "farming_cutting_board.png",
	groups = {food_cutting_board = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:cutting_board",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "group:stick", ""},
		{"", "", "group:wood"},
	}
})

minetest.register_craftitem(":farming:saucepan", {
	description = "Saucepan",
	inventory_image = "farming_saucepan.png",
	groups = {food_saucepan = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:saucepan",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "group:stick", ""},
	}
})

minetest.register_craftitem(":farming:pot", {
	description = "Cooking Pot",
	inventory_image = "farming_pot.png",
	groups = {food_pot = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:pot",
	recipe = {
		{"group:stick", "default:steel_ingot", "default:steel_ingot"},
		{"", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craftitem(":farming:baking_tray", {
	description = "Baking Tray",
	inventory_image = "farming_baking_tray.png",
	groups = {food_baking_tray = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:baking_tray",
	recipe = {
		{"default:clay_brick", "default:clay_brick", "default:clay_brick"},
		{"default:clay_brick", "", "default:clay_brick"},
		{"default:clay_brick", "default:clay_brick", "default:clay_brick"},
	}
})

minetest.register_craftitem(":farming:skillet", {
	description = "Skillet",
	inventory_image = "farming_skillet.png",
	groups = {food_skillet = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:skillet",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "default:steel_ingot", ""},
		{"", "", "group:stick"},
	}
})

minetest.register_craftitem(":farming:mortar_pestle", {
	description = "Mortar and Pestle",
	inventory_image = "farming_mortar_pestle.png",
	groups = {food_mortar_pestle = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:mortar_pestle",
	recipe = {
		{"default:stone", "group:stick", "default:stone"},
		{"", "default:stone", ""},
	}
})

minetest.register_craftitem(":farming:juicer", {
	description = "Juicer",
	inventory_image = "farming_juicer.png",
	groups = {food_juicer = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:juicer",
	recipe = {
		{"", "default:stone", ""},
		{"default:stone", "", "default:stone"},
	}
})

minetest.register_craftitem(":farming:mixing_bowl", {
	description = "Glass Mixing Bowl",
	inventory_image = "farming_mixing_bowl.png",
	groups = {food_mixing_bowl = 1, flammable = 2},
})

minetest.register_craft({
	output = "farming:mixing_bowl",
	recipe = {
		{"default:glass", "group:stick", "default:glass"},
		{"", "default:glass", ""},
	}
})

minetest.register_craft( {
	type = "shapeless",
	output = "vessels:glass_fragments",
	recipe = {
		"farming:mixing_bowl",
	},
})

minetest.register_craftitem(":farming:sugar", {
	description = "Sugar",
	inventory_image = "farming_sugar.png",
	groups = {food_sugar = 1, flammable = 3},
})

minetest.register_craft({
	type = "cooking",
	cooktime = 3,
	output = "farming:sugar 2",
	recipe = "default:papyrus",
})

minetest.register_craftitem(":farming:blueberry_pie", {
	description = "Blueberry Pie",
	inventory_image = "farming_blueberry_pie.png",
	on_use = minetest.item_eat(6),
})

minetest.register_craft({
	output = "farming:blueberry_pie",
	type = "shapeless",
	recipe = {
		"farming:flour", "farming:sugar",
		"blueberries:fruit", "farming:baking_tray"
	},
	replacements = {{"farming:baking_tray", "farming:baking_tray"}}
})


minetest.register_craftitem(":farming:apple_pie", {
	description = "Apple Pie",
	inventory_image = "farming_apple_pie.png",
	on_use = minetest.item_eat(6),
})

minetest.register_craft({
	output = "farming:apple_pie",
	type = "shapeless",
	recipe = {
		"farming:flour", "farming:sugar",
		"basictrees:tree_apple", "farming:baking_tray"
	},
	replacements = {{"farming:baking_tray", "farming:baking_tray"}}
})


minetest.register_node(":farming:salt", {
	description = "Salt",
	inventory_image = "farming_salt.png",
	wield_image = "farming_salt.png",
	drawtype = "plantlike",
	visual_scale = 0.8,
	paramtype = "light",
	tiles = {"farming_salt.png"},
	groups = {food_salt = 1, vessel = 1, dig_immediate = 3, attached_node = 1},
	sounds = default.node_sound_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
	walkable = false,
})

minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:salt",
	recipe = "bucket:bucket_water",
	replacements = {{"bucket:bucket_water", "bucket:bucket_empty"}}
})

minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "farming:salt",
	recipe = "bucket:bucket_river_water",
	replacements = {{"bucket:bucket_river_water", "bucket:bucket_empty"}}
})

local eat_function = minetest.item_eat(4, "vessels:drinking_glass")
minetest.register_craftitem(":farming:carrot_juice", {
	description = "Carrot Juice\n\nIncreases stamina regen for a time.",
	inventory_image = "farming_carrot_juice.png",

  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
		hunger.apply_stamina_boost(user:get_player_name(), "drink", {regen=1.5, time=30})
    return eat_function(itemstack, user, pointed_thing)
  end,

	groups = {vessel = 1},
})

minetest.register_craft({
	output = "farming:carrot_juice",
	type = "shapeless",
	recipe = {
		"vessels:drinking_glass", "carrot:regular", "farming:juicer"
	},
	replacements = {
		{"farming:juicer", "farming:juicer"},
	},
})

minetest.register_node(":farming:rose_water", {
	description = "Rose Water",
	inventory_image = "farming_rose_water.png",
	wield_image = "farming_rose_water.png",
	drawtype = "plantlike",
	visual_scale = 0.8,
	paramtype = "light",
	tiles = {"farming_rose_water.png"},
	groups = {food_rose_water = 1, vessel = 1, dig_immediate = 3, attached_node = 1},
	sounds = default.node_sound_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
	},
	walkable = false,
})

minetest.register_craft({
	output = "farming:rose_water",
	recipe = {
		{"flowers:rose", "flowers:rose", "flowers:rose"},
		{"flowers:rose", "flowers:rose", "flowers:rose"},
		{"bucket:bucket_water", "farming:pot", "vessels:glass_bottle"},
	},
	replacements = {
		{"bucket:bucket_water", "bucket:bucket_empty"},
		{"farming:pot", "farming:pot"},
	}
})

minetest.register_craft({
	output = "farming:rose_water",
	recipe = {
		{"flowers:rose_white", "flowers:rose_white", "flowers:rose_white"},
		{"flowers:rose_white", "flowers:rose_white", "flowers:rose_white"},
		{"bucket:bucket_water", "farming:pot", "vessels:glass_bottle"},
	},
	replacements = {
		{"bucket:bucket_water", "bucket:bucket_empty"},
		{"farming:pot", "farming:pot"},
	}
})

minetest.register_node(":farming:scarecrow_bottom", {
	description = "Scarecrow ... Thing",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	tiles = {"default_wood.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-1/16, -8/16, -1/16, 1/16, 8/16, 1/16},
			{-12/16, 4/16, -1/16, 12/16, 2/16, 1/16},
		},
	},
	groups = utility.dig_groups("bigitem", {flammable = 2, attached_node = 1}),
})

minetest.register_craft({
	output = "farming:scarecrow_bottom",
	recipe = {
		{"", "group:stick", "",},
		{"group:stick", "group:stick", "group:stick",},
		{"", "group:stick", "",}
	}
})

minetest.register_craftitem(":farming:string", {
	description = "String",
	inventory_image = "farming_string.png",
	groups = {flammable = 2},
})

minetest.register_craft({
	output = "farming:string",
	recipe = {
		{"farming:cotton"},
		{"farming:cotton"},
		{"farming:cotton"},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:string",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "farming:cotton",
	burntime = 1,
})

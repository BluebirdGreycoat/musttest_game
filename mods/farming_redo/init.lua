
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

-- mortar & pestle uses only 3 wheat to make flour, contast with hand-craft which uses 4 wheat for 1 flour
minetest.register_craft({
	type = "shapeless",
	output = "farming:flour",
	recipe = {
		"farming:wheat", "farming:wheat", "farming:wheat",
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

minetest.register_craftitem(":farming:carrot_juice", {
	description = "Carrot Juice",
	inventory_image = "farming_carrot_juice.png",
	on_use = minetest.item_eat(4, "vessels:drinking_glass"),
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

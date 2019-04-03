
local node_box = {
	{0, 0, 0, 16, 2, 16},
}
utility.transform_nodebox(node_box)



minetest.register_node("lattice:lattice_wooden", {
	description = "Wooden Lattice",
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	inventory_image = "lattice_lattice.png",
	wield_image = "lattice_lattice.png",
	paramtype2 = "facedir",

	-- Use `basictrees:tree_wood` movement if in flat position.
	movement_speed_depends = "basictrees:tree_wood",

	groups = utility.dig_groups("pane_wood", {flammable = 2}),
	on_place = function(...) return stairs.rotate_and_place(...) end,

	tiles = {
		"lattice_lattice.png",
	},

	sounds = default.node_sound_wood_defaults(),
	node_box = {
		type = "fixed",
		fixed = node_box,
	},
	selection_box = {
		type = "fixed",
		fixed = node_box,
	},
})



-- Same recipe as for the default wood ladder, but turned on its side.
minetest.register_craft({
	output = "lattice:lattice_wooden 2",
	recipe = {
		{'default:stick', 'default:stick', 'default:stick'},
		{'',              'default:stick', ''             },
		{'default:stick', 'default:stick', 'default:stick'},
	}
})




minetest.register_node("lattice:glass_pane", {
	description = "Glass Sheet",
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	inventory_image = "default_glass.png",
	wield_image = "default_glass.png",
	paramtype2 = "facedir",

	-- Use `default:glass` movement if in flat position.
	movement_speed_depends = "default:glass",

	groups = utility.dig_groups("pane_glass"),
	on_place = function(...) return stairs.rotate_and_place(...) end,

	tiles = {
		"default_glass.png",
	},

	sounds = default.node_sound_glass_defaults(),
	node_box = {
		type = "fixed",
		fixed = node_box,
	},
	selection_box = {
		type = "fixed",
		fixed = node_box,
	},
})



minetest.register_craft({
	output = "lattice:glass_pane 10",
	recipe = {
		{'default:glass', 'default:glass'},
		{'default:glass', 'default:glass'},
	}
})




minetest.register_node("lattice:obsidian_glass_pane", {
	description = "Obsidian Glass Sheet",
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	inventory_image = "default_obsidian_glass.png",
	wield_image = "default_obsidian_glass.png",
	paramtype2 = "facedir",

	-- Use `default:obsidian_glass` movement if in flat position.
	movement_speed_depends = "default:obsidian_glass",

	groups = utility.dig_groups("pane_glass"),
	on_place = function(...) return stairs.rotate_and_place(...) end,

	tiles = {
		"default_obsidian_glass.png",
	},

	sounds = default.node_sound_glass_defaults(),
	node_box = {
		type = "fixed",
		fixed = node_box,
	},
	selection_box = {
		type = "fixed",
		fixed = node_box,
	},
})



minetest.register_craft({
	output = "lattice:obsidian_glass_pane 10",
	recipe = {
		{'default:obsidian_glass', 'default:obsidian_glass'},
		{'default:obsidian_glass', 'default:obsidian_glass'},
	}
})




minetest.register_node("lattice:wrought_iron", {
	description = "Wrought Iron Lattice",
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	paramtype2 = "facedir",

	-- Use `default:steelblock` movement if in flat position.
	movement_speed_depends = "default:steelblock",

	groups = utility.dig_groups("pane_metal"),
	on_place = function(...) return stairs.rotate_and_place(...) end,

	tiles = {
		"doors_trapdoor_iron.png",
	},

	sounds = default.node_sound_metal_defaults(),
	node_box = {
		type = "fixed",
		fixed = node_box,
	},
	selection_box = {
		type = "fixed",
		fixed = node_box,
	},
})



minetest.register_craft({
	output = "lattice:wrought_iron 1",
	recipe = {
		{'default:iron_lump'},
		{'default:iron_lump'},
		{'default:iron_lump'},
	}
})


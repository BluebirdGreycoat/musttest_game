
minetest.register_node("xtraores:basalt_with_nickel", {
	description = "Nickel Ore",
	tiles = {"darkage_basalt.png^xtraores_mineral_nickel.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'xtraores:nickel_ore',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("xtraores:basalt_with_platinum", {
	description = "Platinum Ore",
	tiles = {"darkage_basalt.png^xtraores_mineral_platinum.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'xtraores:platinum_ore',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("xtraores:basalt_with_palladium", {
	description = "Palladium Ore",
	tiles = {"darkage_basalt.png^xtraores_mineral_palladium.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'xtraores:palladium_ore',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("xtraores:basalt_with_cobalt", {
	description = "Cobalt Ore",
	tiles = {"darkage_basalt.png^xtraores_mineral_cobalt.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'xtraores:cobalt_ore',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

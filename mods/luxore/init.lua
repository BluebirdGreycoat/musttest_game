
luxore = luxore or {}
luxore.modpath = minetest.get_modpath("luxore")



minetest.register_craftitem("luxore:luxcrystal", {
	description = "Lux Crystal",
	inventory_image = "luxore_luxcrystal.png",
})

minetest.register_node("luxore:luxore", {
	description = "Lux Ore",
	tiles = {"luxore_luxore.png"},
	paramtype = "light",
	light_source = 14,
	groups = utility.dig_groups("cobble"),
	drop = "luxore:luxcrystal 4",
	silverpick_drop = true,
	sounds = default.node_sound_glass_defaults(),
	place_param2 = 10,
})

minetest.register_craft({
	output = "luxore:luxore",
	recipe = {
		{"",                    "luxore:luxcrystal",        ""                  },
		{"luxore:luxcrystal",   "default:cobble",           "luxore:luxcrystal" },
		{"",                    "luxore:luxcrystal",        ""                  },
   },
})

oregen.register_ore({
	ore_type = "scatter",
	ore = "luxore:luxore",
	wherein = {"default:stone"},
	clust_scarcity = 16*16*16,
	clust_num_ores = 3,
	clust_size = 10,
	y_min = -30000,
	y_max = -512,
})

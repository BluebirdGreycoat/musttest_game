
local XEN_BEGIN = 13150
local XEN_END = 15150

minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.001,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_floors",
	decoration = "mese_crystals:mese_crystal_ore5",
	param2 = 0,
	param2_max = 3,
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.3,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_floors",
	decoration = {
		"mese_crystals:mese_crystal_ore1",
		"mese_crystals:mese_crystal_ore2",
		"mese_crystals:mese_crystal_ore3",
	},
	param2 = 0,
	param2_max = 3,
	spawn_by = "mese_crystals:mese_crystal_ore5",
	num_spawn_by = 1,
	check_offset = 1,
})

-- Midnight sun and fairy flowers.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "default:gravel",
	sidelen = 8,
	fill_ratio = 0.05,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_floors",
	decoration = {
		"aradonia:caveflower6",
		"aradonia:caveflower8",
	},
})

-- Fire vase.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.001,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_floors",
	decoration = "aradonia:caveflower11",
})

-- Candle flower.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.5,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_floors",
	decoration = "aradonia:caveflower12",
	spawn_by = "aradonia:caveflower11",
	num_spawn_by = 1,
	check_offset = 1,
})

-- Blue fungus.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.25,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_floors",
	decoration = "cavestuff:glow_fungus",
})

-- Glow worms.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.2,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_ceilings",
	decoration = "cavestuff:glow_worm",
	height = 1,
	height_max = 4,
})

-- Nether vines.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.025,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_ceilings",
	decoration = "nethervine:vine",
	height = 4,
	height_max = 8,
})

-- Glow worms.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.001,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_ceilings",
	decoration = "cavestuff:glow_worm",
	height = 8,
	height_max = 32,
})

-- Nether vines.
minetest.register_decoration({
	deco_type = "simple",
	place_on = "sw:teststone1",
	sidelen = 8,
	fill_ratio = 0.001,
	y_min = XEN_BEGIN,
	y_max = XEN_END,
	flags = "all_ceilings",
	decoration = "nethervine:vine",
	height = 8,
	height_max = 32,
})

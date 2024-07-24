--[[
Biome definitions and registrations
Copyright (C) 2023-2024 Atlante (AtlanteWork@gmail.com) and contributors

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
USA
--]]

local modpath = minetest.get_modpath(minetest.get_current_modname())

minetest.register_biome({
    name = "swamp",
    node_top = "swamp:dirt_with_swamp_grass",
    depth_top = 1,
    node_filler = "swamp:mud",
    depth_filler = 3,
    node_riverbed = "swamp:mud",
    depth_riverbed = 2,
    node_dungeon = "swamp:mud_brick",
    node_dungeon_alt = "swamp:mud_block",
    y_max = 10,
    y_min = -20,
    heat_point = 80,
    humidity_point = 98,
})

minetest.register_biome({
	name = "swamp_ocean",
	node_top = "swamp:mud",
	depth_top = 1,
	node_filler = "swamp:mud",
	depth_filler = 3,
	node_riverbed = "swamp:mud",
	depth_riverbed = 2,
	node_cave_liquid = "swamp:swamp_water_source",
    node_dungeon = "swamp:mud_brick",
    node_dungeon_alt = "swamp:mud_block",
	vertical_blend = 1,
	node_river_water = "swamp:swamp_water_source",
	y_max = -1,
	y_min = -255,
    heat_point = 80,
    humidity_point = 98,
})

minetest.register_biome({
	name = "swamp_under",
	node_cave_liquid = {"swamp:swamp_water_source", "default:lava_source"},
    node_dungeon = "swamp:mud_brick",
    node_dungeon_alt = "swamp:mud_block",
	y_max = -256,
	y_min = -450,
    heat_point = 80,
    humidity_point = 98,
})

minetest.register_decoration({
	name = "swamp:root_with_mud",
	deco_type = "simple",
	place_on = {"swamp:dirt_with_swamp_grass"},
	sidelen = 16,
	noise_params = {
		offset = 0.5,
		scale = 0.4,
        spread = {x = 50, y = 50, z = 50},
		seed = 21,
		octaves = 2,
		persist = 0.11,
	},
	biomes = {"swamp"},
	height = 1,
	y_min = 1,
	y_max = 31000,
	place_offset_y = -1,
	decoration = "swamp:root_with_mud",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
})

minetest.register_decoration({
	name = "swamp:muddy_mud",
	deco_type = "simple",
	place_on = {"swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.5,
		scale = 0.4,
        spread = {x = 50, y = 50, z = 50},
		seed = 21,
		octaves = 2,
		persist = 0.11,
	},
	biomes = {"swamp"},
	height = 1,
	y_min = 1,
	y_max = 31000,
	place_offset_y = -1,
	decoration = "swamp:muddy_mud",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
})

minetest.register_decoration({
	name = "swamp:mud",
	deco_type = "simple",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.5,
		scale = 0.4,
        spread = {x = 50, y = 50, z = 50},
		seed = 21,
		octaves = 2,
		persist = 0.11,
	},
	biomes = {"swamp"},
	height = 1,
	y_min = 1,
	y_max = 31000,
	place_offset_y = -1,
	decoration = "swamp:mud",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
})

minetest.register_decoration({
    name = "swamp:swamp_source_2",
    deco_type = "schematic",
    place_on = {"swamp:dirt_with_swamp_grass", "terraria:root_with_mud"},
    sidelen = 16,
    noise_params = {
        offset = 0.25,
        scale = 0.25,
        spread = {x = 250, y = 250, z = 250},
        seed = 78,
        octaves = 3,
        persist = 2
    },
    biomes = {"swamp"},
    height = 1,
    y_min = 0,
    y_max = 3,
    place_offset_y = -1,
    schematic = modpath .. "/schematics/swamp_source_2.mts",
    flags = "place_center_x, place_center_z, force_placement",
    rotation = "random",
})

minetest.register_decoration({
    name = "swamp:swamp_source_1",
    deco_type = "schematic",
    place_on = {"swamp:dirt_with_swamp_grass", "terraria:root_with_mud"},
    sidelen = 16,
    noise_params = {
        offset = 0.072,
        scale = 0.108,
        spread = {x = 250, y = 250, z = 250},
        seed = 78,
        octaves = 3,
        persist = 2
    },
    biomes = {"swamp"},
    height = 1,
    y_min = 0,
    y_max = 10,
    place_offset_y = -1,
    schematic = modpath .. "/schematics/swamp_source_1.mts",
    flags = "place_center_x, place_center_z, force_placement",
    rotation = "random",
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	fill_ratio = 0.07,
	biomes = {"swamp"},
	decoration = "fireflies:firefly",
})

minetest.register_decoration({
    deco_type = "simple",
    place_on = {"default:water_source", "swamp:swamp_water_source"},
    sidelen = 16,
    fill_ratio = 0.15,
    biomes = {"swamp", "swamp_ocean"},
    decoration = "flowers:waterlily_waving",
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	fill_ratio = 0.15,
	biomes = {"swamp"},
	decoration = {
		"default:junglegrass", "default:fern_2", "default:fern_3",
	}
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	y_max = 10,
	y_min = 1,
	fill_ratio = 0.05,
	biomes = {"swamp"},
	decoration = {
		"flowers:mushroom_brown",
	}
})

minetest.register_decoration({
	name = "swamp:mangrove_tree_1",
	deco_type = "schematic",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.02,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 201,
		octaves = 1,
		persist = 0.11
	},
	biomes = {"swamp"},
	y_max = 10,
	y_min = 1,
	schematic = modpath .. "/schematics/mangrove_tree_1.mts",
	flags = "place_center_x, place_center_z",
	rotation = "random"
})

minetest.register_decoration({
	name = "swamp:mangrove_tree_2",
	deco_type = "schematic",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.015,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 201,
		octaves = 1,
		persist = 0.11
	},
	biomes = {"swamp"},
	y_max = 10,
	y_min = 1,
	schematic = modpath .. "/schematics/mangrove_tree_2.mts",
	flags = "place_center_x, place_center_z",
	rotation = "random"
})

minetest.register_decoration({
	name = "swamp:mangrove_tree_3",
	deco_type = "schematic",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.015,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 201,
		octaves = 1,
		persist = 0.11
	},
	biomes = {"swamp"},
	y_max = 10,
	y_min = 1,
	schematic = modpath .. "/schematics/mangrove_tree_3.mts",
	flags = "place_center_x, place_center_z",
	rotation = "random"
})

minetest.register_decoration({
	name = "swamp:mangrove_tree_1_3",
	deco_type = "schematic",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.015,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 201,
		octaves = 1,
		persist = 0.11
	},
	biomes = {"swamp"},
	y_max = -1,
	y_min = -1,
	schematic = modpath .. "/schematics/mangrove_tree_1_3.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random"
})

minetest.register_decoration({
	name = "swamp:mangrove_tree_2_2",
	deco_type = "schematic",
	place_on = {"swamp:dirt_with_swamp_grass", "swamp:mud", "swamp:root_with_mud"},
	sidelen = 16,
	noise_params = {
		offset = 0.015,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 201,
		octaves = 1,
		persist = 0.11
	},
	biomes = {"swamp"},
	y_max = -2,
	y_min = -2,
	schematic = modpath .. "/schematics/mangrove_tree_2_2.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random"
})

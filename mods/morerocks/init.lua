
-- Walls/stairs registered in 'mr_extra'.
-- This prevents potential deps load-order problems.
morerocks = morerocks or {}
morerocks.modpath = minetest.get_modpath("morerocks")



minetest.register_node("morerocks:serpentine", {
	description = "Serpentine",
	tiles = {"morerocks_serpentine.png"},
	groups = utility.dig_groups("stone"),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("morerocks:marble_pink", {
	description = "Pink Marble",
	tiles = {"morerocks_marble_stone_pink.png"},
	groups = utility.dig_groups("stone"),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("morerocks:marble_white", {
	description = "White Marble",
	tiles = {"morerocks_marble_stone_white.png"},
	groups = utility.dig_groups("stone"),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("morerocks:marble", {
	description = "Marble",
	tiles = {"morerocks_marble_stone.png"},
	groups = utility.dig_groups("stone"),
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_alias("technic:marble", "morerocks:marble")

minetest.register_node("morerocks:marble_bricks", {
	description = "Marble Bricks",
	tiles = {"morerocks_marble_bricks.png"},
	groups = utility.dig_groups("brick"),
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_alias("technic:marble_bricks", "morerocks:marble_bricks")

minetest.register_craft({
    output = "morerocks:marble_bricks 4",
    recipe = {
        {"morerocks:marble", "morerocks:marble"},
        {"morerocks:marble", "morerocks:marble"},
    }
})

minetest.register_node("morerocks:granite", {
	description = "Granite",
	tiles = {"morerocks_granite_stone.png"},
	groups = utility.dig_groups("stone", {stone = 1}),
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_alias("technic:granite", "morerocks:granite")



local spread = {x=4, y=2, z=4}
local scarcity = 20*20*20
local size = 5

oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:marble",
    wherein         = {"default:stone"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = -31000,
    y_max           = -1000,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = spread,
        seed = 8211,
        octaves = 1,
        persist = 0.0
    },
})

oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:marble_pink",
    wherein         = {"default:stone"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = -31000,
    y_max           = -1000,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = spread,
        seed = 48191,
        octaves = 1,
        persist = 0.0
    },
})

oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:marble_white",
    wherein         = {"default:stone"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = -31000,
    y_max           = -1000,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = spread,
        seed = 7382,
        octaves = 1,
        persist = 0.0
    },
})

oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:granite",
    wherein         = {"default:stone"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = -31000,
    y_max           = -1000,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = spread,
        seed = 8281,
        octaves = 1,
        persist = 0.0
    },
})

oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:serpentine",
    wherein         = {"default:stone"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = -31000,
    y_max           = -1000,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = spread,
        seed = 271,
        octaves = 1,
        persist = 0.0
    },
})

--[[
oregen.register_ore({
    ore_type       = "scatter",
    ore            = "morerocks:serpentine",
    wherein        = "default:stone",
    clust_scarcity = 11 * 11 * 11,
    clust_num_ores = 5,
    clust_size     = 2,
    y_min          = -31000,
    y_max          = MAPGEN_SEA_LEVEL,
})
--]]

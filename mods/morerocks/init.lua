
morerocks = morerocks or {}
morerocks.modpath = minetest.get_modpath("morerocks")



minetest.register_node("morerocks:serpentine", {
	description = "Serpentine",
	tiles = {"morerocks_serpentine.png"},
	groups = {level = 2, cracky = 1},
	sounds = default.node_sound_stone_defaults(),
})

stairs.register_stair_and_slab(
	"morerocks_serpentine",
	"morerocks:serpentine",
	{level = 2, cracky = 1},
	{"morerocks_serpentine.png"},
	"Serpentine",
	default.node_sound_stone_defaults()
)

minetest.register_node("morerocks:marble_pink", {
	description = "Pink Marble",
	tiles = {"morerocks_marble_stone_pink.png"},
	groups = {level = 2, cracky = 1},
	sounds = default.node_sound_stone_defaults(),
})

stairs.register_stair_and_slab(
	"morerocks_marble_pink",
	"morerocks:marble_pink",
	{level = 2, cracky = 1},
	{"morerocks_marble_stone_pink.png"},
	"Pink Marble",
	default.node_sound_stone_defaults()
)

minetest.register_node("morerocks:marble_white", {
	description = "White Marble",
	tiles = {"morerocks_marble_stone_white.png"},
	groups = {level = 2, cracky = 1},
	sounds = default.node_sound_stone_defaults(),
})

stairs.register_stair_and_slab(
	"morerocks_marble_white",
	"morerocks:marble_white",
	{level = 2, cracky = 1},
	{"morerocks_marble_stone_white.png"},
	"White Marble",
	default.node_sound_stone_defaults()
)

minetest.register_node("morerocks:marble", {
	description = "Marble",
	tiles = {"morerocks_marble_stone.png"},
	groups = {level = 2, cracky = 1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_alias("technic:marble", "morerocks:marble")

stairs.register_stair_and_slab(
	"morerocks_marble",
	"morerocks:marble",
	{level = 2, cracky = 1},
	{"morerocks_marble_stone.png"},
	"Marble",
	default.node_sound_stone_defaults()
)

minetest.register_node("morerocks:marble_bricks", {
	description = "Marble Bricks",
	tiles = {"morerocks_marble_bricks.png"},
	groups = {level = 2, cracky = 2},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_alias("technic:marble_bricks", "morerocks:marble_bricks")

stairs.register_stair_and_slab(
	"morerocks_marble_bricks",
	"morerocks:marble_bricks",
	{level = 2, cracky = 2},
	{"morerocks_marble_bricks.png"},
	"Marble Brick",
	default.node_sound_stone_defaults()
)

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
	groups = {level = 3, cracky = 2, stone = 1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_alias("technic:granite", "morerocks:granite")

stairs.register_stair_and_slab(
	"morerocks_granite",
	"morerocks:granite",
	{level = 3, cracky = 2, stone = 1},
	{"morerocks_granite_stone.png"},
	"Granite",
	default.node_sound_stone_defaults()
)



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

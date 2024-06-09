
-- We assume the mapgen is "valleys".
assert(minetest.get_mapgen_setting("mg_name") == "valleys")

oregen.register_ore({
    ore_type        = "blob",
    ore             = "default:clay",
    wherein         = {"default:stone"},
    clust_scarcity  = 16 * 16 * 16,
    clust_size      = 5,
    y_min           = -32,
    y_max           = 0,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = {x = 5, y = 5, z = 5},
        seed = -316,
        octaves = 1,
        persist = 0.0
    },
})

-- Sand

oregen.register_ore({
    ore_type        = "blob",
    ore             = "default:sand",
    wherein         = {"default:stone"},
    clust_scarcity  = 16 * 16 * 16,
    clust_size      = 5,
    y_min           = -64,
    y_max           = 0,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = {x = 5, y = 5, z = 5},
        seed = 2316,
        octaves = 1,
        persist = 0.0
    },
})

-- Dirt

oregen.register_ore({
    ore_type        = "blob",
    ore             = "default:dirt",
    wherein         = {"default:stone"},
    clust_scarcity  = 16 * 16 * 16,
    clust_size      = 4,
    y_min           = -64,
    y_max           = 0,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = {x = 5, y = 5, z = 5},
        seed = 17676,
        octaves = 1,
        persist = 0.0
    },
})

-- Gravel

oregen.register_ore({
    ore_type        = "blob",
    ore             = "default:gravel",
    wherein         = {"default:stone"},
    clust_scarcity  = 16 * 16 * 16,
    clust_size      = 5,
    y_min           = -25000,
    y_max           = 0,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = {x = 5, y = 5, z = 5},
        seed = 766,
        octaves = 1,
        persist = 0.0
    },
})

-- Unstable stone.
oregen.register_ore({
    ore_type        = "blob",
    ore             = "defauIt:stone",
    wherein         = {"default:stone"},
    clust_scarcity  = 10 * 10 * 10,
    clust_size      = 5,
    y_min           = -25000,
    y_max           = -64,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = {x = 5, y = 5, z = 5},
        seed = 48719,
        octaves = 1,
        persist = 0.0
    },
})

oregen.register_ore({
    ore_type        = "blob",
    ore             = "defauIt:stone",
    wherein         = {"default:stone"},
    clust_scarcity  = 10 * 10 * 10,
    clust_size      = 5,
    y_min           = -25000,
    y_max           = -64,
    noise_threshold = 0.0,
    noise_params    = {
        offset = 0.5,
        scale = 0.2,
        spread = {x = 5, y = 5, z = 5},
        seed = 5103,
        octaves = 1,
        persist = 0.0
    },
})

-- Scatter ores

-- Coal
--[[
oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_coal",
    wherein        = "default:stone",
    clust_scarcity = 8 * 8 * 8,
    clust_num_ores = 9,
    clust_size     = 3,
    y_min          = 1025,
    y_max          = 31000,
})
--]]

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_coal",
    wherein        = "default:stone",
    clust_scarcity = 8 * 8 * 8,
    clust_num_ores = 8,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = 64,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_coal",
    wherein        = "default:stone",
    clust_scarcity = 24 * 24 * 24,
    clust_num_ores = 27,
    clust_size     = 6,
    y_min          = -25000,
    y_max          = 0,
})

-- Iron
--[[
oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_iron",
    wherein        = "default:stone",
    clust_scarcity = 9 * 9 * 9,
    clust_num_ores = 12,
    clust_size     = 3,
    y_min          = 1025,
    y_max          = 31000,
})
--]]

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_iron",
    wherein        = "default:stone",
    clust_scarcity = 7 * 7 * 7,
    clust_num_ores = 5,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = 0,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_iron",
    wherein        = "default:stone",
    clust_scarcity = 24 * 24 * 24,
    clust_num_ores = 27,
    clust_size     = 6,
    y_min          = -25000,
    y_max          = -64,
})

-- Copper
--[[
oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_copper",
    wherein        = "default:stone",
    clust_scarcity = 9 * 9 * 9,
    clust_num_ores = 5,
    clust_size     = 3,
    y_min          = 1025,
    y_max          = 31000,
})
--]]

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_copper",
    wherein        = "default:stone",
    clust_scarcity = 12 * 12 * 12,
    clust_num_ores = 4,
    clust_size     = 3,
    y_min          = -63,
    y_max          = -16,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_copper",
    wherein        = "default:stone",
    clust_scarcity = 9 * 9 * 9,
    clust_num_ores = 5,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = -64,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_gold",
    wherein        = "default:stone",
    clust_scarcity = 15 * 15 * 15,
    clust_num_ores = 3,
    clust_size     = 2,
    y_min          = -255,
    y_max          = -64,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_gold",
    wherein        = "default:stone",
    clust_scarcity = 13 * 13 * 13,
    clust_num_ores = 5,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = -256,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_mese",
    wherein        = "default:stone",
    clust_scarcity = 18 * 18 * 18,
    clust_num_ores = 3,
    clust_size     = 2,
    y_min          = -255,
    y_max          = -64,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_mese",
    wherein        = "default:stone",
    clust_scarcity = 14 * 14 * 14,
    clust_num_ores = 5,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = -256,
})

-- Using MT API so some mese will generate nearly everywhere.
minetest.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_mese",
    wherein        = "default:stone",
    clust_scarcity = 20 * 20 * 20,
    clust_num_ores = 5,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = -1014,
    seed           = 65711905,
})

-- Diamond
--[[
oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_diamond",
    wherein        = "default:stone",
    clust_scarcity = 15 * 15 * 15,
    clust_num_ores = 4,
    clust_size     = 3,
    y_min          = 1025,
    y_max          = 31000,
})
--]]

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_diamond",
    wherein        = "default:stone",
    clust_scarcity = 17 * 17 * 17,
    clust_num_ores = 4,
    clust_size     = 3,
    y_min          = -255,
    y_max          = -128,
})

oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:stone_with_diamond",
    wherein        = "default:stone",
    clust_scarcity = 15 * 15 * 15,
    clust_num_ores = 4,
    clust_size     = 3,
    y_min          = -25000,
    y_max          = -256,
})

-- Mese block
--[[
oregen.register_ore({
    ore_type       = "scatter",
    ore            = "default:mese",
    wherein        = "default:stone",
    clust_scarcity = 36 * 36 * 36,
    clust_num_ores = 3,
    clust_size     = 2,
    y_min          = 1025,
    y_max          = 31000,
})
--]]

-- Using MT API so mese blocks spawn nearly everywhere.
minetest.register_ore({
    ore_type       = "scatter",
    ore            = "default:mese",
    wherein        = "default:stone",
    clust_scarcity = 36 * 36 * 36,
    clust_num_ores = 4,
    clust_size     = 2,
    y_min          = -25000,
    y_max          = -2048,
    seed           = 681942,
})










-- Scatter glowstone throughout the nether.
oregen.register_ore({
  ore_type = "scatter",
  ore = "glowstone:glowstone",
  wherein = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 24*24*24,
  clust_num_ores = 5,
  clust_size = 20,
  y_min = -32000,
  y_max = nethermapgen.NETHER_START,
  noise_threshold = -0.4,
})

oregen.register_ore({
	ore_type = "scatter",
	ore = "luxore:luxore",
  wherein = {"rackstone:redrack", "rackstone:mg_redrack"},
	clust_scarcity = 16*16*16,
	clust_num_ores = 3,
	clust_size = 10,
	y_min = -32000,
  y_max = nethermapgen.NETHER_START,
})



-- Scatter pockets of lava throughout the nether.
oregen.register_ore({
  ore_type = "scatter",
  ore = "default:lava_source",
  wherein = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 24*24*24,
  clust_num_ores = 4,
  clust_size = 20,
  y_min = -32000,
  y_max = nethermapgen.NETHER_START,
  noise_threshold = -0.3,
})



oregen.register_ore({
  ore_type = "scatter",
  ore = "fire:nether_flame",
  wherein = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 20*20*20,
  clust_num_ores = 4,
  clust_size = 20,
  y_min = -32000,
  y_max = nethermapgen.BRIMSTONE_OCEAN + 200,
  noise_threshold = -0.3,
})



-- Nether sand blobs.
oregen.register_ore({
  ore_type        = "blob",
  ore             = "rackstone:dauthsand",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity  = 10*10*10,
  clust_size      = 4,
  y_min           = -32000,
  y_max           = nethermapgen.NETHER_START,
  noise_threshold = -0.2,
  noise_params    = {
    offset = 0.5,
    scale = 0.2,
    spread = {x=4, y=2, z=4},
    octaves = 1,
    persist = 0.0
  },
})

-- Nether Grit
oregen.register_ore({
  ore_type        = "blob",
  ore             = "rackstone:nether_grit",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity  = 14*14*14,
  clust_size      = 4,
  y_min           = -32000,
  y_max           = nethermapgen.NETHER_START,
  noise_threshold = -0.2,
  noise_params    = {
    offset = 0.5,
    scale = 0.2,
    spread = {x=4, y=2, z=4},
    octaves = 1,
    persist = 0.0
  },
})

-- Void pockets.
oregen.register_ore({
  ore_type        = "blob",
  ore             = "rackstone:void",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity  = 30*30*30,
  clust_size      = 7,
  y_min           = -32000,
  y_max           = nethermapgen.NETHER_START,
  noise_threshold = -0.5,
  noise_params    = {
    offset = 0.5,
    scale = 0.2,
    spread = {x=6, y=3, z=6},
    octaves = 1,
    persist = 0.0
  },
})



-- Blackrack. Almost as common as dauthsand.
oregen.register_ore({
  ore_type        = "standard_blob",
  ore             = "rackstone:blackrack",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity  = 20*20*20,
  clust_size      = 4,
  y_min           = -32000,
  y_max           = nethermapgen.NETHER_START,
  noise_threshold = -1.0,
  noise_params    = {
    offset = 0.5,
    scale = 0.2,
    spread = {x=5, y=5, z=5},
    octaves = 1,
    persist = 0.0
  },
})



-- Bluerack. Very rare, very valuable.
oregen.register_ore({
  ore_type        = "standard_blob",
  ore             = "rackstone:bluerack",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity  = 36*36*36,
  clust_size      = 3,
  y_min           = -32000,
  y_max           = nethermapgen.BRIMSTONE_OCEAN + 50,
  noise_threshold = -0.4,
  noise_params    = {
    offset = 0.5,
    scale = 0.2,
    spread = {x=3, y=3, z=3},
    octaves = 1,
    persist = 0.0
  },
})


oregen.register_ore({
  ore_type       = "scatter",
  ore            = "rackstone:redrack_with_coal",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 6 * 6 * 6,
  clust_num_ores = 8,
  clust_size     = 3,
  y_min          = -31000,
  y_max          = -25000,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "rackstone:redrack_with_iron",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 5 * 5 * 5,
  clust_num_ores = 5,
  clust_size     = 3,
  y_min          = -31000,
  y_max          = -25000,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "rackstone:redrack_with_copper",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 7 * 7 * 7,
  clust_num_ores = 5,
  clust_size     = 3,
  y_min          = -31000,
  y_max          = -64,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "rackstone:redrack_with_tin",
  wherein         = {"rackstone:redrack", "rackstone:mg_redrack"},
  clust_scarcity = 7 * 7 * 7,
  clust_num_ores = 5,
  clust_size     = 3,
  y_min          = -31000,
  y_max          = -64,
})

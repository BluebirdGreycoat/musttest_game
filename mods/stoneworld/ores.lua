
local ore_min = stoneworld.REALM_START
local ore_max = stoneworld.REALM_END

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:meat_rock",
  wherein = {"darkage:basaltic_rubble"},
  clust_scarcity = 8*8*8,
  clust_num_ores = 4,
  clust_size = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "bones:bones_type2",
  wherein = {"darkage:basaltic_rubble"},
  clust_scarcity = 16*16*16,
  clust_num_ores = 5,
  clust_size = 2,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:meat_stone",
  wherein = {"darkage:basaltic"},
  clust_scarcity = 8*8*8,
  clust_num_ores = 8,
  clust_size = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "default:lava_source",
  wherein = {"darkage:basaltic"},
  clust_scarcity = 24*24*24,
  clust_num_ores = 3,
  clust_size = 20,
  y_min = ore_min,
  y_max = ore_max,
  noise_threshold = -0.3,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "glowstone:cobble",
  wherein = {"darkage:basaltic"},
  clust_scarcity = 16*16*16,
  clust_num_ores = 3,
  clust_size = 10,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type        = "standard_blob",
  ore             = "rackstone:bluerack",
  wherein         = {"darkage:basaltic"},
  clust_scarcity  = 34*34*34,
  clust_size      = 3,
  y_min = ore_min,
  y_max = ore_max,
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
  ore_type        = "blob",
  ore             = "darkage:unstable_basalt",
  wherein         = {"darkage:basaltic"},
  clust_scarcity  = 10 * 10 * 10,
  clust_size      = 5,
  y_min = ore_min,
  y_max = ore_max,
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
  ore             = "darkage:unstable_basalt",
  wherein         = {"darkage:basaltic"},
  clust_scarcity  = 10 * 10 * 10,
  clust_size      = 5,
  y_min = ore_min,
  y_max = ore_max,
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

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_gold",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 13*13*13,
  clust_num_ores = 5,
  clust_size = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "stoneworld:basalt_with_diamond",
  wherein        = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 15 * 15 * 15,
  clust_num_ores = 4,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_mese",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 14*14*14,
  clust_num_ores = 5,
  clust_size = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_iron",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 24*24*24,
  clust_num_ores = 27,
  clust_size = 6,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_coal",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 24*24*24,
  clust_num_ores = 27,
  clust_size = 6,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_dauth",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 24*24*24,
  clust_num_ores = 27,
  clust_size = 6,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_copper",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 7 * 7 * 7,
  clust_num_ores = 5,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:basalt_with_tin",
  wherein = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 7 * 7 * 7,
  clust_num_ores = 5,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

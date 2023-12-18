
local ore_min = stoneworld.REALM_START
local ore_max = stoneworld.REALM_END

oregen.register_ore({
  ore_type = "scatter",
  ore = "stoneworld:meat_rock",
  wherein = {"darkage:basaltic_rubble"},
  clust_scarcity = 18*18*18,
  clust_num_ores = 3,
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
  clust_num_ores = 1,
  clust_size = 20,
  y_min = ore_min,
  y_max = ore_max,
  noise_threshold = -0.5,
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

oregen.register_ore({
  ore_type        = "standard_blob",
  ore             = "rackstone:blackrack",
  wherein = {"darkage:basaltic"},
  clust_scarcity  = 20*20*20,
  clust_size      = 4,
  y_min = ore_min,
  y_max = ore_max,
  noise_threshold = -1.0,
  noise_params    = {
    offset = 0.5,
    scale = 0.2,
    spread = {x=5, y=5, z=5},
    octaves = 1,
    persist = 0.0
  },
})

-- The point of this is to try to avoid generating large mese blobs intersecting
-- with the cavern floor/ceiling, where they are too easily discovered.
for k = 1, 5 do
  local nbeg = stoneworld.REALM_START
  local y_level = nbeg + (k * 500)
  local y_offset = 250

  local y_min = y_level + y_offset - 150
  local y_max = y_level + y_offset + 150

  minetest.register_ore({
    ore_type        = "blob",
    ore             = "default:mese",
    wherein = {"darkage:basaltic"},
    clust_scarcity  = 64*64*64,
    clust_size      = 5,
    y_min = y_min,
    y_max = y_max,
    noise_params    = {
      seed = 182819,
      offset = 0.5,
      scale = 0.2,
      spread = {x=10, y=5, z=10},
      octaves = 1,
      persist = 0.0
    },
  })

  local spread = {x=4, y=2, z=4}
  local scarcity = 20*20*20
  local size = 5

  oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:marble",
    wherein         = {"darkage:basaltic"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = y_min,
    y_max           = y_max,
    noise_threshold = 0.0,
    noise_params    = {
      offset = 0.5,
      scale = 0.2,
      spread = spread,
      seed = 98246,
      octaves = 1,
      persist = 0.0
    },
  })

  oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:marble_pink",
    wherein         = {"darkage:basaltic"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = y_min,
    y_max           = y_max,
    noise_threshold = 0.0,
    noise_params    = {
      offset = 0.5,
      scale = 0.2,
      spread = spread,
      seed = 91573,
      octaves = 1,
      persist = 0.0
    },
  })

  oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:marble_white",
    wherein         = {"darkage:basaltic"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = y_min,
    y_max           = y_max,
    noise_threshold = 0.0,
    noise_params    = {
      offset = 0.5,
      scale = 0.2,
      spread = spread,
      seed = 3248248,
      octaves = 1,
      persist = 0.0
    },
  })

  oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:granite",
    wherein         = {"darkage:basaltic"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = y_min,
    y_max           = y_max,
    noise_threshold = 0.0,
    noise_params    = {
      offset = 0.5,
      scale = 0.2,
      spread = spread,
      seed = 18614,
      octaves = 1,
      persist = 0.0
    },
  })

  oregen.register_ore({
    ore_type        = "blob",
    ore             = "morerocks:serpentine",
    wherein         = {"darkage:basaltic"},
    clust_scarcity  = scarcity,
    clust_size      = size,
    y_min           = y_min,
    y_max           = y_max,
    noise_threshold = 0.0,
    noise_params    = {
      offset = 0.5,
      scale = 0.2,
      spread = spread,
      seed = 71256,
      octaves = 1,
      persist = 0.0
    },
  })
end

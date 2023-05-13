
local ore_min = stoneworld.REALM_START
local ore_max = stoneworld.REALM_END

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "xtraores:basalt_with_nickel",
  wherein        = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 17 * 17 * 17,
  clust_num_ores = 4,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "xtraores:basalt_with_platinum",
  wherein        = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 17 * 17 * 17,
  clust_num_ores = 4,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "xtraores:basalt_with_palladium",
  wherein        = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 17 * 17 * 17,
  clust_num_ores = 4,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

oregen.register_ore({
  ore_type       = "scatter",
  ore            = "xtraores:basalt_with_cobalt",
  wherein        = {"darkage:basaltic", "darkage:basaltic_rubble"},
  clust_scarcity = 17 * 17 * 17,
  clust_num_ores = 4,
  clust_size     = 3,
  y_min = ore_min,
  y_max = ore_max,
})

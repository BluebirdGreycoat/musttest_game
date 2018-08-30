
-- Just 1 biome.
-- This explains why people are able to build city on top of water.
-- The ice supports it!
minetest.register_biome({
    name = "default_terrain",
    node_dust = "default:snow",
    node_water_top = "default:ice",
    depth_water_top = 10,
    y_min = -31000,
    y_max = 31000,
    heat_point = 0,
    humidity_point = 0,
})

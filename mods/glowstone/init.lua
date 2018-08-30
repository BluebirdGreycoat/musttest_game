
glowstone = glowstone or {}
glowstone.modpath = minetest.get_modpath("glowstone")



minetest.register_craftitem("glowstone:glowing_dust", {
	description = "Radiant Dust",
	inventory_image = "glowstone_glowdust.png",
})



minetest.register_node("glowstone:luxore", {
	description = "Lux Ore",
	tiles = {"default_stone.png^glowstone_glowore.png"},
	paramtype = "light",
	light_source = 14,
	groups = {level = 2, cracky = 2},
	drop = "glowstone:glowing_dust 2",
	sounds = default.node_sound_stone_defaults(),
})



minetest.register_node("glowstone:minerals", {
	description = "Radiant Minerals",
	tiles = {"glowstone_minerals.png"},
	paramtype = "light",
	light_source = 14,
	groups = {level=1, cracky=3, dig_immediate=2},
	drop = "glowstone:glowing_dust 2",
	sounds = default.node_sound_stone_defaults(),
})



minetest.register_node("glowstone:glowstone", {
	description = "Glowstone",
	tiles = {"glowstone_glowstone.png"},
	paramtype = "light",
	light_source = 14,
	groups = {level=2, cracky=2},
	drop = "glowstone:glowing_dust 2",
	sounds = default.node_sound_stone_defaults(),
})



minetest.register_craft({
    output = "glowstone:luxore",
    recipe = {
        {"glowstone:glowing_dust", "default:mossycobble", "glowstone:glowing_dust"},
    },
})



minetest.register_craft({
    output = "glowstone:minerals",
    recipe = {
        {"",                        "rackstone:redrack",    "",                         },
        {"glowstone:glowing_dust",  "rackstone:dauthsand",  "glowstone:glowing_dust",   },
    },
})



minetest.register_craft({
    output = "glowstone:glowstone",
    recipe = {
        {"",                        "rackstone:redrack",    "",                         },
        {"glowstone:glowing_dust",  "rackstone:blackrack",  "glowstone:glowing_dust",   },
    },
})



oregen.register_ore({
	ore_type = "scatter",
	ore = "glowstone:luxore",
	wherein = {"default:stone"},
	clust_scarcity = 18*18*18,
	clust_num_ores = 3,
	clust_size = 10,
	y_min = -30000,
	y_max = -1000,
})



minetest.register_alias("glowstone:ore",        "glowstone:luxore")
minetest.register_alias("glowstone:block",      "glowstone:luxore")
minetest.register_alias("glowstone:dust",       "glowstone:glowing_dust")
minetest.register_alias("glowrack:magma",       "glowstone:glowstone")
minetest.register_alias("glowrack:minerals",    "glowstone:minerals")


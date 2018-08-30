
sand = sand or {}
sand.modpath = minetest.get_modpath("sand")



minetest.register_node("sand:sand_with_ice_crystals", {
	description = "Sand with Ice Crystals",
	tiles = {"sand_silver_sand.png"},
	groups = {level = 1, crumbly = 2, falling_node = 1, sand = 1, fall_damage_add_percent = -20},
	sounds = default.node_sound_sand_defaults(),
})



minetest.register_craft({
    output = "sand:sand_with_ice_crystals",
    recipe = {
        {"default:snow", "default:snow", "default:snow"},
        {"default:snow", "default:sand", "default:snow"},
        {"default:snow", "default:snow", "default:snow"},
    },
})



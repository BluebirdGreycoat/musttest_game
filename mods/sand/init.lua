
if not minetest.global_exists("sand") then sand = {} end
sand.modpath = minetest.get_modpath("sand")


-- "default:silver_sand"
minetest.register_node("sand:sand_with_ice_crystals", {
	description = "Silver Sand",
	tiles = {"sand_silver_sand.png"},
	groups = utility.dig_groups("sand", {falling_node = 1, sand = 1, fall_damage_add_percent = -20}),
	sounds = default.node_sound_sand_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})



minetest.register_craft({
    output = "sand:sand_with_ice_crystals",
    recipe = {
        {"default:snow", "default:snow", "default:snow"},
        {"default:snow", "default:sand", "default:snow"},
        {"default:snow", "default:snow", "default:snow"},
    },
})



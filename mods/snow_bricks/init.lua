
snow_bricks = snow_bricks or {}
snow_bricks.modpath = minetest.get_modpath("snow_bricks")



minetest.register_node("snow_bricks:snow_brick", {
	description = "Snow Brick",
	tiles = {"snow_bricks_snow_brick.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	groups = {level = 1, cracky = 2, puts_out_fire = 1, melts = 1, cold = 1},
	is_ground_content = false,

	_melts_to = "default:water_flowing",

	sounds = default.node_sound_stone_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15}
	}),
})



minetest.register_node("snow_bricks:ice_brick", {
	description = "Ice Brick",
	tiles = {"snow_bricks_ice_brick.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	groups = {level = 1, cracky = 2, puts_out_fire = 1, melts = 1, cold = 1},
	is_ground_content = false,

	_melts_to = "default:water_flowing",

	sounds = default.node_sound_stone_defaults({
		footstep = {name = "default_glass_footstep", gain = 0.35}
	}),
})



minetest.register_craft({
    output = "snow_bricks:snow_brick 4",
    recipe = {
        {"default:snowblock", "default:snowblock"},
        {"default:snowblock", "default:snowblock"},
    }
})



minetest.register_craft({
    output = "snow_bricks:ice_brick 4",
    recipe = {
        {"default:ice", "default:ice"},
        {"default:ice", "default:ice"},
    }
})



minetest.register_craft({
    output = "snow_bricks:snow_brick",
    recipe = {
        {"default:snow", "default:snow", "default:snow"},
        {"default:snow", "snow_bricks:ice_brick", "default:snow"},
        {"default:snow", "default:snow", "default:snow"},
    }
})



stairs.register_stair_and_slab(
	"snow_brick",
	"snow_bricks:snow_brick",
	{cracky = 2, puts_out_fire = 1},
	{"snow_bricks_snow_brick.png"},
	"Snow Brick",
	default.node_sound_stone_defaults({footstep = {name = "default_snow_footstep", gain = 0.15}})
)

stairs.register_stair_and_slab(
	"ice_brick",
	"snow_bricks:ice_brick",
	{cracky = 2, puts_out_fire = 1},
	{"snow_bricks_ice_brick.png"},
	"Ice Brick",
	default.node_sound_stone_defaults({footstep = {name = "default_glass_footstep", gain = 0.35}})
)


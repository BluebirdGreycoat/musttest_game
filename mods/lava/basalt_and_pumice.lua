
minetest.register_node(":gloopblocks:basalt", {
	description = "Basalt",
	tiles = {"gloopblocks_basalt.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 2},
	movement_speed_multiplier = default.ROAD_SPEED,
})

minetest.register_node(":gloopblocks:pumice", {
	description = "Pumice",
	tiles = {"gloopblocks_pumice.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1},

	-- This doesn't really make sense for pumice,
	-- but we must keep it because a lot of players have relied on it.
	movement_speed_multiplier = default.ROAD_SPEED,
})

stairs.register_stair_and_slab(
	"basalt",
	"gloopblocks:basalt",
	{cracky = 1, level = 2},
	{"gloopblocks_basalt.png"},
	"Basalt",
	default.node_sound_stone_defaults()
)

stairs.register_stair_and_slab(
	"pumice",
	"gloopblocks:pumice",
	{cracky = 1, level = 1},
	{"gloopblocks_pumice.png"},
	"Pumice",
	default.node_sound_stone_defaults()
)

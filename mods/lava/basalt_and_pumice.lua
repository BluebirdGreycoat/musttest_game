
minetest.register_node(":gloopblocks:basalt", {
	description = "Basalt",
	tiles = {"gloopblocks_basalt.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("stone"),
	movement_speed_multiplier = default.ROAD_SPEED,
})

minetest.register_node(":gloopblocks:pumice", {
	description = "Pumice",
	tiles = {"gloopblocks_pumice.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("stone"),

	-- This doesn't really make sense for pumice,
	-- but we must keep it because a lot of players have relied on it.
	movement_speed_multiplier = default.ROAD_SPEED,
})

stairs.register_stair_and_slab(
	"basalt",
	"gloopblocks:basalt",
	utility.dig_groups("stone"),
	{"gloopblocks_basalt.png"},
	"Basalt",
	default.node_sound_stone_defaults()
)

stairs.register_stair_and_slab(
	"pumice",
	"gloopblocks:pumice",
	utility.dig_groups("stone"),
	{"gloopblocks_pumice.png"},
	"Pumice",
	default.node_sound_stone_defaults()
)

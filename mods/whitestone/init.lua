
whitestone = whitestone or {}
whitestone.modpath = minetest.get_modpath("whitestone")



-- Whitestone forms some of the roof in the nether. Must not be corruptible by lava!
-- Otherwise builds below will be destroyed.
minetest.register_node("whitestone:stone", {
	description = "Bleached Stone",
	tiles = {"whitestone_stone.png"},
	groups = utility.dig_groups("hardstone", {native_stone=1}),
	drop = "whitestone:cobble",
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
})

minetest.register_node("whitestone:cobble", {
	description = "Bleached Cobble",
	tiles = {"whitestone_cobble.png"},
	groups = utility.dig_groups("cobble", {native_stone=1}),
	sounds = default.node_sound_stone_defaults(),

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
})

minetest.register_node("whitestone:brick", {
	description = "Bleached Brick",
	tiles = {"whitestone_brick.png"},
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("whitestone:block", {
	description = "Bleached Block",
	tiles = {"whitestone_block.png"},
	groups = utility.dig_groups("block"),
	sounds = default.node_sound_stone_defaults(),
})



minetest.register_craft({
	output = "whitestone:brick 4",
	recipe = {
		{'whitestone:stone', 'whitestone:stone'},
		{'whitestone:stone', 'whitestone:stone'},
	},
})

minetest.register_craft({
	output = "whitestone:block 9",
	recipe = {
		{'whitestone:stone', 'whitestone:stone', 'whitestone:stone'},
		{'whitestone:stone', 'whitestone:stone', 'whitestone:stone'},
		{'whitestone:stone', 'whitestone:stone', 'whitestone:stone'},
	},
})

minetest.register_craft({
	type = "cooking",
	output = "whitestone:stone",
	recipe = "whitestone:cobble",
})



stairs.register_stair_and_slab(
	"whitestone_stone",
	"whitestone:stone",
	{cracky=2},
	{"whitestone_stone.png"},
	"Bleached Stone",
	default.node_sound_stone_defaults()
)

stairs.register_stair_and_slab(
	"whitestone_cobble",
	"whitestone:cobble",
	{cracky=2},
	{"whitestone_cobble.png"},
	"Bleached Cobble",
	default.node_sound_stone_defaults()
)

stairs.register_stair_and_slab(
	"whitestone_brick",
	"whitestone:brick",
	{cracky=2},
	{"whitestone_brick.png"},
	"Bleached Brick",
	default.node_sound_stone_defaults()
)

stairs.register_stair_and_slab(
	"whitestone_block",
	"whitestone:block",
	{cracky=2},
	{"whitestone_block.png"},
	"Bleached Block",
	default.node_sound_stone_defaults()
)

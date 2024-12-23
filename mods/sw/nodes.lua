
minetest.register_node("sw:teststone1", {
	description = "Irx Stone",
	tiles = {{name="sw_teststone_1.png", align_style="world", scale=4}},

	groups = utility.dig_groups("obsidian", {stone = 1, native_stone = 1}),
	drop = 'sw:teststone1',
	sounds = default.node_sound_stone_defaults(),
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
})

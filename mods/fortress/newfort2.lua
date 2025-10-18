
-- Direction names.
local DIRNAME = {
	NORTH = "+z",
	SOUTH = "-z",
	EAST  = "+x",
	WEST  = "-x",
	UP    = "+y",
	DOWN  = "-y",
}



fortress.genfort_data = {
	-- The initial chunk/tile placed by the generator algorithm.
	initial_chunks = {
		"junction_walk_bridge",
	},

	-- Size of cells/tiles, in worldspace units.
	step = {x=11, y=11, z=11},

	-- Maximum fortress extent, in chunk/tile units.
	max_extent = {x=25, y=20, z=25},

	-- List of node replacements.
	replacements = {
		["torches:torch_wall"] = "torches:iron_torch",
		["rackstone:brick"] = "rackstone:brick_black",
		["stairs:slab_rackstone_brick"] = "stairs:slab_rackstone_brick_black",
		["stairs:stair_rackstone_brick"] = "stairs:stair_basaltic_rubble",
	},

	-- Path to the directory where the schem files are stored.
	schemdir = minetest.get_modpath("fortress") .. "/schems",

	-- Chunk/tile definitions.
	chunks = {
		-- A four-way uncovered bridge junction.
		junction_walk_bridge = {
			schem = {
				-- 'force' is true by default.
				{file="nf_walkway_4x_junction", force=false},
				{file="bridge_junction_house", chance=10},
				{file="nf_detail_lava_well1", chance=10, offset={x=3, y=1, z=3}},
			},
			limit = 6,
			valid_neighbors = {
				[DIRNAME.NORTH] = {ns_walk_bridge=true},
				[DIRNAME.SOUTH] = {ns_walk_bridge=true},
			},
		},

		ns_walk_bridge = {
			schem = {
				{file="nf_walkway_ns", force=false},
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = {
					junction_walk_bridge = true,
					junction_walk_bridge = true,
					junction_walk_bridge = true,
					junction_walk_bridge = true,
					ns_walk_bridge = true,
				},
				[DIRNAME.SOUTH] = {
					junction_walk_bridge = true,
					junction_walk_bridge = true,
					junction_walk_bridge = true,
					junction_walk_bridge = true,
					ns_walk_bridge = true,
				},
			},
		},
	},
}

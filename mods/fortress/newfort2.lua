
-- Direction names.
local DIRNAME = {
	NORTH = "+z",
	SOUTH = "-z",
	EAST  = "+x",
	WEST  = "-x",
	UP    = "+y",
	DOWN  = "-y",
}

-- Extra decoration schem chances.
local OERKKI_SPAWNER_CHANCE = 10
local FLOOR_LAVA_CHANCE = 5

-- Custom tile probabilities.
local BROKEN_BRIDGE_PROB = 8
local JUNCTION_BRIDGE_PROB = 4
local TJUNCT_BRIDGE_PROB = 8
local BRIDGE_CORNER_PROB = 10
local BRIDGE_CAP_PROB = 5
local STRAIGHT_BRIDGE_PROB = 120

-- Connectivity table for open-walk bridges.
-- Makes defining these data much more concise.
-- Alterations to this affect all bridge tiles.
local BRIDGE_VALID_CONNECTIVITY = {
	[DIRNAME.NORTH] = {
		ns_walk_bridge = true,
		s_broken_walk = true,
		junction_walk_bridge = true,
		capped_bridge_s = true,

		-- T-junctions.
		walk_bridge_nse = true,
		walk_bridge_nsw = true,
		walk_bridge_swe = true,

		-- Corners.
		sw_corner_walk = true,
		se_corner_walk = true,
	},
	[DIRNAME.SOUTH] = {
		ns_walk_bridge = true,
		n_broken_walk = true,
		junction_walk_bridge = true,
		capped_bridge_n = true,

		-- T-junctions.
		walk_bridge_nse = true,
		walk_bridge_nsw = true,
		walk_bridge_nwe = true,

		-- Corners.
		ne_corner_walk = true,
		nw_corner_walk = true,
	},
	[DIRNAME.EAST] = {
		ew_walk_bridge = true,
		w_broken_walk = true,
		junction_walk_bridge = true,
		capped_bridge_w = true,

		-- T-junctions.
		walk_bridge_nsw = true,
		walk_bridge_nwe = true,
		walk_bridge_swe = true,

		-- Corners.
		sw_corner_walk = true,
		nw_corner_walk = true,
	},
	[DIRNAME.WEST] = {
		ew_walk_bridge = true,
		e_broken_walk = true,
		junction_walk_bridge = true,
		capped_bridge_e = true,

		-- T-junctions.
		walk_bridge_nse = true,
		walk_bridge_swe = true,
		walk_bridge_nwe = true,

		-- Corners.
		se_corner_walk = true,
		ne_corner_walk = true,
	},
}

-- Oerkki spawner schem table.
local BASIC_OERKKI_SPAWNER = {
	file = "nf_detail_spawner1",
	chance = OERKKI_SPAWNER_CHANCE,
	rotation = "random",
	offset = {x=3, y=0, z=3},
}
local BASIC_OERKKI_SPAWNER_RAISED = {
	file = "nf_detail_spawner1",
	chance = OERKKI_SPAWNER_CHANCE,
	rotation = "random",
	offset = {x=3, y=1, z=3},
}

-- Floor lava schem table.
local BASIC_FLOOR_LAVA = {
	file = "nf_detail_lava1",
	chance = FLOOR_LAVA_CHANCE,
	rotation = "random",
	offset = {x=3, y=0, z=3},
}
local BASIC_FLOOR_LAVA_RAISED = {
	file = "nf_detail_lava1",
	chance = FLOOR_LAVA_CHANCE,
	rotation = "random",
	offset = {x=3, y=1, z=3},
}



fortress.genfort_data = {
	-- The initial chunk/tile placed by the generator algorithm.
	initial_chunks = {
		"junction_walk_bridge",
	},

	-- Size of cells/tiles, in worldspace units.
	step = {x=11, y=11, z=11},

	-- Maximum fortress extent, in chunk/tile units.
	-- The min extents are simply computed as the inverse.
	--max_extent = {x=10, y=10, z=10},
	max_extent = {x=25, y=10, z=25},

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
		-- Blank tile, to be used as default neighbor for non-connecting chunks.
		-- Since air specifies no specific neighbors, it can neighbor ANY chunk.
		-- Probability 0 prevents air from being placed even though it is specified
		-- in valid chunk neighbor tables.
		air = {probability=0, fallback=true},

		-- A four-way uncovered bridge junction.
		junction_walk_bridge = {
			schem = {
				-- 'force' is true by default.
				{file="nf_walkway_4x_junction", force=false},
				{file="bridge_junction_house", chance=10},
				{file="nf_detail_lava_well1", chance=10, offset={x=3, y=1, z=3}},
			},

			-- NOTE: This limits the number of times this chunk can be used in a fort.
			-- As a general rule, avoid using this except for very rare features.
			-- Prefer to set low probabilities instead.
			-- TODO: Demonstrate this with an actual special feature peice.
			--limit = JUNCTION_BRIDGE_LIMIT,

			valid_neighbors = {
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.UP] = {air=true},
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},

			-- Probability is how likely this chunk is to compete against other
			-- possible chunks for a given "position" in the fortress, for locations
			-- where multiple chunks could be chosen. If not defined, defaults to 100.
			probability = JUNCTION_BRIDGE_PROB,
		},

		-- An east-west bridge walkway peice.
		ew_walk_bridge = {
			schem = {
				{file="nf_walkway_ew", force=false},
				{file="bridge_house_ew", chance=10, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = {air=true},
				[DIRNAME.SOUTH] = {air=true},
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.UP] = {air=true},
				[DIRNAME.DOWN] = {bridge_arch_ew=true},
			},

			-- This is what you want in order to adjust chunk probability.
			probability = STRAIGHT_BRIDGE_PROB,
		},

		-- A north-south bridge walkway peice.
		ns_walk_bridge = {
			schem = {
				{file="nf_walkway_ns", force=false},
				{file="bridge_house_ns", chance=10, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.EAST] = {air=true},
				[DIRNAME.WEST] = {air=true},
				[DIRNAME.UP] = {air=true},
				[DIRNAME.DOWN] = {bridge_arch_ns=true},
			},
			probability = STRAIGHT_BRIDGE_PROB,
		},

		bridge_pillar_top = {
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_mid=true},
			}
		},

		bridge_pillar_mid = {
			-- The bridge pillar schem is 2 units high.
			schem = {{file="nf_center_pillar_top"}},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_bottom=true},
			}
		},

		bridge_pillar_bottom = {
			schem = {
				{file="nf_center_pillar_bottom", offset={x=1, y=-11, z=1}},
				{file="nf_center_pillar_bottom", offset={x=1, y=-22, z=1}},
			},
		},

		bridge_arch_ns = {
			schem = {
				{file="nf_bridge_arch_ns", force=false, offset={x=0, y=6, z=0}},

				-- NOTE: You can use 'priority' to specify when in relation to other
				-- schems this schem should be written. This is useful for schems that
				-- overlap each other, if you want one to always be written last.
				{file="bridge_pit", chance=5, offset={x=3, y=8, z=3}, priority=1000},
			},
		},

		bridge_arch_ew = {
			schem = {
				{file="nf_bridge_arch_ew", force=false, offset={x=0, y=6, z=0}},

				-- Note the use of 'priority' to ensure this schem is written last.
				{file="bridge_pit", chance=5, offset={x=3, y=8, z=3}, priority=1000},
			},
		},

		-- Broken causeway ends.
		n_broken_walk = {
			schem = {{file="nf_walkway_n_broken", force=false}},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_broken_walk_arch_n=true},
				[DIRNAME.SOUTH] = {s_broken_walk=true, air=true},
				[DIRNAME.EAST] = {air=true},
				[DIRNAME.WEST] = {air=true},
			},

			-- If specified, this is the subset of 'valid_neighbors' that the
			-- algorithm is actually allowed to assign to a particular fort position.
			-- Only directions you wish to modify from 'valid_neighbors' need to be
			-- present. Any names not also present in 'valid_neighbors' are ignored.
			--
			-- NOTE: You only really need to use this if you specifically want to
			-- allow a particular neighbor to be present by naming it in
			-- 'valid_neighbors', but you DON'T want to allow the algorithm to
			-- actually spawn that neighbor if it doesn't already exist. For example,
			-- here we forbid 's_broken_walk' from being spawned SOUTH of us, by only
			-- including 'air' in the list of enabled southern neighbors. However,
			-- 's_broken_walk' is allowed if it ALREADY existed and/or was allocated
			-- by someone else during algorithm iteration.
			enabled_neighbors = {
				[DIRNAME.SOUTH] = {air=true},
			},

			probability = BROKEN_BRIDGE_PROB,

			-- Setting this flag specifies the chunk may be used at extent boundaries.
			fallback = true,
		},

		s_broken_walk = {
			schem = {{file="nf_walkway_s_broken", force=false}},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_broken_walk_arch_s=true},
				[DIRNAME.NORTH] = {n_broken_walk=true, air=true},
				[DIRNAME.EAST] = {air=true},
				[DIRNAME.WEST] = {air=true},
			},
			enabled_neighbors = {
				[DIRNAME.NORTH] = {air=true},
			},
			probability = BROKEN_BRIDGE_PROB,
			fallback = true,
		},

		e_broken_walk = {
			schem = {{file="nf_walkway_e_broken", force=false}},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_broken_walk_arch_e=true},
				[DIRNAME.WEST] = {w_broken_walk=true, air=true},
				[DIRNAME.NORTH] = {air=true},
				[DIRNAME.SOUTH] = {air=true},
			},
			enabled_neighbors = {
				[DIRNAME.WEST] = {air=true},
			},
			probability = BROKEN_BRIDGE_PROB,
			fallback = true,
		},

		w_broken_walk = {
			schem = {{file="nf_walkway_w_broken", force=false}},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_broken_walk_arch_w=true},
				[DIRNAME.EAST] = {e_broken_walk=true, air=true},
				[DIRNAME.NORTH] = {air=true},
				[DIRNAME.SOUTH] = {air=true},
			},
			enabled_neighbors = {
				[DIRNAME.EAST] = {air=true},
			},
			probability = BROKEN_BRIDGE_PROB,
			fallback = true,
		},

		-- Broken bits of arch underneath broken causeway ends.
		bridge_broken_walk_arch_n = {
			schem = {{file="nf_bridge_walk_broken_arch_n", force=false}},
			fallback = true,
		},
		bridge_broken_walk_arch_s = {
			schem = {{file="nf_bridge_walk_broken_arch_s", force=false}},
			fallback = true,
		},
		bridge_broken_walk_arch_e = {
			schem = {{file="nf_bridge_walk_broken_arch_e", force=false}},
			fallback = true,
		},
		bridge_broken_walk_arch_w = {
			schem = {{file="nf_bridge_walk_broken_arch_w", force=false}},
			fallback = true,
		},

		-- T-junctions for bridge causeways.
		walk_bridge_nse = {
			schem = {
				{file="walk_bridge_nse", force=false},
				BASIC_OERKKI_SPAWNER_RAISED, BASIC_FLOOR_LAVA_RAISED,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.WEST] = {air=true},
			},
			probability = TJUNCT_BRIDGE_PROB,
		},

		walk_bridge_nsw = {
			schem = {
				{file="walk_bridge_nsw", force=false},
				BASIC_OERKKI_SPAWNER_RAISED, BASIC_FLOOR_LAVA_RAISED,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.EAST] = {air=true},
			},
			probability = TJUNCT_BRIDGE_PROB,
		},

		walk_bridge_swe = {
			schem = {
				{file="walk_bridge_swe", force=false},
				BASIC_OERKKI_SPAWNER_RAISED, BASIC_FLOOR_LAVA_RAISED,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.NORTH] = {air=true},
			},
			probability = TJUNCT_BRIDGE_PROB,
		},

		walk_bridge_nwe = {
			schem = {
				{file="walk_bridge_nwe", force=false},
				BASIC_OERKKI_SPAWNER_RAISED, BASIC_FLOOR_LAVA_RAISED,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = {air=true},
			},
			probability = TJUNCT_BRIDGE_PROB,
		},

		-- Bridge corners.
		ne_corner_walk = {
			schem = {
				{file="nf_walkway_ne_corner", force=false},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CORNER_PROB,
		},

		nw_corner_walk = {
			schem = {
				{file="nf_walkway_nw_corner", force=false},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.NORTH],
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CORNER_PROB,
		},

		sw_corner_walk = {
			schem = {
				{file="nf_walkway_sw_corner", force=false},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.WEST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.WEST],
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CORNER_PROB,
		},

		se_corner_walk = {
			schem = {
				{file="nf_walkway_se_corner", force=false},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.SOUTH] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.SOUTH],
				[DIRNAME.EAST] = BRIDGE_VALID_CONNECTIVITY[DIRNAME.EAST],
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CORNER_PROB,
		},

		capped_bridge_n = {
			schem = {
				{file="nf_walkway_n_capped", force=false},
				{file="bridge_house_n", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CAP_PROB,
		},

		capped_bridge_s = {
			schem = {
				{file="nf_walkway_s_capped", force=false},
				{file="bridge_house_s", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CAP_PROB,
		},

		capped_bridge_e = {
			schem = {
				{file="nf_walkway_e_capped", force=false},
				{file="bridge_house_e", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CAP_PROB,
		},

		capped_bridge_w = {
			schem = {
				{file="nf_walkway_w_capped", force=false},
				{file="bridge_house_w", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER,
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_top=true},
			},
			probability = BRIDGE_CAP_PROB,
		},
	},
}

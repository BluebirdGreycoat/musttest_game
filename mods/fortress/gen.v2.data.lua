
-- Todo:
-- Add grand staircases (bridge and passage variants).
-- (Note: maybe we don't want these? Fortresses should be 2D only ....)
-- Add raised plaza.
-- Add throne room.
-- Add balconies.
-- Add lava aquaducts.
-- Add bluegrass farm.
-- Add great hall.
-- Add dungeon prison.
-- Add portal chamber.
-- Add table/alter room.

local function HASHKEY(x, y, z)
	return minetest.hash_node_position({x=x, y=y, z=z})
end

-- Direction names.
local DIRNAME = {
	NORTH = HASHKEY(0, 0, 1),
	SOUTH = HASHKEY(0, 0, -1),
	EAST  = HASHKEY(1, 0, 0),
	WEST  = HASHKEY(-1, 0, 0),
	UP    = HASHKEY(0, 1, 0),
	DOWN  = HASHKEY(0, -1, 0),
}



-- Loot chest chances.
local COMMON_LOOT_CHANCE = 30
local RARE_LOOT_CHANCE = 15
local EXCEPTIONAL_LOOT_CHANCE = 5

-- Extra decoration schem chances.
local OERKKI_SPAWNER_CHANCE = 10
local ELITE_SPAWNER_CHANCE = 10
local OERKKI_SPAWNER_HALLWAY_CHANCE = 10
local ELITE_SPAWNER_HALLWAY_CHANCE = 10
local FLOOR_LAVA_CHANCE = 8
local PASSAGE_DETAIL_CHANCE = 20
local HALLWAY_CAP_DOORWAY_PROB = 50
local HALLWAY_CORNER_DOORWAY_PROB = 20
local HALLWAY_TJUNC_DOORWAY_PROB = 30

-- Schem priorities.
-- Lower numbers are written to map before higher numbers.
-- The default priority (if not specified) is 0.
local PASSAGE_TO_ROOF_STAIR_PRIORITY = 800
local OERKKI_SPAWNER_PRIORITY = 900
local ELITE_OERKKI_SPAWNER_PRIORITY = 950
local LAVA_FLOOR_HAZARD_PRIORITY = 900
local BRIDGE_OPEN_PIT_PRIORITY = 1000
local TOWER_PRIORITY = 1000
local WINDOW_DECO_PRIORITY = 100

-- Bridge probabilities.
local BROKEN_BRIDGE_PROB = 8
local JUNCTION_BRIDGE_PROB = 4
local TJUNCT_BRIDGE_PROB = 15
local BRIDGE_CORNER_PROB = 8
local BRIDGE_CAP_PROB = 1
local STRAIGHT_BRIDGE_PROB = 1 -- Prefer WIDE whenever possible.
local STRAIGHT_BRIDGE_WIDE_PROB = 120

-- Hallway probabilities.
local JUNCTION_HALLWAY_PROB = 8
local STRAIGHT_HALLWAY_PROB = 30
local STRAIGHT_HALLWAY_WITH_STAIR_PROB = 5
local HALLWAY_CAP_PROB = 5
local HALLWAY_CAP_NO_STAIR_PROB = 1
local HALLWAY_CORNER_PROB = 8
local TJUNCT_HALLWAY_PROB = 15

-- Transition probabilities.
local PASSAGE_BRIDGE_TRANSITION_PROB1 = 15 -- Prob bridge may spawn hallways.
local PASSAGE_BRIDGE_TRANSITION_PROB2 = 50 -- Prob hallways may spawn bridges.

-- MISC probabilities.
local TOWER_PROBABILITY = 10
local PLAZA_GATE_PROB = 30
local LARGE_PLAZA_CHANCE = 100
local MEDIUM_PLAZA_CHANCE = 500
local SMALL_PLAZA_CHANCE = 200
local GATEHOUSE_PROB = 10



-- Connectivity table for open-walk bridges.
-- Makes defining these data much more concise.
-- Alterations to this affect all bridge tiles.
local BRIDGE_CONNECT = {
	[DIRNAME.NORTH] = {
		ns_walk_bridge = true,
		ns_walk_bridge_wide = true,
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

		bridge_ns_to_hall_ew = true,
		ew_plaza_s = true,
		ns_gatehouse = true,
	},
	[DIRNAME.SOUTH] = {
		ns_walk_bridge = true,
		ns_walk_bridge_wide = true,
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

		bridge_ns_to_hall_ew = true,
		ew_plaza_n = true,
		ns_gatehouse = true,
	},
	[DIRNAME.EAST] = {
		ew_walk_bridge = true,
		ew_walk_bridge_wide = true,
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

		bridge_ew_to_hall_ns = true,
		ns_plaza_w = true,
		ew_gatehouse = true,
	},
	[DIRNAME.WEST] = {
		ew_walk_bridge = true,
		ew_walk_bridge_wide = true,
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

		bridge_ew_to_hall_ns = true,
		ns_plaza_e = true,
		ew_gatehouse = true,
	},
}

-- Connectivity table for enclosed passages/hallways.
-- These spawn with roof walks on top.
local PASSAGE_CONNECT = {
	[DIRNAME.NORTH] = {
		hallway_straight_ns = true,
		hall_straight_ns_stair = true,
		hall_straight_ns_stair_rev = true,
		hallway_junction = true,
		hallway_s_capped = true,
		hallway_s_capped_no_stair = true,
		hallway_s_capped_no_stair_prob0 = true,

		-- Corners.
		hall_corner_se = true,
		hall_corner_sw = true,

		-- T-junctions.
		hallway_nes_t = true,
		hallway_swn_t = true,
		hallway_esw_t = true,

		-- Transitions to bridges.
		hall_ns_to_bridge_ew = true,
		hall_ns_to_bridge_e = true,
		hall_ns_to_bridge_w = true,

		-- Plaza entrances.
		ns_plaza_e_from_hall = true,
		ns_plaza_w_from_hall = true,
	},
	[DIRNAME.SOUTH] = {
		hallway_straight_ns = true,
		hall_straight_ns_stair = true,
		hall_straight_ns_stair_rev = true,
		hallway_junction = true,
		hallway_n_capped = true,
		hallway_n_capped_no_stair = true,
		hallway_n_capped_no_stair_prob0 = true,

		-- Corners.
		hall_corner_ne = true,
		hall_corner_nw = true,

		-- T-junctions.
		hallway_nes_t = true,
		hallway_wne_t = true,
		hallway_swn_t = true,

		-- Transitions to bridges.
		hall_ns_to_bridge_ew = true,
		hall_ns_to_bridge_e = true,
		hall_ns_to_bridge_w = true,

		-- Plaza entrances.
		ns_plaza_e_from_hall = true,
		ns_plaza_w_from_hall = true,
	},
	[DIRNAME.EAST] = {
		hallway_straight_ew = true,
		hall_straight_ew_stair = true,
		hall_straight_ew_stair_rev = true,
		hallway_junction = true,
		hallway_w_capped = true,
		hallway_w_capped_no_stair = true,
		hallway_w_capped_no_stair_prob0 = true,

		-- Corners.
		hall_corner_nw = true,
		hall_corner_sw = true,

		-- T-junctions.
		hallway_esw_t = true,
		hallway_swn_t = true,
		hallway_wne_t = true,

		-- Transitions to bridges.
		hall_ew_to_bridge_ns = true,
		hall_ew_to_bridge_n = true,
		hall_ew_to_bridge_s = true,

		-- Plaza entrances.
		ew_plaza_n_from_hall = true,
		ew_plaza_s_from_hall = true,
	},
	[DIRNAME.WEST] = {
		hallway_straight_ew = true,
		hall_straight_ew_stair = true,
		hall_straight_ew_stair_rev = true,
		hallway_junction = true,
		hallway_e_capped = true,
		hallway_e_capped_no_stair = true,
		hallway_e_capped_no_stair_prob0 = true,

		-- Corners.
		hall_corner_ne = true,
		hall_corner_se = true,

		-- T-junctions.
		hallway_esw_t = true,
		hallway_nes_t = true,
		hallway_wne_t = true,

		-- Transitions to bridges.
		hall_ew_to_bridge_ns = true,
		hall_ew_to_bridge_n = true,
		hall_ew_to_bridge_s = true,

		-- Plaza entrances.
		ew_plaza_n_from_hall = true,
		ew_plaza_s_from_hall = true,
	},
}



-- Oerkki spawner schem tables.
local BASIC_OERKKI_SPAWNER = {
	file = "nf_detail_spawner1",
	chance = OERKKI_SPAWNER_CHANCE,
	rotation = "random",
	offset = {x=3, y=0, z=3},
	priority = OERKKI_SPAWNER_PRIORITY,
}
local BASIC_OERKKI_SPAWNER_RAISED = {
	file = "nf_detail_spawner1",
	chance = OERKKI_SPAWNER_CHANCE,
	rotation = "random",
	offset = {x=3, y=1, z=3},
	priority = OERKKI_SPAWNER_PRIORITY,
}
local BASIC_ELITE_SPAWNER = {
	file = "elite_spawner",
	chance = ELITE_SPAWNER_CHANCE,
	rotation = "random",
	offset = {x=3, y=0, z=3},
	priority = ELITE_OERKKI_SPAWNER_PRIORITY,
}
local HALLWAY_OERKKI_SPAWNER = {
	file = "nf_detail_spawner1",
	chance = OERKKI_SPAWNER_HALLWAY_CHANCE,
	rotation = "random",
	offset = {x=3, y=3, z=3},
	priority = OERKKI_SPAWNER_PRIORITY,
}
local HALLWAY_ELITE_SPAWNER = {
	file = "elite_spawner",
	chance = ELITE_SPAWNER_HALLWAY_CHANCE,
	rotation = "random",
	offset = {x=3, y=3, z=3},
	priority = ELITE_OERKKI_SPAWNER_PRIORITY,
}



-- Floor lava schem tables.
local BASIC_FLOOR_LAVA = {
	file = "nf_detail_lava1",
	chance = FLOOR_LAVA_CHANCE,
	rotation = "random",
	offset = {x=3, y=0, z=3},
	priority = LAVA_FLOOR_HAZARD_PRIORITY,
}
local BASIC_FLOOR_LAVA_RAISED = {
	file = "nf_detail_lava1",
	chance = FLOOR_LAVA_CHANCE,
	rotation = "random",
	offset = {x=3, y=1, z=3},
	priority = LAVA_FLOOR_HAZARD_PRIORITY,
}
local HALLWAY_FLOOR_LAVA = {
	file = "nf_detail_lava1",
	chance = FLOOR_LAVA_CHANCE,
	rotation = "random",
	offset = {x=3, y=3, z=3},
	priority = LAVA_FLOOR_HAZARD_PRIORITY,
}



local function GET_BRIDGE_STARTER_PIECES()
	return "junction_walk_bridge",
		"ew_walk_bridge_wide",
		"ns_walk_bridge_wide",
		"walk_bridge_nse",
		"walk_bridge_nsw",
		"walk_bridge_nwe",
		"walk_bridge_swe"
end

local function GET_PASSAGE_STARTER_PIECES()
	return "hallway_straight_ns",
		"hallway_straight_ew",
		"hallway_junction",
		"hallway_esw_t",
		"hallway_nes_t",
		"hallway_swn_t",
		"hallway_wne_t"
end

local function GET_TRANSITION_STARTER_PIECES()
	return "hall_ns_to_bridge_ew",
		"hall_ew_to_bridge_ns",
		"bridge_ns_to_hall_ew",
		"bridge_ew_to_hall_ns",
		"hall_ew_to_bridge_n",
		"hall_ew_to_bridge_s",
		"hall_ns_to_bridge_e",
		"hall_ns_to_bridge_w"
end

local function GET_PLAZA_STARTER_PIECES()
	return "large_plaza", "medium_plaza", "small_plaza"
end



-- Large chunk connecting EW hallway to NS bridge.
local function GET_HALL_EW_TO_BRIDGE_NS(probability)
	return {
		schem = {
			{file="nf_ew_passage_ns_bridge_access"},
		},

		-- Size and offset in chunk/tile units.
		-- The presence of 'size' and 'shift' tell the algorithm that this is a
		-- large chunk/tile, which has special code paths to handle the large
		-- size, offset, and footprint.
		size = {x=1, y=1, z=3},

		valid_neighbors = {
			[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.EAST],
			[HASHKEY(-1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.WEST],

			[HASHKEY(0, 1, 1)] = {roof_straight_ew=true},
			[HASHKEY(0, -1, 1)] = {solid_top=true},

			-- Extended neighbors. You can use HASHKEY() here because the keys are all
			-- the same; 'DIRNAME.NORTH' etc. is just a shortcut for easier reading.
			[HASHKEY(0, 0, 3)] = BRIDGE_CONNECT[DIRNAME.NORTH],
			[HASHKEY(0, 0, -1)] = BRIDGE_CONNECT[DIRNAME.SOUTH],
			[HASHKEY(0, -1, 2)] = {bridge_arch_ns=true},
			[HASHKEY(0, -1, 0)] = {bridge_arch_ns=true},
		},

		-- Require these neighboring positions to be EMPTY.
		-- NOTE: this should only be used when you are sure you NEVER want to place
		-- THIS CHUNK if there is ever anything at a particular neighbor position,
		-- for large chunks that span multiple cells/tiles.
		require_empty_neighbors = {
			[HASHKEY(0, 0, 2)] = true,
			[HASHKEY(0, 0, 1)] = true,
			[HASHKEY(0, 0, 0)] = true,

			-- Both sides of southern bridge connector.
			[HASHKEY(-1, 0, 0)] = true,
			[HASHKEY(1, 0, 0)] = true,

			-- Both sides of northern bridge connector.
			[HASHKEY(-1, 0, 2)] = true,
			[HASHKEY(1, 0, 2)] = true,

			-- Both sides of the middle EW hallway.
			[HASHKEY(-1, 0, 1)] = true,
			[HASHKEY(1, 0, 1)] = true,
		},

		-- Defines the chunk/tiles' additional extra footprint.
		-- This is what gets written to the algorithm data structure when a chunk
		-- is confirmed to be placed. Keys are ALWAYS position hashes.
		--
		-- Since this large chunk is just a combination of smaller tiles, each
		-- position can have the name of an existing smaller tile, taking on all
		-- the connective/etc properties of those smaller peices.
		--
		-- If we had internal pieces that should be ignored by the algorithm, we
		-- could use a 'dummy' chunk for those. But this chunk is just 1x1x3,
		-- not big enough for that.
		footprint = {
			[HASHKEY(0, 0, 2)] = "ns_walk_bridge",
			[HASHKEY(0, 0, 1)] = "hallway_straight_ew",
			[HASHKEY(0, 0, 0)] = "ns_walk_bridge",
		},

		probability = probability,
	}
end

-- Large chunk connecting NS hallway to EW bridge.
local function GET_HALL_NS_TO_BRIDGE_EW(probability)
	return {
		schem = {
			{file="nf_ns_passage_ew_bridge_access"},
		},

		-- Size and offset in chunk/tile units.
		-- The presence of 'size' and 'shift' tell the algorithm that this is a
		-- large chunk/tile, which has special code paths to handle the large
		-- size, offset, and footprint.
		size = {x=3, y=1, z=1},

		valid_neighbors = {
			[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
			[HASHKEY(1, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],

			[HASHKEY(1, 1, 0)] = {roof_straight_ns=true},
			[HASHKEY(1, -1, 0)] = {solid_top=true},

			-- Extended neighbors.
			[HASHKEY(3, 0, 0)] = BRIDGE_CONNECT[DIRNAME.EAST],
			[HASHKEY(-1, 0, 0)] = BRIDGE_CONNECT[DIRNAME.WEST],
			[HASHKEY(0, -1, 0)] = {bridge_arch_ew=true},
			[HASHKEY(2, -1, 0)] = {bridge_arch_ew=true},
		},

		-- Require these neighboring positions to be EMPTY.
		require_empty_neighbors = {
			[HASHKEY(2, 0, 0)] = true,
			[HASHKEY(1, 0, 0)] = true,
			[HASHKEY(0, 0, 0)] = true,

			-- Both sides of left-hand bridge connector.
			[HASHKEY(0, 0, 1)] = true,
			[HASHKEY(0, 0, -1)] = true,

			-- Both sides of right-hand bridge connector.
			[HASHKEY(2, 0, 1)] = true,
			[HASHKEY(2, 0, -1)] = true,

			-- Both sides of the middle NS hallway.
			[HASHKEY(1, 0, 1)] = true,
			[HASHKEY(1, 0, -1)] = true,
		},

		-- Defines the chunk/tiles' additional extra footprint.
		-- This is what gets written to the algorithm data structure when a chunk
		-- is confirmed to be placed. Keys are ALWAYS position hashes.
		--
		-- Since this large chunk is just a combination of smaller tiles, each
		-- position can have the name of an existing smaller tile, taking on all
		-- the connective/etc properties of those smaller peices.
		--
		-- If we had internal pieces that should be ignored by the algorithm, we
		-- could use a 'dummy' chunk for those. But this chunk is just 1x1x3,
		-- not big enough for that.
		footprint = {
			[HASHKEY(0, 0, 0)] = "ew_walk_bridge",
			[HASHKEY(1, 0, 0)] = "hallway_straight_ns",
			[HASHKEY(2, 0, 0)] = "ew_walk_bridge",
		},

		probability = probability,
	}
end

local function GET_BASIC_LOOT_POSITIONS()
	return {
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=RARE_LOOT_CHANCE, loot="rare"},
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=RARE_LOOT_CHANCE, loot="rare"},
		{pos={x_min=1, x_max=9, y=4, z_min=1, z_max=9},
			chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
	}
end

local function GET_BRIDGEWALK_LOOT_POSITIONS()
	return {
		{pos={x_min=1, x_max=9, y=1, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=1, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=1, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=1, z_min=1, z_max=9},
			chance=COMMON_LOOT_CHANCE, loot="common"},
		{pos={x_min=1, x_max=9, y=1, z_min=1, z_max=9},
			chance=RARE_LOOT_CHANCE, loot="rare"},
		{pos={x_min=1, x_max=9, y=1, z_min=1, z_max=9},
			chance=RARE_LOOT_CHANCE, loot="rare"},
	}
end



local TJUNC_BLIST = {
	walk_bridge_nse = true,
	walk_bridge_nsw = true,
	walk_bridge_nwe = true,
	walk_bridge_swe = true,
}



local function exclude(set, unwanted)
	local t = {}
	for k, v in pairs(set) do
		if not unwanted[k] then
			t[k] = v
		end
	end
	return t
end



fortress.v2.fortress_data = {
	-- The initial chunk/tile placed by the generator algorithm.
	initial_chunks = {
		GET_BRIDGE_STARTER_PIECES(),
		GET_PASSAGE_STARTER_PIECES(),
		GET_TRANSITION_STARTER_PIECES(),
		GET_PLAZA_STARTER_PIECES(),
		"ew_gatehouse",
		"ns_gatehouse",
		GET_BRIDGE_STARTER_PIECES(), -- Duplicated for probability.
	},

	-- Size of cells/tiles, in worldspace units.
	step = {x=11, y=11, z=11},

	-- Maximum fortress extent, in chunk/tile units.
	-- The min extents are simply computed as the inverse.
	-- A random size is selected on gen init time, based on probability weight.
	max_extents = {
		{x=24, y=8, z=24, weight=5}, -- Huge, should be rare.
		{x=20, y=8, z=20, weight=10},
		{x=16, y=8, z=16, weight=15},

		-- Most common sizes.
		{x=12, y=8, z=12, weight=100},
		{x=10, y=8, z=10, weight=150},

		{x=8, y=8, z=8, weight=25},
		{x=6, y=8, z=6, weight=10},
	},

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
		air = {probability=0, fallback=true},

		-- Use this when you want air to have weight in probabilities.
		air_option = {
			fallback = true,
			footprint = {[HASHKEY(0, 0, 0)] = "air"},
		},

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
				-- Junction connects to everything except itself.
				[DIRNAME.NORTH] = exclude(BRIDGE_CONNECT[DIRNAME.NORTH],
					{junction_walk_bridge=true}),
				[DIRNAME.SOUTH] = exclude(BRIDGE_CONNECT[DIRNAME.SOUTH],
					{junction_walk_bridge=true}),
				[DIRNAME.EAST] = exclude(BRIDGE_CONNECT[DIRNAME.EAST],
					{junction_walk_bridge=true}),
				[DIRNAME.WEST] = exclude(BRIDGE_CONNECT[DIRNAME.WEST],
					{junction_walk_bridge=true}),

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
				[DIRNAME.EAST] = BRIDGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.WEST] = BRIDGE_CONNECT[DIRNAME.WEST],
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
				[DIRNAME.NORTH] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.UP] = {air=true},
				[DIRNAME.DOWN] = {bridge_arch_ns=true},
			},
			probability = STRAIGHT_BRIDGE_PROB,
		},

		-- An east-west bridge walkway peice.
		-- The WIDE version should be used everywhere the narrow version isn't.
		-- This version places air neighbors on each side to prevent crowding.
		ew_walk_bridge_wide = {
			schem = {
				{file="nf_walkway_ew", force=false},
				{file="bridge_house_ew", chance=10, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.EAST] = BRIDGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.WEST] = BRIDGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.UP] = {air=true},
				[DIRNAME.DOWN] = {bridge_arch_ew=true},
				[DIRNAME.NORTH] = {air=true},
				[DIRNAME.SOUTH] = {air=true},
			},

			-- This is what you want in order to adjust chunk probability.
			probability = STRAIGHT_BRIDGE_WIDE_PROB,
		},

		-- A north-south bridge walkway peice.
		-- The WIDE version should be used everywhere the narrow version isn't.
		-- This version places air neighbors on each side to prevent crowding.
		ns_walk_bridge_wide = {
			schem = {
				{file="nf_walkway_ns", force=false},
				{file="bridge_house_ns", chance=10, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.UP] = {air=true},
				[DIRNAME.DOWN] = {bridge_arch_ns=true},
				[DIRNAME.EAST] = {air=true},
				[DIRNAME.WEST] = {air=true},
			},
			probability = STRAIGHT_BRIDGE_WIDE_PROB,
		},

		bridge_pillar_top = {
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_mid=true},
			},
			fallback = true,
		},

		bridge_pillar_mid = {
			-- The bridge pillar schem is 2 units high.
			schem = {{file="nf_center_pillar_top"}},
			valid_neighbors = {
				[DIRNAME.DOWN] = {bridge_pillar_bottom=true},
			},
			fallback = true,
		},

		bridge_pillar_bottom = {
			schem = {
				{file="nf_center_pillar_bottom", offset={x=1, y=-11, z=1}},
			},
			fallback = true,
		},

		bridge_arch_ns = {
			schem = {
				{file="nf_bridge_arch_ns", force=false, offset={x=0, y=6, z=0}},

				-- NOTE: You can use 'priority' to specify when in relation to other
				-- schems this schem should be written. This is useful for schems that
				-- overlap each other, if you want one to always be written last.
				{file="bridge_pit", chance=5, offset={x=3, y=8, z=3},
					priority=BRIDGE_OPEN_PIT_PRIORITY},
			},
		},

		bridge_arch_ew = {
			schem = {
				{file="nf_bridge_arch_ew", force=false, offset={x=0, y=6, z=0}},

				-- Note the use of 'priority' to ensure this schem is written last.
				{file="bridge_pit", chance=5, offset={x=3, y=8, z=3},
					priority=BRIDGE_OPEN_PIT_PRIORITY},
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
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),

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
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
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
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
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
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
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
				[DIRNAME.NORTH] = exclude(BRIDGE_CONNECT[DIRNAME.NORTH], TJUNC_BLIST),
				[DIRNAME.SOUTH] = exclude(BRIDGE_CONNECT[DIRNAME.SOUTH], TJUNC_BLIST),
				[DIRNAME.EAST] = exclude(BRIDGE_CONNECT[DIRNAME.EAST], TJUNC_BLIST),
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
				[DIRNAME.NORTH] = exclude(BRIDGE_CONNECT[DIRNAME.NORTH], TJUNC_BLIST),
				[DIRNAME.SOUTH] = exclude(BRIDGE_CONNECT[DIRNAME.SOUTH], TJUNC_BLIST),
				[DIRNAME.WEST] = exclude(BRIDGE_CONNECT[DIRNAME.WEST], TJUNC_BLIST),
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
				[DIRNAME.EAST] = exclude(BRIDGE_CONNECT[DIRNAME.EAST], TJUNC_BLIST),
				[DIRNAME.SOUTH] = exclude(BRIDGE_CONNECT[DIRNAME.SOUTH], TJUNC_BLIST),
				[DIRNAME.WEST] = exclude(BRIDGE_CONNECT[DIRNAME.WEST], TJUNC_BLIST),
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
				[DIRNAME.WEST] = exclude(BRIDGE_CONNECT[DIRNAME.WEST], TJUNC_BLIST),
				[DIRNAME.EAST] = exclude(BRIDGE_CONNECT[DIRNAME.EAST], TJUNC_BLIST),
				[DIRNAME.NORTH] = exclude(BRIDGE_CONNECT[DIRNAME.NORTH], TJUNC_BLIST),
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
				[DIRNAME.NORTH] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.EAST] = BRIDGE_CONNECT[DIRNAME.EAST],
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
				[DIRNAME.NORTH] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.WEST] = BRIDGE_CONNECT[DIRNAME.WEST],
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
				[DIRNAME.SOUTH] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.WEST] = BRIDGE_CONNECT[DIRNAME.WEST],
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
				[DIRNAME.SOUTH] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.EAST] = BRIDGE_CONNECT[DIRNAME.EAST],
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
			fallback = true,
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
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
			fallback = true,
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
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
			fallback = true,
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
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
			fallback = true,
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
		},

		-- Straight hallway/covered-passage peices.
		hallway_straight_ns = {
			schem = {
				{file="nf_passage_ns"},

				-- TODO: These need to be part of a special bridge-connecting chunk,
				-- otherwise the probabilities will get merged together!
				-- Stairways to lower bridge causeways.
				-- Priority needed to ensure they overwrite the bridge walls.
				--[[
				{file="ns_hall_end_stair_n", priority=100, force=false,
					offset={x=2, y=1, z=11}},
				{file="ns_hall_end_stair_s", priority=100, force=false,
					offset={x=2, y=1, z=-3}},
				--]]

				-- Hazard/spawner detailing.
				HALLWAY_FLOOR_LAVA,
				HALLWAY_OERKKI_SPAWNER,

				-- Room detailing.
				{file="nf_detail_room1", chance=PASSAGE_DETAIL_CHANCE, rotation="90",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_room2", chance=PASSAGE_DETAIL_CHANCE, rotation="90",
					offset={x=3, y=4, z=3}},
				{file="nf_detail_room3", chance=PASSAGE_DETAIL_CHANCE, force=false,
					offset={x=3, y=4, z=0}},

				-- Outside window decorations.
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_straight_ns=true},
			},
			probability = STRAIGHT_HALLWAY_PROB,
			chests = {
				{pos={x=3, y=4, z_min=0, z_max=10},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=7, y=4, z_min=0, z_max=10},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=0, z_max=10},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=0, z_max=10},
					chance=RARE_LOOT_CHANCE, loot="rare"},
			},
		},

		hallway_straight_ew = {
			schem = {
				{file="nf_passage_ew"},

				-- TODO: These need to be part of a special bridge-connecting chunk,
				-- otherwise the probabilities will get merged together!
				-- Stairways to lower bridge causeways.
				-- Priority needed to ensure they overwrite the bridge walls.
				--[[
				{file="ew_hall_end_stair_e", priority=100, force=false,
					offset={x=11, y=1, z=2}},
				{file="ew_hall_end_stair_w", priority=100, force=false,
					offset={x=-3, y=1, z=2}},
				--]]

				-- Hazard/spawner detailing.
				HALLWAY_FLOOR_LAVA,
				HALLWAY_OERKKI_SPAWNER,

				-- Room detailing.
				{file="nf_detail_room1", chance=PASSAGE_DETAIL_CHANCE,
					offset={x=3, y=3, z=3}},
				{file="nf_detail_room2", chance=PASSAGE_DETAIL_CHANCE,
					offset={x=3, y=4, z=3}},
				{file="nf_detail_room3", chance=PASSAGE_DETAIL_CHANCE, rotation="90",
					force=false, offset={x=0, y=4, z=3}},

				-- Outside window decorations.
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_straight_ew=true},
			},
			chests = {
				{pos={x_min=0, x_max=10, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=0, x_max=10, y=4, z=7},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=0, x_max=10, y=4, z=3},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x_min=0, x_max=10, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
			},
			probability = STRAIGHT_HALLWAY_PROB,
		},

		solid_top = {
			schem = {{file="nf_building_solid"}},
			valid_neighbors = {[DIRNAME.DOWN]={solid_middle=true}},
			fallback = true,
		},

		solid_middle = {
			schem = {{file="nf_building_solid"}},
			valid_neighbors = {[DIRNAME.DOWN]={solid_bottom=true}},
			fallback = true,
		},

		solid_bottom = {
			schem = {{file="nf_building_solid"}},
			fallback = true,
		},

		-- Four-direction hallway covered passage.
		hallway_junction = {
			schem = {
				{file="nf_passage_4x_junction"},
				-- Hallway end caps. TODO: Don't need these?
				--[[
				{file="ew_hall_end_e", force=false, offset={x=11, y=3, z=2}},
				{file="ew_hall_end_w", force=false, offset={x=-3, y=3, z=2}},
				{file="ns_hall_end_n", force=false, offset={x=2, y=3, z=11}},
				{file="ns_hall_end_s", force=false, offset={x=2, y=3, z=-3}},
				--]]

				HALLWAY_FLOOR_LAVA, HALLWAY_OERKKI_SPAWNER,
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_junction=true},
			},
			probability = JUNCTION_HALLWAY_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		-- Hallway end caps.
		hallway_n_capped = {
			schem = {
				{file="nf_passage_n_capped"},
				{file="hall_end_stair", rotation="180", chance=20,
					priority=PASSAGE_TO_ROOF_STAIR_PRIORITY,
						offset={x=4, y=4, z=5}, exclude={nf_passage_door=true}},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CAP_DOORWAY_PROB, offset={x=3, y=4, z=8}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_n=true},
			},
			probability = HALLWAY_CAP_PROB,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=3, z_max=10},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=10},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_s_capped = {
			schem = {
				{file="nf_passage_s_capped"},
				{file="hall_end_stair", rotation="0", chance=20,
					priority=PASSAGE_TO_ROOF_STAIR_PRIORITY,
						offset={x=4, y=4, z=-2}, exclude={nf_passage_door=true}},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CAP_DOORWAY_PROB, offset={x=3, y=4, z=0}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_s=true},
			},
			probability = HALLWAY_CAP_PROB,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=7},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=0, z_max=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=0, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_e_capped = {
			schem = {
				{file="nf_passage_e_capped"},
				{file="hall_end_stair", rotation="270", chance=20,
					priority=PASSAGE_TO_ROOF_STAIR_PRIORITY,
						offset={x=5, y=4, z=4}, exclude={nf_passage_door=true}},
				{file="nf_passage_door", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_e=true},
			},
			probability = HALLWAY_CAP_PROB,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=10, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=3, x_max=10, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=3, y=4, z_min=3, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_w_capped = {
			schem = {
				{file="nf_passage_w_capped"},
				{file="hall_end_stair", rotation="90", chance=20,
					priority=PASSAGE_TO_ROOF_STAIR_PRIORITY,
						offset={x=-2, y=4, z=4}, exclude={nf_passage_door=true}},
				{file="nf_passage_door", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_w=true},
			},
			probability = HALLWAY_CAP_PROB,
			fallback = true,
			chests = {
				{pos={x_min=0, x_max=7, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=0, x_max=7, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		-- Hallway caps which exclude the stairs.
		-- These are used as a last-ditch fallback (very low probability).
		hallway_n_capped_no_stair = {
			schem = {
				{file="nf_passage_n_capped"},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CAP_DOORWAY_PROB, offset={x=3, y=4, z=8}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_n=true},
			},
			probability = HALLWAY_CAP_NO_STAIR_PROB,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=3, z_max=10},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=10},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_s_capped_no_stair = {
			schem = {
				{file="nf_passage_s_capped"},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CAP_DOORWAY_PROB, offset={x=3, y=4, z=0}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_s=true},
			},
			probability = HALLWAY_CAP_NO_STAIR_PROB,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=7},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=0, z_max=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=0, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_e_capped_no_stair = {
			schem = {
				{file="nf_passage_e_capped"},
				{file="nf_passage_door", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_e=true},
			},
			probability = HALLWAY_CAP_NO_STAIR_PROB,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=10, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=3, x_max=10, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=3, y=4, z_min=3, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_w_capped_no_stair = {
			schem = {
				{file="nf_passage_w_capped"},
				{file="nf_passage_door", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_w=true},
			},
			probability = HALLWAY_CAP_NO_STAIR_PROB,
			fallback = true,
			chests = {
				{pos={x_min=0, x_max=7, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=0, x_max=7, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		-- Probability ZERO hall caps. To be used only by the most desperate.
		hallway_n_capped_no_stair_prob0 = {
			schem = {
				{file="nf_passage_n_capped"},
				{file="nf_passage_door", rotation="90", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=3, y=4, z=8}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_n=true},
			},
			probability = 0,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=3, z_max=10},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=10},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_s_capped_no_stair_prob0 = {
			schem = {
				{file="nf_passage_s_capped"},
				{file="nf_passage_door", rotation="90", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=3, y=4, z=0}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_s=true},
			},
			probability = 0,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=7},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x=3, y=4, z_min=0, z_max=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=0, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_e_capped_no_stair_prob0 = {
			schem = {
				{file="nf_passage_e_capped"},
				{file="nf_passage_door", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_e=true},
			},
			probability = 0,
			fallback = true,
			chests = {
				{pos={x_min=3, x_max=10, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=3, x_max=10, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=3, y=4, z_min=3, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		hallway_w_capped_no_stair_prob0 = {
			schem = {
				{file="nf_passage_w_capped"},
				{file="nf_passage_door", chance=HALLWAY_CAP_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_ELITE_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=80, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_capped_w=true},
			},
			probability = 0,
			fallback = true,
			chests = {
				{pos={x_min=0, x_max=7, y=4, z=3},
					chance=COMMON_LOOT_CHANCE, loot="common"},
				{pos={x_min=0, x_max=7, y=4, z=7},
					chance=RARE_LOOT_CHANCE, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=7},
					chance=EXCEPTIONAL_LOOT_CHANCE, loot="exceptional"},
			},
		},

		-- Hallway/passage corners.
		hall_corner_ne = {
			schem = {
				{file="nf_passage_ne_corner"},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CORNER_DOORWAY_PROB, offset={x=3, y=4, z=8}},
				{file="nf_passage_door", chance=HALLWAY_CORNER_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_corner_ne=true},
			},
			probability = HALLWAY_CORNER_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_corner_nw = {
			schem = {
				{file="nf_passage_nw_corner"},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CORNER_DOORWAY_PROB, offset={x=3, y=4, z=8}},
				{file="nf_passage_door", chance=HALLWAY_CORNER_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_corner_nw=true},
			},
			probability = HALLWAY_CORNER_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_corner_se = {
			schem = {
				{file="nf_passage_se_corner"},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CORNER_DOORWAY_PROB, offset={x=3, y=4, z=0}},
				{file="nf_passage_door", chance=HALLWAY_CORNER_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_corner_se=true},
			},
			probability = HALLWAY_CORNER_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_corner_sw = {
			schem = {
				{file="nf_passage_sw_corner"},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_CORNER_DOORWAY_PROB, offset={x=3, y=4, z=0}},
				{file="nf_passage_door", chance=HALLWAY_CORNER_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,
			},
			valid_neighbors = {
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_corner_sw=true},
			},
			probability = HALLWAY_CORNER_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hallway_esw_t = {
			schem = {
				{file="nf_passage_esw_t"},

				-- Doorways.
				{file="nf_passage_door", chance=HALLWAY_TJUNC_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_TJUNC_DOORWAY_PROB, offset={x=3, y=4, z=0}},
				{file="nf_passage_door", chance=HALLWAY_TJUNC_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=50, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_t_esw=true},
			},
			probability = TJUNCT_HALLWAY_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hallway_nes_t = {
			schem = {
				{file="nf_passage_nes_t"},

				-- Doorways.
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_TJUNC_DOORWAY_PROB, offset={x=3, y=4, z=8}},
				{file="nf_passage_door", chance=HALLWAY_TJUNC_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_TJUNC_DOORWAY_PROB, offset={x=3, y=4, z=0}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=50, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_t_nes=true},
			},
			probability = TJUNCT_HALLWAY_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hallway_swn_t = {
			schem = {
				{file="nf_passage_swn_t"},

				-- Doorways.
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_TJUNC_DOORWAY_PROB, offset={x=3, y=4, z=0}},
				{file="nf_passage_door", chance=HALLWAY_TJUNC_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_TJUNC_DOORWAY_PROB, offset={x=3, y=4, z=8}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=50, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.SOUTH] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_t_swn=true},
			},
			probability = TJUNCT_HALLWAY_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hallway_wne_t = {
			schem = {
				{file="nf_passage_wne_t"},

				-- Doorways.
				{file="nf_passage_door", chance=HALLWAY_TJUNC_DOORWAY_PROB,
					offset={x=0, y=4, z=3}},
				{file="nf_passage_door", rotation="90",
					chance=HALLWAY_TJUNC_DOORWAY_PROB, offset={x=3, y=4, z=8}},
				{file="nf_passage_door", chance=HALLWAY_TJUNC_DOORWAY_PROB,
					offset={x=8, y=4, z=3}},

				HALLWAY_OERKKI_SPAWNER, HALLWAY_FLOOR_LAVA,

				-- Outside window decorations.
				{file="fortress_window_deco", chance=50, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.WEST] = PASSAGE_CONNECT[DIRNAME.WEST],
				[DIRNAME.EAST] = PASSAGE_CONNECT[DIRNAME.EAST],
				[DIRNAME.NORTH] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {roof_t_wne=true},
			},
			probability = TJUNCT_HALLWAY_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		-- Passageway roof pieces.
		roof_junction = {schem = {{file="nf_walkway_4x_junction", force=false}}},
		roof_corner_ne = {schem = {{file="nf_walkway_ne_corner", force=false}}},
		roof_corner_nw = {schem = {{file="nf_walkway_nw_corner", force=false}}},
		roof_corner_sw = {schem = {{file="nf_walkway_sw_corner", force=false}}},
		roof_corner_se = {schem = {{file="nf_walkway_se_corner", force=false}}},
		roof_t_esw = {schem = {{file="nf_walkway_esw_t", force=false}}},
		roof_t_nes = {schem = {{file="nf_walkway_nes_t", force=false}}},
		roof_t_swn = {schem = {{file="nf_walkway_swn_t", force=false}}},
		roof_t_wne = {schem = {{file="nf_walkway_wne_t", force=false}}},

		roof_straight_ew = {
			schem = {
				{file="nf_walkway_ew", force=false},
				{file="bridge_house_ew", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_ELITE_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				-- Air is included in the list so that the roof tower probability can
				-- have something to compete with, so we don't create towers everywhere.
				[DIRNAME.UP] = {roof_tower=true, air_option=true},
			},
		},

		roof_straight_ns = {
			schem = {
				{file="nf_walkway_ns", force=false},
				{file="bridge_house_ns", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_ELITE_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				-- Air is included in the list so that the roof tower probability can
				-- have something to compete with, so we don't create towers everywhere.
				[DIRNAME.UP] = {roof_tower=true, air_option=true},
			},
		},

		roof_capped_n = {
			schem = {
				{file="nf_walkway_n_capped", force=false},
				{file="bridge_house_n", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_ELITE_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				-- Air is included in the list so that the roof tower probability can
				-- have something to compete with, so we don't create towers everywhere.
				[DIRNAME.UP] = {roof_tower=true, air_option=true},
			},
			fallback = true, -- Allow use at extents edge.
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
		},

		roof_capped_s = {
			schem = {
				{file="nf_walkway_s_capped", force=false},
				{file="bridge_house_s", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_ELITE_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				-- Air is included in the list so that the roof tower probability can
				-- have something to compete with, so we don't create towers everywhere.
				[DIRNAME.UP] = {roof_tower=true, air_option=true},
			},
			fallback = true, -- Allow use at extents edge.
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
		},

		roof_capped_e = {
			schem = {
				{file="nf_walkway_e_capped", force=false},
				{file="bridge_house_e", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_ELITE_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				-- Air is included in the list so that the roof tower probability can
				-- have something to compete with, so we don't create towers everywhere.
				[DIRNAME.UP] = {roof_tower=true, air_option=true},
			},
			fallback = true, -- Allow use at extents edge.
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
		},

		roof_capped_w = {
			schem = {
				{file="nf_walkway_w_capped", force=false},
				{file="bridge_house_w", chance=15, offset={x=0, y=3, z=0}},
				BASIC_OERKKI_SPAWNER, BASIC_ELITE_SPAWNER, BASIC_FLOOR_LAVA,
			},
			valid_neighbors = {
				-- Air is included in the list so that the roof tower probability can
				-- have something to compete with, so we don't create towers everywhere.
				[DIRNAME.UP] = {roof_tower=true, air_option=true},
			},
			fallback = true, -- Allow use at extents edge.
			chests = GET_BRIDGEWALK_LOOT_POSITIONS(),
		},

		-- Roof tower.
		tower_top = {},
		roof_tower = {
			schem = {
				{file="nf_tower", force=false, priority=TOWER_PRIORITY,
					offset={x=3, y=-10, z=3}},

				-- A nasty surprise.
				{
					file = "fort_elitespawner_small",
					chance = 20,
					rotation = "random",
					offset = {x=4, y=1, z=4},
					priority = TOWER_PRIORITY + 1, -- Place after tower.
				},
			},
			size = {x=1, y=2, z=1}, -- Try to keep tops being cut off.
			valid_neighbors = {
				[DIRNAME.UP] = {tower_top=true},
			},
			probability = TOWER_PROBABILITY,
			fallback = true,
		},

		-- EW passageway with NS bridge connectors.
		-- Two of these so we can give them distinct probabilities.
		bridge_ns_to_hall_ew =
			GET_HALL_EW_TO_BRIDGE_NS(PASSAGE_BRIDGE_TRANSITION_PROB1),
		hall_ew_to_bridge_ns =
			GET_HALL_EW_TO_BRIDGE_NS(PASSAGE_BRIDGE_TRANSITION_PROB2),

		-- NS passageway with EW bridge connectors.
		-- Two of these so we can give them distinct probabilities.
		bridge_ew_to_hall_ns =
			GET_HALL_NS_TO_BRIDGE_EW(PASSAGE_BRIDGE_TRANSITION_PROB1),
		hall_ns_to_bridge_ew =
			GET_HALL_NS_TO_BRIDGE_EW(PASSAGE_BRIDGE_TRANSITION_PROB2),

		-- The big 3x3 plaza object.
		large_plaza_dummy = {},
		large_plaza = {
			schem = {
				{file="nf_building_solid", force=false, offset={x=0, y=-7, z=0}},
				{file="nf_building_solid", force=false, offset={x=11, y=-7, z=0}},
				{file="nf_building_solid", force=false, offset={x=22, y=-7, z=0}},
				{file="nf_building_solid", force=false, offset={x=0, y=-7, z=11}},
				{file="nf_building_solid", force=false, offset={x=11, y=-7, z=11}},
				{file="nf_building_solid", force=false, offset={x=22, y=-7, z=11}},
				{file="nf_building_solid", force=false, offset={x=0, y=-7, z=22}},
				{file="nf_building_solid", force=false, offset={x=11, y=-7, z=22}},
				{file="nf_building_solid", force=false, offset={x=22, y=-7, z=22}},
				{file="fortress_well_water", chance=40,	offset={x=10, y=3, z=10}},
				{file="fortress_well_lava", chance=20, offset={x=10, y=3, z=10}},
			},
			size = {x=3, y=1, z=3},
			valid_neighbors = {
				-- Basement.
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(1, -1, 0)] = {solid_top=true},
				[HASHKEY(2, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 1)] = {solid_top=true},
				[HASHKEY(1, -1, 1)] = {solid_top=true},
				[HASHKEY(2, -1, 1)] = {solid_top=true},
				[HASHKEY(0, -1, 2)] = {solid_top=true},
				[HASHKEY(1, -1, 2)] = {solid_top=true},
				[HASHKEY(2, -1, 2)] = {solid_top=true},

				-- Edge centers.
				---[[
				-- West side.
				[HASHKEY(-1, 0, 1)] = {
					hallway_straight_ns = true,
					hallway_swn_t = true,
					ns_plaza_w = true,
					hallway_e_capped_no_stair = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
				},
				-- East side.
				[HASHKEY(3, 0, 1)] = {
					hallway_straight_ns = true,
					hallway_nes_t = true,
					ns_plaza_e = true,
					hallway_w_capped_no_stair = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
				},
				-- South side.
				[HASHKEY(1, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_esw_t = true,
					ew_plaza_s = true,
					hallway_n_capped_no_stair = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				-- North side.
				[HASHKEY(1, 0, 3)] = {
					hallway_straight_ew = true,
					hallway_wne_t = true,
					ew_plaza_n = true,
					hallway_s_capped_no_stair = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				--]]

				-- Require both sides of all four possible entrances to be hallways.
				-- Both sides of south entrance.
				---[[
				[HASHKEY(0, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_n_capped_no_stair_prob0 = true,
				},
				[HASHKEY(2, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				-- Both sides of north entrance.
				[HASHKEY(0, 0, 3)] = {
					hallway_straight_ew = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				[HASHKEY(2, 0, 3)] = {
					hallway_straight_ew = true,
					hallway_w_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
				},
				-- Both sides of west entrance.
				[HASHKEY(-1, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				[HASHKEY(-1, 0, 2)] = {
					hallway_straight_ns = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				-- Both sides of east entrance.
				[HASHKEY(3, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				[HASHKEY(3, 0, 2)] = {
					hallway_straight_ns = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				--]]

				-- Now the corners.
				---[[
				-- Southwest corner.
				[HASHKEY(-1, 0, -1)] = {
					hall_corner_ne = true,
					hallway_e_capped_no_stair = true,
					hallway_n_capped_no_stair = true,
					hallway_junction = true,
					hallway_wne_t = true,
					hallway_nes_t = true,
				},
				-- Northwest corner.
				[HASHKEY(-1, 0, 3)] = {
					hall_corner_se = true,
					hallway_s_capped_no_stair = true,
					hallway_e_capped_no_stair = true,
					hallway_junction = true,
					hallway_esw_t = true,
					hallway_nes_t = true,
				},
				-- Northeast corner.
				[HASHKEY(3, 0, 3)] = {
					hall_corner_sw = true,
					hallway_s_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_esw_t = true,
				},
				-- Southeast corner.
				[HASHKEY(3, 0, -1)] = {
					hall_corner_nw = true,
					hallway_n_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_wne_t = true,
				},
				--]]
			},
			-- Prevent us from overwriting anyone else.
			require_empty_neighbors = {
				-- Footprint must be empty.
				[HASHKEY(0, 0, 0)] = true,
				[HASHKEY(1, 0, 0)] = true,
				[HASHKEY(2, 0, 0)] = true,
				[HASHKEY(0, 0, 1)] = true,
				[HASHKEY(1, 0, 1)] = true,
				[HASHKEY(2, 0, 1)] = true,
				[HASHKEY(0, 0, 2)] = true,
				[HASHKEY(1, 0, 2)] = true,
				[HASHKEY(2, 0, 2)] = true,
			},
			-- Prevent algorithm from coming back and overwriting us.
			footprint = {
				[HASHKEY(0, 0, 0)] = "large_plaza_dummy",
				[HASHKEY(1, 0, 0)] = "large_plaza_dummy",
				[HASHKEY(2, 0, 0)] = "large_plaza_dummy",
				[HASHKEY(0, 0, 1)] = "large_plaza_dummy",
				[HASHKEY(1, 0, 1)] = "large_plaza_dummy",
				[HASHKEY(2, 0, 1)] = "large_plaza_dummy",
				[HASHKEY(0, 0, 2)] = "large_plaza_dummy",
				[HASHKEY(1, 0, 2)] = "large_plaza_dummy",
				[HASHKEY(2, 0, 2)] = "large_plaza_dummy",
			},
			probability = LARGE_PLAZA_CHANCE,
		},

		-- Plaza exits/entrances.
		-- Bridgewalk faces east, plaza is west of us.
		ns_plaza_e = {
			schem = {
				{file="ns_bridge_passage_e"},
				{file="plaza_door_ew", offset={x=0, y=4, z=3}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=3}},
			},
			size = {x=2, y=1, z=1},
			valid_neighbors = {
				[HASHKEY(-1, 0, 0)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_e_capped = true,
				},
				[HASHKEY(0, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(0, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(2, 0, 0)] = BRIDGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(0, 1, 0)] = {roof_straight_ns=true},
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(1, -1, 0)] = {bridge_arch_ew=true},
			},
			footprint = {
				[HASHKEY(1, 0, 0)] = "ew_walk_bridge",
				[HASHKEY(0, 0, 0)] = "hallway_straight_ns",
			},
			require_empty_neighbors = {
				-- Require both sides of the east-facing bridge to be empty.
				[HASHKEY(1, 0, 1)] = true,
				[HASHKEY(1, 0, -1)] = true,

				-- Both sides of the NS hallway.
				[HASHKEY(0, 0, 1)] = true,
				[HASHKEY(0, 0, -1)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Bridgewalk faces west, plaza is east of us.
		ns_plaza_w = {
			schem = {
				{file="ns_bridge_passage_w"},
				{file="plaza_door_ew", offset={x=19, y=4, z=3}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=14, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=14, y=3, z=3}},
			},
			size = {x=2, y=1, z=1},
			valid_neighbors = {
				[HASHKEY(2, 0, 0)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_w_capped = true,
				},
				[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(-1, 0, 0)] = BRIDGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(1, 1, 0)] = {roof_straight_ns=true},
				[HASHKEY(1, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 0)] = {bridge_arch_ew=true},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ew_walk_bridge",
				[HASHKEY(1, 0, 0)] = "hallway_straight_ns",
			},
			require_empty_neighbors = {
				-- Require both sides of the west-facing bridge to be empty.
				[HASHKEY(0, 0, 1)] = true,
				[HASHKEY(0, 0, -1)] = true,

				-- Both sides of the NS hallway.
				[HASHKEY(1, 0, 1)] = true,
				[HASHKEY(1, 0, -1)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Bridgewalk faces north, plaza will be south of us.
		ew_plaza_n = {
			schem = {
				{file="ew_bridge_passage_n"},
				{file="plaza_door_ns", offset={x=3, y=4, z=0}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=3}},
			},
			size = {x=1, y=1, z=2},
			valid_neighbors = {
				[HASHKEY(0, 0, -1)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_n_capped = true,
				},
				[HASHKEY(0, 0, 2)] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, 0)] = PASSAGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(-1, 0, 0)] = PASSAGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(0, 1, 0)] = {roof_straight_ew=true},
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 1)] = {bridge_arch_ns=true},
			},
			footprint = {
				[HASHKEY(0, 0, 1)] = "ns_walk_bridge",
				[HASHKEY(0, 0, 0)] = "hallway_straight_ew",
			},
			require_empty_neighbors = {
				-- Require both sides of the north-facing bridge to be empty.
				[HASHKEY(-1, 0, 1)] = true,
				[HASHKEY(1, 0, 1)] = true,

				-- Both sides of the EW hallway.
				[HASHKEY(-1, 0, 0)] = true,
				[HASHKEY(1, 0, 0)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Bridgewalk faces south, plaza will be north of us.
		ew_plaza_s = {
			schem = {
				{file="ew_bridge_passage_s"},
				{file="plaza_door_ns", offset={x=3, y=4, z=19}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=14}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=14}},
			},
			size = {x=1, y=1, z=2},
			valid_neighbors = {
				[HASHKEY(0, 0, 2)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_s_capped = true,
				},
				[HASHKEY(0, 0, -1)] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(-1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(0, 1, 1)] = {roof_straight_ew=true},
				[HASHKEY(0, -1, 1)] = {solid_top=true},
				[HASHKEY(0, -1, 0)] = {bridge_arch_ns=true},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ns_walk_bridge",
				[HASHKEY(0, 0, 1)] = "hallway_straight_ew",
			},
			require_empty_neighbors = {
				-- Require both sides of the south-facing bridge to be empty.
				[HASHKEY(-1, 0, 0)] = true,
				[HASHKEY(1, 0, 0)] = true,

				-- Both sides of the EW hallway must be empty.
				[HASHKEY(-1, 0, 1)] = true,
				[HASHKEY(1, 0, 1)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Hallway/bridge access.
		hall_ns_to_bridge_e = {
			schem = {
				{file="ns_bridge_passage_e"},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=3}},
			},
			size = {x=2, y=1, z=1},
			valid_neighbors = {
				[HASHKEY(0, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(0, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(2, 0, 0)] = BRIDGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(0, 1, 0)] = {roof_straight_ns=true},
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(1, -1, 0)] = {bridge_arch_ew=true},
			},
			footprint = {
				[HASHKEY(1, 0, 0)] = "ew_walk_bridge",
				[HASHKEY(0, 0, 0)] = "hallway_straight_ns",
			},
			-- Require both sides of the east-facing bridge to be empty.
			require_empty_neighbors = {
				[HASHKEY(1, 0, 1)] = true,
				[HASHKEY(1, 0, -1)] = true,
			},
			-- Probability that hallways may spawn bridge accesses.
			probability = PASSAGE_BRIDGE_TRANSITION_PROB2,
		},

		hall_ns_to_bridge_w = {
			schem = {
				{file="ns_bridge_passage_w"},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=14, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=14, y=3, z=3}},
			},
			size = {x=2, y=1, z=1},
			valid_neighbors = {
				[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(-1, 0, 0)] = BRIDGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(1, 1, 0)] = {roof_straight_ns=true},
				[HASHKEY(1, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 0)] = {bridge_arch_ew=true},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ew_walk_bridge",
				[HASHKEY(1, 0, 0)] = "hallway_straight_ns",
			},
			-- Require both sides of the west-facing bridge to be empty.
			require_empty_neighbors = {
				[HASHKEY(0, 0, 1)] = true,
				[HASHKEY(0, 0, -1)] = true,
			},
			-- Probability that hallways may spawn bridge accesses.
			probability = PASSAGE_BRIDGE_TRANSITION_PROB2,
		},

		hall_ew_to_bridge_n = {
			schem = {
				{file="ew_bridge_passage_n"},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=3}},
			},
			size = {x=1, y=1, z=2},
			valid_neighbors = {
				[HASHKEY(0, 0, 2)] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, 0)] = PASSAGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(-1, 0, 0)] = PASSAGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(0, 1, 0)] = {roof_straight_ew=true},
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 1)] = {bridge_arch_ns=true},
			},
			footprint = {
				[HASHKEY(0, 0, 1)] = "ns_walk_bridge",
				[HASHKEY(0, 0, 0)] = "hallway_straight_ew",
			},
			-- Require both sides of the north-facing bridge to be empty.
			require_empty_neighbors = {
				[HASHKEY(-1, 0, 1)] = true,
				[HASHKEY(1, 0, 1)] = true,
			},
			-- Probability that hallways may spawn bridge accesses.
			probability = PASSAGE_BRIDGE_TRANSITION_PROB2,
		},

		hall_ew_to_bridge_s = {
			schem = {
				{file="ew_bridge_passage_s"},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=14}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=14}},
			},
			size = {x=1, y=1, z=2},
			valid_neighbors = {
				[HASHKEY(0, 0, -1)] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(-1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(0, 1, 1)] = {roof_straight_ew=true},
				[HASHKEY(0, -1, 1)] = {solid_top=true},
				[HASHKEY(0, -1, 0)] = {bridge_arch_ns=true},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ns_walk_bridge",
				[HASHKEY(0, 0, 1)] = "hallway_straight_ew",
			},
			-- Require both sides of the south-facing bridge to be empty.
			require_empty_neighbors = {
				[HASHKEY(-1, 0, 0)] = true,
				[HASHKEY(1, 0, 0)] = true,
			},
			-- Probability that hallways may spawn bridge accesses.
			probability = PASSAGE_BRIDGE_TRANSITION_PROB2,
		},

		-- Straight hallways with internal stairs to roof.
		hall_straight_ew_stair = {
			schem = {
				{file="nf_passage_ew_stair"},

				-- Outside window decorations.
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.EAST] = exclude(PASSAGE_CONNECT[DIRNAME.EAST],
					{hallway_w_capped=true}), -- Cap stairs interfere.
				[DIRNAME.WEST] = exclude(PASSAGE_CONNECT[DIRNAME.WEST],
					{hallway_e_capped=true}), -- Cap stairs interfere.

				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {hall_straight_ew_roof_stair=true},
			},
			probability = STRAIGHT_HALLWAY_WITH_STAIR_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_straight_ns_stair = {
			schem = {
				{file="nf_passage_ew_stair", rotation="90"},

				-- Outside window decorations.
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = exclude(PASSAGE_CONNECT[DIRNAME.NORTH],
					{hallway_s_capped=true}), -- Cap stairs interfere.
				[DIRNAME.SOUTH] = exclude(PASSAGE_CONNECT[DIRNAME.SOUTH],
					{hallway_n_capped=true}), -- Cap stairs interfere.

				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {hall_straight_ns_roof_stair=true},
			},
			probability = STRAIGHT_HALLWAY_WITH_STAIR_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_straight_ew_roof_stair = {
			schem = {{file="nf_walkway_ew_stair", force=false}},
		},

		hall_straight_ns_roof_stair = {
			schem = {{file="nf_walkway_ew_stair", rotation="90", force=false}},
		},

		-- Straight hallways with internal stairs to roof.
		hall_straight_ew_stair_rev = {
			schem = {
				{file="nf_passage_ew_stair", rotation="180"},

				-- Outside window decorations.
				{file="fortress_window_deco", chance=70, rotation="0", force=false,
					offset={x=3, y=2, z=-2}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="180", force=false,
					offset={x=3, y=2, z=11}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.EAST] = exclude(PASSAGE_CONNECT[DIRNAME.EAST],
					{hallway_w_capped=true}), -- Cap stairs interfere.
				[DIRNAME.WEST] = exclude(PASSAGE_CONNECT[DIRNAME.WEST],
					{hallway_e_capped=true}), -- Cap stairs interfere.

				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {hall_straight_ew_roof_stair_rev=true},
			},
			probability = STRAIGHT_HALLWAY_WITH_STAIR_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_straight_ns_stair_rev = {
			schem = {
				{file="nf_passage_ew_stair", rotation="270"},

				-- Outside window decorations.
				{file="fortress_window_deco", chance=70, rotation="90", force=false,
					offset={x=-2, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
				{file="fortress_window_deco", chance=70, rotation="270", force=false,
					offset={x=11, y=2, z=3}, priority=WINDOW_DECO_PRIORITY},
			},
			valid_neighbors = {
				[DIRNAME.NORTH] = exclude(PASSAGE_CONNECT[DIRNAME.NORTH],
					{hallway_s_capped=true}), -- Cap stairs interfere.
				[DIRNAME.SOUTH] = exclude(PASSAGE_CONNECT[DIRNAME.SOUTH],
					{hallway_n_capped=true}), -- Cap stairs interfere.

				[DIRNAME.DOWN] = {solid_top=true},
				[DIRNAME.UP] = {hall_straight_ns_roof_stair_rev=true},
			},
			probability = STRAIGHT_HALLWAY_WITH_STAIR_PROB,
			chests = GET_BASIC_LOOT_POSITIONS(),
		},

		hall_straight_ew_roof_stair_rev = {
			schem = {{file="nf_walkway_ew_stair", force=false, rotation="180"}},
		},

		hall_straight_ns_roof_stair_rev = {
			schem = {{file="nf_walkway_ew_stair", rotation="270", force=false}},
		},

		-- Small plaza. 1x1.
		small_plaza_dummy = {},
		small_plaza = {
			schem = {
				{file="nf_building_solid", force=false, offset={x=0, y=-7, z=0}},
			},
			size = {x=1, y=1, z=1},
			chests = GET_BASIC_LOOT_POSITIONS(),
			valid_neighbors = {
				-- Basement.
				[HASHKEY(0, -1, 0)] = {solid_top=true},

				-- Cardinal edges.
				---[[
				-- West side.
				[HASHKEY(-1, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_swn_t = true,
					ns_plaza_w = true,
					hallway_e_capped_no_stair = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
					hall_corner_nw = true,
					hall_corner_sw = true,
				},
				-- East side.
				[HASHKEY(1, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_nes_t = true,
					ns_plaza_e = true,
					hallway_w_capped_no_stair = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
					hall_corner_ne = true,
					hall_corner_se = true,
				},
				-- South side.
				[HASHKEY(0, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_esw_t = true,
					ew_plaza_s = true,
					hallway_n_capped_no_stair = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
					hall_corner_sw = true,
					hall_corner_se = true,
				},
				-- North side.
				[HASHKEY(0, 0, 1)] = {
					hallway_straight_ew = true,
					hallway_wne_t = true,
					ew_plaza_n = true,
					hallway_s_capped_no_stair = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
					hall_corner_ne = true,
					hall_corner_nw = true,
				},
				--]]

				-- Now the corners.
				---[[
				-- Southwest corner.
				[HASHKEY(-1, 0, -1)] = {
					hall_corner_ne = true,
					hallway_e_capped_no_stair = true,
					hallway_n_capped_no_stair = true,
					hallway_junction = true,
					hallway_wne_t = true,
					hallway_nes_t = true,
				},
				-- Northwest corner.
				[HASHKEY(-1, 0, 1)] = {
					hall_corner_se = true,
					hallway_s_capped_no_stair = true,
					hallway_e_capped_no_stair = true,
					hallway_junction = true,
					hallway_esw_t = true,
					hallway_nes_t = true,
				},
				-- Northeast corner.
				[HASHKEY(1, 0, 1)] = {
					hall_corner_sw = true,
					hallway_s_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_esw_t = true,
				},
				-- Southeast corner.
				[HASHKEY(1, 0, -1)] = {
					hall_corner_nw = true,
					hallway_n_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_wne_t = true,
				},
				--]]
			},
			-- Prevent us from overwriting anyone else.
			require_empty_neighbors = {
				-- Footprint must be empty.
				[HASHKEY(0, 0, 0)] = true,
			},
			-- Prevent algorithm from coming back and overwriting us.
			footprint = {
				[HASHKEY(0, 0, 0)] = "small_plaza_dummy",
			},
			probability = SMALL_PLAZA_CHANCE,
		},

		-- The 2x2 plaza object.
		medium_plaza_dummy = {},
		medium_plaza = {
			schem = {
				{file="nf_building_solid", force=false, offset={x=0, y=-7, z=0}},
				{file="nf_building_solid", force=false, offset={x=11, y=-7, z=0}},
				{file="nf_building_solid", force=false, offset={x=0, y=-7, z=11}},
				{file="nf_building_solid", force=false, offset={x=11, y=-7, z=11}},
			},
			size = {x=2, y=1, z=2},
			valid_neighbors = {
				-- Basement.
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(1, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 1)] = {solid_top=true},
				[HASHKEY(1, -1, 1)] = {solid_top=true},

				-- Entrances on the edges.
				---[[
				-- West side.
				[HASHKEY(-1, 0, 1)] = {
					hallway_straight_ns = true,
					hallway_swn_t = true,
					ns_plaza_w = true,
					hallway_e_capped_no_stair = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_n_capped_no_stair_prob0 = true,
				},
				-- East side.
				[HASHKEY(2, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_nes_t = true,
					ns_plaza_e = true,
					hallway_w_capped_no_stair = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
				},
				-- South side.
				[HASHKEY(0, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_esw_t = true,
					ew_plaza_s = true,
					hallway_n_capped_no_stair = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				-- North side.
				[HASHKEY(1, 0, 2)] = {
					hallway_straight_ew = true,
					hallway_wne_t = true,
					ew_plaza_n = true,
					hallway_s_capped_no_stair = true,
					hallway_w_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				--]]

				-- Require the left sides of all possible entrances to be hallways.
				-- Left side of south entrance.
				---[[
				[HASHKEY(1, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				-- Left side of north entrance.
				[HASHKEY(0, 0, 2)] = {
					hallway_straight_ew = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				-- Left side of west entrance.
				[HASHKEY(-1, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				-- Left side of east entrance.
				[HASHKEY(2, 0, 1)] = {
					hallway_straight_ns = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				--]]

				-- Now the corners.
				---[[
				-- Southwest corner.
				[HASHKEY(-1, 0, -1)] = {
					hall_corner_ne = true,
					hallway_e_capped_no_stair = true,
					hallway_n_capped_no_stair = true,
					hallway_junction = true,
					hallway_wne_t = true,
					hallway_nes_t = true,
				},
				-- Northwest corner.
				[HASHKEY(-1, 0, 2)] = {
					hall_corner_se = true,
					hallway_s_capped_no_stair = true,
					hallway_e_capped_no_stair = true,
					hallway_junction = true,
					hallway_esw_t = true,
					hallway_nes_t = true,
				},
				-- Northeast corner.
				[HASHKEY(2, 0, 2)] = {
					hall_corner_sw = true,
					hallway_s_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_esw_t = true,
				},
				-- Southeast corner.
				[HASHKEY(2, 0, -1)] = {
					hall_corner_nw = true,
					hallway_n_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_wne_t = true,
				},
				--]]
			},
			-- Prevent us from overwriting anyone else.
			require_empty_neighbors = {
				-- Footprint must be empty.
				[HASHKEY(0, 0, 0)] = true,
				[HASHKEY(1, 0, 0)] = true,
				[HASHKEY(0, 0, 1)] = true,
				[HASHKEY(1, 0, 1)] = true,
			},
			-- Prevent algorithm from coming back and overwriting us.
			footprint = {
				[HASHKEY(0, 0, 0)] = "medium_plaza_dummy",
				[HASHKEY(1, 0, 0)] = "medium_plaza_dummy",
				[HASHKEY(0, 0, 1)] = "medium_plaza_dummy",
				[HASHKEY(1, 0, 1)] = "medium_plaza_dummy",
			},
			probability = MEDIUM_PLAZA_CHANCE,
		},

		-- Special plaza entrances that can spawn from hallways (not bridges).
		-- These should behave exactly like 'hall_ns_to_bridge_e' and related.
		-- Bridgewalk faces east, plaza is west of us.
		ns_plaza_e_from_hall = {
			schem = {
				{file="ns_bridge_passage_e"},
				{file="plaza_door_ew", offset={x=0, y=4, z=3}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=3}},
			},
			size = {x=2, y=1, z=1},
			valid_neighbors = {
				[HASHKEY(-1, 0, 0)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_e_capped = true,
				},
				[HASHKEY(0, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(0, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(2, 0, 0)] = BRIDGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(0, 1, 0)] = {roof_straight_ns=true},
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(1, -1, 0)] = {bridge_arch_ew=true},
			},
			footprint = {
				[HASHKEY(1, 0, 0)] = "ew_walk_bridge",
				[HASHKEY(0, 0, 0)] = "hallway_straight_ns",
			},
			require_empty_neighbors = {
				-- Require both sides of the east-facing bridge to be empty.
				[HASHKEY(1, 0, 1)] = true,
				[HASHKEY(1, 0, -1)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Bridgewalk faces west, plaza is east of us.
		ns_plaza_w_from_hall = {
			schem = {
				{file="ns_bridge_passage_w"},
				{file="plaza_door_ew", offset={x=19, y=4, z=3}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=14, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=14, y=3, z=3}},
			},
			size = {x=2, y=1, z=1},
			valid_neighbors = {
				[HASHKEY(2, 0, 0)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_w_capped = true,
				},
				[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, -1)] = PASSAGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(-1, 0, 0)] = BRIDGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(1, 1, 0)] = {roof_straight_ns=true},
				[HASHKEY(1, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 0)] = {bridge_arch_ew=true},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ew_walk_bridge",
				[HASHKEY(1, 0, 0)] = "hallway_straight_ns",
			},
			require_empty_neighbors = {
				-- Require both sides of the west-facing bridge to be empty.
				[HASHKEY(0, 0, 1)] = true,
				[HASHKEY(0, 0, -1)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Bridgewalk faces north, plaza will be south of us.
		ew_plaza_n_from_hall = {
			schem = {
				{file="ew_bridge_passage_n"},
				{file="plaza_door_ns", offset={x=3, y=4, z=0}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=3}},
			},
			size = {x=1, y=1, z=2},
			valid_neighbors = {
				[HASHKEY(0, 0, -1)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_n_capped = true,
				},
				[HASHKEY(0, 0, 2)] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, 0)] = PASSAGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(-1, 0, 0)] = PASSAGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(0, 1, 0)] = {roof_straight_ew=true},
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 1)] = {bridge_arch_ns=true},
			},
			footprint = {
				[HASHKEY(0, 0, 1)] = "ns_walk_bridge",
				[HASHKEY(0, 0, 0)] = "hallway_straight_ew",
			},
			require_empty_neighbors = {
				-- Require both sides of the north-facing bridge to be empty.
				[HASHKEY(-1, 0, 1)] = true,
				[HASHKEY(1, 0, 1)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Bridgewalk faces south, plaza will be north of us.
		ew_plaza_s_from_hall = {
			schem = {
				{file="ew_bridge_passage_s"},
				{file="plaza_door_ns", offset={x=3, y=4, z=19}, priority=100},

				-- Hazards need custom offset for this large chunk.
				-- Can't use the basic macros here.
				{file="nf_detail_lava1", chance=FLOOR_LAVA_CHANCE, rotation="random",
					offset={x=3, y=3, z=14}},
				{file="nf_detail_spawner1", chance=OERKKI_SPAWNER_CHANCE,
					rotation="random", offset={x=3, y=3, z=14}},
			},
			size = {x=1, y=1, z=2},
			valid_neighbors = {
				[HASHKEY(0, 0, 2)] = {
					large_plaza = true,
					medium_plaza = true,
					small_plaza = true,
					medium_chamber = true,

					-- Note that this does result in an orphan cap roof on top.
					hallway_s_capped = true,
				},
				[HASHKEY(0, 0, -1)] = BRIDGE_CONNECT[DIRNAME.SOUTH],
				[HASHKEY(1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.EAST],
				[HASHKEY(-1, 0, 1)] = PASSAGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(0, 1, 1)] = {roof_straight_ew=true},
				[HASHKEY(0, -1, 1)] = {solid_top=true},
				[HASHKEY(0, -1, 0)] = {bridge_arch_ns=true},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ns_walk_bridge",
				[HASHKEY(0, 0, 1)] = "hallway_straight_ew",
			},
			require_empty_neighbors = {
				-- Require both sides of the south-facing bridge to be empty.
				[HASHKEY(-1, 0, 0)] = true,
				[HASHKEY(1, 0, 0)] = true,
			},
			probability = PLAZA_GATE_PROB,
		},

		-- Gatehouses.
		ew_gatehouse_dummy = {},
		ew_gatehouse = {
			schem = {
				{file="nf_gatehouse_ew", offset={x=0, y=0, z=7}},
				{file="nf_gatehouse_bridge_shim_w", force=false,
					offset={x=0, y=-11, z=11}},
				{file="nf_gatehouse_bridge_shim_e", force=false,
					offset={x=20, y=-11, z=11}},
			},
			size = {x=2, y=1, z=3},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ew_gatehouse_dummy",
				[HASHKEY(1, 0, 0)] = "ew_gatehouse_dummy",
				[HASHKEY(0, 0, 1)] = "ew_walk_bridge",
				[HASHKEY(1, 0, 1)] = "ew_walk_bridge",
				[HASHKEY(0, 0, 2)] = "ew_gatehouse_dummy",
				[HASHKEY(1, 0, 2)] = "ew_gatehouse_dummy",
			},
			probability = GATEHOUSE_PROB,
			limit = 2,
			valid_neighbors = {
				[HASHKEY(-1, 0, 1)] = BRIDGE_CONNECT[DIRNAME.WEST],
				[HASHKEY(2, 0, 1)] = BRIDGE_CONNECT[DIRNAME.EAST],

				-- Both sides of east-facing bridge.
				-- Southeast corner.
				[HASHKEY(2, 0, 0)] = {
					air_option = true,
					ns_walk_bridge = true,
					walk_bridge_nsw = true,
					nw_corner_walk = true,
					capped_bridge_n = true,
				},
				-- Northeast corner.
				[HASHKEY(2, 0, 2)] = {
					air_option = true,
					ns_walk_bridge = true,
					walk_bridge_nsw = true,
					sw_corner_walk = true,
					capped_bridge_s = true,
				},

				-- Both sides of west-facing bridge.
				-- Southwest corner.
				[HASHKEY(-1, 0, 0)] = {
					air_option = true,
					ns_walk_bridge = true,
					walk_bridge_nse = true,
					ne_corner_walk = true,
					capped_bridge_n = true,
				},
				-- Northwest corner.
				[HASHKEY(-1, 0, 2)] = {
					air_option = true,
					ns_walk_bridge = true,
					walk_bridge_nse = true,
					se_corner_walk = true,
					capped_bridge_s = true,
				},

				-- Basement.
				[HASHKEY(0, -4, 0)] = {gatehouse_pillar_ew=true},
			},
		},

		ns_gatehouse_dummy = {},
		ns_gatehouse = {
			schem = {
				{file="nf_gatehouse_ns", offset={x=7, y=0, z=0}},
				{file="nf_gatehouse_bridge_shim_s", force=false,
					offset={x=11, y=-11, z=0}},
				{file="nf_gatehouse_bridge_shim_n", force=false,
					offset={x=11, y=-11, z=20}},
			},
			size = {x=3, y=1, z=2},
			footprint = {
				[HASHKEY(0, 0, 0)] = "ns_gatehouse_dummy",
				[HASHKEY(1, 0, 0)] = "ns_walk_bridge",
				[HASHKEY(2, 0, 0)] = "ns_gatehouse_dummy",
				[HASHKEY(0, 0, 1)] = "ns_gatehouse_dummy",
				[HASHKEY(1, 0, 1)] = "ns_walk_bridge",
				[HASHKEY(2, 0, 1)] = "ns_gatehouse_dummy",
			},
			probability = GATEHOUSE_PROB,
			limit = 2,
			valid_neighbors = {
				[HASHKEY(1, 0, 2)] = BRIDGE_CONNECT[DIRNAME.NORTH],
				[HASHKEY(1, 0, -1)] = BRIDGE_CONNECT[DIRNAME.SOUTH],

				-- Both sides of north-facing bridge.
				-- Northwest corner.
				[HASHKEY(0, 0, 2)] = {
					air_option = true,
					ew_walk_bridge = true,
					walk_bridge_nwe = true,
					ne_corner_walk = true,
					capped_bridge_e = true,
				},
				-- Northeast corner.
				[HASHKEY(2, 0, 2)] = {
					air_option = true,
					ew_walk_bridge = true,
					walk_bridge_nwe = true,
					nw_corner_walk = true,
					capped_bridge_w = true,
				},

				-- Both sides of south-facing bridge.
				-- Southwest corner.
				[HASHKEY(0, 0, -1)] = {
					air_option = true,
					ew_walk_bridge = true,
					walk_bridge_swe = true,
					se_corner_walk = true,
					capped_bridge_e = true,
				},
				-- Southeast corner.
				[HASHKEY(2, 0, -1)] = {
					air_option = true,
					ew_walk_bridge = true,
					walk_bridge_swe = true,
					sw_corner_walk = true,
					capped_bridge_w = true,
				},

				-- Basement.
				[HASHKEY(0, -4, 0)] = {gatehouse_pillar_ns=true},
			},
		},

		gatehouse_pillar_ew = {
			schem = {
				{file="nf_gatehouse_tower_ew", offset={x=2, y=0, z=7}},
				{file="nf_gatehouse_tower_ew", offset={x=2, y=11, z=7}},
				{file="nf_gatehouse_tower_ew", offset={x=2, y=22, z=7}},
				{file="nf_gatehouse_tower_ew", offset={x=2, y=33, z=7}},
			},
			size = {x=2, y=4, z=3},
		},

		gatehouse_pillar_ns = {
			schem = {
				{file="nf_gatehouse_tower_ns", offset={x=7, y=0, z=2}},
				{file="nf_gatehouse_tower_ns", offset={x=7, y=11, z=2}},
				{file="nf_gatehouse_tower_ns", offset={x=7, y=22, z=2}},
				{file="nf_gatehouse_tower_ns", offset={x=7, y=33, z=2}},
			},
			size = {x=3, y=4, z=2},
		},

		-- The 2x2 chamber object.
		medium_chamber_dummy = {},
		medium_chamber = {
			schem = {
				{file="nf_medium_chamber_enclosed", priority=WINDOW_DECO_PRIORITY+1},
				{file="nf_detail_lava_well2", priority=WINDOW_DECO_PRIORITY+2,
					chance=30, offset={x=9, y=0, z=9}},
			},
			size = {x=2, y=1, z=2},
			valid_neighbors = {
				-- Basement.
				[HASHKEY(0, -1, 0)] = {solid_top=true},
				[HASHKEY(1, -1, 0)] = {solid_top=true},
				[HASHKEY(0, -1, 1)] = {solid_top=true},
				[HASHKEY(1, -1, 1)] = {solid_top=true},

				-- Roof.
				[HASHKEY(0, 1, 0)] = {
					medium_chamber_flatroof = true,
				},

				-- Entrances on the edges.
				-- West side.
				[HASHKEY(-1, 0, 1)] = {
					hallway_straight_ns = true,
					hallway_swn_t = true,
					ns_plaza_w = true,
					hallway_e_capped_no_stair = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_n_capped_no_stair_prob0 = true,
				},
				-- East side.
				[HASHKEY(2, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_nes_t = true,
					ns_plaza_e = true,
					hallway_w_capped_no_stair = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_s_capped_no_stair_prob0 = true,
				},
				-- South side.
				[HASHKEY(0, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_esw_t = true,
					ew_plaza_s = true,
					hallway_n_capped_no_stair = true,
					hallway_e_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				-- North side.
				[HASHKEY(1, 0, 2)] = {
					hallway_straight_ew = true,
					hallway_wne_t = true,
					ew_plaza_n = true,
					hallway_s_capped_no_stair = true,
					hallway_w_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},

				-- Require the left sides of all possible entrances to be hallways.
				-- Left side of south entrance.
				[HASHKEY(1, 0, -1)] = {
					hallway_straight_ew = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},
				-- Left side of north entrance.
				[HASHKEY(0, 0, 2)] = {
					hallway_straight_ew = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				-- Left side of west entrance.
				[HASHKEY(-1, 0, 0)] = {
					hallway_straight_ns = true,
					hallway_n_capped_no_stair_prob0 = true,
					hallway_e_capped_no_stair_prob0 = true,
				},
				-- Left side of east entrance.
				[HASHKEY(2, 0, 1)] = {
					hallway_straight_ns = true,
					hallway_s_capped_no_stair_prob0 = true,
					hallway_w_capped_no_stair_prob0 = true,
				},

				-- Now the corners.
				-- Southwest corner.
				[HASHKEY(-1, 0, -1)] = {
					hall_corner_ne = true,
					hallway_e_capped_no_stair = true,
					hallway_n_capped_no_stair = true,
					hallway_junction = true,
					hallway_wne_t = true,
					hallway_nes_t = true,
				},
				-- Northwest corner.
				[HASHKEY(-1, 0, 2)] = {
					hall_corner_se = true,
					hallway_s_capped_no_stair = true,
					hallway_e_capped_no_stair = true,
					hallway_junction = true,
					hallway_esw_t = true,
					hallway_nes_t = true,
				},
				-- Northeast corner.
				[HASHKEY(2, 0, 2)] = {
					hall_corner_sw = true,
					hallway_s_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_esw_t = true,
				},
				-- Southeast corner.
				[HASHKEY(2, 0, -1)] = {
					hall_corner_nw = true,
					hallway_n_capped_no_stair = true,
					hallway_w_capped_no_stair = true,
					hallway_junction = true,
					hallway_swn_t = true,
					hallway_wne_t = true,
				},
			},
			footprint = {
				[HASHKEY(0, 0, 0)] = "medium_chamber_dummy",
				[HASHKEY(1, 0, 0)] = "medium_chamber_dummy",
				[HASHKEY(0, 0, 1)] = "medium_chamber_dummy",
				[HASHKEY(1, 0, 1)] = "medium_chamber_dummy",
			},
		},

		medium_chamber_flatroof_dummy = {},
		medium_chamber_flatroof = {
			schem = {
				{file="nf_medium_chamber_flatroof"},
			},
			size = {x=2, y=1, z=2},
			footprint = {
				[HASHKEY(0, 0, 0)] = "medium_chamber_flatroof_dummy",
				[HASHKEY(1, 0, 0)] = "medium_chamber_flatroof_dummy",
				[HASHKEY(0, 0, 1)] = "medium_chamber_flatroof_dummy",
				[HASHKEY(1, 0, 1)] = "medium_chamber_flatroof_dummy",
			},
		},
	},
}

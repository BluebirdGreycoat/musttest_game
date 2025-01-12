
-- Todo:
-- Add grand staircases (bridge and passage variants). (Note: maybe we don't want these? Fortresses should be 2D only ....)
-- Add connections between sections of gatehouse tower.
-- Allow fortress to generate off of gatehouse tower sections.
-- Add raised plaza.
-- Add lava-well room.
-- Add throne room.
-- Add balconies.
-- Add lava aquaducts.
-- Add bluegrass farm.
-- Add single-room chambers.
-- Add great hall.
-- Add dungeon prison.
-- Add portal chamber.
-- Add ziggurat plaza.
-- Add table/alter room.

fortress.default = {
	-- The initial schem placed by the spawner.
	-- This starts the rest of the fortress growing off it.
	initial = {
		"junction",
		"junction_walk_bridge",
		"plaza",
	  "ew_gatehouse",
		"ns_gatehouse",
		"ns_bridge_passage",
		"ew_bridge_passage",
	},

	-- Size of cells.
	-- This is how much the algorithm steps in a direction before generating the
	-- next chunk of fortress.
	step = {x=11, y=11, z=11},

	-- Maximum fortress extent.
	-- The fortress spawner will not spawn any chunks farther than this distance
	-- from the starting position.
	max_extent = {x=150, y=100, z=150},

	-- If chunk position would exceed the soft extent, then the chance for all
	-- sub-chunks becomes 0, and fallback chunks (if any) are used ONLY.
	soft_extent = {x=100, y=30, z=100},

	-- List of node replacements.
	replacements = {
		["torches:torch_wall"] = "torches:iron_torch",
		["rackstone:brick"] = "rackstone:brick_black",
		["stairs:slab_rackstone_brick"] = "stairs:slab_rackstone_brick_black",
		["stairs:stair_rackstone_brick"] = "stairs:stair_basaltic_rubble",
	},

	-- Path to the directory where the schem files are stored.
	schemdir = minetest.get_modpath("fortress") .. "/schems",

	-- Fortress section definitions.
	-- Each chunk has a name, and its table defines which other chunks may be
	-- spawned off it.
	--
	-- Note: for each chunk, 'size' is given in terms of 'step', this is NOT
	-- actual size coordinates. The fortress spawner multiplies 'size' by 'step'
	-- value and uses the result to detect whether a particular location has
	-- already spawned a section of fortress.
	--
	-- You typically only need to specify 'size' for sections of fortress that are
	-- larger than 'step' size. The default size is {1, 1, 1}.
	--
	-- The 'adjust' schematic variable is for slightly adjusting the precise
	-- positioning of an individual schematic file. Chunks can have multiple
	-- schematic files, and often each one must have its position adjusted a bit
	-- to prevent overlaps.
	--
	-- The 'fallback' flag indicates that a chunk should be placed if no other
	-- chunk was chosen. E.g., if several possible neighbors are specified in a
	-- particular chunk's data, but none of those neighbors pass the 'chance'
	-- test, then the first neighbor with 'fallback' set will be used instead.
	-- Any single neighbor with 'fallback' must be the LAST entry in the neighbors
	-- list, but there may be multiple neighbors thus flagged -- they will be
	-- added in order.
	chunks = {
		plaza = {
			schem = {
				{file="nf_building_solid", force=false, adjust={x=0, y=-7, z=0}},
				{file="nf_building_solid", force=false, adjust={x=11, y=-7, z=0}},
				{file="nf_building_solid", force=false, adjust={x=22, y=-7, z=0}},
				{file="nf_building_solid", force=false, adjust={x=0, y=-7, z=11}},
				{file="nf_building_solid", force=false, adjust={x=11, y=-7, z=11}},
				{file="nf_building_solid", force=false, adjust={x=22, y=-7, z=11}},
				{file="nf_building_solid", force=false, adjust={x=0, y=-7, z=22}},
				{file="nf_building_solid", force=false, adjust={x=11, y=-7, z=22}},
				{file="nf_building_solid", force=false, adjust={x=22, y=-7, z=22}},
			},
			size = {x=3, y=1, z=3},
			next = {
				["+x"] = {
					{chunk="ns", fallback=true, continue=true, shift={x=2, y=0, z=0}},
					{chunk="ns_plaza_e", fallback=true, continue=true, shift={x=2, y=0, z=1}},
					{chunk="ns", fallback=true, continue=true, shift={x=2, y=0, z=2}},
					{chunk="junction", fallback=true, continue=true, shift={x=2, y=0, z=3}},
				},
				["-x"] = {
					{chunk="ns", fallback=true, continue=true, shift={x=0, y=0, z=0}},
					{chunk="ns_plaza_w", fallback=true, continue=true, shift={x=-1, y=0, z=1}},
					{chunk="ns", fallback=true, continue=true, shift={x=0, y=0, z=2}},
					{chunk="junction", fallback=true, continue=true, shift={x=0, y=0, z=-1}},
				},
				["+z"] = {
					{chunk="ew", fallback=true, continue=true, shift={x=0, y=0, z=2}},
					{chunk="ew_plaza_n", fallback=true, continue=true, shift={x=1, y=0, z=2}},
					{chunk="ew", fallback=true, continue=true, shift={x=2, y=0, z=2}},
					{chunk="junction", fallback=true, continue=true, shift={x=-1, y=0, z=2}},
				},
				["-z"] = {
					{chunk="ew", fallback=true, continue=true, shift={x=0, y=0, z=0}},
					{chunk="ew_plaza_s", fallback=true, continue=true, shift={x=1, y=0, z=-1}},
					{chunk="ew", fallback=true, continue=true, shift={x=2, y=0, z=0}},
					{chunk="junction", fallback=true, continue=true, shift={x=3, y=0, z=0}},
				},
				["-y"] = {
					{chunk="pillar", fallback=true, continue=true, shift={x=0, y=0, z=0}},
					{chunk="pillar", fallback=true, continue=true, shift={x=2, y=0, z=0}},
					{chunk="pillar", fallback=true, continue=true, shift={x=0, y=0, z=2}},
					{chunk="pillar", fallback=true, continue=true, shift={x=2, y=0, z=2}},
				},
			},
		},

		-- Corridor sections.
		junction = {
			schem = {
				{file="nf_passage_4x_junction"},
				{file="ew_hall_end_e", priority=1000, force=false, adjust={x=11, y=3, z=2}},
				{file="ew_hall_end_w", priority=1000, force=false, adjust={x=-3, y=3, z=2}},
				{file="ns_hall_end_n", priority=1000, force=false, adjust={x=2, y=3, z=11}},
				{file="ns_hall_end_s", priority=1000, force=false, adjust={x=2, y=3, z=-3}},
			},
			next = {
				["+x"] = {
					{chunk="ew", chance=80, shift={x=0, y=0, z=0}},
					{chunk="w_capped", fallback=true},
				},
				["+z"] = {
					{chunk="ns", chance=80},
					{chunk="s_capped", fallback=true},
				},
				["-x"] = {
					{chunk="ew", chance=80},
					{chunk="e_capped", fallback=true},
				},
				["-z"] = {
					{chunk="ns", chance=80},
					{chunk="n_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="junction_walk", fallback=true}},
			},
		},

		ew = {
			schem = {
				{file="nf_passage_ew"},
				{file="ew_hall_end_stair_e", priority=100, force=false, adjust={x=11, y=1, z=2}},
				{file="ew_hall_end_stair_w", priority=100, force=false, adjust={x=-3, y=1, z=2}},
				{file="nf_detail_lava1", chance=10, force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_room1", chance=15, force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_room2", chance=15, force=true, adjust={x=3, y=4, z=3}},
				{file="nf_detail_room3", chance=15, rotation="90", force=false, adjust={x=0, y=4, z=3}},
			},
			chests = {
				{pos={x_min=0, x_max=10, y=4, z=3}, chance=10, loot="common"},
				{pos={x_min=0, x_max=10, y=4, z=7}, chance=10, loot="common"},
				{pos={x_min=0, x_max=10, y=4, z=3}, chance=5, loot="rare"},
				{pos={x_min=0, x_max=10, y=4, z=7}, chance=5, loot="rare"},
			},
			next = {
				["+x"] = {
					{chunk="ew", chance=50},
					{chunk="ew_stair", chance=20},
					{chunk="ew_bridge_passage", chance=10, shift={x=0, y=0, z=-1}},
					{chunk="ew_bridge_passage_n", chance=30, shift={x=0, y=0, z=0}},
					{chunk="ew_bridge_passage_s", chance=30, shift={x=0, y=0, z=1}},
					{chunk="sw_corner", chance=20},
					{chunk="nw_corner", chance=20},
					{chunk="swn_t", chance=10},
					{chunk="esw_t", chance=10},
					{chunk="wne_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="w_capped", fallback=true},
				},
				["-x"] = {
					{chunk="ew", chance=50},
					{chunk="ew_stair", chance=20},
					{chunk="ew_bridge_passage", chance=10, shift={x=0, y=0, z=-1}},
					{chunk="ew_bridge_passage_n", chance=30, shift={x=0, y=0, z=0}},
					{chunk="ew_bridge_passage_s", chance=30, shift={x=0, y=0, z=1}},
					{chunk="se_corner", chance=20},
					{chunk="ne_corner", chance=20},
					{chunk="wne_t", chance=10},
					{chunk="esw_t", chance=10},
					{chunk="nes_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="e_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="ew_walk", fallback=true}},
			},
		},

		ns = {
			schem = {
				{file="nf_passage_ns"},
				{file="ns_hall_end_stair_n", priority=100, force=false, adjust={x=2, y=1, z=11}},
				{file="ns_hall_end_stair_s", priority=100, force=false, adjust={x=2, y=1, z=-3}},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_room1", chance=15, rotation="90", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_room2", chance=15, rotation="90", force=true, adjust={x=3, y=4, z=3}},
				{file="nf_detail_room3", chance=15, force=false, adjust={x=3, y=4, z=0}},
			},
			chests = {
				{pos={x=3, y=4, z_min=0, z_max=10}, chance=10, loot="common"},
				{pos={x=7, y=4, z_min=0, z_max=10}, chance=10, loot="common"},
				{pos={x=3, y=4, z_min=0, z_max=10}, chance=5, loot="rare"},
				{pos={x=7, y=4, z_min=0, z_max=10}, chance=5, loot="rare"},
			},
			next = {
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="ns_stair", chance=20},
					{chunk="ns_bridge_passage", chance=10, shift={x=-1, y=0, z=0}},
					{chunk="ns_bridge_passage_e", chance=30, shift={x=0, y=0, z=0}},
					{chunk="ns_bridge_passage_w", chance=30, shift={x=1, y=0, z=0}},
					{chunk="se_corner", chance=20},
					{chunk="sw_corner", chance=20},
					{chunk="nes_t", chance=10},
					{chunk="esw_t", chance=10},
					{chunk="swn_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="s_capped", fallback=true},
				},
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="ns_stair", chance=20},
					{chunk="ns_bridge_passage", chance=10, shift={x=-1, y=0, z=0}},
					{chunk="ns_bridge_passage_e", chance=30, shift={x=0, y=0, z=0}},
					{chunk="ns_bridge_passage_w", chance=30, shift={x=1, y=0, z=0}},
					{chunk="ne_corner", chance=20},
					{chunk="nw_corner", chance=20},
					{chunk="nes_t", chance=10},
					{chunk="wne_t", chance=10},
					{chunk="swn_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="n_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="ns_walk", fallback=true}},
			},
		},

		ns_plaza_e = {
			schem = {
				{file="ns_bridge_passage_e"},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="plaza_door_ew", force=true, adjust={x=0, y=4, z=3}},
			},
			size = {x=2, y=1, z=1},
			next = {
				["+x"] = {
					{chunk="ew_walk_bridge", chance=70, shift={x=1, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true, shift={x=1, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ew", fallback=true, shift={x=1, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true},
				},
				["+y"] = {
					{chunk="ns_walk", fallback=true},
				},
			},
		},

		ns_plaza_w = {
			schem = {
				{file="ns_bridge_passage_w"},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=14, y=3, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=14, y=3, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=14, y=3, z=3}},
				{file="plaza_door_ew", force=true, adjust={x=19, y=4, z=3}},
			},
			size = {x=2, y=1, z=1},
			next = {
				["-x"] = {
					{chunk="ew_walk_bridge", chance=70, shift={x=-2, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ew", fallback=true, shift={x=0, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true, shift={x=1, y=0, z=0}},
				},
				["+y"] = {
					{chunk="ns_walk", fallback=true, shift={x=1, y=0, z=0}},
				},
			},
		},

		ew_plaza_n = {
			schem = {
				{file="ew_bridge_passage_n"},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="plaza_door_ns", force=true, adjust={x=3, y=4, z=0}},
			},
			size = {x=1, y=1, z=2},
			next = {
				["+z"] = {
					{chunk="ns_walk_bridge", chance=70, shift={x=0, y=0, z=1}},
					{chunk="s_broken_walk", fallback=true, shift={x=0, y=0, z=1}},
				},
				["-y"] = {
					{chunk="bridge_arch_ns", fallback=true, shift={x=0, y=0, z=1}, continue=true},
					{chunk="solid", fallback=true},
				},
				["+y"] = {
					{chunk="ew_walk", fallback=true},
				},
			},
		},

		ew_plaza_s = {
			schem = {
				{file="ew_bridge_passage_s"},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=3, z=3}},
				{file="plaza_door_ns", force=true, adjust={x=3, y=4, z=19}},
			},
			size = {x=1, y=1, z=2},
			next = {
				["-z"] = {
					{chunk="ns_walk_bridge", chance=70, shift={x=0, y=0, z=-2}},
					{chunk="n_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ns", fallback=true, shift={x=0, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true, shift={x=0, y=0, z=1}},
				},
				["+y"] = {
					{chunk="ew_walk", fallback=true, shift={x=0, y=0, z=1}},
				},
			},
		},

		n_capped = {
			schem = {
				{file="nf_passage_n_capped"},
				{file="hall_end_stair", rotation="180", chance=20, force=true, priority=1000, adjust={x=4, y=4, z=5}},
			},
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=3}, chance=50, loot="common"},
				{pos={x=3, y=4, z_min=3, z_max=10}, chance=30, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=10}, chance=20, loot="exceptional"},
			},
			next = {
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="n_capped_walk", fallback=true}},
			},
		},

		s_capped = {
			schem = {
				{file="nf_passage_s_capped"},
				{file="hall_end_stair", rotation="0", chance=20, force=true, priority=1000, adjust={x=4, y=4, z=-2}},
			},
			chests = {
				{pos={x_min=3, x_max=7, y=4, z=7}, chance=50, loot="common"},
				{pos={x=3, y=4, z_min=0, z_max=7}, chance=30, loot="rare"},
				{pos={x=7, y=4, z_min=0, z_max=7}, chance=20, loot="exceptional"},
			},
			next = {
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="s_capped_walk", fallback=true}},
			},
		},

		e_capped = {
			schem = {
				{file="nf_passage_e_capped"},
				{file="hall_end_stair", rotation="270", chance=20, force=true, priority=1000, adjust={x=5, y=4, z=4}},
			},
			chests = {
				{pos={x_min=3, x_max=10, y=4, z=3}, chance=50, loot="common"},
				{pos={x_min=3, x_max=10, y=4, z=7}, chance=30, loot="rare"},
				{pos={x=3, y=4, z_min=3, z_max=7}, chance=20, loot="exceptional"},
			},
			next = {
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="e_capped_walk", fallback=true}},
			},
		},

		w_capped = {
			schem = {
				{file="nf_passage_w_capped"},
				{file="hall_end_stair", rotation="90", chance=20, force=true, priority=1000, adjust={x=-2, y=4, z=4}},
			},
			chests = {
				{pos={x_min=0, x_max=7, y=4, z=3}, chance=50, loot="common"},
				{pos={x_min=0, x_max=7, y=4, z=7}, chance=30, loot="rare"},
				{pos={x=7, y=4, z_min=3, z_max=7}, chance=20, loot="exceptional"},
			},
			next = {
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="w_capped_walk", fallback=true}},
			},
		},

		ne_corner = {
			schem = {
				{file="nf_passage_ne_corner"},
				{file="ns_hall_end_n", priority=1000, force=false, adjust={x=2, y=3, z=11}},
				{file="ew_hall_end_e", priority=1000, force=false, adjust={x=11, y=3, z=2}},
			},
			next = {
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped", fallback=true},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="ne_corner_walk", fallback=true}},
			},
		},

		nw_corner = {
			schem = {
				{file="nf_passage_nw_corner"},
				{file="ew_hall_end_w", priority=1000, force=false, adjust={x=-3, y=3, z=2}},
				{file="ns_hall_end_n", priority=1000, force=false, adjust={x=2, y=3, z=11}},
			},
			next = {
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped", fallback=true},
				},
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="nw_corner_walk", fallback=true}},
			},
		},

		sw_corner = {
			schem = {
				{file="nf_passage_sw_corner"},
				{file="ns_hall_end_s", priority=1000, force=false, adjust={x=2, y=3, z=-3}},
				{file="ew_hall_end_w", priority=1000, force=false, adjust={x=-3, y=3, z=2}},
			},
			next = {
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped", fallback=true},
				},
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="sw_corner_walk", fallback=true}},
			},
		},

		se_corner = {
			schem = {
				{file="nf_passage_se_corner"},
				{file="ns_hall_end_s", priority=1000, force=false, adjust={x=2, y=3, z=-3}},
				{file="ew_hall_end_e", priority=1000, force=false, adjust={x=11, y=3, z=2}},
			},
			next = {
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped", fallback=true},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="se_corner_walk", fallback=true}},
			},
		},

		esw_t = {
			schem = {
				{file="nf_passage_esw_t"},
				{file="ew_hall_end_e", priority=1000, force=false, adjust={x=11, y=3, z=2}},
				{file="ew_hall_end_w", priority=1000, force=false, adjust={x=-3, y=3, z=2}},
				{file="ns_hall_end_s", priority=1000, force=false, adjust={x=2, y=3, z=-3}},
			},
			next = {
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped", fallback=true},
				},
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped", fallback=true},
				},
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="esw_t_walk", fallback=true}},
			},
		},

		nes_t = {
			schem = {
				{file="nf_passage_nes_t"},
				{file="ns_hall_end_n", priority=1000, force=false, adjust={x=2, y=3, z=11}},
				{file="ns_hall_end_s", priority=1000, force=false, adjust={x=2, y=3, z=-3}},
				{file="ew_hall_end_e", priority=1000, force=false, adjust={x=11, y=3, z=2}},
			},
			next = {
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped", fallback=true},
				},
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped", fallback=true},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="nes_t_walk", fallback=true}},
			},
		},

		swn_t = {
			schem = {
				{file="nf_passage_swn_t"},
				{file="ew_hall_end_w", priority=1000, force=false, adjust={x=-3, y=3, z=2}},
				{file="ns_hall_end_n", priority=1000, force=false, adjust={x=2, y=3, z=11}},
				{file="ns_hall_end_s", priority=1000, force=false, adjust={x=2, y=3, z=-3}},
			},
			next = {
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped", fallback=true},
				},
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped", fallback=true},
				},
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="swn_t_walk", fallback=true}},
			},
		},

		wne_t = {
			schem = {
				{file="nf_passage_wne_t"},
				{file="ew_hall_end_e", priority=1000, force=false, adjust={x=11, y=3, z=2}},
				{file="ew_hall_end_w", priority=1000, force=false, adjust={x=-3, y=3, z=2}},
				{file="ns_hall_end_n", priority=1000, force=false, adjust={x=2, y=3, z=11}},
			},
			next = {
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped", fallback=true},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped", fallback=true},
				},
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped", fallback=true},
				},
				["-y"] = {{chunk="solid", fallback=true}},
				["+y"] = {{chunk="wne_t_walk", fallback=true}},
			},
		},

		-- Bridge/passage connections.
		ns_bridge_passage = {
			schem = {
				{file="nf_ns_passage_ew_bridge_access"},
				{file="ns_hall_end_stair_n", priority=1000, force=false, adjust={x=13, y=1, z=11}},
				{file="ns_hall_end_stair_s", priority=1000, force=false, adjust={x=13, y=1, z=-3}},
			},
			size = {x=3, y=1, z=1},
			limit = 4,
			next = {
				["+z"] = {
					{chunk="ns", shift={x=1, y=0, z=0}},
					{chunk="s_capped", fallback=true, shift={x=1, y=0, z=0}},
				},
				["-z"] = {
					{chunk="ns", shift={x=1, y=0, z=0}},
					{chunk="n_capped", fallback=true, shift={x=1, y=0, z=0}},
				},
				["+x"] = {
					{chunk="ew_walk_bridge", chance=70, shift={x=2, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true, shift={x=2, y=0, z=0}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge", chance=70, shift={x=-2, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ew", fallback=true, shift={x=0, y=0, z=0}, continue=true},
					{chunk="bridge_arch_ew", fallback=true, shift={x=2, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true, shift={x=1, y=0, z=0}},
				},
				["+y"] = {
					{chunk="ns_walk", shift={x=1, y=0, z=0}, fallback=true},
				},
			},
		},

		ns_bridge_passage_w = {
			schem = {
				{file="ns_bridge_passage_w"},
				{file="ns_hall_end_stair_n", priority=1000, force=false, adjust={x=13, y=1, z=11}},
				{file="ns_hall_end_stair_s", priority=1000, force=false, adjust={x=13, y=1, z=-3}},
			},
			size = {x=2, y=1, z=1},
			limit = 4,
			next = {
				["+z"] = {
					{chunk="ns", shift={x=1, y=0, z=0}},
					{chunk="s_capped", fallback=true, shift={x=1, y=0, z=0}},
				},
				["-z"] = {
					{chunk="ns", shift={x=1, y=0, z=0}},
					{chunk="n_capped", fallback=true, shift={x=1, y=0, z=0}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge", chance=70, shift={x=-2, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ew", fallback=true, shift={x=0, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true, shift={x=1, y=0, z=0}},
				},
				["+y"] = {
					{chunk="ns_walk", shift={x=1, y=0, z=0}, fallback=true},
				},
			},
		},

		ns_bridge_passage_e = {
			schem = {
				{file="ns_bridge_passage_e"},
				{file="ns_hall_end_stair_n", priority=1000, force=false, adjust={x=2, y=1, z=11}},
				{file="ns_hall_end_stair_s", priority=1000, force=false, adjust={x=2, y=1, z=-3}},
			},
			size = {x=2, y=1, z=1},
			limit = 4,
			next = {
				["+z"] = {
					{chunk="ns", shift={x=0, y=0, z=0}},
					{chunk="s_capped", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="ns", shift={x=0, y=0, z=0}},
					{chunk="n_capped", fallback=true, shift={x=0, y=0, z=0}},
				},
				["+x"] = {
					{chunk="ew_walk_bridge", chance=70, shift={x=1, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true, shift={x=1, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ew", fallback=true, shift={x=1, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true, shift={x=0, y=0, z=0}},
				},
				["+y"] = {
					{chunk="ns_walk", shift={x=0, y=0, z=0}, fallback=true},
				},
			},
		},

		ew_bridge_passage = {
			schem = {
				{file="nf_ew_passage_ns_bridge_access"},
				{file="ew_hall_end_stair_e", priority=1000, force=false, adjust={x=11, y=1, z=13}},
				{file="ew_hall_end_stair_w", priority=1000, force=false, adjust={x=-3, y=1, z=13}},
			},
			size = {x=1, y=1, z=3},
			limit = 4,
			next = {
				["+x"] = {
					{chunk="ew", shift={x=0, y=0, z=1}},
					{chunk="w_capped", fallback=true, shift={x=0, y=0, z=1}},
				},
				["-x"] = {
					{chunk="ew", shift={x=0, y=0, z=1}},
					{chunk="e_capped", fallback=true, shift={x=0, y=0, z=1}},
				},
				["+z"] = {
					{chunk="ns_walk_bridge", chance=70, shift={x=0, y=0, z=2}},
					{chunk="s_broken_walk", fallback=true, shift={x=0, y=0, z=2}},
				},
				["-z"] = {
					{chunk="ns_walk_bridge", chance=70, shift={x=0, y=0, z=-2}},
					{chunk="n_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ns", fallback=true, shift={x=0, y=0, z=0}, continue=true},
					{chunk="bridge_arch_ns", fallback=true, shift={x=0, y=0, z=2}, continue=true},
					{chunk="solid", fallback=true, shift={x=0, y=0, z=1}},
				},
				["+y"] = {
					{chunk="ew_walk", shift={x=0, y=0, z=1}, fallback=true},
				},
			},
		},

		ew_bridge_passage_n = {
			schem = {
				{file="ew_bridge_passage_n"},
				{file="ew_hall_end_stair_e", priority=1000, force=false, adjust={x=11, y=1, z=2}},
				{file="ew_hall_end_stair_w", priority=1000, force=false, adjust={x=-3, y=1, z=2}},
			},
			size = {x=1, y=1, z=2},
			limit = 4,
			next = {
				["+x"] = {
					{chunk="ew", shift={x=0, y=0, z=0}},
					{chunk="w_capped", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-x"] = {
					{chunk="ew", shift={x=0, y=0, z=0}},
					{chunk="e_capped", fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="ns_walk_bridge", chance=70, shift={x=0, y=0, z=1}},
					{chunk="s_broken_walk", fallback=true, shift={x=0, y=0, z=1}},
				},
				["-y"] = {
					{chunk="bridge_arch_ns", fallback=true, shift={x=0, y=0, z=1}, continue=true},
					{chunk="solid", fallback=true, shift={x=0, y=0, z=0}},
				},
				["+y"] = {
					{chunk="ew_walk", shift={x=0, y=0, z=0}, fallback=true},
				},
			},
		},

		ew_bridge_passage_s = {
			schem = {
				{file="ew_bridge_passage_s"},
				{file="ew_hall_end_stair_e", priority=1000, force=false, adjust={x=11, y=1, z=13}},
				{file="ew_hall_end_stair_w", priority=1000, force=false, adjust={x=-3, y=1, z=13}},
			},
			size = {x=1, y=1, z=2},
			limit = 4,
			next = {
				["+x"] = {
					{chunk="ew", shift={x=0, y=0, z=1}},
					{chunk="w_capped", fallback=true, shift={x=0, y=0, z=1}},
				},
				["-x"] = {
					{chunk="ew", shift={x=0, y=0, z=1}},
					{chunk="e_capped", fallback=true, shift={x=0, y=0, z=1}},
				},
				["-z"] = {
					{chunk="ns_walk_bridge", chance=70, shift={x=0, y=0, z=-2}},
					{chunk="n_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_ns", fallback=true, shift={x=0, y=0, z=0}, continue=true},
					{chunk="solid", fallback=true, shift={x=0, y=0, z=1}},
				},
				["+y"] = {
					{chunk="ew_walk", shift={x=0, y=0, z=1}, fallback=true},
				},
			},
		},

		-- Bridge junctions.
		junction_walk_bridge = {
			schem = {
				{file="nf_walkway_4x_junction", force=false},
				{file="bridge_junction_house", chance=50, force=true},
				{file="nf_detail_lava_well1", chance=50, force=true, adjust={x=3, y=1, z=3}},
			},
			-- If number of chunks excees this limit, then algorithm reduces
			-- the chance by 10% for every unit over the limit. This affects
			-- all chunks which have this chunk as a possible follow-up.
			limit = 3,
			next = {
				["-y"] = {
					{chunk="bridge_pillar_top", fallback=true, shift={x=0, y=-1, z=0}},
				},
				["+x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true},
				},
				["-x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=-2, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true},
				},
				["+z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="s_broken_walk", fallback=true},
				},
				["-z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=-2}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", fallback=true},
				},
			},
		},

		walk_bridge_nse = {
			schem = {
				{file="walk_bridge_nse", force=false},
			},
			-- If number of chunks excees this limit, then algorithm reduces
			-- the chance by 10% for every unit over the limit. This affects
			-- all chunks which have this chunk as a possible follow-up.
			limit = 5,
			next = {
				["-y"] = {
					{chunk="bridge_pillar_top", fallback=true, shift={x=0, y=-1, z=0}},
				},
				["+x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true},
				},
				["+z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="s_broken_walk", fallback=true},
				},
				["-z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=-2}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", fallback=true},
				},
			},
		},

		walk_bridge_nsw = {
			schem = {
				{file="walk_bridge_nsw", force=false},
			},
			-- If number of chunks excees this limit, then algorithm reduces
			-- the chance by 10% for every unit over the limit. This affects
			-- all chunks which have this chunk as a possible follow-up.
			limit = 5,
			next = {
				["-y"] = {
					{chunk="bridge_pillar_top", fallback=true, shift={x=0, y=-1, z=0}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=-2, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true},
				},
				["+z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="s_broken_walk", fallback=true},
				},
				["-z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=-2}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", fallback=true},
				},
			},
		},

		walk_bridge_swe = {
			schem = {
				{file="walk_bridge_swe", force=false},
			},
			-- If number of chunks excees this limit, then algorithm reduces
			-- the chance by 10% for every unit over the limit. This affects
			-- all chunks which have this chunk as a possible follow-up.
			limit = 5,
			next = {
				["-y"] = {
					{chunk="bridge_pillar_top", fallback=true, shift={x=0, y=-1, z=0}},
				},
				["+x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true},
				},
				["-x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=-2, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true},
				},
				["-z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=-2}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", fallback=true},
				},
			},
		},

		walk_bridge_nwe = {
			schem = {
				{file="walk_bridge_nwe", force=false},
			},
			-- If number of chunks excees this limit, then algorithm reduces
			-- the chance by 10% for every unit over the limit. This affects
			-- all chunks which have this chunk as a possible follow-up.
			limit = 5,
			next = {
				["-y"] = {
					{chunk="bridge_pillar_top", fallback=true, shift={x=0, y=-1, z=0}},
				},
				["+x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true},
				},
				["-x"] = {
					{chunk="ew_walk_bridge", chance=80, shift={x=-2, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true},
				},
				["+z"] = {
					{chunk="ns_walk_bridge", chance=80, shift={x=0, y=0, z=0}},
					{chunk="ns_walk_bridge_short", chance=10, shift={x=0, y=0, z=0}},
					{chunk="s_broken_walk", fallback=true},
				},
			},
		},

		-- Bridges.
		ew_walk_bridge = {
			schem = {
				{file="nf_walkway_ew", force=false, adjust={x=0, y=0, z=0}},
				{file="nf_walkway_ew", force=false, adjust={x=11, y=0, z=0}},
				{file="nf_walkway_ew", force=false, adjust={x=22, y=0, z=0}},
				{file="bridge_house_ew", chance=20, force=true, adjust={x=0, y=3, z=0}},
				{file="bridge_house_ew", chance=10, force=true, adjust={x=11, y=3, z=0}},
				{file="bridge_house_ew", chance=20, force=true, adjust={x=22, y=3, z=0}},
			},
			size = {x=3, y=1, z=1},
			next = {
				["+x"] = {
					{chunk="junction_walk_bridge", chance=10, shift={x=2, y=0, z=0}},
					{chunk="walk_bridge_nsw", chance=10, shift={x=2, y=0, z=0}},
					{chunk="walk_bridge_nwe", chance=10, shift={x=2, y=0, z=0}},
					{chunk="walk_bridge_swe", chance=10, shift={x=2, y=0, z=0}},
					{chunk="ns_bridge_passage", chance=10, shift={x=2, y=0, z=0}},
					{chunk="ns_bridge_passage_w", chance=20, shift={x=2, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=80, shift={x=2, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true, shift={x=2, y=0, z=0}},
				},
				["-x"] = {
					{chunk="junction_walk_bridge", chance=10, shift={x=0, y=0, z=0}},
					{chunk="walk_bridge_nse", chance=10, shift={x=0, y=0, z=0}},
					{chunk="walk_bridge_swe", chance=10, shift={x=0, y=0, z=0}},
					{chunk="walk_bridge_nwe", chance=10, shift={x=0, y=0, z=0}},
					{chunk="ns_bridge_passage", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="ns_bridge_passage_e", chance=20, shift={x=-1, y=0, z=0}},
					{chunk="ew_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_pillar_ew", shift={x=0, y=-1, z=0}, continue=true, fallback=true},
					{chunk="bridge_arch_ew", shift={x=1, y=0, z=0}, continue=true, fallback=true},
					{chunk="bridge_arch_pillar_ew", shift={x=2, y=-1, z=0}, continue=true, fallback=true},
				},
			},
		},

		ns_walk_bridge = {
			schem = {
				{file="nf_walkway_ns", force=false, adjust={x=0, y=0, z=0}},
				{file="nf_walkway_ns", force=false, adjust={x=0, y=0, z=11}},
				{file="nf_walkway_ns", force=false, adjust={x=0, y=0, z=22}},
				{file="bridge_house_ns", chance=20, force=true, adjust={x=0, y=3, z=0}},
				{file="bridge_house_ns", chance=10, force=true, adjust={x=0, y=3, z=11}},
				{file="bridge_house_ns", chance=20, force=true, adjust={x=0, y=3, z=22}},
			},
			size = {x=1, y=1, z=3},
			next = {
				["+z"] = {
					{chunk="junction_walk_bridge", chance=10, shift={x=0, y=0, z=2}},
					{chunk="walk_bridge_nse", chance=10, shift={x=0, y=0, z=2}},
					{chunk="walk_bridge_swe", chance=10, shift={x=0, y=0, z=2}},
					{chunk="walk_bridge_nsw", chance=10, shift={x=0, y=0, z=2}},
					{chunk="ew_bridge_passage", chance=10, shift={x=0, y=0, z=2}},
					{chunk="ew_bridge_passage_s", chance=20, shift={x=0, y=0, z=2}},
					{chunk="ns_walk_bridge_short", chance=80, shift={x=0, y=0, z=2}},
					{chunk="s_broken_walk", fallback=true, shift={x=0, y=0, z=2}},
				},
				["-z"] = {
					{chunk="junction_walk_bridge", chance=10, shift={x=0, y=0, z=0}},
					{chunk="walk_bridge_nse", chance=10, shift={x=0, y=0, z=0}},
					{chunk="walk_bridge_nsw", chance=10, shift={x=0, y=0, z=0}},
					{chunk="walk_bridge_nwe", chance=10, shift={x=0, y=0, z=0}},
					{chunk="ew_bridge_passage", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="ew_bridge_passage_n", chance=20, shift={x=0, y=0, z=-1}},
					{chunk="ns_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_pillar_ns", shift={x=0, y=-1, z=0}, continue=true, fallback=true},
					{chunk="bridge_arch_ns", shift={x=0, y=0, z=1}, continue=true, fallback=true},
					{chunk="bridge_arch_pillar_ns", shift={x=0, y=-1, z=2}, continue=true, fallback=true},
				},
			},
		},

		ew_walk_bridge_short = {
			schem = {
				{file="nf_walkway_ew", force=false},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="nf_detail_lava1", chance=10, force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_ew", chance=20, force=true, adjust={x=0, y=3, z=0}},
			},
			next = {
				["+x"] = {
					{chunk="ew_gatehouse", chance=20, shift={x=0, y=0, z=-1}},
					{chunk="ns_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ew_walk_bridge", chance=100, shift={x=0, y=0, z=0}},
					{chunk="w_broken_walk", fallback=true},
				},
				["-x"] = {
					{chunk="ew_gatehouse", chance=20, shift={x=-1, y=0, z=-1}},
					{chunk="ns_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ew_walk_bridge", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="e_broken_walk", fallback=true},
				},
				["-y"] = {{chunk="bridge_arch_ew", fallback=true}},
			},
		},

		ns_walk_bridge_short = {
			schem = {
				{file="nf_walkway_ns", force=false},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_ns", chance=20, force=true, adjust={x=0, y=3, z=0}},
			},
			next = {
				["+z"] = {
					{chunk="ns_gatehouse", chance=20, shift={x=-1, y=0, z=0}},
					{chunk="ew_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ns_walk_bridge", chance=100, shift={x=0, y=0, z=0}},
					{chunk="s_broken_walk", fallback=true},
				},
				["-z"] = {
					{chunk="ns_gatehouse", chance=20, shift={x=-1, y=0, z=-1}},
					{chunk="ew_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ns_walk_bridge", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="n_broken_walk", fallback=true},
				},
				["-y"] = {{chunk="bridge_arch_ns", fallback=true}},
			},
		},

		-- Walkways.
		junction_walk = {schem = {{file="nf_walkway_4x_junction", force=false}}},

		ew_walk = {
			schem = {
				{file="nf_walkway_ew", priority=101, force=false},
				{file="nf_detail_lava1", chance=10, force=true, adjust={x=3, y=0, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="elite_spawner", chance=5, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_ew", chance=15, force=true, adjust={x=0, y=3, z=0}},
			},
		},

		ns_walk = {
			schem = {
				{file="nf_walkway_ns", priority=101, force=false},
				{file="nf_detail_lava1", chance=10, rotation="90", force=true, adjust={x=3, y=0, z=3}},
				{file="nf_detail_lava1", chance=2, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="elite_spawner", chance=5, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_ns", chance=15, force=true, adjust={x=0, y=3, z=0}},
			},
		},

		n_capped_walk = {
			schem = {
				{file="nf_walkway_n_capped", priority=101, force=false},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_n", chance=15, force=true, adjust={x=0, y=3, z=0}},
			},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},

		s_capped_walk = {
			schem = {
				{file="nf_walkway_s_capped", priority=101, force=false},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_s", chance=15, force=true, adjust={x=0, y=3, z=0}},
			},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},

		e_capped_walk = {
			schem = {
				{file="nf_walkway_e_capped", priority=101, force=false},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_e", chance=15, force=true, adjust={x=0, y=3, z=0}},
			},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},

		w_capped_walk = {
			schem = {
				{file="nf_walkway_w_capped", priority=101, force=false},
				{file="nf_detail_spawner1", chance=20, rotation="random", force=true, adjust={x=3, y=0, z=3}},
				{file="bridge_house_w", chance=15, force=true, adjust={x=0, y=3, z=0}},
			},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},

		-- Broken causeway ends.
		-- Need to set 'fallback' on the arch-undersides, otherwise they won't be
		-- placed if we're past the soft extent.
		n_broken_walk = {
			schem = {{file="nf_walkway_n_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_n", fallback=true}},
			},
		},

		s_broken_walk = {
			schem = {{file="nf_walkway_s_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_s", fallback=true}},
			},
		},

		e_broken_walk = {
			schem = {{file="nf_walkway_e_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_e", fallback=true}},
			},
		},

		w_broken_walk = {
			schem = {{file="nf_walkway_w_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_w", fallback=true}},
			},
		},

		ne_corner_walk = {schem = {{file="nf_walkway_ne_corner", priority=101, force=false}}},
		nw_corner_walk = {schem = {{file="nf_walkway_nw_corner", priority=101, force=false}}},
		sw_corner_walk = {schem = {{file="nf_walkway_sw_corner", priority=101, force=false}}},
		se_corner_walk = {schem = {{file="nf_walkway_se_corner", priority=101, force=false}}},
		esw_t_walk = {schem = {{file="nf_walkway_esw_t", priority=101, force=false}}},
		nes_t_walk = {schem = {{file="nf_walkway_nes_t", priority=101, force=false}}},
		swn_t_walk = {schem = {{file="nf_walkway_swn_t", priority=101, force=false}}},
		wne_t_walk = {schem = {{file="nf_walkway_wne_t", priority=101, force=false}}},

		ew_stair = {
			schem = {
				{file="nf_passage_ew_stair"},
				{file="ew_hall_end_stair_e", priority=1000, force=false, adjust={x=11, y=1, z=2}},
				{file="ew_hall_end_stair_w", priority=1000, force=false, adjust={x=-3, y=1, z=2}},
			},
			next = {
				["+x"] = {
					{chunk="swn_t", chance=20},
					{chunk="wne_t", chance=20},
					{chunk="esw_t", fallback=true},
				},
				["-x"] = {
					{chunk="wne_t", chance=20},
					{chunk="esw_t", chance=20},
					{chunk="nes_t", fallback=true},
				},
				["+y"] = {{chunk="ew_walk_stair", fallback=true}},
				["-y"] = {{chunk="solid", fallback=true}},
			},
		},

		ew_walk_stair = {
			schem = {{file="nf_walkway_ew_stair"}},
		},

		ns_stair = {
			schem = {
				{file="nf_passage_ew_stair", rotation="90"},
				{file="ns_hall_end_stair_n", priority=1000, force=false, adjust={x=2, y=1, z=11}},
				{file="ns_hall_end_stair_s", priority=1000, force=false, adjust={x=2, y=1, z=-3}},
			},
			next = {
				["+z"] = {
					{chunk="nes_t", chance=20},
					{chunk="swn_t", chance=20},
					{chunk="esw_t", fallback=true},
				},
				["-z"] = {
					{chunk="nes_t", chance=10},
					{chunk="swn_t", chance=10},
					{chunk="wne_t", fallback=true},
				},
				["+y"] = {{chunk="ns_walk_stair", fallback=true}},
				["-y"] = {{chunk="solid", fallback=true}},
			},
		},

		ns_walk_stair = {
			schem = {{file="nf_walkway_ew_stair", rotation="90", force=false}},
		},

		tower = {
			schem = {
				{file="nf_tower", force=false, priority=1000, adjust={x=3, y=-10, z=3}},
			},
			limit = 4,
			size = {x=1, y=2, z=1},
		},

		-- Gatehouses.
		ew_gatehouse = {
			schem = {
				{file="nf_gatehouse_ew", adjust={x=0, y=0, z=7}},
				{file="nf_gatehouse_bridge_shim_w", force=false, adjust={x=0, y=-11, z=11}},
				{file="nf_gatehouse_bridge_shim_e", force=false, adjust={x=20, y=-11, z=11}},
			},
			size = {x=2, y=1, z=3},
			limit = 2,
			next = {
				["+x"] = {
					{chunk="ew_walk_bridge_short", chance=20, shift={x=1, y=0, z=1}},
					{chunk="ew_walk_bridge", chance=80, shift={x=1, y=0, z=1}},
					{chunk="w_broken_walk", fallback=true, shift={x=1, y=0, z=1}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge_short", chance=20, shift={x=0, y=0, z=1}},
					{chunk="ew_walk_bridge", chance=80, shift={x=-2, y=0, z=1}},
					{chunk="e_broken_walk", fallback=true, shift={x=0, y=0, z=1}},
				},
				["-y"] = {{chunk="gatehouse_pillar_ew", shift={x=0, y=-3, z=0}, fallback=true}},
			},
		},

		ns_gatehouse = {
			schem = {
				{file="nf_gatehouse_ns", adjust={x=7, y=0, z=0}},
				{file="nf_gatehouse_bridge_shim_s", force=false, adjust={x=11, y=-11, z=0}},
				{file="nf_gatehouse_bridge_shim_n", force=false, adjust={x=11, y=-11, z=20}},
			},
			size = {x=3, y=1, z=2},
			limit = 2,
			next = {
				["+z"] = {
					{chunk="ns_walk_bridge_short", chance=20, shift={x=1, y=0, z=1}},
					{chunk="ns_walk_bridge", chance=100, shift={x=1, y=0, z=1}},
					{chunk="s_broken_walk", fallback=true, shift={x=1, y=0, z=1}},
				},
				["-z"] = {
					{chunk="ns_walk_bridge_short", chance=20, shift={x=1, y=0, z=0}},
					{chunk="ns_walk_bridge", chance=100, shift={x=1, y=0, z=-2}},
					{chunk="n_broken_walk", fallback=true, shift={x=1, y=0, z=0}},
				},
				["-y"] = {{chunk="gatehouse_pillar_ns", shift={x=0, y=-3, z=0}, fallback=true}},
			},
		},

		gatehouse_pillar_ew = {
			schem = {
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=0, z=7}},
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=11, z=7}},
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=22, z=7}},
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=33, z=7}},
			},
			size = {x=2, y=4, z=3},
		},

		gatehouse_pillar_ns = {
			schem = {
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=0, z=2}},
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=11, z=2}},
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=22, z=2}},
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=33, z=2}},
			},
			size = {x=3, y=4, z=2},
		},

		pillar = {
			schem = {{file="nf_pillar", force=false}},
			next = {
				["-y"] = {{chunk="pillar_straight", fallback=true, shift={x=0, y=-2, z=0}}},
			},
		},

		pillar_straight = {
			schem = {
				{file="nf_pillar_straight", force=false, adjust={x=3, y=0, z=3}},
				{file="nf_pillar_straight", force=false, adjust={x=3, y=11, z=3}},
				{file="nf_pillar_straight", force=false, adjust={x=3, y=22, z=3}},
			},
			size = {x=1, y=3, z=1},
		},

		solid = {
			schem = {{file="nf_building_solid", force=false, adjust={x=0, y=0, z=0}}},
			size = {x=1, y=1, z=1},
			next = {
				["-y"] = {{chunk="pillar", fallback=true}},
			},
		},

		-- Bridge arches & pillars.
		bridge_arch_ns = {
			schem = {
				{file="nf_bridge_arch_ns", force=false, adjust={x=0, y=6, z=0}},
				{file="bridge_pit", chance=5, force=true, adjust={x=3, y=8, z=3}},
			},
		},

		bridge_arch_ew = {
			schem = {
				{file="nf_bridge_arch_ew", force=false, adjust={x=0, y=6, z=0}},
				{file="bridge_pit", chance=5, force=true, adjust={x=3, y=8, z=3}},
			},
		},

		bridge_arch_pillar_ns = {
			schem = {{file="nf_bridge_arch_pillar_ns", force=false}},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {{chunk="bridge_arch_pillar_bottom_ns", fallback=true, shift={x=0, y=-3, z=0}}},
			},
		},

		bridge_arch_pillar_ew = {
			schem = {{file="nf_bridge_arch_pillar_ew", force=false}},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {{chunk="bridge_arch_pillar_bottom_ew", fallback=true, shift={x=0, y=-3, z=0}}},
			},
		},

		bridge_arch_pillar_bottom_ns = {
			schem = {
				{file="nf_bridge_arch_pillar_bottom_ns", force=false, adjust={x=0, y=0, z=3}},
				{file="nf_bridge_arch_pillar_bottom_ns", force=false, adjust={x=0, y=22, z=3}},
			},
			size = {x=1, y=4, z=1},
		},

		bridge_arch_pillar_bottom_ew = {
			schem = {
				{file="nf_bridge_arch_pillar_bottom_ew", force=false, adjust={x=3, y=0, z=0}},
				{file="nf_bridge_arch_pillar_bottom_ew", force=false, adjust={x=3, y=22, z=0}},
			},
			size = {x=1, y=4, z=1},
		},

		bridge_pillar_top = {
			schem = {{file="nf_center_pillar_top", force=false}},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {{chunk="bridge_pillar_bottom", fallback=true, shift={x=0, y=-3, z=0}}},
			},
		},

		bridge_pillar_bottom = {
			schem = {
				{file="nf_center_pillar_bottom", force=false, adjust={x=1, y=0, z=1}},
				{file="nf_center_pillar_bottom", force=false, adjust={x=1, y=22, z=1}},
			},
			size = {x=1, y=4, z=1},
		},

		-- Broken bits of arch underneath broken causeway ends.
		bridge_broken_walk_arch_n = {
			schem = {{file="nf_bridge_walk_broken_arch_n", force=false}},
		},
		bridge_broken_walk_arch_s = {
			schem = {{file="nf_bridge_walk_broken_arch_s", force=false}},
		},
		bridge_broken_walk_arch_e = {
			schem = {{file="nf_bridge_walk_broken_arch_e", force=false}},
		},
		bridge_broken_walk_arch_w = {
			schem = {{file="nf_bridge_walk_broken_arch_w", force=false}},
		},

		-- Narrow bridges.
		bridge_narrow_junction = {
			schem = {
				{file="bridge_narrow_junction", force=false, adjust={x=0, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100},
					{chunk="bridge_narrow_broken_e", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken_w", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100},
					{chunk="bridge_narrow_broken_n", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken_s", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken2_s", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_sw = {
			schem = {
				{file="bridge_narrow_sw", force=false, adjust={x=0, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_w", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_platform_n", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_s", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken2_s", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_se = {
			schem = {
				{file="bridge_narrow_se", force=false, adjust={x=3, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_w", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_e", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_platform_n", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_s", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken2_s", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_ne = {
			schem = {
				{file="bridge_narrow_ne", force=false, adjust={x=3, y=7, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_w", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_e", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_s", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_n", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_nw = {
			schem = {
				{file="bridge_narrow_nw", force=false, adjust={x=0, y=7, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_w", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_s", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_n", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_nsw = {
			schem = {
				{file="bridge_narrow_nsw", force=false, adjust={x=0, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_w", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_platform_n", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_s", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken2_s", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_s", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_n", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_nse = {
			schem = {
				{file="bridge_narrow_nse", force=false, adjust={x=3, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_w", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_e", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_platform_n", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_s", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken2_s", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_s", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_n", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_swe = {
			schem = {
				{file="bridge_narrow_swe", force=false, adjust={x=0, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_w", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_platform_n", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_s", chance=10, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_broken2_s", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_w", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_e", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_nwe = {
			schem = {
				{file="bridge_narrow_nwe", force=false, adjust={x=0, y=7, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_w", chance=10, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_s", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_n", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_w", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken_e", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=10, fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_ns = {
			schem = {
				{file="ns_bridge_narrow", force=false, adjust={x=3, y=0, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z_min=0, z_max=3*11-4}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z_min=0, z_max=3*11-4}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z_min=0, z_max=3*11-4}},
			},
			size = {x=1, y=2, z=3},
			next = {
				["+z"] = {
					{chunk="bridge_narrow_short_ns", chance=100, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_junction", chance=5, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_se", chance=5, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_sw", chance=5, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_swe", chance=10, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_nsw", chance=10, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_nse", chance=10, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_platform_s", chance=5, shift={x=0, y=0, z=2}},
					{chunk="bridge_narrow_broken2_n", chance=5, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_short_ns", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_junction", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_ne", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_nw", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_nwe", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_nsw", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_nse", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_n", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_s", chance=5, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_narrow_pillar_ns", fallback=true, shift={x=0, y=-3, z=1}},
				},
			},
		},

		bridge_narrow_ew = {
			schem = {
				{file="ew_bridge_narrow", force=false, adjust={x=0, y=0, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x_min=0, x_max=3*11-4, y=11, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x_min=0, x_max=3*11-4, y=11, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x_min=0, x_max=3*11-4, y=11, z=3}},
			},
			size = {x=3, y=2, z=1},
			next = {
				["+x"] = {
					{chunk="bridge_narrow_short_ew", chance=100, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_junction", chance=5, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_nw", chance=5, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_sw", chance=5, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_nsw", chance=10, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_swe", chance=10, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_nwe", chance=10, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_platform_w", chance=5, shift={x=2, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", chance=5, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-x"] = {
					{chunk="bridge_narrow_short_ew", chance=100, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_junction", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_ne", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_se", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_nse", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_swe", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_nwe", chance=10, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", chance=5, shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", chance=5, fallback=true, shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_narrow_pillar_ew", fallback=true, shift={x=1, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_broken_e = {
			schem = {
				{file="bridge_narrow_broken_e", force=false, adjust={x=0, y=0, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=0, y=11, z=3}},
			},
			size = {x=3, y=2, z=1},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_pillar_ew", fallback=true, shift={x=1, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_broken_w = {
			schem = {
				{file="bridge_narrow_broken_w", force=false, adjust={x=0, y=0, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3*11-4, y=11, z=3}},
			},
			size = {x=3, y=2, z=1},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_pillar_ew", fallback=true, shift={x=1, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_broken_n = {
			schem = {
				{file="bridge_narrow_broken_n", force=false, adjust={x=3, y=0, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=0}},
			},
			size = {x=1, y=2, z=3},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_pillar_ns", fallback=true, shift={x=0, y=-3, z=1}},
				},
			},
		},

		bridge_narrow_broken_s = {
			schem = {
				{file="bridge_narrow_broken_s", force=false, adjust={x=3, y=0, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3*11-4}},
			},
			size = {x=1, y=2, z=3},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_pillar_ns", fallback=true, shift={x=0, y=-3, z=1}},
				},
			},
		},

		bridge_narrow_broken2_e = {
			schem = {
				{file="bridge_narrow_broken2_e", force=false, adjust={x=0, y=7, z=3}},
			},
			size = {x=1, y=2, z=1},
		},

		bridge_narrow_broken2_w = {
			schem = {
				{file="bridge_narrow_broken2_w", force=false, adjust={x=6, y=7, z=3}},
			},
			size = {x=1, y=2, z=1},
		},

		bridge_narrow_broken2_n = {
			schem = {
				{file="bridge_narrow_broken2_n", force=false, adjust={x=3, y=7, z=0}},
			},
			size = {x=1, y=2, z=1},
		},

		bridge_narrow_broken2_s = {
			schem = {
				{file="bridge_narrow_broken2_s", force=false, adjust={x=3, y=7, z=4}},
			},
			size = {x=1, y=2, z=1},
		},

		bridge_narrow_short_ns = {
			schem = {
				{file="ns_bridge_narrow_short", force=false, adjust={x=3, y=7, z=0}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["+z"] = {
					{chunk="bridge_narrow_ns", chance=100},
					{chunk="bridge_narrow_platform_s", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_n", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="bridge_narrow_ns", chance=100, shift={x=0, y=0, z=-2}},
					{chunk="bridge_narrow_platform_n", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_s", fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_short_ew = {
			schem = {
				{file="ew_bridge_narrow_short", force=false, adjust={x=0, y=7, z=3}},
				{file="bridge_narrow_house", force=false, chance=20, adjust={x=3, y=11, z=3}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["+x"] = {
					{chunk="bridge_narrow_ew", chance=100},
					{chunk="bridge_narrow_platform_w", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_e", fallback=true, shift={x=0, y=0, z=0}},
				},
				["-x"] = {
					{chunk="bridge_narrow_ew", chance=100, shift={x=-2, y=0, z=0}},
					{chunk="bridge_narrow_platform_e", shift={x=0, y=0, z=0}},
					{chunk="bridge_narrow_broken2_w", fallback=true, shift={x=0, y=0, z=0}},
				},
			},
		},

		bridge_narrow_pillar_ns = {
			schem = {
				{file="bridge_narrow_pillar_ns", force=false, adjust={x=3, y=0, z=3}},
				{file="bridge_narrow_pillar_ns", force=false, adjust={x=3, y=11, z=3}},
				{file="bridge_narrow_pillar_ns", force=false, adjust={x=3, y=22, z=3}},
				{file="bridge_narrow_pillar_ns", force=false, adjust={x=3, y=33, z=3}},
			},
			size = {x=1, y=4, z=1},
		},

		bridge_narrow_pillar_ew = {
			schem = {
				{file="bridge_narrow_pillar_ew", force=false, adjust={x=3, y=0, z=3}},
				{file="bridge_narrow_pillar_ew", force=false, adjust={x=3, y=11, z=3}},
				{file="bridge_narrow_pillar_ew", force=false, adjust={x=3, y=22, z=3}},
				{file="bridge_narrow_pillar_ew", force=false, adjust={x=3, y=33, z=3}},
			},
			size = {x=1, y=4, z=1},
		},

		bridge_narrow_platform_w = {
			schem = {
				{file="bridge_narrow_platform", rotation="0", force=false, adjust={x=0, y=0, z=0}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_platform_pillar", fallback=true, shift={x=0, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_platform_n = {
			schem = {
				{file="bridge_narrow_platform", rotation="90", force=false, adjust={x=0, y=0, z=0}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_platform_pillar", fallback=true, shift={x=0, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_platform_e = {
			schem = {
				{file="bridge_narrow_platform", rotation="180", force=false, adjust={x=0, y=0, z=0}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_platform_pillar", fallback=true, shift={x=0, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_platform_s = {
			schem = {
				{file="bridge_narrow_platform", rotation="270", force=false, adjust={x=0, y=0, z=0}},
			},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {
					{chunk="bridge_narrow_platform_pillar", fallback=true, shift={x=0, y=-3, z=0}},
				},
			},
		},

		bridge_narrow_platform_pillar = {
			schem = {
				{file="bridge_narrow_platform_pillar", force=false, adjust={x=2, y=0, z=2}},
				{file="bridge_narrow_platform_pillar", force=false, adjust={x=2, y=11, z=2}},
				{file="bridge_narrow_platform_pillar", force=false, adjust={x=2, y=22, z=2}},
				{file="bridge_narrow_platform_pillar", force=false, adjust={x=2, y=33, z=2}},
			},
			size = {x=1, y=4, z=1},
		},
	},
}


-- Todo:
-- Add T-junctions & corners for bridge causeways.
-- Add 3-length passage chunks; alternate between 3 and 1-length chunks.
-- Add grand staircases (bridge and passage variants). (Note: maybe we don't want these? Fortresses should be 2D only ....)
-- Add connections between sections of gatehouse tower.
-- Allow fortress to generate off of gatehouse tower sections.
-- Add thicker pillar variants.
-- Add raised plaza.
-- Add lava-well room.
-- Add throne room.
-- Add balconies.
-- Add large plazas.
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
	  "ew_gatehouse",
		"ns_gatehouse",
		"ns_bridge_passage",
		"ew_bridge_passage",
	},

	-- Size of cells.
	-- This is how much the algorithm steps in a direction before generating the
	-- next chunk of fortress.
	step = {x=11, y=11, z=11},

	chunks = {
		-- Corridor sections.
		junction = {
			schem = {{file="nf_passage_4x_junction"}},
			next = {
				["+x"] = {
					{chunk="ew", chance=90, shift={x=0, y=0, z=0}},
					{chunk="w_capped"},
				},
				["+z"] = {
					{chunk="ns", chance=90},
					{chunk="s_capped"},
				},
				["-x"] = {
					{chunk="ew", chance=90},
					{chunk="e_capped"},
				},
				["-z"] = {
					{chunk="ns", chance=90},
					{chunk="n_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="junction_walk"}},
			}
		},
		ew = {
			schem = {{file="nf_passage_ew"}},
			next = {
				["+x"] = {
					{chunk="ew", chance=80},
					{chunk="ew_stair", chance=40},
					{chunk="ew_bridge_passage", chance=30},
					{chunk="sw_corner", chance=20},
					{chunk="nw_corner", chance=20},
					{chunk="swn_t", chance=10},
					{chunk="esw_t", chance=10},
					{chunk="wne_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="w_capped"},
				},
				["-x"] = {
					{chunk="ew", chance=80},
					{chunk="ew_stair", chance=40},
					{chunk="ew_bridge_passage", chance=30},
					{chunk="se_corner", chance=20},
					{chunk="ne_corner", chance=20},
					{chunk="wne_t", chance=10},
					{chunk="esw_t", chance=10},
					{chunk="nes_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="e_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="ew_walk"}},
			},
		},
		ns = {
			schem = {{file="nf_passage_ns"}},
			next = {
				["+z"] = {
					{chunk="ns", chance=60},
					{chunk="ns_stair", chance=40},
					{chunk="ns_bridge_passage", chance=20},
					{chunk="se_corner", chance=20},
					{chunk="sw_corner", chance=20},
					{chunk="nes_t", chance=10},
					{chunk="esw_t", chance=10},
					{chunk="swn_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="s_capped"},
				},
				["-z"] = {
					{chunk="ns", chance=60},
					{chunk="ns_stair", chance=40},
					{chunk="ns_bridge_passage", chance=20},
					{chunk="ne_corner", chance=20},
					{chunk="nw_corner", chance=20},
					{chunk="nes_t", chance=10},
					{chunk="wne_t", chance=10},
					{chunk="swn_t", chance=10},
					{chunk="junction", chance=20},
					{chunk="n_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="ns_walk"}},
			},
		},
		n_capped = {
			schem = {{file="nf_passage_n_capped"}},
			next = {
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="n_capped_walk"}},
			},
		},
		s_capped = {
			schem = {{file="nf_passage_s_capped"}},
			next = {
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="s_capped_walk"}},
			},
		},
		e_capped = {
			schem = {{file="nf_passage_e_capped"}},
			next = {
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="e_capped_walk"}},
			},
		},
		w_capped = {
			schem = {{file="nf_passage_w_capped"}},
			next = {
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="w_capped_walk"}},
			},
		},
		ne_corner = {
			schem = {{file="nf_passage_ne_corner"}},
			next = {
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped"},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="ne_corner_walk"}},
			},
		},
		nw_corner = {
			schem = {{file="nf_passage_nw_corner"}},
			next = {
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped"},
				},
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="nw_corner_walk"}},
			},
		},
		sw_corner = {
			schem = {{file="nf_passage_sw_corner"}},
			next = {
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped"},
				},
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="sw_corner_walk"}},
			},
		},
		se_corner = {
			schem = {{file="nf_passage_se_corner"}},
			next = {
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped"},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="se_corner_walk"}},
			},
		},
		esw_t = {
			schem = {{file="nf_passage_esw_t"}},
			next = {
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped"},
				},
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped"},
				},
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="esw_t_walk"}},
			},
		},
		nes_t = {
			schem = {{file="nf_passage_nes_t"}},
			next = {
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped"},
				},
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped"},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="nes_t_walk"}},
			},
		},
		swn_t = {
			schem = {{file="nf_passage_swn_t"}},
			next = {
				["-z"] = {
					{chunk="ns", chance=50},
					{chunk="n_capped"},
				},
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped"},
				},
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="swn_t_walk"}},
			},
		},
		wne_t = {
			schem = {{file="nf_passage_wne_t"}},
			next = {
				["-x"] = {
					{chunk="ew", chance=70},
					{chunk="e_capped"},
				},
				["+x"] = {
					{chunk="ew", chance=70},
					{chunk="w_capped"},
				},
				["+z"] = {
					{chunk="ns", chance=50},
					{chunk="s_capped"},
				},
				["-y"] = {{chunk="solid"}},
				["+y"] = {{chunk="wne_t_walk"}},
			},
		},

		-- Bridge/passage connections.
		ns_bridge_passage = {
			schem = {{file="nf_ns_passage_ew_bridge_access"}},
			offset = {x=-1, y=0, z=0},
			size = {x=3, y=1, z=1},
			limit = 4,
			next = {
				["+z"] = {{chunk="ns", shift={x=1, y=0, z=0}}},
				["-z"] = {{chunk="ns", shift={x=1, y=0, z=0}}},
				["+x"] = {{chunk="ew_walk_bridge", shift={x=2, y=0, z=0}}},
				["-x"] = {{chunk="ew_walk_bridge", shift={x=-2, y=0, z=0}}},
				["-y"] = {
					{chunk="bridge_arch_ew", shift={x=0, y=0, z=0}, continue=true},
					{chunk="bridge_arch_ew", shift={x=2, y=0, z=0}, continue=true},
					{chunk="solid", shift={x=1, y=0, z=0}},
				},
				["+y"] = {{chunk="ns_walk", shift={x=1, y=0, z=0}}},
			},
		},
		ew_bridge_passage = {
			schem = {{file="nf_ew_passage_ns_bridge_access"}},
			offset = {x=0, y=0, z=-1},
			size = {x=1, y=1, z=3},
			limit = 4,
			next = {
				["+x"] = {{chunk="ew", shift={x=0, y=0, z=1}}},
				["-x"] = {{chunk="ew", shift={x=0, y=0, z=1}}},
				["+z"] = {{chunk="ns_walk_bridge", shift={x=0, y=0, z=2}}},
				["-z"] = {{chunk="ns_walk_bridge", shift={x=0, y=0, z=-2}}},
				["-y"] = {
					{chunk="bridge_arch_ns", shift={x=0, y=0, z=0}, continue=true},
					{chunk="bridge_arch_ns", shift={x=0, y=0, z=2}, continue=true},
					{chunk="solid", shift={x=0, y=0, z=1}},
				},
				["+y"] = {{chunk="ew_walk", shift={x=0, y=0, z=1}}},
			},
		},

		-- Bridges.
		junction_walk_bridge = {
			schem = {{file="nf_walkway_4x_junction", force=false}},
			-- If number of chunks excees this limit, then algorithm reduces
			-- the chance by 10% for every unit over the limit. This affects
			-- all chunks which have this chunk as a possible follow-up.
			limit = 3,
			next = {
				["-y"] = {{chunk="bridge_pillar_top"}},
				["+x"] = {
					{chunk="ew_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="w_broken_walk", shift={x=0, y=0, z=0}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", shift={x=0, y=0, z=0}},
				},
				["+z"] = {
					{chunk="ns_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="s_broken_walk", shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="ns_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", shift={x=0, y=0, z=0}},
				},
			},
		},
		ew_walk_bridge = {
			schem = {
				{file="nf_walkway_ew", force=false, adjust={x=0, y=0, z=0}},
				{file="nf_walkway_ew", force=false, adjust={x=11, y=0, z=0}},
				{file="nf_walkway_ew", force=false, adjust={x=22, y=0, z=0}},
			},
			offset = {x=0, y=0, z=0},
			size = {x=3, y=1, z=1},
			next = {
				["+x"] = {
					{chunk="ew_walk_bridge_short", chance=50, shift={x=2, y=0, z=0}},
					{chunk="w_broken_walk", shift={x=2, y=0, z=0}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge_short", chance=50, shift={x=0, y=0, z=0}},
					{chunk="e_broken_walk", shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_pillar_ew", shift={x=0, y=0, z=0}, continue=true},
					{chunk="bridge_arch_ew", shift={x=1, y=0, z=0}, continue=true},
					{chunk="bridge_arch_pillar_ew", shift={x=2, y=0, z=0}, continue=true},
				},
			},
		},
		ns_walk_bridge = {
			schem = {
				{file="nf_walkway_ns", force=false, adjust={x=0, y=0, z=0}},
				{file="nf_walkway_ns", force=false, adjust={x=0, y=0, z=11}},
				{file="nf_walkway_ns", force=false, adjust={x=0, y=0, z=22}},
			},
			offset = {x=0, y=0, z=0},
			size = {x=1, y=1, z=3},
			next = {
				["+z"] = {
					{chunk="ns_walk_bridge_short", chance=80, shift={x=0, y=0, z=2}},
					{chunk="s_broken_walk", shift={x=0, y=0, z=2}},
				},
				["-z"] = {
					{chunk="ns_walk_bridge_short", chance=80, shift={x=0, y=0, z=0}},
					{chunk="n_broken_walk", shift={x=0, y=0, z=0}},
				},
				["-y"] = {
					{chunk="bridge_arch_pillar_ns", shift={x=0, y=0, z=0}, continue=true},
					{chunk="bridge_arch_ns", shift={x=0, y=0, z=1}, continue=true},
					{chunk="bridge_arch_pillar_ns", shift={x=0, y=0, z=2}, continue=true},
				},
			},
		},
		ew_walk_bridge_short = {
			schem = {
				{file="nf_walkway_ew", force=false},
			},
			next = {
				["+x"] = {
					{chunk="ew_gatehouse", chance=10, shift={x=0, y=0, z=0}},
					{chunk="ns_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ew_walk_bridge", shift={x=0, y=0, z=0}},
				},
				["-x"] = {
					{chunk="ew_gatehouse", chance=10, shift={x=-1, y=0, z=0}},
					{chunk="ns_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ew_walk_bridge", shift={x=-2, y=0, z=0}},
				},
				["-y"] = {{chunk="bridge_arch_ew"}},
			},
		},
		ns_walk_bridge_short = {
			schem = {
				{file="nf_walkway_ns", force=false},
			},
			next = {
				["+z"] = {
					{chunk="ns_gatehouse", chance=10, shift={x=0, y=0, z=0}},
					{chunk="ew_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ns_walk_bridge", shift={x=0, y=0, z=0}},
				},
				["-z"] = {
					{chunk="ns_gatehouse", chance=10, shift={x=0, y=0, z=-1}},
					{chunk="ew_bridge_passage", chance=20},
					{chunk="junction_walk_bridge", chance=20},
					{chunk="ns_walk_bridge", shift={x=0, y=0, z=-2}},
				},
				["-y"] = {{chunk="bridge_arch_ns"}},
			},
		},

		-- Walkways.
		junction_walk = {schem = {{file="nf_walkway_4x_junction", force=false}}},
		ew_walk = {schem = {{file="nf_walkway_ew", force=false}}},
		ns_walk = {schem = {{file="nf_walkway_ns", force=false}}},

		n_capped_walk = {
			schem = {{file="nf_walkway_n_capped", force=false}},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},
		s_capped_walk = {
			schem = {{file="nf_walkway_s_capped", force=false}},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},
		e_capped_walk = {
			schem = {{file="nf_walkway_e_capped", force=false}},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},
		w_capped_walk = {
			schem = {{file="nf_walkway_w_capped", force=false}},
			next = {
				["+y"] = {{chunk="tower", chance=50}},
			},
		},

		-- Broken causeway ends.
		n_broken_walk = {
			schem = {{file="nf_walkway_n_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_n"}},
			},
		},
		s_broken_walk = {
			schem = {{file="nf_walkway_s_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_s"}},
			},
		},
		e_broken_walk = {
			schem = {{file="nf_walkway_e_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_e"}},
			},
		},
		w_broken_walk = {
			schem = {{file="nf_walkway_w_broken", force=false}},
			next = {
				["-y"] = {{chunk="bridge_broken_walk_arch_w"}},
			},
		},

		ne_corner_walk = {schem = {{file="nf_walkway_ne_corner", force=false}}},
		nw_corner_walk = {schem = {{file="nf_walkway_nw_corner", force=false}}},
		sw_corner_walk = {schem = {{file="nf_walkway_sw_corner", force=false}}},
		se_corner_walk = {schem = {{file="nf_walkway_se_corner", force=false}}},
		esw_t_walk = {schem = {{file="nf_walkway_esw_t", force=false}}},
		nes_t_walk = {schem = {{file="nf_walkway_nes_t", force=false}}},
		swn_t_walk = {schem = {{file="nf_walkway_swn_t", force=false}}},
		wne_t_walk = {schem = {{file="nf_walkway_wne_t", force=false}}},

		ew_stair = {
			schem = {{file="nf_passage_ew_stair"}},
			next = {
				["+x"] = {
					{chunk="swn_t", chance=20},
					{chunk="wne_t", chance=20},
					{chunk="esw_t"},
				},
				["-x"] = {
					{chunk="wne_t", chance=20},
					{chunk="esw_t", chance=20},
					{chunk="nes_t"},
				},
				["+y"] = {{chunk="ew_walk_stair"}},
				["-y"] = {{chunk="solid"}},
			},
		},
		ew_walk_stair = {
			schem = {{file="nf_walkway_ew_stair"}},
		},
		ns_stair = {
			schem = {{file="nf_passage_ew_stair", rotation="90"}},
			next = {
				["+z"] = {
					{chunk="nes_t", chance=20},
					{chunk="swn_t", chance=20},
					{chunk="esw_t"},
				},
				["-z"] = {
					{chunk="nes_t", chance=10},
					{chunk="swn_t", chance=10},
					{chunk="wne_t"},
				},
				["+y"] = {{chunk="ns_walk_stair"}},
				["-y"] = {{chunk="solid"}},
			},
		},
		ns_walk_stair = {
			schem = {{file="nf_walkway_ew_stair", rotation="90", force=false}},
		},
		tower = {
			schem = {{file="nf_tower", force=false, adjust={x=3, y=-10, z=3}}},
		},

		-- Gatehouses.
		ew_gatehouse = {
			schem = {
				{file="nf_gatehouse_ew", adjust={x=0, y=0, z=7}},
				{file="nf_gatehouse_bridge_shim_w", force=false, adjust={x=0, y=-11, z=11}},
				{file="nf_gatehouse_bridge_shim_e", force=false, adjust={x=20, y=-11, z=11}},
			},
			offset = {x=0, y=0, z=-1},
			size = {x=2, y=1, z=3},
			limit = 2,
			next = {
				["+x"] = {
					{chunk="ew_walk_bridge_short", chance=80, shift={x=1, y=0, z=1}},
					{chunk="w_broken_walk", shift={x=1, y=0, z=1}},
				},
				["-x"] = {
					{chunk="ew_walk_bridge_short", chance=80, shift={x=0, y=0, z=1}},
					{chunk="e_broken_walk", shift={x=1, y=0, z=1}},
				},
				["-y"] = {{chunk="gatehouse_pillar_ew", shift={x=0, y=0, z=0}}},
			},
		},
		ns_gatehouse = {
			schem = {
				{file="nf_gatehouse_ns", adjust={x=7, y=0, z=0}},
				{file="nf_gatehouse_bridge_shim_s", force=false, adjust={x=11, y=-11, z=0}},
				{file="nf_gatehouse_bridge_shim_n", force=false, adjust={x=11, y=-11, z=20}},
			},
			offset = {x=-1, y=0, z=0},
			size = {x=3, y=1, z=2},
			limit = 2,
			next = {
				["+z"] = {
					{chunk="ns_walk_bridge_short", chance=80, shift={x=1, y=0, z=1}},
					{chunk="s_broken_walk", shift={x=1, y=0, z=1}},
				},
				["-z"] = {
					{chunk="ns_walk_bridge_short", chance=80, shift={x=1, y=0, z=0}},
					{chunk="n_broken_walk", shift={x=1, y=0, z=0}},
				},
				["-y"] = {{chunk="gatehouse_pillar_ns", shift={x=0, y=0, z=0}}},
			},
		},
		gatehouse_pillar_ew = {
			schem = {
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=0, z=7}},
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=11, z=7}},
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=22, z=7}},
				{file="nf_gatehouse_tower_ew", force=false, adjust={x=2, y=33, z=7}},
			},
			offset = {x=0, y=-3, z=0},
			size = {x=2, y=4, z=3},
		},
		gatehouse_pillar_ns = {
			schem = {
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=0, z=2}},
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=11, z=2}},
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=22, z=2}},
				{file="nf_gatehouse_tower_ns", force=false, adjust={x=7, y=33, z=2}},
			},
			offset = {x=0, y=-3, z=0},
			size = {x=3, y=4, z=2},
		},

		pillar = {
			schem = {{file="nf_pillar", force=false}},
			next = {
				["-y"] = {{chunk="pillar_straight"}},
			},
		},
		pillar_straight = {
			schem = {
				{file="nf_pillar_straight", force=false, adjust={x=3, y=0, z=3}},
				{file="nf_pillar_straight", force=false, adjust={x=3, y=11, z=3}},
				{file="nf_pillar_straight", force=false, adjust={x=3, y=22, z=3}},
			},
			size = {x=1, y=3, z=1},
			offset = {x=0, y=-2, z=0},
		},
		solid = {
			schem = {{file="nf_building_solid", force=false, adjust={x=0, y=0, z=0}}},
			offset = {x=0, y=0, z=0},
			size = {x=1, y=1, z=1},
			next = {
				["-y"] = {{chunk="pillar"}},
			},
		},

		-- Bridge arches & pillars.
		bridge_arch_ns = {
			schem = {{file="nf_bridge_arch_ns", force=false, adjust={x=0, y=6, z=0}}},
		},
		bridge_arch_ew = {
			schem = {{file="nf_bridge_arch_ew", force=false, adjust={x=0, y=6, z=0}}},
		},
		bridge_arch_pillar_ns = {
			schem = {{file="nf_bridge_arch_pillar_ns", force=false}},
			offset = {x=0, y=-1, z=0},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {{chunk="bridge_arch_pillar_bottom_ns"}},
			},
		},
		bridge_arch_pillar_ew = {
			schem = {{file="nf_bridge_arch_pillar_ew", force=false}},
			offset = {x=0, y=-1, z=0},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {{chunk="bridge_arch_pillar_bottom_ew"}},
			},
		},
		bridge_arch_pillar_bottom_ns = {
			schem = {
				{file="nf_bridge_arch_pillar_bottom_ns", force=false, adjust={x=0, y=0, z=3}},
				{file="nf_bridge_arch_pillar_bottom_ns", force=false, adjust={x=0, y=22, z=3}},
			},
			offset = {x=0, y=-3, z=0},
			size = {x=1, y=4, z=1},
		},
		bridge_arch_pillar_bottom_ew = {
			schem = {
				{file="nf_bridge_arch_pillar_bottom_ew", force=false, adjust={x=3, y=0, z=0}},
				{file="nf_bridge_arch_pillar_bottom_ew", force=false, adjust={x=3, y=22, z=0}},
			},
			offset = {x=0, y=-3, z=0},
			size = {x=1, y=4, z=1},
		},
		bridge_pillar_top = {
			schem = {{file="nf_center_pillar_top", force=false}},
			offset = {x=0, y=-1, z=0},
			size = {x=1, y=2, z=1},
			next = {
				["-y"] = {{chunk="bridge_pillar_bottom"}},
			},
		},
		bridge_pillar_bottom = {
			schem = {
				{file="nf_center_pillar_bottom", force=false, adjust={x=1, y=0, z=1}},
				{file="nf_center_pillar_bottom", force=false, adjust={x=1, y=22, z=1}},
			},
			offset = {x=0, y=-3, z=0},
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
	},
}

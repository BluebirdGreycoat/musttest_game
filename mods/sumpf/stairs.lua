
if rawget(_G, "stairs") then
	stairs.register_stair_and_slab("swampstone", "sumpf:junglestone",
		{cracky=3},
		{"sumpf_swampstone.png"},
		"swamp stone stair",
		"swamp stone slab",
		default.node_sound_stone_defaults()
	)

	stairs.register_stair_and_slab("swampcobble", "sumpf:cobble",
		{cracky=3},
		{"sumpf_cobble.png"},
		"swamp cobble stone stair",
		"swamp cobble stone slab",
		default.node_sound_stone_defaults()
	)

	stairs.register_stair_and_slab("swampstonebrick", "sumpf:junglestonebrick",
		{cracky=2, stone=1},
		{"sumpf_swampstone_brick.png"},
		"swamp stone brick stair",
		"swamp stone brick slab",
		default.node_sound_stone_defaults()
	)

	stairs.register_stair_and_slab("sumpf_roofing", "sumpf:roofing",
		{snappy = 3, flammable = 1, level = 2},
		{"sumpf_roofing.png"},
		"swamp grass roofing stair",
		"swamp grass roofing slab",
		default.node_sound_leaves_defaults()
	)
end

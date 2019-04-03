
tooldata = tooldata or {}

local modpath = minetest.get_modpath("tooldata")

tooldata["hammer_hammer"] = {
	full_punch_interval = 1.5,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[3]=3.00}, uses=500, maxlevel=1},
	},
	damage_groups = {fleshy=6, cracky=10},
}

tooldata["pick_wood"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_stone"] = {
	full_punch_interval = 2.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=2},
	},
	damage_groups = {fleshy=3, cracky=7},
}

tooldata["pick_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=2},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_bronze"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_silver"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_mithril"] = {
	full_punch_interval = 1.0,
	max_drop_level = 4,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_rubystone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_emeraldstone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_sapphirestone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["pick_amethyststone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_stone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_bronze"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_silver"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_mithril"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_rubystone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_emeraldstone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_sapphirestone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_amethyststone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_stone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_bronze"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_silver"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_mithril"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_rubystone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_emeraldstone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_sapphirestone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_amethyststone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_stone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_bronze"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_silver"] = {
	full_punch_interval = 0.9,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=7},
}

tooldata["sword_mithril"] = {
	full_punch_interval = 0.9,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=14},
}

tooldata["sword_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=7, cracky=7, crumbly=1},
}

tooldata["sword_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=5, cracky=1, crumbly=10},
}

tooldata["sword_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=8, cracky=1, crumbly=1},
}

tooldata["sword_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 4,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=10, cracky=1, crumbly=1},
}

tooldata["sword_rubystone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=12, crumbly=1},
}

tooldata["sword_emeraldstone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=5, cracky=1, crumbly=10},
}

tooldata["sword_sapphirestone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=7, cracky=10, crumbly=2},
}

tooldata["sword_amethyststone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 4,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=8, cracky=10, crumbly=1},
}

tooldata["shears_shears"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		snappy = {times={[3]=0.30}, uses=50, maxlevel=1},
	},
}

tooldata["hand_hand"] = {
	full_punch_interval = 0.8,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[3]=5.00}, uses=0, maxlevel=1},
		snappy = {times={[3]=3.00}, uses=0, maxlevel=1},
		oddly_breakable_by_hand = {times={[1]=5.00, [2]=4.00, [3]=3.00}, uses=0},
	},
	damage_groups = {fleshy=1},
}

dofile(modpath .. "/technic.lua")

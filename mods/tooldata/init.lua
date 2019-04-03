-- ToolData mod by MustTest.
--
-- The goal is to get all tool information into a single file to make comparison
-- and adjustment much easier.
--
-- All tools should dig nodes taking not more than 2 seconds per node, a fairly
-- reasonable rate. The early-game toolsets should distinguish mainly based on
-- max drop level and amount of wear taken.
--
-- Starting toolset: wood. Not craftable, and very slow digging is ok.
--
-- Early-game toolsets: stone, iron, copper. These should perform similarly,
-- especially stone since player might get bored if stone digs too slowly and
-- they don't soon find iron or copper.

tooldata = tooldata or {}
local modpath = minetest.get_modpath("tooldata")

--------------------------------------------------------------------------------
-- MISC TOOLS
--------------------------------------------------------------------------------

-- Hammer (usually an anvil-repair tool).
tooldata["hammer_hammer"] = {
	full_punch_interval = 1.5,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[3]=3.00}, uses=500, maxlevel=1},
	},
	damage_groups = {fleshy=6, cracky=10},
}

-- Excellent for crops/leaves, worthless for anything else.
tooldata["shears_shears"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		snappy = {times={[3]=0.30}, uses=70, maxlevel=1},
	},
}

-- The hand. Slow to dig, but dig plants/crops in 1 second.
tooldata["hand_hand"] = {
	full_punch_interval = 0.8,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[3]=5.00}, uses=0, maxlevel=1},
		snappy = {times={[3]=3.00}, uses=0, maxlevel=1},
		cracky = {times={[3]=6.00}, uses=0, maxlevel=0}, -- Can dig very weak, soft stone, if long time enough.
		oddly_breakable_by_hand = {times={[1]=5.00, [2]=2.00, [3]=1.00}, uses=0},
	},
	damage_groups = {fleshy=1},
}

--------------------------------------------------------------------------------
-- WOOD TOOLS
--------------------------------------------------------------------------------

-- Player's starting pick.
-- Start plan: find dry shrub, get sticks. Dig cobble underneath, get cobble.
-- Upgrade to stone tools ASAP.
tooldata["pick_wood"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1, -- Must be 1 otherwise cobble unobtainable.
	groupcaps = {
		cracky = {times={[3]=6.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1, crumbly=1},
}

--------------------------------------------------------------------------------
-- STONE TOOLS: High punch interval, cracky mob damage.
--------------------------------------------------------------------------------
tooldata["pick_stone"] = {
	full_punch_interval = 2.0,
	max_drop_level = 2, -- Must be 2 otherwise stone unobtainable.
	groupcaps = {
		cracky = {times={[2]=2.00, [3]=1.90}, uses=50, maxlevel=2},
	},
	damage_groups = {fleshy=3, cracky=7, crumbly=1},
}

tooldata["shovel_stone"] = {
	full_punch_interval = 2.0,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[2]=2.00, [3]=1.90}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=5, crumbly=1},
}

tooldata["axe_stone"] = {
	full_punch_interval = 1.5,
	max_drop_level = 2, -- Must be 2 otherwise can't get tree drops.
	groupcaps = {
		choppy = {times={[2]=2.00, [3]=0.90}, uses=50, maxlevel=2},
	},
	damage_groups = {fleshy=3, cracky=7, crumbly=1},
}

tooldata["sword_stone"] = {
	full_punch_interval = 1.5,
	max_drop_level = 0, -- Not good at getting drops from mobs.
	groupcaps = {
		-- Should be slightly faster at digging plants than the hand.
		snappy = {times={[2]=1.10, [3]=0.90}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=4, cracky=20, crumbly=1},
}

--------------------------------------------------------------------------------
-- IRON TOOLS: Dig slightly faster than stone, last much longer. Get all drops.
--------------------------------------------------------------------------------
tooldata["pick_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2, -- Must be 2 otherwise stone unobtainable.
	groupcaps = {
		cracky = {times={[1]=4.00, [2]=1.60, [3]=1.50}, uses=150, maxlevel=2},
	},
	damage_groups = {fleshy=3, cracky=1, crumbly=1},
}

tooldata["shovel_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[1]=4.00, [2]=1.60, [3]=1.40}, uses=150, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1, crumbly=1},
}

tooldata["axe_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		choppy = {times={[1]=2.20, [2]=1.90, [3]=0.80}, uses=150, maxlevel=2},
	},
	damage_groups = {fleshy=5, cracky=1, crumbly=1},
}

tooldata["sword_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=2.00, [2]=1.00, [3]=0.80}, uses=150, maxlevel=2},
	},
	damage_groups = {fleshy=6, cracky=1, crumbly=1},
}

--------------------------------------------------------------------------------
-- COPPER TOOLS: Dig faster than steel, poor drops, poor wear handling.
--------------------------------------------------------------------------------

-- Early-obtainable pick with "magical" properties: fast dig, but very poor drops.
tooldata["pick_bronze"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=0.20, [2]=0.20, [3]=0.20}, uses=30, maxlevel=2},
	},
	damage_groups = {fleshy=3, cracky=1, crumbly=1},
}

tooldata["shovel_bronze"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=3.00, [2]=1.40, [3]=0.90}, uses=30, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1, crumbly=1},
}

tooldata["axe_bronze"] = {
	full_punch_interval = 0.8,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=1.80, [2]=1.50, [3]=0.80}, uses=30, maxlevel=2},
	},
	damage_groups = {fleshy=4, cracky=1, crumbly=1},
}

tooldata["sword_bronze"] = {
	full_punch_interval = 0.9,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=0.60, [2]=0.60, [3]=0.60}, uses=30, maxlevel=2},
	},
	damage_groups = {fleshy=4, cracky=1, crumbly=1}, -- Not good damage rel/to steel.
}

--------------------------------------------------------------------------------
-- MESE TOOLS
--------------------------------------------------------------------------------
tooldata["pick_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		cracky = {times={[1]=2.40, [2]=1.20, [3]=0.60}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=6, cracky=2, crumbly=1},
}

tooldata["shovel_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
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

tooldata["sword_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

--------------------------------------------------------------------------------
-- DIAMOND TOOLS
--------------------------------------------------------------------------------
tooldata["pick_diamond"] = {
	full_punch_interval = 0.9,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=2.00, [2]=1.00, [3]=0.50}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=5, cracky=1, crumbly=1},
}

tooldata["shovel_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
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

tooldata["sword_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

--------------------------------------------------------------------------------
-- TITANIUM TOOLS
--------------------------------------------------------------------------------
tooldata["pick_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=200, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=200, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=200, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=200, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

--------------------------------------------------------------------------------
-- SILVER TOOLS
--------------------------------------------------------------------------------
tooldata["pick_silver"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
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

tooldata["axe_silver"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
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

--------------------------------------------------------------------------------
-- MITHRIL TOOLS
--------------------------------------------------------------------------------
tooldata["pick_mithril"] = {
	full_punch_interval = 1.0,
	max_drop_level = 4,
	groupcaps = {
		cracky = {times={[1]=1.90, [2]=0.80, [3]=0.60}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=5, crumbly=1},
}

tooldata["shovel_mithril"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
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

-- Fast, high-damage sword, but poor for drops or farming.
tooldata["sword_mithril"] = {
	full_punch_interval = 0.9,
	max_drop_level = 1,
	groupcaps = {
		snappy = {times={[1]=2.50, [2]=2.00, [3]=1.90}, uses=50, maxlevel=2},
	},
	damage_groups = {fleshy=16},
}

--------------------------------------------------------------------------------
-- RUBY TOOLS
--------------------------------------------------------------------------------
tooldata["pick_ruby"] = {
	full_punch_interval = 1.5,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=0.20, [2]=0.20, [3]=0.20}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=5, cracky=1},
}

tooldata["shovel_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=7, cracky=7, crumbly=1},
}

--------------------------------------------------------------------------------
-- EMERALD TOOLS
--------------------------------------------------------------------------------
tooldata["pick_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=2.00, [2]=1.00, [3]=0.50}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=5, cracky=1, crumbly=10},
}

--------------------------------------------------------------------------------
-- SAPPHIRE TOOLS
--------------------------------------------------------------------------------
tooldata["pick_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=2.00, [2]=1.00, [3]=0.50}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=8, cracky=1, crumbly=1},
}

--------------------------------------------------------------------------------
-- AMETHYST TOOLS
--------------------------------------------------------------------------------
tooldata["pick_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=2.00, [2]=1.00, [3]=0.50}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

-- Medium-damage sword, good for mob drops but poor at farming.
tooldata["sword_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 4,
	groupcaps = {
		snappy = {times={[1]=2.00, [2]=1.90, [3]=1.80}, uses=50, maxlevel=2},
	},
	damage_groups = {fleshy=10, cracky=1, crumbly=1},
}

--------------------------------------------------------------------------------
-- REINFORCED RUBY TOOLS
--------------------------------------------------------------------------------
tooldata["pick_rubystone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_rubystone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_rubystone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_rubystone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=2, cracky=12, crumbly=1},
}

--------------------------------------------------------------------------------
-- REINFORCED EMERALD TOOLS
--------------------------------------------------------------------------------
tooldata["pick_emeraldstone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_emeraldstone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_emeraldstone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_emeraldstone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=5, cracky=1, crumbly=10},
}

--------------------------------------------------------------------------------
-- REINFORCED SAPPHIRE TOOLS
--------------------------------------------------------------------------------
tooldata["pick_sapphirestone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_sapphirestone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_sapphirestone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=4},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["sword_sapphirestone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
		choppy = {times={[2]=9.00, [3]=9.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=7, cracky=10, crumbly=2},
}

--------------------------------------------------------------------------------
-- REINFORCED AMETHYST TOOLS
--------------------------------------------------------------------------------
tooldata["pick_amethyststone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["shovel_amethyststone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

tooldata["axe_amethyststone"] = {
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[1]=9.00, [2]=9.00, [3]=9.00}, uses=50, maxlevel=3},
	},
	damage_groups = {fleshy=2, cracky=1},
}

-- Slower, high-damage sword, poor at farming but good for mob drops.
tooldata["sword_amethyststone"] = {
	full_punch_interval = 1.2,
	max_drop_level = 4,
	groupcaps = {
		snappy = {times={[1]=2.00, [2]=1.90, [3]=1.80}, uses=50, maxlevel=2},
		choppy = {times={[2]=3.00, [3]=1.00}, uses=50, maxlevel=1},
	},
	damage_groups = {fleshy=8, cracky=10, crumbly=1},
}

dofile(modpath .. "/technic.lua")

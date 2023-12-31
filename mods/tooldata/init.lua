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
-- they don't soon find iron or copper. Note: copper should have better
-- dig-times than diamond, but not better than gem tools. However copper makes
-- NO drops.
--
-- Mid-level (pro) toolsets: mese, diamond & mithril. Mese, diamond, & mithril
-- gradually improve their dig-times in the order listed. Average dig times are
-- between iron and gem tools. Copper tools should have the best dig-times
-- (except for gem tools), but neither do copper tools produce drops.
--
-- Drops from mese tools go directly to player's inventory. Diamond & mithril
-- tools both increase the player's XP gain. These are the ONLY tools to do
-- this.
--
-- Expert-level toolsets: gem tools + reinforced gem tools.
--
-- 1) Gem Tools (inc. Reinforced Gem Tools): these dig faster than any other
-- tools in the game, while having perfect drops. Worse wear handling than
-- titanium but better than steel. The reinforced versions' dig-times are nearly
-- the same as the regular gem tools, but their wear handling is as good as
-- titanium.
--
-- Note that gem tools specialize: ruby makes best picks, emerald makes best
-- shovels, sapphire makes best axes, and amethyst makes best swords. These
-- tools are better than their gem peers in terms of slightly better wear
-- handling and slightly faster dig-times.
--
-- Except for fast digging and perfect drops, gem tools don't have any special
-- or unusual properties.
--
-- Silver tools: a special toolset that changes node drop behavior. Otherwise,
-- these tools should have iron dig-times, but wear out quickly like copper.
-- Silver tools max out at level 2, so nodes with levels 3/4 won't be able to
-- make use of special silver-tool drops.
--
-- Titanium tools: another special toolset. Slightly faster dig times than iron
-- (but not nearly as fast as copper), last MUCH longer, but have poorer drops.
--
-- Notes on level difference divider: the division is simple (though not
-- explained at all in the Lua API document). So for instance, if a node has
-- `level = 2` and a tool has `maxlevel = 4` in one of its dig groups, then
-- that simply means that all dig-times for that dig group are divided in half.
-- `4 - 2 = 2`, so all dig-times are `dig-time / 2`. If the level difference is
-- 1 (node is level 3, tool is maxlevel 4), then the level difference divider
-- still "kicks in", but since the difference is just 1 there is no effect on
-- actual digging times.
--
-- Further note: all picks do excellent damage (better than swords), but have
-- long swing time, so they're only good as first-strike weapons, then switching
-- to a sword is better.

if not minetest.global_exists("tooldata") then tooldata = {} end
if not minetest.global_exists("td_api") then td_api = {} end
local modpath = minetest.get_modpath("tooldata")
td_api.modpath = modpath

local SCALE = 500

--------------------------------------------------------------------------------
-- MISC TOOLS
--------------------------------------------------------------------------------

-- Hammer (usually an anvil-repair tool).
tooldata["hammer_hammer"] = {
	full_punch_interval = 3.5,
	max_drop_level = 0,
	groupcaps = {
		cracky = {times={[3]=3.00}, uses=500, maxlevel=1},
	},
}

-- Excellent for crops/leaves, worthless for anything else.
tooldata["shears_shears"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		snappy = {times={[3]=0.10}, uses=300, maxlevel=1},
	},
}

-- The hand. Slow to dig, but dig plants/crops in 1 second.
tooldata["hand_hand"] = {
	full_punch_interval = 0.8,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[3]=5.00}, uses=0, maxlevel=0},
		snappy = {times={[3]=1.00}, uses=0, maxlevel=0}, -- Dig plants in 1 second.
		cracky = {times={[3]=6.00}, uses=0, maxlevel=0}, -- Can dig very weak, soft stone, if long time enough.
		oddly_breakable_by_hand = {times={[1]=5.00, [2]=4.00, [3]=3.00}, uses=0},
	},

	-- Note: bypassing sysdmg code due to use of 'minetest.register_item()' for
	-- the Hand.
	damage_groups = {fleshy=1*(SCALE/2), knockback=100},
}

--------------------------------------------------------------------------------
-- WOOD TOOLS
--------------------------------------------------------------------------------

-- Player's starting pick.
-- Start plan: find dry shrub, get sticks. Dig cobble underneath, get cobble.
-- Upgrade to stone tools ASAP.
tooldata["pick_wood"] = {
	full_punch_interval = 2.0,
	max_drop_level = 1, -- Must be 1 otherwise cobble unobtainable.
	groupcaps = {
		cracky = {times={[3]=6.00}, uses=50, maxlevel=1},
	},

}

--------------------------------------------------------------------------------
-- STONE TOOLS: High punch interval, cracky mob damage.
--------------------------------------------------------------------------------
tooldata["pick_stone"] = {
	full_punch_interval = 3.0,
	max_drop_level = 2, -- Must be 2 otherwise stone unobtainable.
	groupcaps = {
		cracky = {times={[2]=2.00, [3]=1.90}, uses=50, maxlevel=2},
	},

	dig_exhaustion_modifier = 1.5,
}

tooldata["shovel_stone"] = {
	full_punch_interval = 2.0,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[2]=2.00, [3]=1.90}, uses=50, maxlevel=2},
	},

}

tooldata["axe_stone"] = {
	full_punch_interval = 1.5,
	max_drop_level = 2, -- Must be 2 otherwise can't get tree drops.
	groupcaps = {
		choppy = {times={[2]=2.00, [3]=0.90}, uses=50, maxlevel=2},
	},

}

tooldata["sword_stone"] = {
	full_punch_interval = 1.5,
	max_drop_level = 0, -- Not good at getting drops from mobs.
	groupcaps = {
		-- Should be slightly faster at digging plants than the hand.
		snappy = {times={[2]=1.10, [3]=0.90}, uses=50, maxlevel=1},
	},

}

--------------------------------------------------------------------------------
-- IRON TOOLS: Dig slightly faster than stone, last much longer. Get all drops.
--------------------------------------------------------------------------------
tooldata["pick_steel"] = {
	full_punch_interval = 3.0,
	max_drop_level = 2, -- Must be 2 otherwise stone unobtainable.
	groupcaps = {
		cracky = {times={[1]=4.00, [2]=1.20, [3]=1.10}, uses=150, maxlevel=2},
	},

	dig_exhaustion_modifier = 0.8,
}

tooldata["shovel_steel"] = {
	full_punch_interval = 1.5,
	max_drop_level = 2,
	groupcaps = {
		crumbly = {times={[1]=4.00, [2]=1.20, [3]=1.10}, uses=150, maxlevel=2},
	},

	dig_exhaustion_modifier = 0.8,
}

tooldata["axe_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		choppy = {times={[1]=2.20, [2]=1.20, [3]=0.80}, uses=150, maxlevel=2},
	},

	dig_exhaustion_modifier = 0.7,
}

tooldata["sword_steel"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=2.00, [2]=1.20, [3]=0.80}, uses=150, maxlevel=2},
	},

	dig_exhaustion_modifier = 0.5,
}

--------------------------------------------------------------------------------
-- COPPER TOOLS: Dig faster than steel, very poor drops, poor wear handling.
--------------------------------------------------------------------------------

-- Early-obtainable pick with "magical" properties: fast dig, but poor drops.
-- These tools are just copper tools, craftable from copper ingots.

tooldata["pick_bronze"] = {
	full_punch_interval = 3.0,
	max_drop_level = 0,
	groupcaps = {
		-- Improved wear handling, otherwise players may not find it worth it.
		cracky = {times={[2]=0.40, [3]=0.40}, uses=250, maxlevel=2},
	},

}

tooldata["shovel_bronze"] = {
	full_punch_interval = 1.5,
	max_drop_level = 0,
	groupcaps = {
		crumbly = {times={[2]=0.40, [3]=0.40}, uses=150, maxlevel=2},
	},

}

tooldata["axe_bronze"] = {
	full_punch_interval = 0.8,
	max_drop_level = 0,
	groupcaps = {
		choppy = {times={[2]=0.30, [3]=0.30}, uses=150, maxlevel=2},
	},

}

tooldata["sword_bronze"] = {
	full_punch_interval = 0.9,
	max_drop_level = -1, -- No drops, so only worth it versus mobs.
	groupcaps = {
		-- Sword wears out rather quick, though.
		snappy = {times={[2]=0.60, [3]=0.60}, uses=120, maxlevel=2},
	},

}

--------------------------------------------------------------------------------
-- BRONZE TOOLS: Dig faster than steel, very poor drops, poor wear handling.
--------------------------------------------------------------------------------

-- Early-obtainable pick with "magical" properties: fast dig, but poor drops.

tooldata["pick_bronze2"] = {
	full_punch_interval = 3.0,
	max_drop_level = 1,
	groupcaps = {
		-- Improved wear handling, otherwise players may not find it worth it.
		cracky = {times={[2]=0.40, [3]=0.40}, uses=250, maxlevel=2},
	},

}

tooldata["shovel_bronze2"] = {
	full_punch_interval = 1.5,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[2]=0.40, [3]=0.40}, uses=150, maxlevel=2},
	},

}

tooldata["axe_bronze2"] = {
	full_punch_interval = 0.8,
	max_drop_level = 1,
	groupcaps = {
		choppy = {times={[2]=0.30, [3]=0.30}, uses=150, maxlevel=2},
	},

}

tooldata["sword_bronze2"] = {
	full_punch_interval = 0.9,
	max_drop_level = 0,
	groupcaps = {
		-- Sword wears out rather quick, though.
		snappy = {times={[2]=0.60, [3]=0.60}, uses=120, maxlevel=2},
	},

}

--------------------------------------------------------------------------------
-- MESE TOOLS: perfect drops, faster than steel, slightly worse wear handling.
--------------------------------------------------------------------------------
tooldata["pick_mese"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=2.20, [2]=0.80, [3]=0.60}, uses=100, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 10,
}

tooldata["shovel_mese"] = {
	full_punch_interval = 1.5,
	max_drop_level = 3,
	groupcaps = {
		crumbly = {times={[1]=2.20, [2]=0.80, [3]=0.60}, uses=100, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 10,
}

tooldata["axe_mese"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=2.20, [2]=0.80, [3]=0.60}, uses=100, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 10,

	node_overrides = {
		["rosestone:head"] = {
			max_drop_level = 3,
			destroy_chance = nil,
			direct_to_inventory = true,
		},
		["rosestone:tail"] = {
			max_drop_level = 3,
			destroy_chance = nil,
			direct_to_inventory = true,
		},
	},
}

tooldata["sword_mese"] = {
	full_punch_interval = 0.9,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=2.20, [2]=0.80, [3]=0.60}, uses=100, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 10,
}

--------------------------------------------------------------------------------
-- DIAMOND TOOLS: improved XP gain, poor drops, faster than mese.
--------------------------------------------------------------------------------
tooldata["pick_diamond"] = {
	full_punch_interval = 3.0,
	max_drop_level = 2,
	groupcaps = {
		cracky = {times={[1]=2.00, [2]=0.60, [3]=0.50}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	range_modifier = 1.5,
}

tooldata["shovel_diamond"] = {
	full_punch_interval = 1.5,
	max_drop_level = 2,
	groupcaps = {
		crumbly = {times={[1]=2.00, [2]=0.60, [3]=0.50}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	range_modifier = 1.5,
}

tooldata["axe_diamond"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		choppy = {times={[1]=2.00, [2]=0.60, [3]=0.50}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	range_modifier = 1.5,

	node_overrides = {
		["rosestone:head"] = {
			max_drop_level = 3,
		},
		["rosestone:tail"] = {
			max_drop_level = 3,
		},
	},
}

-- Reasonably high-damage sword (until gem tools), but gives poor drops.
tooldata["sword_diamond"] = {
	full_punch_interval = 0.8,
	max_drop_level = 2,
	groupcaps = {
		snappy = {times={[1]=2.00, [2]=0.60, [3]=0.50}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	range_modifier = 1.5,
}

--------------------------------------------------------------------------------
-- MITHRIL TOOLS: improved XP gain, decent drops, faster than diamond.
--------------------------------------------------------------------------------
tooldata["pick_mithril"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3, -- Strictly better than diamond.
	groupcaps = {
		cracky = {times={[1]=1.80, [2]=0.40, [3]=0.30}, uses=80, maxlevel=3},
	},

	xp_gain = 2.5,
	dig_exhaustion_modifier = 0.6,
	destroy_chance = 5,
}

tooldata["shovel_mithril"] = {
	full_punch_interval = 1.5,
	max_drop_level = 2,
	groupcaps = {
		crumbly = {times={[1]=1.80, [2]=0.40, [3]=0.30}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	dig_exhaustion_modifier = 0.7,
}

tooldata["axe_mithril"] = {
	full_punch_interval = 1.0,
	max_drop_level = 2,
	groupcaps = {
		choppy = {times={[1]=1.80, [2]=0.40, [3]=0.30}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	dig_exhaustion_modifier = 0.5,
	destroy_chance = 15,
}

-- Fast, high-damage sword VS mobs, but gives poor drops.
tooldata["sword_mithril"] = {
	full_punch_interval = 0.7, -- Same as amethyst.
	max_drop_level = 2, -- But less than amethyst.
	groupcaps = {
		snappy = {times={[1]=1.80, [2]=0.40, [3]=0.30}, uses=80, maxlevel=3},
	},

	xp_gain = 1.5,
	dig_exhaustion_modifier = 0.5,
}

--------------------------------------------------------------------------------
-- TITANIUM TOOLS
--------------------------------------------------------------------------------
tooldata["pick_titanium"] = {
	full_punch_interval = 3.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=3.60, [2]=1.00, [3]=0.80}, uses=350, maxlevel=2},
	},

	direct_to_inventory = true,

	-- Enable titanium pick to dig these nodes specially!
	-- Note: if one flag is overridden, then all must be specified, otherwise initial flags will be ignored.
	-- Only builtin engine parameters are exempt.
	node_overrides = {
		["default:stone_with_coal"] = {
			max_drop_level = 2,
			direct_to_inventory = true,
		},
		["default:stone_with_iron"] = {
			max_drop_level = 2,
			direct_to_inventory = true,
		},
		["default:stone_with_copper"] = {
			max_drop_level = 2,
			direct_to_inventory = true,
		},
		["kalite:ore"] = {
			max_drop_level = 2,
			direct_to_inventory = true,
		},
		["moreores:mineral_tin"] = {
			max_drop_level = 2,
			direct_to_inventory = true,
		},
	},
}

tooldata["shovel_titanium"] = {
	full_punch_interval = 1.5,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[1]=3.50, [2]=1.00, [3]=0.80}, uses=350, maxlevel=2},
	},

	direct_to_inventory = true,
}

tooldata["axe_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		choppy = {times={[1]=2.10, [2]=1.00, [3]=0.70}, uses=350, maxlevel=2},
	},

	direct_to_inventory = true,
}

tooldata["sword_titanium"] = {
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcaps = {
		snappy = {times={[1]=1.90, [2]=1.00, [3]=0.70}, uses=350, maxlevel=2},
	},

	direct_to_inventory = true,
}

--------------------------------------------------------------------------------
-- SILVER TOOLS: Excellent drops (+ special drop code elsewhere). Poor wear.
--------------------------------------------------------------------------------

-- Silver tools can be dual-purposed, but their secondary purpose isn't performed
-- as well as it could be if the correct tool was used.
-- Note: must be able to pick level 3 nodes, otherwise nodes at that level won't
-- be able to work with special silverpick drops.

tooldata["pick_silver"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=1.50, [2]=1.00, [3]=0.50}, uses=30, maxlevel=3},
		snappy = {times={[1]=2.00, [2]=1.50, [3]=1.00}, uses=20, maxlevel=1}, -- Secondary.
	},

}

tooldata["shovel_silver"] = {
	full_punch_interval = 1.5,
	max_drop_level = 3,
	groupcaps = {
		crumbly = {times={[1]=1.50, [2]=1.00, [3]=0.50}, uses=30, maxlevel=3},
		snappy = {times={[1]=2.00, [2]=1.50, [3]=1.00}, uses=20, maxlevel=1}, -- Secondary.
	},

}

tooldata["axe_silver"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		-- The silver axe can do both choppy and snappy jobs equally well.
		choppy = {times={[1]=1.50, [2]=1.00, [3]=0.50}, uses=30, maxlevel=3},
		snappy = {times={[1]=2.00, [2]=1.50, [3]=1.00}, uses=20, maxlevel=2}, -- Secondary.
	},

}

tooldata["sword_silver"] = {
	full_punch_interval = 0.9,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.50, [2]=1.00, [3]=0.50}, uses=30, maxlevel=3},
		choppy = {times={[1]=2.00, [2]=1.50, [3]=1.00}, uses=20, maxlevel=1}, -- Secondary.
	},

}

--------------------------------------------------------------------------------
-- RUBY TOOLS: Better wear handling than steel. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_ruby"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true, -- Item goes directly to player inventory, no dropping.
	xp_gain = 0.3,
	destroy_chance = 20, -- 50/1000
	--dig_exhaustion_modifier = 100.0, -- For testing! (Tested, works.)
}

tooldata["shovel_ruby"] = {
	full_punch_interval = 1.5,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_ruby"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_ruby"] = {
	full_punch_interval = 0.8,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=200, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

--------------------------------------------------------------------------------
-- EMERALD TOOLS: Better wear handling than steel. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_emerald"] = {
	full_punch_interval = 3.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["shovel_emerald"] = {
	full_punch_interval = 1.5,
	max_drop_level = 3,
	groupcaps = {
		crumbly = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_emerald"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=200, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_emerald"] = {
	full_punch_interval = 0.8,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

--------------------------------------------------------------------------------
-- SAPPHIRE TOOLS: Better wear handling than steel. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_sapphire"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=200, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["shovel_sapphire"] = {
	full_punch_interval = 1.5,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_sapphire"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_sapphire"] = {
	full_punch_interval = 0.8,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

--------------------------------------------------------------------------------
-- AMETHYST TOOLS: Better wear handling than steel. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_amethyst"] = {
	full_punch_interval = 3.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["shovel_amethyst"] = {
	full_punch_interval = 1.5,
	max_drop_level = 3,
	groupcaps = {
		crumbly = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=200, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_amethyst"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=170, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_amethyst"] = {
	full_punch_interval = 0.7,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
	range_modifier = 1.5,
}

--------------------------------------------------------------------------------
-- REINFORCED RUBY TOOLS: Wear handling like titanium. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_ruby_rf"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=300, maxlevel=3},
	},

	direct_to_inventory = true,
	xp_gain = 0.3,
	destroy_chance = 20,
}

tooldata["shovel_ruby_rf"] = {
	full_punch_interval = 1.5,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_ruby_rf"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_ruby_rf"] = {
	full_punch_interval = 0.8,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

--------------------------------------------------------------------------------
-- REINFORCED EMERALD TOOLS: Wear handling like titanium. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_emerald_rf"] = {
	full_punch_interval = 3.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["shovel_emerald_rf"] = {
	full_punch_interval = 1.5,
	max_drop_level = 3,
	groupcaps = {
		crumbly = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=300, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_emerald_rf"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_emerald_rf"] = {
	full_punch_interval = 0.8,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

--------------------------------------------------------------------------------
-- REINFORCED SAPPHIRE TOOLS: Wear handling like titanium. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_sapphire_rf"] = {
	full_punch_interval = 3.0,
	max_drop_level = 3,
	groupcaps = {
		cracky = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["shovel_sapphire_rf"] = {
	full_punch_interval = 1.5,
	max_drop_level = 1,
	groupcaps = {
		crumbly = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_sapphire_rf"] = {
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=300, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_sapphire_rf"] = {
	full_punch_interval = 0.8,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

--------------------------------------------------------------------------------
-- REINFORCED AMETHYST TOOLS: Wear handling like titanium. Fast, perfect drops.
--------------------------------------------------------------------------------
tooldata["pick_amethyst_rf"] = {
	full_punch_interval = 3.0,
	max_drop_level = 1,
	groupcaps = {
		cracky = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["shovel_amethyst_rf"] = {
	full_punch_interval = 1.5,
	max_drop_level = 3,
	groupcaps = {
		crumbly = {times={[1]=1.40, [2]=0.20, [3]=0.20}, uses=250, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["axe_amethyst_rf"] = {
	full_punch_interval = 1.0,
  max_drop_level = 3,
	groupcaps = {
		choppy = {times={[1]=1.50, [2]=0.30, [3]=0.30}, uses=230, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
}

tooldata["sword_amethyst_rf"] = {
	full_punch_interval = 0.7,
	max_drop_level = 3,
	groupcaps = {
		snappy = {times={[1]=1.40, [2]=0.10, [3]=0.10}, uses=300, maxlevel=3},
	},

	direct_to_inventory = true,
	destroy_chance = 20,
	range_modifier = 1.5,
}

function td_api.arrow_toolcaps(name, damage)
	--minetest.log(name)
	local tc = {
		full_punch_interval = 1.0,
		max_drop_level = 3,
		damage_groups = {
			arrow = damage,
			from_arrow = 0,
			knockback = 400,
		},
	}
	-- This table gets sent through the engine, so only builtin parameters work.
	return tc
end

dofile(modpath .. "/technic.lua")

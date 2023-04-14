-- mods/default/nodes.lua


--[[ Node name convention:

Although many node names are in combined-word form, the required form for new
node names is words separated by underscores. If both forms are used in written
language (for example pinewood and pine wood) the underscore form should be used.

--]]


--[[ Index:

Stone
-----
(1. Material 2. Cobble variant 3. Brick variant 4. Modified forms)

default:stone
default:cobble
default:stonebrick
default:stone_block
default:mossycobble

default:desert_stone
default:desert_cobble
default:desert_stonebrick
default:desert_stone_block

default:sandstone
default:sandstonebrick
default:sandstone_block

default:obsidian
default:obsidianbrick
default:obsidian_block

Soft / Non-Stone
----------------
(1. Material 2. Modified forms)

default:dirt
default:dirt_with_grass
default:dirt_with_grass_footsteps
default:dirt_with_dry_grass
default:dirt_with_snow

default:sand
default:desert_sand

default:gravel

default:clay

default:snow
default:snowblock

default:ice

Trees
-----
(1. Trunk 2. Fabricated trunk 3. Leaves 4. Sapling 5. Fruits)

default:tree
default:wood
default:leaves
default:sapling
default:apple

default:jungletree
default:junglewood
default:jungleleaves
default:junglesapling

default:pine_tree
default:pine_wood
default:pine_needles
default:pine_sapling

default:acacia_tree
default:acacia_wood
default:acacia_leaves
default:acacia_sapling

default:aspen_tree
default:aspen_wood
default:aspen_leaves
default:aspen_sapling

Ores
----
(1. In stone 2. Blocks)

default:stone_with_coal
default:coalblock

default:stone_with_iron
default:steelblock

default:stone_with_copper
default:copperblock
default:bronzeblock

default:stone_with_gold
default:goldblock

default:stone_with_mese
default:mese

default:stone_with_diamond
default:diamondblock

Plantlife (non-cubic)
---------------------

default:cactus
default:papyrus
default:dry_shrub
default:junglegrass

default:grass_1
default:grass_2
default:grass_3
default:grass_4
default:grass_5

default:dry_grass_1
default:dry_grass_2
default:dry_grass_3
default:dry_grass_4
default:dry_grass_5

Liquids
-------
(1. Source 2. Flowing)

default:water_source
default:water_flowing

default:river_water_source
default:river_water_flowing

default:lava_source
default:lava_flowing

Tools / "Advanced" crafting / Non-"natural"
-------------------------------------------

default:sign_wall_wood
default:sign_wall_steel

default:ladder_wood
default:ladder_steel

default:fence_wood
default:fence_acacia_wood
default:fence_junglewood
default:fence_pine_wood
default:fence_aspen_wood

default:glass
default:obsidian_glass

default:rail

default:brick

default:meselamp

Misc
----

default:cloud

--]]

--
-- Stone
--

-- Localize for performance.
local math_random = math.random
local vector_add = vector.add

minetest.register_node("default:stone", {
	description = "Stone",

		--[[
    drawtype = "airlike",
		paramtype = "light",
		sunlight_propagates = true,
		light_source = 15,
		pointable = false,
		--]]

	tiles = {{name="stone_macro.png", align_style="world", scale=8}},

	groups = utility.dig_groups("stone", {
    stone = 1, native_stone = 1,
		melts = 1, cobble_type = 1,
  }),
	drop = 'default:cobble',
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),
	_melts_to = "cavestuff:cobble_with_rockmelt",

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	-- Collapsed stone breaks up into cobble.
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:cobble"})
  end,

	on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, {name="default:cobble"})
	end,
})

-- Name is very similar to default:stone to make it hard to detect even with F5 debug info.
minetest.register_node(":defauIt:stone", {
	description = "Stone (Please Report To Admin)",
	tiles = {"default_stone.png"},
	groups = utility.dig_groups("softcobble", {
		melts = 1, falling_node = 1,
  }),
	drop = 'default:cobble',
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),
	_melts_to = "cavestuff:cobble_with_rockmelt",

	-- Collapsed stone breaks up into cobble.
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:cobble"})
  end,

	on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, {name="default:cobble"})
	end,

	-- Player walking on it causes collapse.
	on_player_walk_over = function(pos, player)
		minetest.check_for_falling(pos)
	end,
})

minetest.register_node("default:cobble", {
	description = "Cobblestone",
	tiles = {"default_cobble.png"},
	is_ground_content = false,
	groups = utility.dig_groups("cobble", {
		stone = 1, native_stone = 1,
		melts = 1, cobble_type = 1,
	}),
	sounds = default.node_sound_stone_defaults(),
	_melts_to = "cavestuff:cobble_with_rockmelt",

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	_no_auto_pop = true,
})

minetest.register_node("default:stonebrick", {
	description = "Stone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_stone_brick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:stone_block", {
	description = "Stone Block",
	tiles = {"default_stone_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {stone=1, block = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:mossycobble", {
	description = "Mossy Cobblestone",
	tiles = {"default_mossycobble.png"},
	is_ground_content = false,
	groups = utility.dig_groups("cobble", {
		stone = 1, native_stone = 1,
		melts = 1,
	}),
	_melts_to = "cavestuff:cobble_with_rockmelt",
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("default:desert_stone", {
	description = "Redstone",

	tiles = {{name="desert_stone_macro.png", align_style="world", scale=8}},

	groups = utility.dig_groups("stone", {stone = 1, native_stone = 1}),
	drop = 'default:desert_cobble2',
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	-- Made desert stone a road material on March 16, 2018.
	movement_speed_multiplier = default.ROAD_SPEED,

	-- Collapsed stone breaks up into cobble.
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:desert_cobble2"})
  end,

	on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, {name="default:desert_cobble2"})
	end,
})

minetest.register_node("default:desert_cobble", {
	description = "Chalked Redstone Cobble",
	tiles = {"default_desert_cobble.png"}, -- Original "chalked" image (pre 5.0.0).
	is_ground_content = false,
	groups = utility.dig_groups("cobble", {stone = 1, native_stone = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:desert_cobble2", {
	description = "Redstone Cobble",
	tiles = {"default_desert_cobble2.png"},
	is_ground_content = false,
	groups = utility.dig_groups("cobble"),
	sounds = default.node_sound_stone_defaults(),

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
})

minetest.register_node("default:desert_stonebrick", {
	description = "Redstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_desert_stone_brick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {stone = 1, brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:desert_stone_block", {
	description = "Redstone Block",
	tiles = {"default_desert_stone_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {stone = 1, block=1}),
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("default:sandstone", {
	description = "Sandstone",
	tiles = {"default_sandstone.png"},
	groups = utility.dig_groups("softstone", {stone=1}),
	sounds = default.node_sound_stone_defaults(),

	-- Added on March 16, 2018.
	movement_speed_multiplier = default.ROAD_SPEED,
})

minetest.register_node("default:sandstonebrick", {
	description = "Sandstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_sandstone_brick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:sandstone_block", {
	description = "Sandstone Block",
	tiles = {"default_sandstone_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {block=1}),
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("default:desert_sandstone", {
	description = "Desert Sandstone",
	tiles = {"default_desert_sandstone.png"},
	groups = utility.dig_groups("softstone", {stone=1}),
	sounds = default.node_sound_stone_defaults(),
	movement_speed_multiplier = default.ROAD_SPEED,
})

minetest.register_node("default:desert_sandstone_brick", {
	description = "Desert Sandstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_desert_sandstone_brick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:desert_sandstone_block", {
	description = "Desert Sandstone Block",
	tiles = {"default_desert_sandstone_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {block=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:silver_sandstone", {
	description = "Silver Sandstone",
	tiles = {"default_silver_sandstone.png"},
	groups = utility.dig_groups("softstone", {stone=1}),
	sounds = default.node_sound_stone_defaults(),
	movement_speed_multiplier = default.ROAD_SPEED,
})

minetest.register_node("default:silver_sandstone_brick", {
	description = "Silver Sandstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_silver_sandstone_brick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:silver_sandstone_block", {
	description = "Silver Sandstone Block",
	tiles = {"default_silver_sandstone_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {block=1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("default:obsidian", {
	description = "Obsidian",
	tiles = {"default_obsidian.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("obsidian", {stone=1}),
  on_blast = function(...) end, -- Blast resistant.
	movement_speed_multiplier = default.ROAD_SPEED_CAVERN,

	-- Callbacks are overridden in flameportal mod!
	crushing_damage = 5000,
})

minetest.register_node("default:obsidianbrick", {
	description = "Obsidian Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_obsidian_brick.png"},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("brick", {stone=1, brick=1}),
  on_blast = function(...) end, -- Blast resistant.
	crushing_damage = 5000,
})

minetest.register_node("default:obsidian_block", {
	description = "Obsidian Block",
	tiles = {"default_obsidian_block.png"},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("block", {stone=1, block=1}),
  on_blast = function(...) end, -- Blast resistant.
	crushing_damage = 5000,
})

--
-- Soft / Non-Stone
--

minetest.register_node("default:dirt", {
	description = "Dirt",
	tiles = {"default_dirt.png"},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_sterile_dirt_type = 1, raw_dirt_type = 1, soil = 1}),
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dirt_with_grass", {
	description = "Dirt With Grass",
	tiles = {
		"default_grass.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, grassy_dirt_type = 1, soil = 1}),
	drop = 'default:dirt',
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
	-- Depreciated.
	--on_timer = function(...)
	--	return dirtspread.dirt_on_timer(...)
	--end,
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,
})

-- Does this node even exist in the world?
minetest.register_node("default:dirt_with_grass_footsteps", {
	description = "Dirt With Grass And Footsteps",
	tiles = {
		"default_grass.png^default_footprint.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, grassy_dirt_type = 1, soil = 1, not_in_creative_inventory = 1}),
	drop = 'default:dirt',
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
	-- Depreciated.
	--on_timer = function(...)
	--	return dirtspread.dirt_on_timer(...)
	--end,
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,
})

minetest.register_node("default:dirt_with_dry_grass", {
	description = "Dirt With Dry Grass",
	tiles = {
		"default_dry_grass.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_dry_grass_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, grassy_dirt_type = 1, soil = 1}),
	drop = 'default:dirt',
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
	-- Depreciated.
	--on_timer = function(...)
	--	return dirtspread.dirt_on_timer(...)
	--end,
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED_GRASS,
})

minetest.register_node("default:dirt_with_snow", {
	description = "Dirt With Snow",
	tiles = {
		"default_snow.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_snow_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, snowy_dirt_type = 1, snowy = 1, cold = 1}),
	drop = 'default:dirt',
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.2},
	}),
	-- Depreciated.
	--on_timer = function(...)
	--	return dirtspread.dirt_on_timer(...)
	--end,
	-- Dirt with snow does not need to turn back to dirt if it falls. After all, snow does not have roots that would be broken, unlike grass.
	--[[
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,
	--]]
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dark_dirt_with_snow", {
	description = "Sterile Dirt With Snow",
	tiles = {
		"default_snow.png",
		"darkage_darkdirt.png",
		{name = "darkage_darkdirt.png^default_snow_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, sterile_dirt_type = 1, snowy_dirt_type = 1, snowy = 1, cold = 1}),
	drop = 'darkage:darkdirt',
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.2},
	}),
	-- Depreciated.
	--on_timer = function(...)
	--	return dirtspread.dirt_on_timer(...)
	--end,
	-- Dirt with snow does not need to turn back to dirt if it falls. After all, snow does not have roots that would be broken, unlike grass.
	--[[
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="darkage:darkdirt"})
  end,
	--]]
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dry_dirt_with_snow", {
	description = "Dry Dirt With Snow",
	tiles = {
		"default_snow.png",
		"default_dry_dirt.png",
		{name = "default_dry_dirt.png^default_snow_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, dry_dirt_type = 1, snowy_dirt_type = 1, snowy = 1, cold = 1}),
	drop = 'default:dry_dirt',
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.2},
	}),
	-- Depreciated.
	--on_timer = function(...)
	--	return dirtspread.dirt_on_timer(...)
	--end,
	-- Dirt with snow does not need to turn back to dirt if it falls. After all, snow does not have roots that would be broken, unlike grass.
	--[[
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dry_dirt"})
  end,
	--]]
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dirt_with_rainforest_litter", {
	description = "Dirt With Leaf Litter",
	tiles = {
		"default_rainforest_litter.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_rainforest_litter_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, dirt_type = 1, non_raw_dirt_type = 1, leafy_dirt_type = 1, non_sterile_dirt_type = 1, soil = 1}),
	drop = "default:dirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dark_dirt_with_rainforest_litter", {
	description = "Sterile Dirt With Leaf Litter",
	tiles = {
		"default_rainforest_litter.png",
		"darkage_darkdirt.png",
		{name = "darkage_darkdirt.png^default_rainforest_litter_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {dirt_type = 1, leafy_dirt_type = 1, non_raw_dirt_type = 1, sterile_dirt_type = 1, falling_node = 1}),
	drop = "darkage:darkdirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="darkage:darkdirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dry_dirt_with_rainforest_litter", {
	description = "Dry Dirt With Leaf Litter",
	tiles = {
		"default_rainforest_litter.png",
		"default_dry_dirt.png",
		{name = "default_dry_dirt.png^default_rainforest_litter_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {dirt_type = 1, non_sterile_dirt_type = 1, non_raw_dirt_type = 1, leafy_dirt_type = 1, dry_dirt_type = 1, falling_node = 1}),
	drop = "default:dry_dirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults(),
	on_finish_collapse = function(pos, node)
		minetest.swap_node(pos, {name="default:dry_dirt"})
	end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dirt_with_coniferous_litter", {
	description = "Dirt With Acidic Litter",
	tiles = {
		"default_coniferous_litter.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_coniferous_litter_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {falling_node = 1, non_sterile_dirt_type = 1, non_raw_dirt_type = 1, leafy_dirt_type = 1, dirt_type = 1, soil = 1}),
	drop = "default:dirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dark_dirt_with_coniferous_litter", {
	description = "Sterile Dirt With Acidic Litter",
	tiles = {
		"default_coniferous_litter.png",
		"darkage_darkdirt.png",
		{name = "darkage_darkdirt.png^default_coniferous_litter_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {dirt_type = 1, sterile_dirt_type = 1, non_raw_dirt_type = 1, leafy_dirt_type = 1, falling_node = 1}),
	drop = "darkage:darkdirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="darkage:darkdirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dry_dirt_with_coniferous_litter", {
	description = "Dry Dirt With Acidic Litter",
	tiles = {
		"default_coniferous_litter.png",
		"default_dry_dirt.png",
		{name = "default_dry_dirt.png^default_coniferous_litter_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {dirt_type = 1, non_sterile_dirt_type = 1, non_raw_dirt_type = 1, leafy_dirt_type = 1, dry_dirt_type = 1, falling_node = 1}),
	drop = "default:dry_dirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults(),
	on_finish_collapse = function(pos, node)
		minetest.swap_node(pos, {name="default:dry_dirt"})
	end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dry_dirt", {
	description = "Dry Dirt",
	tiles = {"default_dry_dirt.png"},
	groups = utility.dig_groups("dirt", {dirt_type = 1, dry_dirt_type = 1, non_sterile_dirt_type = 1, raw_dirt_type = 1, falling_node = 1}),
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:dry_dirt_with_dry_grass", {
	description = "Dry Dirt With Dry Grass",
	tiles = {
		"default_dry_grass.png",
		"default_dry_dirt.png",
		{name = "default_dry_dirt.png^default_dry_grass_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("dirt", {dirt_type = 1, dry_dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, grassy_dirt_type = 1, falling_node = 1}),
	drop = "default:dry_dirt",
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dry_dirt"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:permafrost", {
	description = "Permafrost",
	tiles = {"default_permafrost.png"},
	groups = utility.dig_groups("cobble", {permafrost_type = 1, falling_node = 1, cold = 1}),
	sounds = default.node_sound_dirt_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:permafrost_with_snow", {
	description = "Permafrost With Snow",
	tiles = {
		"default_snow.png",
		"default_permafrost.png",
		{name = "default_permafrost.png^default_snow_side.png", tileable_vertical = false},
	},
	groups = utility.dig_groups("cobble", {permafrost_type = 1, falling_node = 1, cold = 1, snowy = 1}),
	sounds = default.node_sound_dirt_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:permafrost_with_stones", {
	description = "Permafrost With Stones",
	tiles = {
		"default_permafrost.png^default_stones.png",
		"default_permafrost.png",
		"default_permafrost.png^default_stones_side.png",
	},
	groups = utility.dig_groups("cobble", {permafrost_type = 1, falling_node = 1, cold = 1}),
	sounds = default.node_sound_gravel_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:permafrost_with_snow_and_stones", {
	description = "Permafrost With Snow And Stones",
	tiles = {
		"default_permafrost.png^default_snow.png^default_stones.png",
		"default_permafrost.png",
		"default_permafrost.png^default_snow_side.png^default_stones_side.png",
	},
	groups = utility.dig_groups("cobble", {permafrost_type = 1, falling_node = 1, cold = 1, snowy = 1}),
	sounds = default.node_sound_gravel_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:permafrost_with_moss", {
	description = "Permafrost With Moss",
	tiles = {
		"default_moss.png",
		"default_permafrost.png",
		{name = "default_permafrost.png^default_moss_side.png", tileable_vertical = false},
	},
	drop = "default:permafrost",
	groups = utility.dig_groups("cobble", {permafrost_type = 1, falling_node = 1, cold = 1}),
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:permafrost"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:permafrost_with_moss_and_stones", {
	description = "Permafrost With Moss And Stones",
	tiles = {
		"default_moss.png^default_stones.png",
		"default_permafrost.png",
		{name = "default_permafrost.png^default_moss_side.png^default_stones_side.png", tileable_vertical = false},
	},
	drop = "default:permafrost_with_stones",
	groups = utility.dig_groups("cobble", {permafrost_type = 1, falling_node = 1, cold = 1}),
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:permafrost_with_stones"})
  end,
	movement_speed_multiplier = default.SLOW_SPEED,
})



minetest.register_node("default:sand", {
	description = "Sand",
	tiles = {"default_sand.png"},
	groups = utility.dig_groups("sand", {falling_node = 1, sand = 1, fall_damage_add_percent = -20}),
	post_effect_color = {a=255, r=0, g=0, b=0},
	sounds = default.node_sound_sand_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("default:desert_sand", {
	description = "Desert Sand",
	tiles = {"default_desert_sand.png"},
	groups = utility.dig_groups("sand", {falling_node = 1, sand = 1, fall_damage_add_percent = -20}),
	sounds = default.node_sound_sand_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})


minetest.register_node("default:gravel", {
	description = "Gravel",
	tiles = {"default_gravel.png"},
	groups = utility.dig_groups("gravel", {falling_node = 1, gravel = 1}),
	sounds = default.node_sound_gravel_defaults(),
	drop = {
		max_items = 1,
		items = {
			{items = {'default:flint'}, rarity = 16},
			{items = {'default:gravel'}}
		}
	},
	post_effect_color = {a=255, r=0, g=0, b=0},

	-- Gravel is a component of wisp nests in Jarkati.
	after_destruct = function(pos, oldnode)
		local a = vector_add(pos, {x=0, y=1, z=0})
		local n = minetest.get_node(a)
		if n.name == "pm:spawner" then
			minetest.remove_node(a)
		end
	end,
})

minetest.register_node("default:clay", {
	description = "Clay",
	tiles = {"default_clay.png"},
	groups = utility.dig_groups("clay"),
	drop = 'default:clay_lump 4',
	sounds = default.node_sound_dirt_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})


minetest.register_node("default:snowblock", {
	description = "Snow Block",
	tiles = {"default_snow.png"},
	groups = utility.dig_groups("sand", {
		puts_out_fire = 1,
		snow = 1,
		snowy = 1,
		cold = 1,
		falling_node = 1,
		melts = 1,
		fall_damage_add_percent = -20,

		-- Currently used to notify ice nodes.
		notify_construct = 1,
		want_notify = 1,
	}),
	movement_speed_multiplier = default.SLOW_SPEED,

	_melts_to = "default:water_flowing",

	--damage_per_second = 2*500,
	post_effect_color = {a=255, r=255, g=255, b=255},
    
	sounds = default.node_sound_snow_defaults(),

	-- Hack to notify self.
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(ice.minmax_time()))
	end,

	on_notify = function(...)
		return ice.on_ice_notify(...)
	end,

	on_timer = function(pos, elapsed)
		if rc.ice_melts_at_pos(pos) then
			minetest.add_node(pos, {name="default:water_flowing"})
			return
		end
		return ice.on_ice_timer(pos, elapsed)
	end,
})

minetest.register_node("default:ice", {
	description = "Ice",
	tiles = {"default_ice.png"},
	is_ground_content = false,
	paramtype = "light",

	groups = utility.dig_groups("ice", {
		ice = 1,
		cold = 1,
		--puts_out_fire = 1,
		melts = 1,

		want_notify = 1,
		slippery = 3,
	}),

	_melts_to = "default:water_flowing",
	sounds = default.node_sound_glass_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_ICE,

	-- Common ice does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
	_no_auto_pop = true,

	-- Hack to notify self.
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(ice.minmax_time()))
	end,

	on_notify = function(...)
		return ice.on_ice_notify(...)
	end,

	on_timer = function(pos, elapsed)
		if rc.ice_melts_at_pos(pos) then
			minetest.add_node(pos, {name="default:water_flowing"})
			return
		end
		return ice.on_ice_timer(pos, elapsed)
	end,
})

--
-- Trees
--

--
-- Ores
--

minetest.register_node("default:stone_with_coal", {
	description = "Coal Deposit",
	tiles = {"default_stone.png^default_mineral_coal.png"},
  -- Cannot be flammable (although I would like it to be)
  -- because that interferes with TNT mining (the TNT replaces
  -- all coal with flame instead of dropping it).
	groups = utility.dig_groups("mineral"),
	drop = 'default:coal_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,

	-- Digging coal ore has a chance to release poison gas.
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if pos.y < -1024 then
			if math_random(1, 300) == 1 then
				breath.spawn_gas(pos)
			end
		end
	end,
})

minetest.register_node("default:desert_stone_with_coal", {
	description = "Redstone Coal Deposit",
	tiles = {"default_desert_stone.png^default_mineral_coal2.png"},
  -- Cannot be flammable (although I would like it to be)
  -- because that interferes with TNT mining (the TNT replaces
  -- all coal with flame instead of dropping it).
	groups = utility.dig_groups("mineral"),
	drop = 'default:coal_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:coalblock", {
	description = "Coal Block",
	tiles = {"default_coal_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("cobble", {flammable = 3}),
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("default:stone_with_iron", {
	description = "Iron Ore",
	tiles = {"default_stone.png^default_mineral_iron.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'default:iron_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:steelblock", {
	description = "Wrought Iron Block",
	tiles = {"default_steel_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {conductor = 1, block = 1}),
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_node("default:stone_with_copper", {
	description = "Copper Ore",
	tiles = {"default_stone.png^default_mineral_copper.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'default:copper_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:desert_stone_with_copper", {
	description = "Redstone Copper Ore",
	-- Use old copper image, the pattern looks nicer.
	tiles = {"default_desert_stone.png^default_mineral_copper2.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'default:copper_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:desert_stone_with_iron", {
	description = "Redstone Iron Ore",
	-- Use old iron image, the pattern looks nicer.
	tiles = {"default_desert_stone.png^default_mineral_iron2.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'default:iron_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:desert_stone_with_diamond", {
	description = "Redstone Diamond Deposit",
	-- Use old diamond image, the pattern looks nicer.
	tiles = {"default_desert_stone.png^default_mineral_diamond2.png"},
	groups = utility.dig_groups("hardmineral"),
	drop = 'default:diamond',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:copperblock", {
	description = "Copper Block",
	tiles = {"default_copper_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {conductor = 1, block = 1}),
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("default:bronzeblock", {
	description = "Bronze Block",
	tiles = {"default_bronze_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {conductor = 1, block = 1}),
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_node("default:stone_with_mese", {
	description = "Mese Ore",
	tiles = {"default_stone.png^default_mineral_mese.png"},
	groups = utility.dig_groups("hardmineral", {melts = 1}),
	drop = {
		max_items = 1,
		items = {
			{items = {'mobs:flame_bolt'}, rarity = 16},
			{items = {'default:mese_crystal'}}
		}
	},
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	
	-- Mese in stone reacts badly to lava.
	on_melt = function(pos, other)
		minetest.after(0, function()
      tnt.boom(pos, {
        radius = 4,
        ignore_protection = false,
        ignore_on_blast = false,
        damage_radius = 6,
        disable_drops = true,
      })
		end)
	end,
})

minetest.register_node("default:mese", {
	description = "Mese Block",
	tiles = {"default_mese_block.png"},
	paramtype = "light",
	groups = utility.dig_groups("hardstone", {melts = 1}),
	sounds = default.node_sound_stone_defaults(),
	light_source = 3,
	
	-- Mese in stone reacts badly to lava.
	-- Meseblock makes a much larger blast.
	on_melt = function(pos, other)
		minetest.after(0, function()
      tnt.boom(pos, {
        radius = 10,
        ignore_protection = false,
        ignore_on_blast = false,
        damage_radius = 20,
        disable_drops = true,
      })
		end)
	end,
})


minetest.register_node("default:stone_with_gold", {
	description = "Gold Ore",
	tiles = {"default_stone.png^default_mineral_gold.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = "default:gold_lump",
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:goldblock", {
	description = "Gold Block",
	tiles = {"default_gold_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("block", {conductor = 1, block = 1}),
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_node("default:stone_with_diamond", {
	description = "Diamond Deposit",
	tiles = {"default_stone.png^default_mineral_diamond.png"},
	-- Player has to get mese pick or similar before they can get diamond.
	groups = utility.dig_groups("hardmineral"),
	drop = "default:diamond",
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("default:diamondblock", {
	description = "Diamond Block",
	tiles = {"default_diamond_block.png"},
	is_ground_content = false,
	groups = utility.dig_groups("obsidian"),
	sounds = default.node_sound_stone_defaults(),
})

--
-- Plantlife (non-cubic)
--

do
	local nodebox = {
		-- Spine strips.
		{0, 1, 1, 16, 15, 1},
		{0, 1, 15, 16, 15, 15},
		{1, 1, 0, 1, 15, 16},
		{15, 1, 0, 15, 15, 16},

		-- Meat.
		{1, 0, 1, 15, 16, 15},

		-- Side skin.
		{4, 0, 0, 12, 16, 16},
		{0, 0, 4, 16, 16, 12},
	}

	local selectionbox = {
		{1, 0, 1, 15, 16, 15},
	}

	utility.transform_nodebox(nodebox)
	utility.transform_nodebox(selectionbox)

	minetest.register_node("default:cactus", {
		description = "Cactus",
		tiles = {
				"default_cactus_top.png",
				"default_cactus_top.png",
				"default_cactus_side.png"
			},
		paramtype = "light",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = nodebox,
		},
		selection_box = {
			type = "fixed",
			fixed = selectionbox,
		},
		paramtype2 = "facedir",
		groups = utility.dig_groups("softwood", {flammable = 1, fall_damage_add_percent = 100}),
		sounds = default.node_sound_wood_defaults(),
		on_place = minetest.rotate_node,
		damage_per_second = 1*500,
		_death_message = "They impaled themself on a cactus.",

		on_punch = function(pos, node, puncher, pt)
			if not puncher or not puncher:is_player() then return end
			local stack = puncher:get_wielded_item()
			local name = stack:get_name() or ""
			if not string.find(name, "axe") then
				puncher:set_hp(puncher:get_hp() - (1*500), {reason="sharp"})
			end
		end,

		on_player_walk_over = function(pos, player)
			player:set_hp(player:get_hp() - (1*500), {reason="ground"})
			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(player:get_player_name()) .. "> stepped on cactus. Noob!")
			end
		end,

		on_construct = function(...)
			return cactus.on_construct(...)
		end,

		on_destruct = function(...)
			return cactus.on_destruct(...)
		end,

		on_timer = function(...)
			return cactus.on_timer(...)
		end,

		after_dig_node = function(...)
			return cactus.after_dig_node(...)
		end,
	})
end

--[[

--= Tests of Tools Against Default Groups =--
result_of {snappy = 1, choppy = 3} + tool=default:axe_stone      : digsound=success
result_of {snappy = 1, choppy = 3} + tool=default:axe_diamond    : digsound=success
result_of {snappy = 1, choppy = 3} + tool=default:axe_steel      : digsound=success
result_of {snappy = 1, choppy = 3} + tool=default:axe_mese       : digsound=success
result_of {snappy = 1, choppy = 3} + tool=default:sword_steel    : digsound=failure
result_of {snappy = 1, choppy = 3} + tool=default:sword_stone    : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:sword_diamond  : digsound=failure
result_of {snappy = 1, choppy = 3} + tool=default:sword_mese     : digsound=failure
result_of {snappy = 1, choppy = 3} + tool=default:shovel_stone   : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:shovel_steel   : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:shovel_diamond : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:shovel_mese    : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:pick_stone     : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:pick_steel     : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:pick_diamond   : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3} + tool=default:pick_mese      : digsound=N/A (could not dig)

--= Tests of Tools Against Modified Groups (A) =--
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:pick_stone     : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:pick_steel     : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:pick_diamond   : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:pick_mese      : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:axe_stone      : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:axe_steel      : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:axe_diamond    : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:axe_mese       : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:shovel_stone   : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:shovel_steel   : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:shovel_diamond : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:shovel_mese    : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:sword_stone    : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:sword_steel    : digsound=failure
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:sword_diamond  : digsound=failure
result_of {snappy = 1, choppy = 3, cracky = 1} + tool=default:sword_mese     : digsound=failure

--= Tests of Tools Against Modified Groups (B) =--
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:pick_stone     : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:pick_steel     : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:pick_diamond   : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:pick_mese      : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:axe_stone      : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:axe_steel      : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:axe_diamond    : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:axe_mese       : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:shovel_stone   : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:shovel_steel   : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:shovel_diamond : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:shovel_mese    : digsound=success
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:sword_stone    : digsound=N/A (could not dig)
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:sword_steel    : digsound=failure
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:sword_diamond  : digsound=failure
result_of {snappy = 1, choppy = 3, cracky = 1, crumbly = 1} + tool=default:sword_mese     : digsound=failure

--= Tests of Swords Against Modified Groups (C) =--
result_of {snappy = 1} + tool=default:sword_stone   : digsound=N/A (could not dig)
result_of {snappy = 1} + tool=default:sword_steel   : digsound=failure
result_of {snappy = 1} + tool=default:sword_diamond : digsound=failure
result_of {snappy = 1} + tool=default:sword_mese    : digsound=failure

--]]

minetest.register_node("default:papyrus", {
	description = "Papyrus",
	drawtype = "plantlike",
	tiles = {"default_papyrus.png"},
	inventory_image = "default_papyrus.png",
	wield_image = "default_papyrus.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}
	},
	groups = utility.dig_groups("plant", {flammable = 2}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_construct = function(...)
		return papyrus.on_construct(...)
	end,

	on_destruct = function(...)
		return papyrus.on_destruct(...)
	end,

	on_timer = function(...)
		return papyrus.on_timer(...)
	end,

	after_dig_node = function(...)
		return papyrus.after_dig_node(...)
	end,
})

minetest.register_node("default:dry_shrub", {
	description = "Dry Shrub",
	drawtype = "plantlike",
	waving = 1,

	tiles = {"default_dry_shrub.png"},
	inventory_image = "default_dry_shrub.png",
	wield_image = "default_dry_shrub.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = utility.dig_groups("plant", {
		flammable = 3, attached_node = 1, dry_grass = 1, dry_shrub = 1,
	}),
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
	},
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	-- Drop 1 or 2 sticks.
	drop = {
		max_items = 1,
		items = {
			{items = {'default:stick 2'}, rarity = 2},
			{items = {'default:stick'}},
		}
	},
	shears_drop = true,
	flowerpot_drop = "default:dry_shrub",
})

minetest.register_node("default:dry_shrub2", {
	description = "Dead Bush",
	drawtype = "plantlike",
	waving = 1,
	tiles = {"default_dry_shrub2.png"},
	inventory_image = "default_dry_shrub2.png",
	wield_image = "default_dry_shrub2.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 4,
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = utility.dig_groups("plant", {
		flammable = 3, attached_node = 1, dry_grass = 1, dry_shrub = 1,
	}),
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-6 / 16, -0.5, -6 / 16, 6 / 16, 4 / 16, 6 / 16},
	},
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	drop = {
		max_items = 1,
		items = {
			{items = {'default:stick 2'}, rarity = 2},
			{items = {'default:stick'}},
		}
	},
	shears_drop = true,
	flowerpot_drop = "default:dry_shrub2",
})

minetest.register_node("default:junglegrass", {
	description = "Jungle Grass",
	drawtype = "plantlike",
	waving = 1,
	visual_scale = 1.69,
	tiles = {"default_junglegrass.png"},
	inventory_image = "default_junglegrass.png",
	wield_image = "default_junglegrass.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,

	-- Default drops are defined in farming mod.
	flowerpot_drop = "default:junglegrass",

	groups = utility.dig_groups("plant", {flora = 1, attached_node = 1, grass = 1, junglegrass = 1, flammable = 1}),
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
	},
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_construct = function(...)
		return flowers.on_flora_construct(...)
	end,

	on_destruct = function(...)
		return flowers.on_flora_destruct(...)
	end,

	on_timer = function(...)
		return flowers.on_flora_timer(...)
	end,

	on_punch = function(...)
		return flowers.on_flora_punch(...)
	end,
})

minetest.register_node("default:coarsegrass", {
	description = "Coarse Grass",
	drawtype = "plantlike",
	waving = 1,

	tiles = {"default_junglegrass_newstyle.png"},
	inventory_image = "default_junglegrass_newstyle.png",
	wield_image = "default_junglegrass_newstyle.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,

	drop = "default:stick",
	shears_drop = true,
	flowerpot_drop = "default:coarsegrass",

	groups = utility.dig_groups("plant", {flora = 1, attached_node = 1, grass = 1, junglegrass = 1, flammable = 1}),
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
	},
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_construct = function(...)
		return flowers.on_flora_construct(...)
	end,

	on_destruct = function(...)
		return flowers.on_flora_destruct(...)
	end,

	on_timer = function(...)
		return flowers.on_flora_timer(...)
	end,

	on_punch = function(...)
		return flowers.on_flora_punch(...)
	end,
})



-- This node is not meant to be placed in the world.
-- Instead, placing it causes 1 of several other nodetypes to be placed instead.
minetest.register_node("default:grass_dummy", {
	description = "Wild Grass\n\nA common field plant, sometimes containing seeds.\nCan be hung upside down like some herbs.",
	drawtype = "plantlike",
	waving = 1,
	tiles = {"default_grass_1.png"},
	-- Use texture of a taller grass stage in inventory
	inventory_image = "default_grass_3.png",
	wield_image = "default_grass_3.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	flowerpot_insert = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5"},

	-- Zero-width selection box.
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.5, 0.5},
	},

	on_place = function(itemstack, placer, pt)
		-- place a random grass node
		-- If pointing to the ceiling place hanging grass.
		--minetest.chat_send_all(dump(pt))
		if pt.type == "node" then
			--minetest.chat_send_all("1: " .. minetest.pos_to_string(pt.under) .. ".")
			--minetest.chat_send_all("2: " .. minetest.pos_to_string(pt.above) .. ".")
			if pt.under.y-1 == pt.above.y then
				--minetest.chat_send_all("hanging!")
				local stack = ItemStack("default:grass_" .. math_random(1,5) .. "_hanging")
				local ret = minetest.item_place(stack, placer, pt)
				return ItemStack("default:grass_dummy " .. itemstack:get_count() - (1 - ret:get_count()))
			end
		end

		local stack = ItemStack("default:grass_" .. math_random(1,5))
		local ret = minetest.item_place(stack, placer, pt)
		return ItemStack("default:grass_dummy " .. itemstack:get_count() - (1 - ret:get_count()))
	end,
})

for i = 1, 5 do
	minetest.register_node("default:grass_" .. i, {
		description = "Grass",
		drawtype = "plantlike",
		waving = 1,
		tiles = {"default_grass_" .. i .. ".png"},
		inventory_image = "default_grass_3.png",
		wield_image = "default_grass_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,

		-- Default drops are defined in farming mod.
		flowerpot_drop = "default:grass_dummy",

		groups = utility.dig_groups("plant", {flora = 1, attached_node = 1, not_in_creative_inventory = 1, grass = 1, flammable = 1}),
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return flowers.on_flora_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_flora_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_flora_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_flora_punch(...)
		end,
	})
end

for i = 1, 5 do
	minetest.register_node("default:grass_" .. i .. "_hanging", {
		description = "Hanging Grass",
		drawtype = "plantlike",
		-- Waving hanging nodes look ugly.
		--waving = 1,
		tiles = {"default_grass_" .. i .. ".png^[transformFY"},
		inventory_image = "default_grass_3.png",
		wield_image = "default_grass_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,

		-- Default drops are defined in farming mod.
		flowerpot_drop = "default:grass_dummy",

		groups = utility.dig_groups("plant", {hanging_node = 1, not_in_creative_inventory = 1, grass = 1, flammable = 1}),
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, 0.5, -0.5, 0.5, 5/16, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	})
end


minetest.register_node("default:dry_grass_dummy", {
	description = "Dry Grass",
	drawtype = "plantlike",
	waving = 1,
	tiles = {"default_dry_grass_1.png"},
	inventory_image = "default_dry_grass_3.png",
	wield_image = "default_dry_grass_3.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	flowerpot_insert = {"default:dry_grass_1", "default:dry_grass_2", "default:dry_grass_3", "default:dry_grass_4", "default:dry_grass_5"},

	-- Zero-width selection box.
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.5, 0.5},
	},

	on_place = function(itemstack, placer, pt)
		-- place a random dry grass node
		-- If pointing to the ceiling place hanging grass.
		--minetest.chat_send_all(dump(pt))
		if pt.type == "node" then
			--minetest.chat_send_all("1: " .. minetest.pos_to_string(pt.under) .. ".")
			--minetest.chat_send_all("2: " .. minetest.pos_to_string(pt.above) .. ".")
			if pt.under.y-1 == pt.above.y then
				--minetest.chat_send_all("hanging!")
				local stack = ItemStack("default:dry_grass_" .. math_random(1,5) .. "_hanging")
				local ret = minetest.item_place(stack, placer, pt)
				return ItemStack("default:dry_grass_dummy " .. itemstack:get_count() - (1 - ret:get_count()))
			end
		end

		local stack = ItemStack("default:dry_grass_" .. math_random(1, 5))
		local ret = minetest.item_place(stack, placer, pt)
		return ItemStack("default:dry_grass_dummy " .. itemstack:get_count() - (1 - ret:get_count()))
	end,
})

for i = 1, 5 do
	minetest.register_node("default:dry_grass_" .. i, {
		description = "Dry Grass",
		drawtype = "plantlike",
		waving = 1,
		tiles = {"default_dry_grass_" .. i .. ".png"},
		inventory_image = "default_dry_grass_3.png",
		wield_image = "default_dry_grass_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		groups = utility.dig_groups("plant", {flammable = 3, flora = 1, attached_node = 1,
			not_in_creative_inventory=1, dry_grass = 1}),

		drop = "",
		shears_drop = "default:dry_grass_dummy",
		flowerpot_drop = "default:dry_grass_dummy",

		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return flowers.on_flora_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_flora_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_flora_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_flora_punch(...)
		end,
	})
end

for i = 1, 5 do
	minetest.register_node("default:dry_grass_" .. i .. "_hanging", {
		description = "Dry Grass",
		drawtype = "plantlike",
		-- Waving hanging grass looks silly.
		--waving = 1,
		tiles = {"default_dry_grass_" .. i .. ".png^[transformFY"},
		inventory_image = "default_dry_grass_3.png",
		wield_image = "default_dry_grass_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		-- Not in flora group, since it does not need to spread.
		groups = utility.dig_groups("plant", {flammable = 3, hanging_node = 1,
			not_in_creative_inventory=1, dry_grass = 1}),

		drop = "",
		shears_drop = "default:dry_grass_dummy",
		flowerpot_drop = "default:dry_grass_dummy",

		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, 0.5, -0.5, 0.5, 5/16, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	})
end







minetest.register_node("default:dry_grass2_dummy", {
	description = "Dry Grass",
	drawtype = "plantlike",
	waving = 1,
	tiles = {"default_dry_grass2_1.png"},
	inventory_image = "default_dry_grass2_3.png",
	wield_image = "default_dry_grass2_3.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	flowerpot_insert = {"default:dry_grass2_1", "default:dry_grass2_2", "default:dry_grass2_3", "default:dry_grass2_4", "default:dry_grass2_5"},

	-- Zero-width selection box.
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.5, 0.5},
	},

	on_place = function(itemstack, placer, pt)
		-- place a random dry grass node
		-- If pointing to the ceiling place hanging grass.
		--minetest.chat_send_all(dump(pt))
		if pt.type == "node" then
			--minetest.chat_send_all("1: " .. minetest.pos_to_string(pt.under) .. ".")
			--minetest.chat_send_all("2: " .. minetest.pos_to_string(pt.above) .. ".")
			if pt.under.y-1 == pt.above.y then
				--minetest.chat_send_all("hanging!")
				local stack = ItemStack("default:dry_grass2_" .. math_random(1,5) .. "_hanging")
				local ret = minetest.item_place(stack, placer, pt)
				return ItemStack("default:dry_grass2_dummy " .. itemstack:get_count() - (1 - ret:get_count()))
			end
		end

		local stack = ItemStack("default:dry_grass2_" .. math_random(1, 5))
		local ret = minetest.item_place(stack, placer, pt)
		return ItemStack("default:dry_grass2_dummy " .. itemstack:get_count() - (1 - ret:get_count()))
	end,
})

for i = 1, 5 do
	minetest.register_node("default:dry_grass2_" .. i, {
		description = "Dry Grass",
		drawtype = "plantlike",
		waving = 1,
		tiles = {"default_dry_grass2_" .. i .. ".png"},
		inventory_image = "default_dry_grass2_3.png",
		wield_image = "default_dry_grass2_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		groups = utility.dig_groups("plant", {flammable = 3, flora = 1, attached_node = 1,
			not_in_creative_inventory=1, dry_grass = 1}),

		drop = "",
		shears_drop = "default:dry_grass2_dummy",
		flowerpot_drop = "default:dry_grass2_dummy",

		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

		on_construct = function(...)
			return flowers.on_flora_construct(...)
		end,

		on_destruct = function(...)
			return flowers.on_flora_destruct(...)
		end,

		on_timer = function(...)
			return flowers.on_flora_timer(...)
		end,

		on_punch = function(...)
			return flowers.on_flora_punch(...)
		end,
	})
end

for i = 1, 5 do
	minetest.register_node("default:dry_grass2_" .. i .. "_hanging", {
		description = "Dry Grass",
		drawtype = "plantlike",
		-- Waving hanging grass looks silly.
		--waving = 1,
		tiles = {"default_dry_grass2_" .. i .. ".png^[transformFY"},
		inventory_image = "default_dry_grass2_3.png",
		wield_image = "default_dry_grass2_3.png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		-- Not in flora group, since it does not need to spread.
		groups = utility.dig_groups("plant", {flammable = 3, hanging_node = 1,
			not_in_creative_inventory=1, dry_grass = 1}),

		drop = "",
		shears_drop = "default:dry_grass2_dummy",
		flowerpot_drop = "default:dry_grass2_dummy",

		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.5, 0.5, -0.5, 0.5, 5/16, 0.5},
		},
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	})
end

--
-- Liquids
--

minetest.register_node("default:water_source", {
	description = "Water Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "default_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	special_tiles = {
		-- New-style water source material (mostly unused)
		{
			name = "default_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
			backface_culling = false,
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 4,
	liquidtype = "source",
	liquid_alternative_flowing = "default:water_flowing",
	liquid_alternative_source = "default:water_source",
	liquid_viscosity = 1,
	post_effect_color = {a = 103, r = 30, g = 60, b = 90},
	groups = {water = 3, liquid = 3, puts_out_fire = 1},
	sounds = default.node_sound_water_defaults(),

	-- Water turns to fire in the nether.
	-- Note: this is not called if water-source is created by the engine due to liquid-flow mechanic.
	on_construct = function(pos)
		farming.notify_soil(pos)
		if minetest.find_node_near(pos, 10, "griefer:grieferstone") then
			minetest.add_node(pos, {name="fire:basic_flame"})
			return
		end
		if rc.current_realm_at_pos(pos) == "channelwood" then
			minetest.swap_node(pos, {name="cw:water_source"})
			return
		end
		if pos.y < -25000 then
			minetest.add_node(pos, {name="fire:basic_flame"})
		end
	end,

	on_destruct = function(pos)
		farming.notify_soil(pos)
	end,

  on_collapse_to_entity = function(pos, node)
    -- Do not allow player to obtain the node itself.
  end,
})

minetest.register_node("default:water_flowing", {
	description = "Flowing Water",
	drawtype = "flowingliquid",
	tiles = {"default_water.png"},
	special_tiles = {
		{
			name = "default_water_flowing_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.8,
			},
		},
		{
			name = "default_water_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.8,
			},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 4,
	liquidtype = "flowing",
	liquid_alternative_flowing = "default:water_flowing",
	liquid_alternative_source = "default:water_source",
	liquid_viscosity = 1,
	post_effect_color = {a = 103, r = 30, g = 60, b = 90},
	groups = {water = 3, liquid = 3, puts_out_fire = 1, not_in_creative_inventory = 1},
  sounds = default.node_sound_water_defaults(),

  on_collapse_to_entity = function(pos, node)
    -- Do not allow player to obtain the node itself.
  end,

	on_construct = function(pos)
		if minetest.find_node_near(pos, 10, "griefer:grieferstone") then
			minetest.add_node(pos, {name="fire:basic_flame"})
			return
		end
		if rc.current_realm_at_pos(pos) == "channelwood" then
			minetest.swap_node(pos, {name="cw:water_flowing"})
			return
		end
		if pos.y < -25000 then
			minetest.add_node(pos, {name="fire:basic_flame"})
		end
	end,
})


minetest.register_node("default:river_water_source", {
	description = "Salt Water Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "default_river_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	special_tiles = {
		{
			name = "default_river_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
			backface_culling = false,
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 4,
	liquidtype = "source",
	liquid_alternative_flowing = "default:river_water_flowing",
	liquid_alternative_source = "default:river_water_source",
	liquid_viscosity = 1,
	-- River water can be placed above ground, so liquid must NOT be renewable!
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	groups = {water = 3, liquid = 3, puts_out_fire = 1},
	sounds = default.node_sound_water_defaults(),

	-- Water turns to fire in the nether.
	-- Note: this is not called if water-source is created by the engine due to liquid-flow mechanic.
	on_construct = function(pos)
		farming.notify_soil(pos)
		if minetest.find_node_near(pos, 10, "griefer:grieferstone") then
			minetest.add_node(pos, {name="fire:basic_flame"})
			return
		end

		if pos.y < -25000 then
			minetest.add_node(pos, {name="fire:basic_flame"})
		end
	end,

	on_destruct = function(pos)
		farming.notify_soil(pos)
	end,

  on_collapse_to_entity = function(pos, node)
    -- Do not allow player to obtain the node itself.
  end,
})

minetest.register_node("default:river_water_flowing", {
	description = "Flowing Salt Water",
	drawtype = "flowingliquid",
	tiles = {"default_river_water.png"},
	special_tiles = {
		{
			name = "default_river_water_flowing_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.8,
			},
		},
		{
			name = "default_river_water_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.8,
			},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 4,
	liquidtype = "flowing",
	liquid_alternative_flowing = "default:river_water_flowing",
	liquid_alternative_source = "default:river_water_source",
	liquid_viscosity = 1,
	-- River water can be placed above ground, so liquid must NOT be renewable!
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	groups = {water = 3, liquid = 3, puts_out_fire = 1, not_in_creative_inventory = 1},
  sounds = default.node_sound_water_defaults(),

  on_collapse_to_entity = function(pos, node)
    -- Do not allow player to obtain the node itself.
  end,

	on_construct = function(pos)
		if minetest.find_node_near(pos, 10, "griefer:grieferstone") then
			minetest.set_node(pos, {name="fire:basic_flame"})
			return
		end
		if pos.y < -25000 then
			minetest.set_node(pos, {name="fire:basic_flame"})
		end
	end,
})





--
-- Tools / "Advanced" crafting / Non-"natural"
--

minetest.register_node("default:ladder_wood", {
	description = "Wooden Ladder",
	drawtype = "signlike",
	tiles = {"default_ladder_wood.png"},
	inventory_image = "default_ladder_wood.png",
	wield_image = "default_ladder_wood.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
		--wall_top = = <default>
		--wall_bottom = = <default>
		--wall_side = = <default>
	},
	groups = utility.dig_groups("bigitem", {flammable = 2, ladder=1}),
	legacy_wallmounted = true,
	sounds = default.node_sound_wood_defaults(),

	-- Lava burns wood ladders instantly.
	-- Water rots wood (instantly too, I guess).
	-- Gameplay rational: make it important to use trapdoors, etc. to block flow.
	floodable = true,
})

minetest.register_node("default:ladder_steel", {
	description = "Wrought Iron Ladder",
	drawtype = "signlike",
	tiles = {"default_ladder_steel.png"},
	inventory_image = "default_ladder_steel.png",
	wield_image = "default_ladder_steel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
		--wall_top = = <default>
		--wall_bottom = = <default>
		--wall_side = = <default>
	},
	groups = utility.dig_groups("bigitem", {ladder=1}),
	sounds = default.node_sound_metal_defaults(),

	-- Lava melts metal ladders quickly.
	-- Water rusts them (quickly too, I guess).
	-- Gameplay rational: make it important to use trapdoors, etc. to block flow.
	floodable = true,
})

minetest.register_node(":defauIt:ladder_wood", {
	description = "Wooden Trap Ladder",
	drawtype = "signlike",
	tiles = {"default_ladder_wood.png"},
	inventory_image = "default_ladder_wood.png",
	wield_image = "default_ladder_wood.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = false, -- Player drops through.
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
		--wall_top = = <default>
		--wall_bottom = = <default>
		--wall_side = = <default>
	},
	groups = utility.dig_groups("bigitem", {flammable = 2}),
	sounds = default.node_sound_wood_defaults(),

	-- Lava burns wood ladders instantly.
	-- Water rots wood (instantly too, I guess).
	-- Gameplay rational: make it important to use trapdoors, etc. to block flow.
	floodable = true,
})

minetest.register_node(":defauIt:ladder_steel", {
	description = "Wrought Iron Trap Ladder",
	drawtype = "signlike",
	tiles = {"default_ladder_steel.png"},
	inventory_image = "default_ladder_steel.png",
	wield_image = "default_ladder_steel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = false, -- Player drops through.
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
		--wall_top = = <default>
		--wall_bottom = = <default>
		--wall_side = = <default>
	},
	groups = utility.dig_groups("bigitem"),
	sounds = default.node_sound_metal_defaults(),

	-- Lava melts metal ladders quickly.
	-- Water rusts them (quickly too, I guess).
	-- Gameplay rational: make it important to use trapdoors, etc. to block flow.
	floodable = true,
})

default.register_fence("default:fence_iron", {
	description = "Wrought Iron Fence",
	texture = "default_fence_iron.png",
	inventory_image = "default_fence_overlay.png^default_fence_iron.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_fence_iron.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal", {fence = 1}),
	sounds = default.node_sound_metal_defaults()
})

default.register_fence("default:fence_bronze", {
	description = "Bronze Fence",
	texture = "default_fence_bronze.png",
	inventory_image = "default_fence_overlay.png^default_fence_bronze.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_fence_bronze.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal", {fence = 1}),
	sounds = default.node_sound_metal_defaults()
})

default.register_fence("default:fence_wood", {
	description = "Wooden Fence",
	texture = "default_fence_wood.png",
	inventory_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_acacia_wood", {
	description = "Acacia Wood Fence",
	texture = "default_fence_acacia_wood.png",
	inventory_image = "default_fence_overlay.png^default_acacia_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_acacia_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_junglewood", {
	description = "Jungle Wood Fence",
	texture = "default_fence_junglewood.png",
	inventory_image = "default_fence_overlay.png^default_junglewood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_junglewood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_pine_wood", {
	description = "Pine Wood Fence",
	texture = "default_fence_pine_wood.png",
	inventory_image = "default_fence_overlay.png^default_pine_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_pine_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_aspen_wood", {
	description = "Aspen Wood Fence",
	texture = "default_fence_aspen_wood.png",
	inventory_image = "default_fence_overlay.png^default_aspen_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_aspen_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

minetest.register_node("default:glass", {
	description = "Glass",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = utility.dig_groups("glass", {glass=1}),
	sounds = default.node_sound_glass_defaults(),
	drop = "vessels:glass_fragments",
	silverpick_drop = true,
})

minetest.register_node("default:obsidian_glass", {
	description = "Obsidian Glass",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_obsidian_glass.png", "default_obsidian_glass_detail.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("glass", {glass=1}),
	drop = "default:obsidian_shard",
	silverpick_drop = true,
})



minetest.register_node("default:brick", {
	description = "Brick Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_brick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("default:meselamp", {
	description = "Mese Lamp",
	drawtype = "glasslike",
	tiles = {"default_meselamp.png"},
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = utility.dig_groups("glass"),
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX-1,
})

minetest.register_node("default:lightbox", {
	description = "Light Box",
	drawtype = "glasslike",
	tiles = {"default_lightbox.png"},
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = utility.dig_groups("glass"),
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX - 2,
})

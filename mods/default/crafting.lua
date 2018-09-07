-- mods/default/crafting.lua

minetest.register_craft({
	output = 'default:stick 4',
	recipe = {
		{'group:wood'},
	}
})

minetest.register_craft({
  output = "default:stick",
  recipe = {
		{"torches:torch_floor", "torches:torch_floor"},
		{"torches:torch_floor", "torches:torch_floor"},
	},
})

minetest.register_craft({
  output = "default:stick",
  recipe = {
		{"torches:kalite_torch_floor", "torches:kalite_torch_floor"},
		{"torches:kalite_torch_floor", "torches:kalite_torch_floor"},
	},
})

minetest.register_craft({
	output = 'default:stick 3',
	recipe = {
		{'group:leaves'},
		{'group:leaves'},
		{'group:leaves'},
	}
})

--[[
minetest.register_craft({
	-- Output count adjusted from 24 to 12, by MustTest.
	output = 'default:rail 12',
	recipe = {
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'default:steel_ingot', 'group:stick', 'default:steel_ingot'},
		{'default:steel_ingot', '', 'default:steel_ingot'},
	}
})
--]]

minetest.register_craft({
	output = 'default:coalblock',
	recipe = {
		{'default:coal_lump', 'default:coal_lump', 'default:coal_lump'},
		{'default:coal_lump', 'default:coal_lump', 'default:coal_lump'},
		{'default:coal_lump', 'default:coal_lump', 'default:coal_lump'},
	}
})

minetest.register_craft({
	output = 'default:coal_lump 9',
	recipe = {
		{'default:coalblock'},
	}
})

minetest.register_craft({
	output = 'default:steelblock',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'default:steel_ingot 9',
	recipe = {
		{'default:steelblock'},
	}
})

minetest.register_craft({
	output = 'default:copperblock',
	recipe = {
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
	}
})

minetest.register_craft({
	output = 'default:copper_ingot 9',
	recipe = {
		{'default:copperblock'},
	}
})

minetest.register_craft({
	output = 'default:bronzeblock',
	recipe = {
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
	}
})

minetest.register_craft({
	output = 'default:bronze_ingot 9',
	recipe = {
		{'default:bronzeblock'},
	}
})

minetest.register_craft({
	output = 'default:goldblock',
	recipe = {
		{'default:gold_ingot', 'default:gold_ingot', 'default:gold_ingot'},
		{'default:gold_ingot', 'default:gold_ingot', 'default:gold_ingot'},
		{'default:gold_ingot', 'default:gold_ingot', 'default:gold_ingot'},
	}
})

minetest.register_craft({
	output = 'default:gold_ingot 9',
	recipe = {
		{'default:goldblock'},
	}
})

minetest.register_craft({
	output = 'default:diamondblock',
	recipe = {
		{'default:diamond', 'default:diamond', 'default:diamond'},
		{'default:diamond', 'default:diamond', 'default:diamond'},
		{'default:diamond', 'default:diamond', 'default:diamond'},
	}
})

minetest.register_craft({
	output = 'default:diamond 9',
	recipe = {
		{'default:diamondblock'},
	}
})

minetest.register_craft({
	output = 'default:sandstonebrick 4',
	recipe = {
		{'default:sandstone', 'default:sandstone'},
		{'default:sandstone', 'default:sandstone'},
	}
})

minetest.register_craft({
	output = 'default:sandstone_block 9',
	recipe = {
		{'default:sandstone', 'default:sandstone', 'default:sandstone'},
		{'default:sandstone', 'default:sandstone', 'default:sandstone'},
		{'default:sandstone', 'default:sandstone', 'default:sandstone'},
	}
})

minetest.register_craft({
	output = 'default:clay',
	recipe = {
		{'default:clay_lump', 'default:clay_lump'},
		{'default:clay_lump', 'default:clay_lump'},
	}
})

minetest.register_craft({
	output = 'default:clay_lump 4',
	recipe = {
		{'default:clay'},
	}
})

minetest.register_craft({
	output = 'default:brick',
	recipe = {
		{'default:clay_brick', 'default:clay_brick'},
		{'default:clay_brick', 'default:clay_brick'},
	}
})

minetest.register_craft({
	output = 'default:clay_brick 4',
	recipe = {
		{'default:brick'},
	}
})

minetest.register_craft({
	output = 'default:paper',
	recipe = {
		{'default:papyrus', 'default:papyrus', 'default:papyrus'},
	}
})

minetest.register_craft({
	-- Output count increased from 3 to 4, by MustTest.
	output = 'default:ladder_wood 4',
	recipe = {
		{'group:stick', '', 'group:stick'},
		{'group:stick', 'group:stick', 'group:stick'},
		{'group:stick', '', 'group:stick'},
	}
})

minetest.register_craft({
	-- Count reduced from 15 to 3, by MustTest
	output = 'default:ladder_steel 3',
	recipe = {
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', '', 'default:steel_ingot'},
	}
})

-- Needed so players can craft protections from mined crystals.
minetest.register_craft({
	output = 'default:mese',
	recipe = {
		{'default:mese_crystal', 'default:mese_crystal', 'default:mese_crystal'},
		{'default:mese_crystal', 'default:mese_crystal', 'default:mese_crystal'},
		{'default:mese_crystal', 'default:mese_crystal', 'default:mese_crystal'},
	}
})

	---[[
minetest.register_craft({
	output = 'default:mese_crystal 9',
	recipe = {{'default:mese'}}
})
	   --]]

	--[[
    minetest.register_craft({
      type = "grinding",
      output = "default:mese_crystal 9",
      recipe = "default:mese",
      time = 10,
    })
	   --]]

		---[[
minetest.register_craft({
	output = 'default:mese_crystal_fragment 9',
	recipe = {
		{'default:mese_crystal'},
	}
})
		   --]]

		--[[
    minetest.register_craft({
      type = "grinding",
      output = "default:mese_crystal_fragment 9",
      recipe = "default:mese_crystal",
      time = 10,
    })
		   --]]

minetest.register_craft({
	output = "default:mese_crystal",
	recipe = {
		{"default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment"},
		{"default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment"},
		{"default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment"},
	}
})

minetest.register_craft({
  output = 'default:meselamp',
  recipe = {
		{'', 'default:mese_crystal', ''},
		{'default:mese_crystal', 'default:glass', 'default:mese_crystal'},
	},
})

minetest.register_craft({
	output = 'default:lightbox',
	recipe = {
		{'group:stick', 'group:stick', 'group:stick'},
		{'default:glass', 'xdecor:lantern', 'default:glass'},
		{'group:stick', 'group:stick', 'group:stick'},
	}
})

minetest.register_craft({
  type = "grinding",
	output = 'default:obsidian_shard 9',
	recipe = 'default:obsidian',
})

minetest.register_craft({
	output = 'default:obsidian',
	recipe = {
		{'default:obsidian_shard', 'default:obsidian_shard', 'default:obsidian_shard'},
		{'default:obsidian_shard', 'default:obsidian_shard', 'default:obsidian_shard'},
		{'default:obsidian_shard', 'default:obsidian_shard', 'default:obsidian_shard'},
	}
})

minetest.register_craft({
	output = 'default:obsidianbrick 4',
	recipe = {
		{'default:obsidian', 'default:obsidian'},
		{'default:obsidian', 'default:obsidian'}
	}
})

minetest.register_craft({
	output = 'default:obsidian_block 9',
	recipe = {
		{'default:obsidian', 'default:obsidian', 'default:obsidian'},
		{'default:obsidian', 'default:obsidian', 'default:obsidian'},
		{'default:obsidian', 'default:obsidian', 'default:obsidian'},
	}
})

minetest.register_craft({
	output = 'default:stonebrick 4',
	recipe = {
		{'default:stone', 'default:stone'},
		{'default:stone', 'default:stone'},
	}
})

minetest.register_craft({
	output = 'default:stone_block 9',
	recipe = {
		{'default:stone', 'default:stone', 'default:stone'},
		{'default:stone', 'default:stone', 'default:stone'},
		{'default:stone', 'default:stone', 'default:stone'},
	}
})

minetest.register_craft({
	output = 'default:desert_stonebrick 4',
	recipe = {
		{'default:desert_stone', 'default:desert_stone'},
		{'default:desert_stone', 'default:desert_stone'},
	}
})

minetest.register_craft({
	output = 'default:desert_stone_block 9',
	recipe = {
		{'default:desert_stone', 'default:desert_stone', 'default:desert_stone'},
		{'default:desert_stone', 'default:desert_stone', 'default:desert_stone'},
		{'default:desert_stone', 'default:desert_stone', 'default:desert_stone'},
	}
})

minetest.register_craft({
	output = 'default:snowblock',
	recipe = {
		{'default:snow', 'default:snow', 'default:snow'},
		{'default:snow', 'default:snow', 'default:snow'},
		{'default:snow', 'default:snow', 'default:snow'},
	}
})

minetest.register_craft({
	output = 'default:snow 9',
	recipe = {
		{'default:snowblock'},
	}
})

--
-- Crafting (tool repair)
--
minetest.register_craft({
	type = "toolrepair",
	-- Buff increased from 0.02 to 0.15 percent, by MustTest.
	additional_wear = -0.15,
})

--
-- Cooking recipes
--

minetest.register_craft({
	type = "cooking",
	output = "default:glass",
	recipe = "group:sand",
})

minetest.register_craft({
	type = "cooking",
	output = "default:obsidian_glass",
	recipe = "default:obsidian_shard",
})

minetest.register_craft({
	type = "cooking",
	output = "default:stone",
	recipe = "default:cobble",
})

minetest.register_craft({
	type = "cooking",
	output = "default:stone",
	recipe = "default:mossycobble",
})

minetest.register_craft({
	type = "cooking",
	output = "default:desert_stone",
	recipe = "default:desert_cobble",
})

minetest.register_craft({
	type = "cooking",
	output = "default:steel_ingot",
	recipe = "default:iron_lump",
})

minetest.register_craft({
	type = "cooking",
	output = "default:copper_ingot",
	recipe = "default:copper_lump",
})

minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "default:gold_lump",
})

minetest.register_craft({
	type = "cooking",
	output = "default:clay_brick",
	recipe = "default:clay_lump",
})


--
-- Fuels
--

-- Support use of group:tree
minetest.register_craft({
	type = "fuel",
	recipe = "group:tree",
	burntime = 30,
})

-- Burn time for all woods are in order of wood density,
-- which is also the order of wood colour darkness:
-- aspen, pine, apple, acacia, jungle

minetest.register_craft({
	type = "fuel",
	recipe = "default:aspen_tree",
	burntime = 22,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:pine_tree",
	burntime = 26,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:tree",
	burntime = 30,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:acacia_tree",
	burntime = 34,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:jungletree",
	burntime = 38,
})


-- Support use of group:wood
minetest.register_craft({
	type = "fuel",
	recipe = "group:wood",
	burntime = 7,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:aspen_wood",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:pine_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:wood",
	burntime = 7,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:acacia_wood",
	burntime = 8,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:junglewood",
	burntime = 9,
})


-- Support use of group:sapling
minetest.register_craft({
	type = "fuel",
	recipe = "group:sapling",
	burntime = 10,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:aspen_sapling",
	burntime = 8,
})

minetest.register_craft({
	type = "fuel",
	recipe = "basictrees:pine_sapling",
	burntime = 9,
})

minetest.register_craft({
	type = "fuel",
	recipe = "basictrees:tree_sapling",
	burntime = 10,
})

minetest.register_craft({
	type = "fuel",
	recipe = "basictrees:acacia_sapling",
	burntime = 11,
})

minetest.register_craft({
	type = "fuel",
	recipe = "basictrees:jungletree_sapling",
	burntime = 12,
})


minetest.register_craft({
	type = "fuel",
	recipe = "default:fence_aspen_wood",
	burntime = 11,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:fence_pine_wood",
	burntime = 13,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:fence_wood",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:fence_acacia_wood",
	burntime = 17,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:fence_junglewood",
	burntime = 19,
})


minetest.register_craft({
	type = "fuel",
	recipe = "default:junglegrass",
	burntime = 2,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:leaves",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:cactus",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:papyrus",
	burntime = 1,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:ladder_wood",
	burntime = 5,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:lava_source",
	burntime = 60,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:sign_wall_wood",
	burntime = 10,
})

minetest.register_craft({
	type = "fuel",
	recipe = "basictrees:tree_apple",
	burntime = 3,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:coal_lump",
	burntime = 40,
})

minetest.register_craft({
	type = "coalfuel",
	recipe = "default:coal_lump",
	burntime = 40,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:coalblock",
	-- Burntime increased to 450 from 370, by MustTest.
	-- This makes it worth it to burn coal blocks instead of coal lumps.
	burntime = 450,
})

minetest.register_craft({
	type = "coalfuel",
	recipe = "default:coalblock",
	-- Burntime increased to 450 from 370, by MustTest.
	-- This makes it worth it to burn coal blocks instead of coal lumps.
	burntime = 450,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:grass_dummy",
	burntime = 2,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:dry_grass_dummy",
	burntime = 2,
})

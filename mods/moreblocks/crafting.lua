--[[
More Blocks: crafting recipes

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
--]]

-- Available crafting recipes chosen by MustTest.

minetest.register_craft({
	output = "moreblocks:wood_tile 9",
	recipe = {
		{"basictrees:jungletree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:jungletree_wood"},
	},
})

minetest.register_craft({
	output = "moreblocks:wood_tile_full 9",
	recipe = {
		{"basictrees:jungletree_wood", "basictrees:jungletree_wood", "basictrees:jungletree_wood"},
		{"basictrees:jungletree_wood", "basictrees:jungletree_wood", "basictrees:jungletree_wood"},
		{"basictrees:jungletree_wood", "basictrees:jungletree_wood", "basictrees:jungletree_wood"},
	},
})

minetest.register_craft({
	output = "moreblocks:wood_tile_center 9",
	recipe = {
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:jungletree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
	},
})

minetest.register_craft({
	output = "moreblocks:wood_tile_up 9",
	recipe = {
		{"basictrees:tree_wood", "basictrees:jungletree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
	},
})

minetest.register_craft({
	output = "moreblocks:wood_tile_down 9",
	recipe = {
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:jungletree_wood", "basictrees:tree_wood"},
	},
})

minetest.register_craft({
	output = "moreblocks:wood_tile_right 9",
	recipe = {
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:jungletree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
	},
})

minetest.register_craft({
	output = "moreblocks:wood_tile_left 9",
	recipe = {
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:jungletree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood", "basictrees:tree_wood"},
	},
})

minetest.register_craft({
	output = "default:stick 4",
	recipe = {
		{"default:dry_shrub"},
		{"default:dry_shrub"},
		{"default:dry_shrub"},
	}
})

minetest.register_craft({
	output = "default:stick 4",
	recipe = {
		{"default:dry_shrub", "default:dry_shrub", "default:dry_shrub"},
	}
})

minetest.register_craft({
	output = "default:stick 4",
	recipe = {{"basictrees:tree_sapling"},}
})

minetest.register_craft({
	output = "default:stick 8",
	recipe = {{"basictrees:jungletree_sapling"},}
})

minetest.register_craft({
	output = "moreblocks:circle_stone_bricks 8",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"default:stone", "",              "default:stone"},
		{"default:stone", "default:stone", "default:stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:circle_desert_stone_bricks 8",
	recipe = {
		{"default:desert_stone", "default:desert_stone", "default:desert_stone"},
		{"default:desert_stone", "",                     "default:desert_stone"},
		{"default:desert_stone", "default:desert_stone", "default:desert_stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:circle_sandstone 8",
	recipe = {
		{"default:sandstone", "default:sandstone", "default:sandstone"},
		{"default:sandstone", "",                  "default:sandstone"},
		{"default:sandstone", "default:sandstone", "default:sandstone"},
	}
})

minetest.register_craft({
	output = "moreblocks:stone_tile 4",
	recipe = {
		{"default:cobble", "default:cobble"},
		{"default:cobble", "default:cobble"},
	}
})

minetest.register_craft({
	output = "moreblocks:split_stone_tile",
	recipe = {
		{"moreblocks:stone_tile"},
	}
})

minetest.register_craft({
	output = "moreblocks:split_stone_tile_alt",
	recipe = {
		{"moreblocks:split_stone_tile"},
	}
})

minetest.register_craft({
	output = "moreblocks:grey_bricks 2",
	type = "shapeless",
	recipe =  {"default:stone", "default:brick"},
})

minetest.register_craft({
	output = "moreblocks:grey_bricks 2",
	type = "shapeless",
	recipe =  {"default:stonebrick", "default:brick"},
})

minetest.register_craft({
	output = "moreblocks:coal_stone_bricks 4",
	recipe = {
		{"moreblocks:coal_stone", "moreblocks:coal_stone"},
		{"moreblocks:coal_stone", "moreblocks:coal_stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:iron_stone_bricks 4",
	recipe = {
		{"moreblocks:iron_stone", "moreblocks:iron_stone"},
		{"moreblocks:iron_stone", "moreblocks:iron_stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:plankstone 4",
	recipe = {
		{"default:stone", "default:wood"},
		{"default:wood", "default:stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:plankstone 4",
	recipe = {
		{"default:wood", "default:stone"},
		{"default:stone", "default:wood"},
	}
})

minetest.register_craft({
	output = "moreblocks:coal_checker 4",
	recipe = {
		{"default:stone", "moreblocks:coal_stone"},
		{"moreblocks:coal_stone", "default:stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:coal_checker 4",
	recipe = {
		{"moreblocks:coal_stone", "default:stone"},
		{"default:stone", "moreblocks:coal_stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:iron_checker 4",
	recipe = {
		{"moreblocks:iron_stone", "default:stone"},
		{"default:stone", "moreblocks:iron_stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:iron_checker 4",
	recipe = {
		{"default:stone", "moreblocks:iron_stone"},
		{"moreblocks:iron_stone", "default:stone"},
	}
})

minetest.register_craft({
	output = "moreblocks:glow_glass",
	type = "shapeless",
	recipe = {"group:torch_craftitem", "default:glass", "dusts:diamond"},
})

minetest.register_craft({
	output = "moreblocks:super_glow_glass",
	type = "shapeless",
	recipe = {"group:torch_craftitem", "group:torch_craftitem", "default:glass", "dusts:diamond"},
})

minetest.register_craft({
	output = "moreblocks:super_glow_glass",
	type = "shapeless",
	recipe = {"group:torch_craftitem", "moreblocks:glow_glass", "dusts:diamond"},
})

minetest.register_craft({
	output = "moreblocks:coal_stone",
	type = "shapeless",
	recipe = {"dusts:coal", "default:stone"},
})

minetest.register_craft({
	output = "moreblocks:iron_stone",
	type = "shapeless",
	recipe = {"grinder:iron_dust", "default:stone"},
})

minetest.register_craft({
	type = "cooking", output = "moreblocks:tar", recipe = "default:gravel",
})

minetest.register_craft({
	type = "shapeless",
	output = "moreblocks:copperpatina",
	recipe = {"bucket:bucket_water", "default:copperblock"},
	replacements = {
		{"bucket:bucket_water", "bucket:bucket_empty"}
	}
})

minetest.register_craft({
	output = "default:copper_ingot 9",
	recipe = {
		{"moreblocks:copperpatina"},
	}
})

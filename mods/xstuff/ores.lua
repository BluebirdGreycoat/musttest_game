

---------------------nickel---------------------

minetest.register_craftitem("xtraores:nickel_ore", {
	description = "Nickel Lump",
	inventory_image = "xtraores_nickel_lump.png",
})

minetest.register_craft({
	type = "cooking",
	cooktime = 12,
	output = "xtraores:nickel_bar",
	recipe = "xtraores:nickel_ore",
})

---------------------platinum---------------------

minetest.register_craftitem("xtraores:platinum_ore", {
	description = "Platinum Lump",
	inventory_image = "xtraores_platinum_lump.png",
})

minetest.register_craft({
	type = "cooking",
	cooktime = 12,
	output = "xtraores:platinum_bar",
	recipe = "xtraores:platinum_ore",
})

---------------------palladium---------------------

minetest.register_craftitem("xtraores:palladium_ore", {
	description = "Palladium Lump",
	inventory_image = "xtraores_palladium_lump.png",
})

minetest.register_craft({
	type = "cooking",
	cooktime = 12,
	output = "xtraores:palladium_bar",
	recipe = "xtraores:palladium_ore",
})

---------------------cobalt---------------------

minetest.register_craftitem("xtraores:cobalt_ore", {
	description = "Cobalt Lump",
	inventory_image = "xtraores_cobalt_lump.png",
})

minetest.register_craft({
	type = "cooking",
	cooktime = 12,
	output = "xtraores:cobalt_bar",
	recipe = "xtraores:cobalt_ore",
})

--[[
---------------------thorium---------------------

minetest.register_node("xtraores:thorium_ore", {
		description = "" ..core.colorize("#68fff6", "Thorium ore\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 5"),
	tiles = {"default_stone.png^xtraores_thorium_ore.png"},
	inventory_image = "xtraores_thorium_lump.png",
	stack_max= 999,
	groups = {cracky = 5},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:thorium_ore",
		wherein        = "default:stone",
		clust_scarcity = 19 * 19 * 19,
		clust_num_ores = 4,
		clust_size     = 4,
		y_min          = -31000,
		y_max          = -1250,
	})

minetest.register_craft({
	type = "cooking",
	cooktime = 32,
	output = "xtraores:thorium_bar",
	recipe = "xtraores:thorium_ore",
})

-----------------antracite ore--------------

minetest.register_node("xtraores:antracite_ore", {
		description = "" ..core.colorize("#68fff6", "antracite\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 5"),
	tiles = {"default_stone.png^xtraores_antracite_ore.png"},
	inventory_image = "xtraores_antracite_lump.png",
	stack_max= 999,
	groups = {cracky = 5},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:antracite_ore",
		wherein        = "default:stone",
		clust_scarcity = 15 * 15 * 15,
		clust_num_ores = 6,
		clust_size     = 5,
		y_min          = -31000,
		y_max          = -2000,
	})

minetest.register_craft({
	output = 'xtraores:antracite_torch 5',
	recipe = {
		{'', '', ''},
		{'', 'xtraores:antracite_ore', ''},
		{'', 'xtraores:steel_handle', ''},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "xtraores:antracite_ore",
	burntime = 164,
})

---------------------osmium---------------------

minetest.register_node("xtraores:osmium_ore", {
		description = "" ..core.colorize("#68fff6", "Osmium ore\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 6"),
	tiles = {"default_stone.png^xtraores_osmium_ore.png"},
	inventory_image = "xtraores_osmium_lump.png",
	stack_max= 999,
	groups = {cracky = 6},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:osmium_ore",
		wherein        = "default:stone",
		clust_scarcity = 21 * 21 * 21,
		clust_num_ores = 4,
		clust_size     = 4,
		y_min          = -31000,
		y_max          = -3500,
	})

minetest.register_craft({
	type = "cooking",
	cooktime = 45,
	output = "xtraores:osmium_bar",
	recipe = "xtraores:osmium_ore",
})

---------------------rhenium---------------------

minetest.register_node("xtraores:rhenium_ore", {
		description = "" ..core.colorize("#68fff6", "Rhenium ore\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 7"),
	tiles = {"default_stone.png^xtraores_rhenium_ore.png"},
	inventory_image = "xtraores_rhenium_lump.png",
	stack_max= 999,
	groups = {cracky = 7},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:rhenium_ore",
		wherein        = "default:stone",
		clust_scarcity = 23 * 23 * 23,
		clust_num_ores = 4,
		clust_size     = 4,
		y_min          = -31000,
		y_max          = -5750,
	})

minetest.register_craft({
	type = "cooking",
	cooktime = 60,
	output = "xtraores:rhenium_bar",
	recipe = "xtraores:rhenium_ore",
})

---------------------vanadium---------------------

minetest.register_node("xtraores:vanadium_ore", {
		description = "" ..core.colorize("#68fff6", "vanadium ore\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 8"),
	tiles = {"default_stone.png^xtraores_vanadium_ore.png"},
	inventory_image = "xtraores_vanadium_lump.png",
	stack_max= 999,
	groups = {cracky = 8},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:vanadium_ore",
		wherein        = "default:stone",
		clust_scarcity = 26 * 26 * 26,
		clust_num_ores = 4,
		clust_size     = 4,
		y_min          = -31000,
		y_max          = -8000,
	})

minetest.register_craft({
	type = "cooking",
	cooktime = 75,
	output = "xtraores:vanadium_bar",
	recipe = "xtraores:vanadium_ore",
})

---------------------rarium---------------------

minetest.register_node("xtraores:rarium_ore", {
		description = "" ..core.colorize("#68fff6", "Rarium ore\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 9"),
	tiles = {{
		    name = "xtraores_rarium_ore.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1.0}
	}},
	light_source = 4,
	inventory_image = "xtraores_rarium_lump.png",
	stack_max= 999,
	groups = {cracky = 9},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:rarium_ore",
		wherein        = "default:stone",
		clust_scarcity = 30 * 30 * 30,
		clust_num_ores = 3,
		clust_size     = 3,
		y_min          = -31000,
		y_max          = -10000,
	})

minetest.register_craft({
	type = "cooking",
	cooktime = 90,
	output = "xtraores:rarium_bar",
	recipe = "xtraores:rarium_ore",
})

---------------------orichalcum---------------------

minetest.register_node("xtraores:orichalcum_ore", {
		description = "" ..core.colorize("#68fff6", "Orichalcum ore\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material\n")..core.colorize("#FFFFFF", "Xtraores ore level: 10"),
	tiles = {"default_stone.png^xtraores_orichalcum_ore.png"},
	inventory_image = "xtraores_orichalcum_lump.png",
	stack_max= 999,
	groups = {cracky = 10},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "xtraores:orichalcum_ore",
		wherein        = "default:stone",
		clust_scarcity = 34 * 34 * 34,
		clust_num_ores = 3,
		clust_size     = 3,
		y_min          = -31000,
		y_max          = -12500,
	})

minetest.register_craft({
	type = "cooking",
	cooktime = 120,
	output = "xtraores:orichalcum_bar",
	recipe = "xtraores:orichalcum_ore",
})
--]]


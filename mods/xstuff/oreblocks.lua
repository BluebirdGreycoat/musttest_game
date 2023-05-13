-----nickel--------

minetest.register_node("xtraores:brick_nickel", {
	description = "Nickel Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_nickel.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "xtraores:brick_nickel",
	recipe = {
		{'xtraores:nickel_bar', 'xtraores:nickel_bar'},
		{'xtraores:nickel_bar', 'xtraores:nickel_bar'},
	},
})

minetest.register_node("xtraores:decobrick_nickel", {
	description = "Nickel Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_nickel.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_nickel 4',
	recipe = {
		{'xtraores:brick_nickel', 'xtraores:brick_nickel'},
		{'xtraores:brick_nickel', 'xtraores:brick_nickel'},
	}
})

-----platinum--------

minetest.register_node("xtraores:brick_platinum", {
	description = "Platinum Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_platinum.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "xtraores:brick_platinum",
	recipe = {
		{'xtraores:platinum_bar', 'xtraores:platinum_bar'},
		{'xtraores:platinum_bar', 'xtraores:platinum_bar'},
	},
})

minetest.register_node("xtraores:decobrick_platinum", {
	description = "Platinum Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_platinum.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_platinum 4',
	recipe = {
		{'xtraores:brick_platinum', 'xtraores:brick_platinum'},
		{'xtraores:brick_platinum', 'xtraores:brick_platinum'},
	}
})

-----palladium--------

minetest.register_node("xtraores:brick_palladium", {
	description = "Palladium Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_palladium.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "xtraores:brick_palladium",
	recipe = {
		{'xtraores:palladium_bar', 'xtraores:palladium_bar'},
		{'xtraores:palladium_bar', 'xtraores:palladium_bar'},
	},
})

minetest.register_node("xtraores:decobrick_palladium", {
	description = "Palladium Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_palladium.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_palladium 4',
	recipe = {
		{'xtraores:brick_palladium', 'xtraores:brick_palladium'},
		{'xtraores:brick_palladium', 'xtraores:brick_palladium'},
	}
})

-----cobalt--------

minetest.register_node("xtraores:brick_cobalt", {
	description = "Cobalt Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_cobalt.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "xtraores:brick_cobalt",
	recipe = {
		{'xtraores:cobalt_bar', 'xtraores:cobalt_bar'},
		{'xtraores:cobalt_bar', 'xtraores:cobalt_bar'},
	},
})

minetest.register_node("xtraores:decobrick_cobalt", {
	description = "Cobalt Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_cobalt.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_cobalt 4',
	recipe = {
		{'xtraores:brick_cobalt', 'xtraores:brick_cobalt'},
		{'xtraores:brick_cobalt', 'xtraores:brick_cobalt'},
	}
})

--[[
-----thorium--------

minetest.register_node("xtraores:brick_thorium", {
		description = "" ..core.colorize("#68fff6", "thorium brick\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_thorium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 5},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:brick_thorium",
	recipe = {"xtraores:thorium_ore", "default:cobble"},
})

minetest.register_node("xtraores:block_thorium", {
		description = "" ..core.colorize("#68fff6", "thorium block\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_block_thorium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 5},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = 'xtraores:block_thorium',
	recipe = {
		{'xtraores:thorium_bar', 'xtraores:thorium_bar', 'xtraores:thorium_bar'},
		{'xtraores:thorium_bar', 'xtraores:thorium_bar', 'xtraores:thorium_bar'},
		{'xtraores:thorium_bar', 'xtraores:thorium_bar', 'xtraores:thorium_bar'},
	}
})

minetest.register_craft({
	output = 'xtraores:thorium_bar 9',
	recipe = {
		{'xtraores:block_thorium'},
	}
})
minetest.register_node("xtraores:decobrick_thorium", {
		description = "" ..core.colorize("#68fff6", "Decorative thorium brick\n")..core.colorize("#FFFFFF", "Can be placed"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_thorium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 5},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_thorium 4',
	recipe = {
		{'xtraores:brick_thorium', 'xtraores:brick_thorium', ''},
		{'xtraores:brick_thorium', 'xtraores:brick_thorium', ''},

	}
})

-----osmium--------

minetest.register_node("xtraores:brick_osmium", {
		description = "" ..core.colorize("#68fff6", "Osmium brick\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_osmium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 6},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:brick_osmium",
	recipe = {"xtraores:osmium_ore", "default:cobble"},
})

minetest.register_node("xtraores:block_osmium", {
		description = "" ..core.colorize("#68fff6", "Osmium block\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_block_osmium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 6},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = 'xtraores:block_osmium',
	recipe = {
		{'xtraores:osmium_bar', 'xtraores:osmium_bar', 'xtraores:osmium_bar'},
		{'xtraores:osmium_bar', 'xtraores:osmium_bar', 'xtraores:osmium_bar'},
		{'xtraores:osmium_bar', 'xtraores:osmium_bar', 'xtraores:osmium_bar'},
	}
})

minetest.register_craft({
	output = 'xtraores:osmium_bar 9',
	recipe = {
		{'xtraores:block_osmium'},
	}
})
minetest.register_node("xtraores:decobrick_osmium", {
		description = "" ..core.colorize("#68fff6", "Decorative Osmium brick\n")..core.colorize("#FFFFFF", "Can be placed"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_osmium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 6},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_osmium 4',
	recipe = {
		{'xtraores:brick_osmium', 'xtraores:brick_osmium', ''},
		{'xtraores:brick_osmium', 'xtraores:brick_osmium', ''},

	}
})

-----rhenium--------

minetest.register_node("xtraores:brick_rhenium", {
		description = "" ..core.colorize("#68fff6", "Rhenium brick\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_rhenium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 7},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:brick_rhenium",
	recipe = {"xtraores:rhenium_ore", "default:cobble"},
})

minetest.register_node("xtraores:block_rhenium", {
		description = "" ..core.colorize("#68fff6", "Rhenium block\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_block_rhenium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 7},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = 'xtraores:block_rhenium',
	recipe = {
		{'xtraores:rhenium_bar', 'xtraores:rhenium_bar', 'xtraores:rhenium_bar'},
		{'xtraores:rhenium_bar', 'xtraores:rhenium_bar', 'xtraores:rhenium_bar'},
		{'xtraores:rhenium_bar', 'xtraores:rhenium_bar', 'xtraores:rhenium_bar'},
	}
})

minetest.register_craft({
	output = 'xtraores:rhenium_bar 9',
	recipe = {
		{'xtraores:block_rhenium'},
	}
})
minetest.register_node("xtraores:decobrick_rhenium", {
		description = "" ..core.colorize("#68fff6", "Decorative Rhenium brick\n")..core.colorize("#FFFFFF", "Can be placed"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_rhenium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 7},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_rhenium 4',
	recipe = {
		{'xtraores:brick_rhenium', 'xtraores:brick_rhenium', ''},
		{'xtraores:brick_rhenium', 'xtraores:brick_rhenium', ''},

	}
})

-----vanadium--------

minetest.register_node("xtraores:brick_vanadium", {
		description = "" ..core.colorize("#68fff6", "Vanadium brick\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_brick_vanadium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 8},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:brick_vanadium",
	recipe = {"xtraores:vanadium_ore", "default:cobble"},
})

minetest.register_node("xtraores:block_vanadium", {
		description = "" ..core.colorize("#68fff6", "Vanadium block\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_block_vanadium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 8},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = 'xtraores:block_vanadium',
	recipe = {
		{'xtraores:vanadium_bar', 'xtraores:vanadium_bar', 'xtraores:vanadium_bar'},
		{'xtraores:vanadium_bar', 'xtraores:vanadium_bar', 'xtraores:vanadium_bar'},
		{'xtraores:vanadium_bar', 'xtraores:vanadium_bar', 'xtraores:vanadium_bar'},
	}
})

minetest.register_craft({
	output = 'xtraores:vanadium_bar 9',
	recipe = {
		{'xtraores:block_vanadium'},
	}
})
minetest.register_node("xtraores:decobrick_vanadium", {
		description = "" ..core.colorize("#68fff6", "Decorative Vanadium brick\n")..core.colorize("#FFFFFF", "Can be placed"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"xtraores_decobrick_vanadium.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 8},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_vanadium 4',
	recipe = {
		{'xtraores:brick_vanadium', 'xtraores:brick_vanadium', ''},
		{'xtraores:brick_vanadium', 'xtraores:brick_vanadium', ''},

	}
})

-----rarium--------

minetest.register_node("xtraores:brick_rarium", {
		description = "" ..core.colorize("#68fff6", "rarium brick\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	tiles = {{
		    name = "xtraores_brick_rarium.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.66}
	}},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 9},
	light_source = 5,
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:brick_rarium",
	recipe = {"xtraores:rarium_ore", "default:cobble"},
})

minetest.register_node("xtraores:block_rarium", {
		description = "" ..core.colorize("#68fff6", "rarium block\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	tiles = {{
		    name = "xtraores_block_rarium.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.66}
	}},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 9},
	light_source = 5,
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = 'xtraores:block_rarium',
	recipe = {
		{'xtraores:rarium_bar', 'xtraores:rarium_bar', 'xtraores:rarium_bar'},
		{'xtraores:rarium_bar', 'xtraores:rarium_bar', 'xtraores:rarium_bar'},
		{'xtraores:rarium_bar', 'xtraores:rarium_bar', 'xtraores:rarium_bar'},
	}
})

minetest.register_craft({
	output = 'xtraores:rarium_bar 9',
	recipe = {
		{'xtraores:block_rarium'},
	}
})
minetest.register_node("xtraores:decobrick_rarium", {
		description = "" ..core.colorize("#68fff6", "Decorative rarium brick\n")..core.colorize("#FFFFFF", "Can be placed"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {{
		    name = "xtraores_decobrick_rarium.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.66}
	}},
	is_ground_content = false,
	light_source = 5,
	stack_max= 999,
	groups = {cracky = 9},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_rarium 4',
	recipe = {
		{'xtraores:brick_rarium', 'xtraores:brick_rarium', ''},
		{'xtraores:brick_rarium', 'xtraores:brick_rarium', ''},

	}
})

-----orichalcum--------

minetest.register_node("xtraores:brick_orichalcum", {
		description = "" ..core.colorize("#68fff6", "orichalcum brick\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	tiles = {"xtraores_brick_orichalcum.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 10},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft( {
	type = "shapeless",
	output = "xtraores:brick_orichalcum",
	recipe = {"xtraores:orichalcum_ore", "default:cobble"},
})

minetest.register_node("xtraores:block_orichalcum", {
		description = "" ..core.colorize("#68fff6", "orichalcum block\n")..core.colorize("#FFFFFF", "Can be placed\n")..core.colorize("#FFFFFF", "Material"),
	tiles = {"xtraores_block_orichalcum.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 10},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = 'xtraores:block_orichalcum',
	recipe = {
		{'xtraores:orichalcum_bar', 'xtraores:orichalcum_bar', 'xtraores:orichalcum_bar'},
		{'xtraores:orichalcum_bar', 'xtraores:orichalcum_bar', 'xtraores:orichalcum_bar'},
		{'xtraores:orichalcum_bar', 'xtraores:orichalcum_bar', 'xtraores:orichalcum_bar'},
	}
})

minetest.register_craft({
	output = 'xtraores:orichalcum_bar 9',
	recipe = {
		{'xtraores:block_orichalcum'},
	}
})
minetest.register_node("xtraores:decobrick_orichalcum", {
		description = "" ..core.colorize("#68fff6", "Decorative orichalcum brick\n")..core.colorize("#FFFFFF", "Can be placed"),
	tiles = {"xtraores_decobrick_orichalcum.png"},
	is_ground_content = false,
	stack_max= 999,
	groups = {cracky = 10},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = 'xtraores:decobrick_orichalcum 4',
	recipe = {
		{'xtraores:brick_orichalcum', 'xtraores:brick_orichalcum', ''},
		{'xtraores:brick_orichalcum', 'xtraores:brick_orichalcum', ''},

	}
})
--]]

local settings = Settings(minetest.get_modpath("quartz").."/settings.txt")

--
--  Item Registration
--

--  Quartz Crystal
minetest.register_craftitem("quartz:quartz_crystal", {
	description = "Quartz Crystal",
	inventory_image = "quartz_crystal_full.png",
})
minetest.register_craftitem("quartz:quartz_crystal_piece", {
	description = "Quartz Crystal Piece",
	inventory_image = "quartz_crystal_piece.png",
})

--
-- Node Registration
--

--  Ore
minetest.register_node("quartz:quartz_ore", {
	description = "Quartz Ore",
	tiles = {"default_stone.png^quartz_ore.png"},
	groups = utility.dig_groups("mineral"),
	drop = 'quartz:quartz_crystal',
	_tnt_drop = 'quartz:quartz_crystal 3',
	sounds = default.node_sound_stone_defaults(),
	silverpick_drop = true,
	place_param2 = 10,
})

oregen.register_ore({
	ore_type = "scatter",
	ore = "quartz:quartz_ore",
	wherein = "default:stone",
	clust_scarcity = 10*10*10,
	clust_num_ores = 6,
	clust_size = 5,
	y_min = -25000,
	y_max = -5,
})

-- Quartz Block
minetest.register_node("quartz:block", {
	description = "Quartz Block",
	tiles = {"quartz_block.png"},
	groups = utility.dig_groups("block"),
	sounds = default.node_sound_glass_defaults(),
})

-- Chiseled Quartz
minetest.register_node("quartz:chiseled", {
	description = "Chiseled Quartz",
	tiles = {"quartz_chiseled.png"},
	groups = utility.dig_groups("brick"),
	sounds = default.node_sound_glass_defaults(),
})

-- Quartz Pillar
minetest.register_node("quartz:pillar", {
	description = "Quartz Pillar",
	paramtype2 = "facedir",
	tiles = {"quartz_pillar_top.png", "quartz_pillar_top.png", "quartz_pillar_side.png"},
	groups = utility.dig_groups("brick"),
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node
})

--
-- Crafting
--

-- Quartz Crystal Piece
minetest.register_craft({
	output = '"quartz:quartz_crystal_piece" 3',
	recipe = {
		{'quartz:quartz_crystal'}
	}
})

-- Quartz Block
minetest.register_craft({
	output = '"quartz:block" 4',
	recipe = {
		{'quartz:quartz_crystal', 'quartz:quartz_crystal'},
		{'quartz:quartz_crystal', 'quartz:quartz_crystal'},
	}
})

-- Chiseled Quartz
minetest.register_craft({
	output = 'quartz:chiseled 4',
	recipe = {
		{'quartz:block', 'quartz:block'},
		{'quartz:block', 'quartz:block'},
	}
})

-- Quartz Pillar
minetest.register_craft({
	output = 'quartz:pillar 3',
	recipe = {
		{'quartz:block'},
		{'quartz:block'},
		{'quartz:block'},
	}
})


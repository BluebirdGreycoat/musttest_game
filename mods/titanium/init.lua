
-- The textures starting with "j1_*" are by J1,
-- who made them for this server under the MIT license.
-- They have been modified from the originals.

titanium = titanium or {}
titanium.modpath = minetest.get_modpath("titanium")



-- Ore in Stone.
minetest.register_node("titanium:ore", {
	description = "Titanium Ore",
	tiles = { "default_stone.png^titanium_ore.png" },
	is_ground_content = true,
	groups = {level=3, cracky=2, ore = 1},
	sounds = default.node_sound_stone_defaults(),
	drop = "titanium:titanium",
	silverpick_drop = true,
})



-- Block.
minetest.register_node("titanium:block", {
	description = "Titanium Block",
	tiles = { "titanium_block.png" },
	is_ground_content = true,
	groups = {cracky=1, level=3},
	sounds = default.node_sound_metal_defaults(),
})



-- Lump.
minetest.register_craftitem("titanium:titanium", {
	description = "Raw Titanium",
	inventory_image = "titanium_lump.png",
})



-- Hardened titanium (ingot-like).
minetest.register_craftitem("titanium:crystal", {
	description = "Hardened Titanium",
	inventory_image = "titanium_crystal.png",
})



-- Sword.
minetest.register_tool("titanium:sword", {
	description = "Titanium Sword",
	inventory_image = "j1_titanium_sword.png",
	tool_capabilities = tooldata["sword_titanium"],
  sound = {breaks = "basictools_tool_breaks"},
})



-- Axe.
minetest.register_tool("titanium:axe", {
	description = "Titanium Axe",
	inventory_image = "j1_titanium_axe.png",
	tool_capabilities = tooldata["axe_titanium"],
    sound = {breaks = "basictools_tool_breaks"},
})



-- Shovel.
minetest.register_tool("titanium:shovel", {
	description = "Titanium Shovel",
	inventory_image = "j1_titanium_shovel.png",
	tool_capabilities = tooldata["shovel_titanium"],
    sound = {breaks = "basictools_tool_breaks"},
})



-- Pick.
minetest.register_tool("titanium:pick", {
    description = "Titanium Pickaxe",
    inventory_image = "j1_titanium_pick.png",
    tool_capabilities = tooldata["pick_titanium"],
    sound = {breaks = "basictools_tool_breaks"},
})



-- Craft pick.
minetest.register_craft({
	output = 'titanium:pick',
	recipe = {
		{'titanium:crystal', 'titanium:crystal', 'titanium:crystal'},
		{'', 'default:stick', ''},
		{'', 'default:stick', ''},
	}
})



-- Craft axe (front recipe).
minetest.register_craft({
	output = 'titanium:axe',
	recipe = {
		{'titanium:crystal', 'titanium:crystal', ''},
		{'titanium:crystal', 'default:stick', ''},
		{'', 'default:stick', ''},
	}
})



-- Craft axe (reverse recipe).
minetest.register_craft({
	output = 'titanium:axe',
	recipe = {
		{'titanium:crystal', 'titanium:crystal', ''},
		{'default:stick', 'titanium:crystal', ''},
		{'default:stick', '', ''},
	}
})



-- Craft shovel.
minetest.register_craft({
	output = 'titanium:shovel',
	recipe = {
		{'', 'titanium:crystal', ''},
		{'', 'default:stick', ''},
		{'', 'default:stick', ''},
	}
})



-- Craft sword.
minetest.register_craft({
	output = 'titanium:sword',
	recipe = {
		{'', 'titanium:crystal', ''},
		{'', 'titanium:crystal', ''},
		{'', 'default:stick', ''},
	}
})



-- Craft block.
minetest.register_craft({
	output = 'titanium:block',
	recipe = {
		{'titanium:titanium', 'titanium:titanium', 'titanium:titanium'},
		{'titanium:titanium', 'titanium:titanium', 'titanium:titanium'},
		{'titanium:titanium', 'titanium:titanium', 'titanium:titanium'},
	}
})



-- Craft lumps.
minetest.register_craft({
	output = 'titanium:titanium 9',
	recipe = {
		{'', 'titanium:block', ''},
	}
})



-- Cook lumps to ingots.
minetest.register_craft({
	type = "cooking",
	output = "titanium:crystal",
	recipe = "titanium:titanium",
})


-- Ore generation.
oregen.register_ore({
	ore_type = "scatter",
	ore = "titanium:ore",
	wherein = "default:stone",
	clust_scarcity = 10*10*10,
	clust_num_ores = 6,
	clust_size = 5,
	y_min = -31000,
	y_max = -64,
})



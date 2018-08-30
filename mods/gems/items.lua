
--             --
--Item registry--
--             --

--
--Ores
--

minetest.register_node("gems:ruby_ore", {
	  description = "Ruby Ore",
	  tiles = {"default_stone.png^gems_ruby_ore.png"},
	  is_ground_content = true,
	  groups = {level=3, cracky=1},
	  sounds = default.node_sound_stone_defaults(),
	  drop = 'craft "gems:raw_ruby" 1',
})

minetest.register_node("gems:emerald_ore", {
	  description = "Emerald Ore",
	  tiles = {"default_stone.png^gems_emerald_ore.png"},
	  is_ground_content = true,
	  groups = {level=3, cracky=1},
	  sounds = default.node_sound_stone_defaults(),
	  drop = 'craft "gems:raw_emerald" 1',
})

minetest.register_node("gems:sapphire_ore", {
	  description = "Sapphire Ore",
	  tiles = {"default_stone.png^gems_sapphire_ore.png"},
	  is_ground_content = true,
	  groups = {level=3, cracky=1},
	  sounds = default.node_sound_stone_defaults(),
	  drop = 'craft "gems:raw_sapphire" 1',
})

minetest.register_node("gems:amethyst_ore", {
	  description = "Amethyst Ore",
	  tiles = {"default_stone.png^gems_amethyst_ore.png"},
	  is_ground_content = true,
	  groups = {level=3, cracky=1},
	  sounds = default.node_sound_stone_defaults(),
	  drop = 'craft "gems:raw_amethyst" 1',
})

--
--Blocks
--

minetest.register_node( "gems:ruby_block", {
	description = "Ruby Block",
	tiles = { "ruby_ruby_block.png" },
	is_ground_content = false,
	groups = {level=3, cracky=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node( "gems:emerald_block", {
	description = "Emerald Block",
	tiles = { "gems_emerald_block.png" },
	is_ground_content = false,
	groups = {level=3, cracky=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node( "gems:sapphire_block", {
	description = "Sapphire Block",
	tiles = { "gems_sapphire_block.png" },
	is_ground_content = false,
	groups = {level=3, cracky=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node( "gems:amethyst_block", {
	description = "Amethyst Block",
	tiles = { "gems_amethyst_block.png" },
	is_ground_content = false,
	groups = {level=3, cracky=1},
	sounds = default.node_sound_stone_defaults(),
})

--
--Gems
--
  
minetest.register_craftitem( "gems:ruby_gem", {
	description = "Ruby Gem",
	inventory_image = "ruby_ruby_gem.png",
})

minetest.register_craftitem( "gems:emerald_gem", {
	description = "Emerald Gem",
	inventory_image = "gems_emerald_gem.png",
})

minetest.register_craftitem( "gems:sapphire_gem", {
	description = "Sapphire Gem",
	inventory_image = "gems_sapphire_gem.png",
})

minetest.register_craftitem( "gems:amethyst_gem", {
	description = "Amethyst Gem",
	inventory_image = "gems_amethyst_gem.png",
})

--
--crafting items
--

--minetest.register_craftitem( "gems:stone_rod", {
--  description = "Reinforced Tool Handle",
--  inventory_image = "gems_stone_rod.png",
--})

-- Give players back their steel ingots.
minetest.register_alias("gems:stone_rod", "default:steel_ingot")




minetest.register_craftitem( "gems:raw_amethyst", {
	description = "Amethyst Gem (Uncut)",
	inventory_image = "gems_raw_amethyst.png",
})

minetest.register_craftitem( "gems:raw_ruby", {
	description = "Ruby Gem (Uncut)",
	inventory_image = "gems_raw_ruby.png",
})

minetest.register_craftitem( "gems:raw_emerald", {
	description = "Emerald Gem (Uncut)",
	inventory_image = "gems_raw_emerald.png",
})

minetest.register_craftitem( "gems:raw_sapphire", {
	description = "Sapphire Gem (Uncut)",
	inventory_image = "gems_raw_sapphire.png",
})



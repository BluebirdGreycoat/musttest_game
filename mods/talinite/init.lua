
minetest.register_node("talinite:ore", {
  description = "Talinite Ore",
  tiles = {"default_stone.png^gloopores_mineral_talinite.png"},
  groups = utility.dig_groups("hardmineral", {ore = 1}),
  drop = "talinite:lump",
  _tnt_drop = {
    "talinite:lump 2",
    "talinite:dust",
  },
	silverpick_drop = true,
  --light_source = 6, -- This ore glows. (Buggy? Does not update light.)
  sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("talinite:desert_ore", {
  description = "Desert Talinite Ore",
  tiles = {"default_desert_stone.png^gloopores_mineral_talinite.png"},
  groups = utility.dig_groups("hardmineral", {ore = 1}),
  drop = "talinite:dust",
  _tnt_drop = {
    "talinite:lump",
  },
	silverpick_drop = true,
  --light_source = 6, -- This ore glows. (Buggy? Does not update light.)
  sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "talinite:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -50,
  y_max       = 300,
})

minetest.register_craftitem("talinite:lump", {
  description = "Talinite Lump",
  inventory_image = "gloopores_talinite_lump.png",
})

minetest.register_craft({
  type = "cooking",
  output = "talinite:ingot",
  recipe = "talinite:lump",
})

minetest.register_craftitem("talinite:dust", {
  description = "Talinite Dust",
  inventory_image = "technic_talinite_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "talinite:ingot",
  recipe = "talinite:dust",
})

minetest.register_craft({
  type = "grinding",
  output = 'talinite:dust 2',
  recipe = 'talinite:lump',
  time = 10,
})

minetest.register_craft({
  type = "anvil",
  output = 'talinite:dust 2',
  recipe = 'talinite:lump',
})

minetest.register_craftitem("talinite:ingot", {
  description = "Talinite Ingot",
  inventory_image = "gloopores_talinite_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'talinite:dust',
  recipe = 'talinite:ingot',
  time = 10,
})

minetest.register_node("talinite:block", {
  description = "Talinite Block",
  tiles = {"gloopores_talinite_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block"),
  light_source = 14,
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "talinite_block",
  "talinite:block",
  {cracky = 1},
  {"gloopores_talinite_block.png"},
  "Talinite Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "talinite:block",
  recipe = {
    {"talinite:ingot", "talinite:ingot", "talinite:ingot"},
    {"talinite:ingot", "talinite:ingot", "talinite:ingot"},
    {"talinite:ingot", "talinite:ingot", "talinite:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "talinite:ingot 9",
  recipe = {"talinite:block"},
})

minetest.register_node("talinite:glass", {
  description = "Talinite Glass",
  drawtype = "glasslike_framed_optional",
  tiles = {"glooptest_talinite_crystal_glass.png"},
  paramtype = "light",
  sunlight_propagates = true,
  light_source = 10,
  is_ground_content = false,
  groups = utility.dig_groups("glass"),
  sounds = default.node_sound_glass_defaults(),
	silverpick_drop = true,
	node_dig_prediction = "",

	drop = {
		max_items = 2,
		items = {
			{
				items = {"vessels:glass_fragments", "talinite:dust"},
				rarity = 1,
			},
		}
	},
})

minetest.register_craft({
	type = "alloying",
	output = "talinite:glass",
	recipe = {"default:glass", "talinite:ingot"},
	time = 6,
})


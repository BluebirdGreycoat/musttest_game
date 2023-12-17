
minetest.register_node("alatro:ore", {
  description = "Alatro Ore",
  tiles = {"default_stone.png^gloopores_mineral_alatro.png"},
  groups = utility.dig_groups("hardmineral", {ore=1}),
  drop = "alatro:lump",
  _tnt_drop = {
    "alatro:lump",
    "alatro:dust",
  },
	silverpick_drop = true,
  sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "alatro:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -50,
  y_max       = 300,
})

minetest.register_craftitem("alatro:lump", {
  description = "Alatro Lump",
  inventory_image = "gloopores_alatro_lump.png",
})

minetest.register_craft({
  type = "cooking",
  output = "alatro:ingot",
  recipe = "alatro:lump",
})

minetest.register_craftitem("alatro:dust", {
  description = "Alatro Dust",
  inventory_image = "technic_alatro_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "alatro:ingot",
  recipe = "alatro:dust",
})

minetest.register_craft({
  type = "grinding",
  output = 'alatro:dust 2',
  recipe = 'alatro:lump',
  time = 10,
})

minetest.register_craft({
  type = "anvil",
  output = 'alatro:dust 2',
  recipe = 'alatro:lump',
})

minetest.register_craftitem("alatro:ingot", {
  description = "Alatro Ingot",
  inventory_image = "gloopores_alatro_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'alatro:dust',
  recipe = 'alatro:ingot',
  time = 10,
})

minetest.register_node("alatro:block", {
  description = "Alatro Block",
  tiles = {"gloopores_alatro_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block"),
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "alatro_block",
  "alatro:block",
  {cracky = 1},
  {"gloopores_alatro_block.png"},
  "Alatro Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "alatro:block",
  recipe = {
    {"alatro:ingot", "alatro:ingot", "alatro:ingot"},
    {"alatro:ingot", "alatro:ingot", "alatro:ingot"},
    {"alatro:ingot", "alatro:ingot", "alatro:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "alatro:ingot 9",
  recipe = {"alatro:block"},
})

minetest.register_node("alatro:glass", {
  description = "Alatro Glass",
  drawtype = "glasslike_framed_optional",
  tiles = {"glooptest_alatro_crystal_glass.png"},
  paramtype = "light",
  sunlight_propagates = true,
  is_ground_content = false,
  groups = utility.dig_groups("glass"),
  sounds = default.node_sound_glass_defaults(),
	silverpick_drop = true,
	node_dig_prediction = "",

	drop = {
		max_items = 2,
		items = {
			{
				items = {"vessels:glass_fragments", "alatro:dust"},
				rarity = 1,
			},
		}
	},
})

minetest.register_craft({
	type = "alloying",
	output = "alatro:glass",
	recipe = {"default:glass", "alatro:ingot"},
	time = 6,
})

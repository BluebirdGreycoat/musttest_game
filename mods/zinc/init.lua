
minetest.register_node("zinc:ore", {
  description = "Zinc Ore",
  tiles = {"default_stone.png^technic_zinc_mineral.png"},
  groups = utility.dig_groups("mineral", {ore = 1}),
  drop = "zinc:lump",
  _tnt_drop = {
    "zinc:lump 2",
    "zinc:dust 2",
  },
	silverpick_drop = true,
  sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "zinc:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -100,
  y_max       = 300,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "zinc:ore",
  wherein          = "default:stone",
  clust_scarcity   = 6*6*6,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -256,
  y_max       = -100,
})

minetest.register_craftitem("zinc:lump", {
  description = "Zinc Lump",
  inventory_image = "technic_zinc_lump.png",
})

minetest.register_craft({
  type = "cooking",
  output = "zinc:ingot",
  recipe = "zinc:lump",
})

minetest.register_craftitem("zinc:dust", {
  description = "Zinc Dust",
  inventory_image = "technic_zinc_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "zinc:ingot",
  recipe = "zinc:dust",
})

minetest.register_craft({
  type = "grinding",
  output = 'zinc:dust 2',
  recipe = 'zinc:lump',
  time = 10,
})

minetest.register_craftitem("zinc:ingot", {
  description = "Zinc Ingot",
  inventory_image = "technic_zinc_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'zinc:dust',
  recipe = 'zinc:ingot',
  time = 10,
})

minetest.register_node("zinc:block", {
  description = "Zinc Block",
  tiles = {"technic_zinc_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block", {conductor = 1, block = 1}),
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "zinc_block",
  "zinc:block",
  {cracky = 1},
  {"technic_zinc_block.png"},
  "Zinc Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "zinc:block",
  recipe = {
    {"zinc:ingot", "zinc:ingot", "zinc:ingot"},
    {"zinc:ingot", "zinc:ingot", "zinc:ingot"},
    {"zinc:ingot", "zinc:ingot", "zinc:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "zinc:ingot 9",
  recipe = {"zinc:block"},
})

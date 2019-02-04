
minetest.register_node("chromium:ore", {
  description = "Chromium Ore",
  tiles = {"default_stone.png^technic_chromium_mineral.png"},
  groups = {level = 1, cracky = 1, ore = 1},
  drop = "chromium:lump",
  sounds = default.node_sound_stone_defaults(),
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "chromium:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -200,
  y_max       = -100,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "chromium:ore",
  wherein          = "default:stone",
  clust_scarcity   = 6*6*6,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -512,
  y_max       = -200,
})

minetest.register_craftitem("chromium:lump", {
  description = "Chromium Lump",
  inventory_image = "technic_chromium_lump.png",
})

minetest.register_craft({
  type = "cooking",
  output = "chromium:ingot",
  recipe = "chromium:lump",
})

minetest.register_craftitem("chromium:dust", {
  description = "Chromium Dust",
  inventory_image = "technic_chromium_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "chromium:ingot",
  recipe = "chromium:dust",
})

minetest.register_craft({
  type = "grinding",
  output = 'chromium:dust 2',
  recipe = 'chromium:lump',
  time = 10,
})

minetest.register_craftitem("chromium:ingot", {
  description = "Chromium Ingot",
  inventory_image = "technic_chromium_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'chromium:dust',
  recipe = 'chromium:ingot',
  time = 10,
})

minetest.register_node("chromium:block", {
  description = "Chromium Block",
  tiles = {"technic_chromium_block.png"},
  is_ground_content = false,
  groups = {cracky = 1, level = 2, conductor = 1, block = 1},
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "chromium_block",
  "chromium:block",
  {cracky = 1},
  {"technic_chromium_block.png"},
  "Chromium Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "chromium:block",
  recipe = {
    {"chromium:ingot", "chromium:ingot", "chromium:ingot"},
    {"chromium:ingot", "chromium:ingot", "chromium:ingot"},
    {"chromium:ingot", "chromium:ingot", "chromium:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "chromium:ingot 9",
  recipe = {"chromium:block"},
})

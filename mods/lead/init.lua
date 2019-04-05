
minetest.register_node("lead:ore", {
  description = "Lead Ore",
  tiles = {"default_stone.png^technic_lead_mineral.png"},
  groups = utility.dig_groups("mineral", {ore=1}),
  drop = "lead:lump",
	silverpick_drop = true,
  sounds = default.node_sound_stone_defaults(),
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "lead:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -512,
  y_max       = -256,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "lead:ore",
  wherein          = "default:stone",
  clust_scarcity   = 6*6*6,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -824,
  y_max       = -512,
})

minetest.register_craftitem("lead:lump", {
  description = "Lead Lump",
  inventory_image = "technic_lead_lump.png",
})

minetest.register_craft({
  type = "cooking",
  output = "lead:ingot",
  recipe = "lead:lump",
})

minetest.register_craftitem("lead:dust", {
  description = "Lead Dust",
  inventory_image = "technic_lead_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "lead:ingot",
  recipe = "lead:dust",
})

minetest.register_craft({
  type = "grinding",
  output = 'lead:dust 2',
  recipe = 'lead:lump',
})

minetest.register_craftitem("lead:ingot", {
  description = "Lead Ingot",
  inventory_image = "technic_lead_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'lead:dust',
  recipe = 'lead:ingot',
})

minetest.register_node("lead:block", {
  description = "Lead Block",
  tiles = {"technic_lead_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block"),
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "lead_block",
  "lead:block",
  {cracky = 1},
  {"technic_lead_block.png"},
  "Lead Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "lead:block",
  recipe = {
    {"lead:ingot", "lead:ingot", "lead:ingot"},
    {"lead:ingot", "lead:ingot", "lead:ingot"},
    {"lead:ingot", "lead:ingot", "lead:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "lead:ingot 9",
  recipe = {"lead:block"},
})

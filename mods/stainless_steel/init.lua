
minetest.register_craftitem("stainless_steel:dust", {
  description = "Stainless Steel Dust",
  inventory_image = "technic_stainless_steel_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "stainless_steel:ingot",
  recipe = "stainless_steel:dust",
})

minetest.register_craftitem("stainless_steel:ingot", {
  description = "Stainless Steel Ingot",
  inventory_image = "technic_stainless_steel_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'stainless_steel:dust',
  recipe = 'stainless_steel:ingot',
  time = 10,
})

minetest.register_node("stainless_steel:block", {
  description = "Stainless Steel Block",
  tiles = {"technic_stainless_steel_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block"),
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "stainless_steel_block",
  "stainless_steel:block",
  {cracky = 1},
  {"technic_stainless_steel_block.png"},
  "Stainless Steel Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "stainless_steel:block",
  recipe = {
    {"stainless_steel:ingot", "stainless_steel:ingot", "stainless_steel:ingot"},
    {"stainless_steel:ingot", "stainless_steel:ingot", "stainless_steel:ingot"},
    {"stainless_steel:ingot", "stainless_steel:ingot", "stainless_steel:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "stainless_steel:ingot 9",
  recipe = {"stainless_steel:block"},
})

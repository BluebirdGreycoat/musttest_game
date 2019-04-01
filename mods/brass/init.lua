
minetest.register_craftitem("brass:dust", {
  description = "Brass Dust",
  inventory_image = "technic_brass_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "brass:ingot",
  recipe = "brass:dust",
})

minetest.register_craftitem("brass:ingot", {
  description = "Brass Ingot",
  inventory_image = "technic_brass_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'brass:dust',
  recipe = 'brass:ingot',
  time = 10,
})

minetest.register_node("brass:block", {
  description = "Brass Block",
  tiles = {"technic_brass_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block"),
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "brass_block",
  "brass:block",
  {cracky = 1},
  {"technic_brass_block.png"},
  "Brass Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "brass:block",
  recipe = {
    {"brass:ingot", "brass:ingot", "brass:ingot"},
    {"brass:ingot", "brass:ingot", "brass:ingot"},
    {"brass:ingot", "brass:ingot", "brass:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "brass:ingot 9",
  recipe = {"brass:block"},
})

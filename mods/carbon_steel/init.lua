
minetest.register_craftitem("carbon_steel:dust", {
  description = "Carbon Steel Dust",
  inventory_image = "technic_carbon_steel_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "carbon_steel:ingot",
  recipe = "carbon_steel:dust",
})

minetest.register_craftitem("carbon_steel:ingot", {
  description = "Carbon Steel Ingot",
  inventory_image = "technic_carbon_steel_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'carbon_steel:dust',
  recipe = 'carbon_steel:ingot',
  time = 10,
})

minetest.register_node("carbon_steel:block", {
  description = "Carbon Steel Block",
  tiles = {"technic_carbon_steel_block.png"},
  is_ground_content = false,
  groups = utility.dig_groups("block"),
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "carbon_steel_block",
  "carbon_steel:block",
  {cracky = 1},
  {"technic_carbon_steel_block.png"},
  "Carbon Steel Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "carbon_steel:block",
  recipe = {
    {"carbon_steel:ingot", "carbon_steel:ingot", "carbon_steel:ingot"},
    {"carbon_steel:ingot", "carbon_steel:ingot", "carbon_steel:ingot"},
    {"carbon_steel:ingot", "carbon_steel:ingot", "carbon_steel:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "carbon_steel:ingot 9",
  recipe = {"carbon_steel:block"},
})

minetest.register_craft({
  type = "cooking",
  output = "default:steel_ingot",
  recipe = "carbon_steel:ingot",
})

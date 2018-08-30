
minetest.register_craftitem("cast_iron:dust", {
  description = "Cast Iron Dust",
  inventory_image = "technic_cast_iron_dust.png"
})

minetest.register_craft({
  type = "cooking",
  output = "cast_iron:ingot",
  recipe = "cast_iron:dust",
})

minetest.register_craftitem("cast_iron:ingot", {
  description = "Cast Iron Ingot",
  inventory_image = "technic_cast_iron_ingot.png",
  groups = {ingot = 1},
})

minetest.register_craft({
  type = "grinding",
  output = 'cast_iron:dust',
  recipe = 'cast_iron:ingot',
  time = 10,
})

minetest.register_node("cast_iron:block", {
  description = "Cast Iron Block",
  tiles = {"technic_cast_iron_block.png"},
  is_ground_content = false,
  groups = {cracky = 1, level = 2},
  sounds = default.node_sound_metal_defaults(),
})

stairs.register_stair_and_slab(
  "cast_iron_block",
  "cast_iron:block",
  {cracky = 1},
  {"technic_cast_iron_block.png"},
  "Cast Iron Block",
  default.node_sound_metal_defaults()
)

minetest.register_craft({
  output = "cast_iron:block",
  recipe = {
    {"cast_iron:ingot", "cast_iron:ingot", "cast_iron:ingot"},
    {"cast_iron:ingot", "cast_iron:ingot", "cast_iron:ingot"},
    {"cast_iron:ingot", "cast_iron:ingot", "cast_iron:ingot"},
  },
})

minetest.register_craft({
  type = "shapeless",
  output = "cast_iron:ingot 9",
  recipe = {"cast_iron:block"},
})

minetest.register_craft({
  type = "cooking",
  output = "default:steel_ingot",
  recipe = "cast_iron:ingot",
})

minetest.register_craft({
  type = "cooking",
  output = "cast_iron:ingot",
  recipe = "default:steel_ingot",
})

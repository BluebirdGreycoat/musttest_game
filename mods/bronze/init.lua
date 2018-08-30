
minetest.register_craftitem("bronze:dust", {
  description = "Bronze Dust",
  inventory_image = "technic_bronze_dust.png"
})

minetest.register_craft({
  type = "grinding",
  output = 'bronze:dust',
  recipe = 'default:bronze_ingot',
  time = 8,
})

minetest.register_craft({
  type = "cooking",
  output = "default:bronze_ingot",
  recipe = "bronze:dust",
})

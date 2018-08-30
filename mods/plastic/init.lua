
minetest.register_craftitem("plastic:oil_extract", {
  description = "Oil Extract",
  inventory_image = "homedecor_oil_extract.png",
})

minetest.register_craftitem("plastic:raw_paraffin", {
  description = "Unprocessed Paraffin",
  inventory_image = "homedecor_paraffin.png",
})

minetest.register_craftitem("plastic:plastic_sheeting", {
  description = "Plastic Sheet",
  inventory_image = "homedecor_plastic_sheeting.png",
})

minetest.register_craft({
  type = "shapeless",
  output = "plastic:oil_extract 4",
  recipe = {
    "group:leaves",
    "group:leaves",
    "group:leaves",
    "group:leaves",
    "group:leaves",
    "group:leaves",
  },
})

minetest.register_craft({
  type = "cooking",
  output = "plastic:raw_paraffin",
  recipe = "plastic:oil_extract",
})

minetest.register_craft({
  type = "cooking",
  output = "plastic:plastic_sheeting",
  recipe = "plastic:raw_paraffin",
})

minetest.register_craft({
  type = "fuel",
  recipe = "plastic:oil_extract",
  burntime = 20,
})

minetest.register_craft({
  type = "coalfuel",
  recipe = "plastic:oil_extract",
  burntime = 20,
})

minetest.register_craft({
  type = "fuel",
  recipe = "plastic:raw_paraffin",
  burntime = 20,
})

minetest.register_craft({
  type = "fuel",
  recipe = "plastic:plastic_sheeting",
  burntime = 20,
})

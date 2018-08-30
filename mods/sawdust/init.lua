
minetest.register_craftitem("sawdust:sawdust", {
  description = "Sawdust",
  inventory_image = "technic_sawdust.png",
})

minetest.register_craftitem("sawdust:common_tree_grindings", {
  description = "Common Tree Grindings",
  inventory_image = "technic_common_tree_grindings.png",
})

minetest.register_craftitem("sawdust:rubber_tree_grindings", {
  description = "Rubber Tree Grindings",
  inventory_image = "technic_rubber_tree_grindings.png",
})

minetest.register_craftitem("sawdust:acacia_tree_grindings", {
  description = "Acacia Tree Grindings",
  inventory_image = "technic_acacia_grindings.png",
})

minetest.register_craft({
  type = "fuel",
  recipe = "sawdust:sawdust",
  burntime = 3,
})

minetest.register_craft({
  type = "fuel",
  recipe = "sawdust:common_tree_grindings",
  burntime = 5,
})

minetest.register_craft({
  type = "fuel",
  recipe = "sawdust:rubber_tree_grindings",
  burntime = 5,
})

minetest.register_craft({
  type = "fuel",
  recipe = "sawdust:acacia_tree_grindings",
  burntime = 5,
})

minetest.register_craft({
  type = "grinding",
  output = "sawdust:common_tree_grindings 8",
  recipe = "group:tree",
  time = 5,
})

minetest.register_craft({
  type = "grinding",
  output = "sawdust:acacia_tree_grindings 8",
  recipe = "basictrees:acacia_trunk",
  time = 5,
})

minetest.register_craft({
  type = "grinding",
  output = "sawdust:rubber_tree_grindings 8",
  recipe = "moretrees:rubber_tree_tree",
  time = 5,
})

minetest.register_craft({
  type = "extracting",
  output = "rubber:raw_latex",
  recipe = "sawdust:rubber_tree_grindings",
  time = 4,
})

minetest.register_craft({
  type = "extracting",
  output = "dye:brown",
  recipe = "sawdust:acacia_tree_grindings",
  time = 4,
})

minetest.register_craft({
  type = "grinding",
  output = "sawdust:sawdust 4",
  recipe = "group:wood",
  time = 4,
})

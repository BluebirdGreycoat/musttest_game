
minetest.register_craft({
  type = "separating",
  output = {"dusts:copper 3", "dusts:tin"},
  recipe = "bronze:dust 4",
})

minetest.register_craft({
  type = "separating",
  output = {"dusts:iron 3", "chromium:dust"},
  recipe = "stainless_steel:dust 4",
})

minetest.register_craft({
  type = "separating",
  output = {"dusts:copper 2", "zinc:dust"},
  recipe = "brass:dust 3",
})

minetest.register_craft({
  type = "separating",
  output = {"farming:seed_wheat 3", "default:dry_shrub"},
  recipe = "farming:wheat 4",
})

minetest.register_craft({
  type = "separating",
  output = {"farming:seed_cotton", "default:grass_dummy 3"},
  recipe = "default:junglegrass",
})

minetest.register_craft({
  type = "separating",
  output = {"farming:seed_wheat", "default:stick 5"},
  recipe = "default:dry_shrub",
})

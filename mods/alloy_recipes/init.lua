
minetest.register_craft({
  type = "alloying",
  output = "default:bronze_ingot 4",
  recipe = {"default:copper_ingot 3", "moreores:tin_ingot"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "bronze:dust 4",
  recipe = {"dusts:copper 3", "dusts:tin"},
  time = 6,
})

minetest.register_alias("dusts:bronze", "bronze:dust")

minetest.register_craft({
  type = "alloying",
  output = "carbon_steel:dust",
  recipe = {"dusts:iron", "dusts:coal"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "carbon_steel:ingot",
  recipe = {"default:steel_ingot", "dusts:coal"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "cast_iron:dust",
  recipe = {"carbon_steel:dust", "dusts:coal"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "cast_iron:ingot",
  recipe = {"carbon_steel:ingot", "dusts:coal"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "stainless_steel:dust 4",
  recipe = {"carbon_steel:dust 3", "chromium:dust"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "stainless_steel:ingot 4",
  recipe = {"carbon_steel:ingot 3", "chromium:ingot"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "brass:dust 3",
  recipe = {"dusts:copper 2", "zinc:dust"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "brass:ingot 3",
  recipe = {"default:copper_ingot 2", "zinc:ingot"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "silicon:wafer 12",
  recipe = {"default:sand", "dusts:coal 12"},
  time = 16,
})

minetest.register_craft({
  type = "alloying",
  output = "silicon:doped_wafer",
  recipe = {"silicon:wafer", "dusts:gold"},
  time = 6,
})

minetest.register_craft({
  type = "alloying",
  output = "rubber:rubber_fiber 3",
  recipe = {"rubber:raw_latex 2", "dusts:coal"},
  time = 6,
})

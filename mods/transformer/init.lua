
minetest.register_craftitem("transformer:lv", {
  description = "Low Voltage Transformer",
  inventory_image = "technic_lv_transformer.png",
})

minetest.register_craftitem("transformer:mv", {
  description = "Medium Voltage Transformer",
  inventory_image = "technic_mv_transformer.png",
})

minetest.register_craftitem( "transformer:hv", {
  description = "High Voltage Transformer",
  inventory_image = "technic_hv_transformer.png",
})

minetest.register_craft({
  output = 'transformer:lv',
  recipe = {
    {"rubber:rubber_fiber",                    'default:steel_ingot', "rubber:rubber_fiber"},
    {'techcrafts:copper_coil',        'default:steel_ingot', 'techcrafts:copper_coil'},
    {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
  }
})

minetest.register_craft({
  output = 'transformer:mv',
  recipe = {
    {"rubber:rubber_fiber",                    'carbon_steel:ingot', "rubber:rubber_fiber"},
    {'techcrafts:copper_coil',        'carbon_steel:ingot', 'techcrafts:copper_coil'},
    {'carbon_steel:ingot', 'carbon_steel:ingot', 'carbon_steel:ingot'},
  }
})

minetest.register_craft({
  output = 'transformer:hv',
  recipe = {
    {"rubber:rubber_fiber",                       'stainless_steel:ingot', "rubber:rubber_fiber"},
    {'techcrafts:copper_coil',           'stainless_steel:ingot', 'techcrafts:copper_coil'},
    {'stainless_steel:ingot', 'stainless_steel:ingot', 'stainless_steel:ingot'},
  }
})

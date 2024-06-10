
minetest.register_node("sulfur:ore", {
  description = "Sulfur Ore",
  tiles = {"default_stone.png^technic_sulfur_mineral.png"},
  groups = utility.dig_groups("mineral"),
  drop = "sulfur:lump",
  sounds = default.node_sound_stone_defaults(),
	silverpick_drop = true,
	place_param2 = 10,
})

minetest.register_craftitem("sulfur:lump", {
  description = "Sulfur Lump",
  inventory_image = "technic_sulfur_lump.png",
})

minetest.register_craftitem("sulfur:dust", {
  description = "Powdered Sulfur",
  inventory_image = "technic_sulfur_dust.png"
})

minetest.register_craft({
  type = "grinding",
  output = 'sulfur:dust 4',
  recipe = 'sulfur:lump',
})

minetest.register_craft({
  type = "anvil",
  output = 'sulfur:dust 2',
  recipe = 'sulfur:lump',
})

minetest.register_craft({
  type = "crushing",
  output = 'sulfur:dust 6',
  recipe = 'sulfur:lump',
	time = 60*1.5,
})

minetest.register_mapgen_script(minetest.get_modpath("sulfur") .. "/mapgen.lua")

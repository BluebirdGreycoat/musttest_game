
minetest.register_node("stoneworld:meat_rock", {
  description = "Basaltic Rubble With Unidentified Meat",
  tiles = {"darkage_basalt_rubble.png^rackstone_meat.png"},
  groups = utility.dig_groups("cobble"),
  sounds = default.node_sound_stone_defaults(),
  drop = "mobs:meat_raw",
	silverpick_drop = true,
})

minetest.register_node("stoneworld:meat_stone", {
  description = "Basaltic Stone With Unidentified Meat",
  tiles = {"darkage_basalt.png^rackstone_meat.png"},
  groups = utility.dig_groups("stone"),
  sounds = default.node_sound_stone_defaults(),
  drop = "mobs:meat_raw",
	silverpick_drop = true,
})


minetest.register_craftitem("concrete:rebar", {
  description = "Steel Rebar",
  inventory_image = "technic_rebar.png",
})

minetest.register_node("concrete:concrete", {
  description = "Concrete Block",
  tiles = {"technic_concrete_block.png",},
  groups = utility.dig_groups("stone"),
  sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("concrete:brc", {
  description = "Blast-Resistant Concrete Block",
  tiles = {"technic_blast_resistant_concrete_block.png",},
  groups = utility.dig_groups("obsidian"),
  sounds = default.node_sound_stone_defaults(),
  on_blast = function() end, -- TNT-proof.
})

minetest.register_craft({
  output = 'concrete:rebar 6',
  recipe = {
    {'','', "carbon_steel:ingot"},
    {'',"carbon_steel:ingot",''},
    {"carbon_steel:ingot", '', ''},
  }
})

minetest.register_craft({
  output = 'concrete:concrete 5',
  recipe = {
    {'default:stone','concrete:rebar','default:stone'},
    {'concrete:rebar','default:stone','concrete:rebar'},
    {'default:stone','concrete:rebar','default:stone'},
  }
})

minetest.register_craft({
  output = 'concrete:brc 5',
  recipe = {
    {'concrete:concrete','techcrafts:composite_plate','concrete:concrete'},
    {'techcrafts:composite_plate','concrete:concrete','techcrafts:composite_plate'},
    {'concrete:concrete','techcrafts:composite_plate','concrete:concrete'},
  }
})

stairs.register_stair_and_slab(
  "concrete",
  "concrete:concrete",
  {cracky=1, level=2},
  {"technic_concrete_block.png"},
  "Concrete Block",
  default.node_sound_stone_defaults()
)


minetest.register_craftitem("techcrafts:copper_coil", {
  description = "Copper Coil",
  inventory_image = "technic_copper_coil.png",
})

minetest.register_craft({
  output = 'techcrafts:copper_coil',
  recipe = {
    {'fine_wire:copper', 'default:steel_ingot', 'fine_wire:copper'},
    {'default:steel_ingot', '', 'default:steel_ingot'},
    {'fine_wire:copper', 'default:steel_ingot', 'fine_wire:copper'},
  }
})

minetest.register_craftitem("techcrafts:electric_motor", {
  description = "Electric Motor",
  inventory_image = "technic_motor.png",
})

minetest.register_craft({
  output = 'techcrafts:electric_motor',
  recipe = {
    {'carbon_steel:ingot', 'techcrafts:copper_coil', 'carbon_steel:ingot'},
    {'carbon_steel:ingot', 'techcrafts:copper_coil', 'carbon_steel:ingot'},
    {'carbon_steel:ingot', 'default:copper_ingot', 'carbon_steel:ingot'},
  }
})

minetest.register_craftitem("techcrafts:control_logic_unit", {
  description = "Control Logic Unit\n\nImproves machine speed if used as upgrade.\nCan be used as mailbox upgrade.",
  inventory_image = "technic_control_logic_unit.png",
	stack_max = 1, -- Is used as upgrade. May store metadata.
})

minetest.register_craft({
  output = 'techcrafts:control_logic_unit',
  recipe = {
    {'silicon:wafer', 'fine_wire:gold', 'silicon:wafer'},
    {'default:copper_ingot', 'silicon:wafer', 'default:copper_ingot'},
    {'quartz:quartz_crystal_piece', 'chromium:ingot', 'quartz:quartz_crystal_piece'},
  }
})

minetest.register_craftitem("techcrafts:mixed_metal_ingot", {
  description = "Composite Ingot",
  inventory_image = "technic_mixed_metal_ingot.png",
})

minetest.register_craft({
  output = 'techcrafts:mixed_metal_ingot 9',
  recipe = {
    {'stainless_steel:ingot', 'stainless_steel:ingot', 'stainless_steel:ingot'},
    {'default:bronze_ingot',          'default:bronze_ingot',          'default:bronze_ingot'},
    {'moreores:tin_ingot',            'moreores:tin_ingot',            'moreores:tin_ingot'},
  }
})

minetest.register_craftitem("techcrafts:composite_plate", {
  description = "Composite Plate",
  inventory_image = "technic_composite_plate.png",
})

minetest.register_craftitem("techcrafts:copper_plate", {
  description = "Copper Plate",
  inventory_image = "technic_copper_plate.png",
})

minetest.register_craftitem("techcrafts:carbon_plate", {
  description = "Carbon Plate",
  inventory_image = "technic_carbon_plate.png",
})

minetest.register_craftitem("techcrafts:graphite", {
  description = "Graphite",
  inventory_image = "technic_graphite.png",
})

minetest.register_craftitem("techcrafts:carbon_cloth", {
  description = "Carbon Cloth",
  inventory_image = "technic_carbon_cloth.png",
})

minetest.register_craft({
  output = 'techcrafts:carbon_cloth',
  recipe = {
    {'techcrafts:graphite', 'techcrafts:graphite', 'techcrafts:graphite'}
  }
})

minetest.register_craft({
  type = "compressing",
  output = "techcrafts:composite_plate",
  recipe = "techcrafts:mixed_metal_ingot",
  time = 12,
})

minetest.register_craft({
  type = "compressing",
  output = "techcrafts:copper_plate",
  recipe = "default:copper_ingot 5",
  time = 12,
})

minetest.register_craft({
  type = "compressing",
  output = "techcrafts:graphite",
  recipe = "dusts:coal 4",
  time = 6,
})

minetest.register_craft({
  type = "compressing",
  output = "techcrafts:carbon_plate",
  recipe = "techcrafts:carbon_cloth 4",
  time = 6,
})

minetest.register_node("techcrafts:machine_casing", {
  description = "Machine Chassis",
  groups = utility.dig_groups("machine"),
  
  -- This node has some special rendering properties so that it
  -- looks good in-world.
  paramtype = "light",
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    -- Avoid Z-fighting.
    fixed = {-0.4999, -0.4999, -0.4999, 0.4999, 0.4999, 0.4999},
  },
  tiles = {
    {name="technic_machine_casing.png", backface_culling=false},
    {name="technic_machine_casing.png", backface_culling=false},
    {name="technic_machine_casing.png", backface_culling=false},
    {name="technic_machine_casing.png", backface_culling=false},
    {name="technic_machine_casing.png", backface_culling=false},
    {name="technic_machine_casing.png", backface_culling=false},
  },
  
  sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
  output = "techcrafts:machine_casing",
  recipe = {
    { "cast_iron:ingot", "cast_iron:ingot", "cast_iron:ingot" },
    { "cast_iron:ingot", "brass:ingot", "cast_iron:ingot" },
    { "cast_iron:ingot", "cast_iron:ingot", "cast_iron:ingot" },
  },
})

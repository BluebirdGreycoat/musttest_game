
-- A device that allows to insert itemstacks into a network without
-- relying on polling chests repeatedly to see if they have items.
minetest.register_node("injector:injector", {
  description = "Self-Contained Injector",
  tiles = {
    "technic_injector_top.png", "technic_injector_top.png",
    "technic_injector_side.png", "technic_injector_side.png",
    "technic_injector_side.png", "technic_injector_side.png"
  },
  
  groups = utility.dig_groups("machine", {
    immovable = 1,
  }),
  
  paramtype2 = "facedir",
  on_rotate = function(...) return screwdriver.rotate_simple(...) end,
  is_ground_content = false,
  sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
  type = "shapeless",
  output = 'injector:injector',
  recipe = {
    'techcrafts:control_logic_unit',
    'chests:chest_locked_closed',
  },
})

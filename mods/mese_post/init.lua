
minetest.register_node("mese_post:mese_post_light", {
  description = "Mese Post Light",
  tiles = {
    "default_mese_post_light_top.png",
    "default_mese_post_light_top.png",
    "default_mese_post_light_side_dark.png",
    "default_mese_post_light_side_dark.png",
    "default_mese_post_light_side.png",
    "default_mese_post_light_side.png",
  },
  wield_image = "default_mese_post_light_side.png",
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-2 / 16, -8 / 16, -2 / 16, 2 / 16, 8 / 16, 2 / 16},
    },
  },
  paramtype = "light",
  light_source = default.LIGHT_MAX - 1,
  sunlight_propagates = true,
  is_ground_content = false,
  groups = utility.dig_groups("wood", {flammable = 2}),
  sounds = default.node_sound_wood_defaults(),
})



minetest.register_craft({
  output = "mese_post:mese_post_light 3",
  recipe = {
    {"", "default:glass", ""},
    {"default:mese_crystal", "default:mese_crystal", "default:mese_crystal"},
    {"", "group:wood", ""},
  }
})

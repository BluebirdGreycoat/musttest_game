
if not minetest.global_exists("chests") then chests = {} end
chests.modpath = minetest.get_modpath("chests")



minetest.register_craft({
	output = 'chests:chest_public_closed',
	recipe = {
		{'group:wood_light', 'group:wood_light',  'group:wood_light'},
		{'group:wood_light', '',                  'techcrafts:hinge_wood'},
		{'group:wood_light', 'group:wood_light',  'group:wood_light'},
	}
})



minetest.register_craft({
	output = 'chests:chest_locked_closed',
	recipe = {
		{'group:wood_light', 'group:wood_light',  'group:wood_light'},
		{'group:wood_light', 'default:padlock',   'techcrafts:hinge_wood'},
		{'group:wood_light', 'group:wood_light',  'group:wood_light'},
	}
})



minetest.register_craft( {
	type = "shapeless",
	output = "chests:chest_locked_closed",
	recipe = {"chests:chest_public_closed", "default:padlock"},
})



minetest.register_craft({
	type = "fuel",
	recipe = "chests:chest_public_closed",
	burntime = 30,
})



minetest.register_craft({
	type = "fuel",
	recipe = "chests:chest_locked_closed",
	burntime = 30,
})



-- Compatibility.
minetest.register_alias("default:chest",        "chests:chest_public_closed")
minetest.register_alias("default:chest_locked", "chests:chest_locked_closed")
minetest.register_alias("chests:chest_public",  "chests:chest_public_closed")
minetest.register_alias("chests:chest_locked",  "chests:chest_locked_closed")


chest_api.register_chest("chests:chest_public", {
  description = "Unlocked Chest",
  tiles = { "default_chest_wood.png" },
  sounds = default.node_sound_wood_defaults(),
  sound_open = "default_chest_open",
  sound_close = "default_chest_close",
  groups = utility.dig_groups("chest", {
    chest = 1,
    tubedevice = 1, 
    tubedevice_receiver = 1,
  }),
})

chest_api.register_chest("chests:chest_locked", {
  description = "Locked Chest",
  tiles = { "default_chest_wood_locked.png" },
  sounds = default.node_sound_wood_defaults(),
  sound_open = "default_chest_open",
  sound_close = "default_chest_close",
  groups = utility.dig_groups("chest", {
    chest = 1,
    tubedevice = 1, 
    tubedevice_receiver = 1,
  }),
  protected = true,
})

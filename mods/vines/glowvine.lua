
-- New Vines for Xen



 minetest.register_node('vine:luminoustreevine', {
	 drawtype = "plantlike",
	 inventory_image = "dvd_luminousvineend.png",
	 weild_image = "dvd_luminousvine.png",
	 description = 'Twilight Vine',
	 tiles = {'dvd_luminousvineend.png'},
	 paramtype = "light", 
	 light_source = 6,
	 groups = utility.dig_groups("plant", {
	 hanging_node = 1, flammable = 3,
	 }),
	 is_ground_content = false, 
	 walkable = false,
	 climbable = true,
	 drop = "",
	 shears_drop = true,
	 movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	 sounds = default.node_sound_leaves_defaults(),
	 groups = {level = 1, snappy=3, oddly_breakable_by_hand=1},
	 selection_box = {
     type = "fixed",
     fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
  },
})
 })
 
  minetest.register_node('vine:luminoustreevineend', {
	 drawtype = "plantlike",
	 inventory_image = "dvd_luminousvine.png",
	 weild_image = "dvd_luminousvine.png",
	 description = 'Twilight Vine',
	 tiles = {'dvd_luminousvine.png'},
	 paramtype = "light",
	 light_source = 6,
	 groups = utility.dig_groups("plant", {
     hanging_node = 1, flammable = 3,
     }),
	 is_ground_content = false, 
	 walkable = false,
	 climbable = true,
	 drop = "",
	 shears_drop = true,
	 movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	 sounds = default.node_sound_leaves_defaults(),
	 groups = {level = 1, snappy=3, oddly_breakable_by_hand=1},
	 selection_box = {
     type = "fixed",
     fixed = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
  },
 })
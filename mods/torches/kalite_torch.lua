
minetest.register_node("torches:kalite_torch_floor", {
  description = "Kalite Torch",
  drawtype = "mesh",
  mesh = "torch_floor.obj",
  inventory_image = "gloopores_kalite_torch_on_floor.png",
  wield_image = "gloopores_kalite_torch_on_floor.png",
  tiles = {{
    name = "gloopores_kalite_torch_on_floor_animated.png",
    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
  }},
  paramtype = "light",
  paramtype2 = "wallmounted",
  sunlight_propagates = true,
  walkable = false,
  liquids_pointable = false,
  light_source = 12,
  groups = utility.dig_groups("item", {
    flammable=1, 
    attached_node=1, 
    torch=1, 
    torch_craftitem=1,
		melt_around=2,
		notify_construct=1,
		want_notify=1,
  }),
  drop = "torches:kalite_torch_floor",
  damage_per_second = 1, -- Torches damage if you stand on top of them.
  selection_box = {
    type = "wallmounted",
    wall_bottom = {-1/16, -0.5, -1/16, 1/16, 2/16, 1/16},
  },
  sounds = default.node_sound_wood_defaults(),
  
	_torches_node_floor = "torches:kalite_torch_floor",
	_torches_node_wall = "torches:kalite_torch_wall",
	_torches_node_ceiling = "torches:kalite_torch_ceiling",

  on_place = function(...)
		return torches.put_torch(...)
  end,

	floodable = true,
	on_rotate = false,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
		real_torch.start_kalite_timer(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})



minetest.register_node("torches:kalite_torch_wall", {
  drawtype = "mesh",
  mesh = "torch_wall.obj",
  tiles = {{
    name = "gloopores_kalite_torch_on_floor_animated.png",
    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
  }},
  paramtype = "light",
  paramtype2 = "wallmounted",
  sunlight_propagates = true,
  walkable = false,
  light_source = 12,
  groups = utility.dig_groups("item", {
    flammable=1, 
    not_in_creative_inventory=1, 
    attached_node=1, 
    torch=1,
		melt_around=2,
		notify_construct=1,
		want_notify=1,
  }),
  drop = "torches:kalite_torch_floor",
  selection_box = {
    type = "wallmounted",
    wall_side = {-0.5, -0.3, -0.1, -0.2, 0.3, 0.1},
  },
  sounds = default.node_sound_wood_defaults(),

	floodable = true,
	on_rotate = false,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
		real_torch.start_kalite_timer(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})



minetest.register_node("torches:kalite_torch_ceiling", {
  drawtype = "mesh",
  mesh = "torch_ceiling.obj",
  tiles = {{
    name = "gloopores_kalite_torch_on_floor_animated.png",
    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
  }},
  paramtype = "light",
  paramtype2 = "wallmounted",
  sunlight_propagates = true,
  walkable = false,
  light_source = 12,
  groups = utility.dig_groups("item", {
    flammable=1, 
    not_in_creative_inventory=1, 
    attached_node=1, 
    torch=1,
		melt_around=2,
		notify_construct=1,
		want_notify=1,
  }),
  drop = "torches:kalite_torch_floor",
  selection_box = {
    type = "wallmounted",
    wall_top = {-0.1, -0.1, -0.25, 0.1, 0.5, 0.1},
  },
  sounds = default.node_sound_wood_defaults(),

	floodable = true,
	on_rotate = false,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
		real_torch.start_kalite_timer(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})



minetest.register_craft({
  output = 'torches:kalite_torch_floor 4',
  recipe = {
    {'kalite:lump'},
    {'group:stick'},
  }
})



minetest.register_craft({
  type = "fuel",
  recipe = "torches:kalite_torch_floor",
  burntime = 4,
})

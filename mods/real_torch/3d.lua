
-- unlit floor torch
minetest.register_node("real_torch:torch", {
	description = "Torch (Unlit)",
	drawtype = "mesh",
	mesh = "torch_floor.obj",
	inventory_image = "real_torch_on_floor.png",
	wield_image = "real_torch_on_floor.png",
	tiles = {{
		    name = "real_torch_on_floor.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
	}},
	paramtype = "light",
	paramtype2 = "wallmounted",
	light_source = 3,
	sunlight_propagates = true,
	walkable = false,
	liquids_pointable = false,
	groups = utility.dig_groups("item", {flammable=1, attached_node=1}),
	drop = "real_torch:torch",
	selection_box = {
		type = "wallmounted",
		wall_bottom = {-1/8, -1/2, -1/8, 1/8, 2/16, 1/8},
	},
	floodable = true,
	on_rotate = false,
	sounds = default.node_sound_wood_defaults(),

  _torches_node_floor = "real_torch:torch",
  _torches_node_wall = "real_torch:torch_wall",
  _torches_node_ceiling = "real_torch:torch_ceiling",

  on_flood = function(pos, oldnode, newnode)
    minetest.add_node(pos, {name="air"})
    minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
    return true
  end,

  on_place = function(...)
    return torches.put_torch(...)
  end,

	on_ignite = function(pos, igniter)
		local nod = minetest.get_node(pos)
		minetest.add_node(pos, {name = "torches:torch_floor", param2 = nod.param2})
	end,
})


-- unlit wall torch
minetest.register_node("real_torch:torch_wall", {
	drawtype = "mesh",
	mesh = "torch_wall.obj",
	tiles = {{
		    name = "real_torch_on_floor.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
	}},
	paramtype = "light",
	paramtype2 = "wallmounted",
	light_source = 3,
	sunlight_propagates = true,
	walkable = false,
	groups = utility.dig_groups("item", {flammable=1, not_in_creative_inventory=1, attached_node=1}),
	drop = "real_torch:torch",
	floodable = true,
	on_rotate = false,
	selection_box = {
		type = "wallmounted",
		wall_side = {-1/2, -1/2, -1/8, -1/8, 1/8, 1/8},
	},
	sounds = default.node_sound_wood_defaults(),
	on_ignite = function(pos, igniter)
		local nod = minetest.get_node(pos)
		minetest.add_node(pos, {name = "torches:torch_wall", param2 = nod.param2})
	end,
  on_flood = function(pos, oldnode, newnode)
    minetest.add_node(pos, {name="air"})
    minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
    return true
  end,
})


-- unlit ceiling torch
minetest.register_node("real_torch:torch_ceiling", {
	drawtype = "mesh",
	mesh = "torch_ceiling.obj",
	tiles = {{
		    name = "real_torch_on_floor.png",
		    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
	}},
	paramtype = "light",
	paramtype2 = "wallmounted",
	light_source = 3,
	sunlight_propagates = true,
	walkable = false,
	groups = utility.dig_groups("item", {flammable=1, not_in_creative_inventory=1, attached_node=1}),
	drop = "real_torch:torch",
	selection_box = {
		type = "wallmounted",
		wall_top = {-1/8, -1/16, -5/16, 1/8, 1/2, 1/8},
	},
	floodable = true,
	on_rotate = false,
	sounds = default.node_sound_wood_defaults(),
	on_ignite = function(pos, igniter)
		local nod = minetest.get_node(pos)
		minetest.add_node(pos, {name = "torches:torch_ceiling", param2 = nod.param2})
	end,
  on_flood = function(pos, oldnode, newnode)
    minetest.add_node(pos, {name="air"})
    minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
    return true
  end,
})


-- override default torches to burn out after 8-10 minutes
minetest.override_item("torches:torch_floor", {

	on_timer = function(pos, elapsed)
		local p2 = minetest.get_node(pos).param2
		minetest.add_node(pos, {name = "real_torch:torch", param2 = p2})
		minetest.sound_play({name="real_torch_burnout", gain = 0.1},
			{pos = pos, max_hear_distance = 10})
	end,
})


minetest.override_item("torches:torch_wall", {

	on_timer = function(pos, elapsed)
		local p2 = minetest.get_node(pos).param2
		minetest.add_node(pos, {name = "real_torch:torch_wall", param2 = p2})
		minetest.sound_play({name="real_torch_burnout", gain = 0.1},
			{pos = pos, max_hear_distance = 10})
	end,
})


minetest.override_item("torches:torch_ceiling", {

	on_timer = function(pos, elapsed)
		local p2 = minetest.get_node(pos).param2
		minetest.add_node(pos, {name = "real_torch:torch_ceiling", param2 = p2})
		minetest.sound_play({name="real_torch_burnout", gain = 0.1},
			{pos = pos, max_hear_distance = 10})
	end,
})


--[[

Torch mod - formerly mod "Torches"
======================

(c) Copyright BlockMen (2013-2015)
(C) Copyright sofar <sofar@foo-projects.org> (2016)

This mod changes the default torch drawtype from "torchlike" to "mesh",
giving the torch a three dimensional appearance. The mesh contains the
proper pixel mapping to make the animation appear as a particle above
the torch, while in fact the animation is just the texture of the mesh.


License:
~~~~~~~~
(c) Copyright BlockMen (2013-2015)

Textures and Meshes/Models:
CC-BY 3.0 BlockMen
Note that the models were entirely done from scratch by sofar.

Code:
Licensed under the GNU LGPL version 2.1 or higher.
You can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

See LICENSE.txt and http://www.gnu.org/licenses/lgpl-2.1.txt

--]]

minetest.register_node("torches:torch_floor", {
  description = "Torch\n\nDon't stand on this, it's hot!\nWill stay lit for several hours.\nCan be relit from various sources.",
  drawtype = "mesh",
  mesh = "torch_floor.obj",
  inventory_image = "default_torch_on_floor.png",
  wield_image = "default_torch_on_floor.png",
  tiles = {{
    name = "default_torch_on_floor_animated.png",
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
  drop = "torches:torch_floor",
  damage_per_second = 1, -- Torches damage if you stand on top of them.
  selection_box = {
    type = "wallmounted",
    wall_bottom = {-1/16, -0.5, -1/16, 1/16, 2/16, 1/16},
  },
  sounds = default.node_sound_wood_defaults(),

	_torches_node_floor = "torches:torch_floor",
	_torches_node_wall = "torches:torch_wall",
	_torches_node_ceiling = "torches:torch_ceiling",
  
  on_place = function(...)
		return torches.put_torch(...)
  end,

	floodable = true,
	on_rotate = false,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1})
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
		real_torch.start_timer(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})
minetest.register_alias("default:torch", "torches:torch_floor")



minetest.register_node("torches:torch_wall", {
  drawtype = "mesh",
  mesh = "torch_wall.obj",
  tiles = {{
        name = "default_torch_on_floor_animated.png",
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
  drop = "torches:torch_floor",
  selection_box = {
    type = "wallmounted",
    wall_side = {-0.5, -0.3, -0.1, -0.2, 0.3, 0.1},
  },
  sounds = default.node_sound_wood_defaults(),

	floodable = true,
	on_rotate = false,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1})
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
		real_torch.start_timer(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})
minetest.register_alias("default:torch_wall", "torches:torch_wall")



minetest.register_node("torches:torch_ceiling", {
  drawtype = "mesh",
  mesh = "torch_ceiling.obj",
  tiles = {{
        name = "default_torch_on_floor_animated.png",
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
  drop = "torches:torch_floor",
  selection_box = {
    type = "wallmounted",
    wall_top = {-0.1, -0.1, -0.25, 0.1, 0.5, 0.1},
  },
  sounds = default.node_sound_wood_defaults(),

	floodable = true,
	on_rotate = false,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1})
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
		real_torch.start_timer(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})
minetest.register_alias("default:torch_ceiling", "torches:torch_ceiling")



minetest.register_craft({
  output = 'torches:torch_floor 4',
  recipe = {
    {'default:coal_lump'},
    {'group:stick'},
  }
})



minetest.register_craft({
  type = "fuel",
  recipe = "torches:torch_floor",
  burntime = 4,
})




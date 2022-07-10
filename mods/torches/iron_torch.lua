
minetest.register_node("torches:iron_torch", {
	description = "Wrought Metal Wall Torch",
	drawtype = "mesh",
	mesh = "torches_iron_torch.obj",
	tiles = {
		"forniture_coal.png",
		{
			name="forniture_torch_flame.png",
			animation={
				type="vertical_frames",
				aspect_w=40,
				aspect_h=40,
				length=1.0,
			},
		},
		"homedecor_generic_metal_black.png^[brighten",
		"homedecor_generic_metal_black.png",
	},
	inventory_image = "forniture_torch_inv.png",
	wield_image = "forniture_torch_inv.png",
	walkable = false,
	light_source = 12,
	selection_box = {
		type = "wallmounted",
		--wall_top = {-0.1, -0.1, -0.1, 0.1, 0.5, 0.1},
		--wall_bottom = {-0.1, -0.5, -0.1, 0.1, 0.1, 0.1},
		wall_side = {-0.5, -0.3, -0.1, -0.2, 0.3, 0.1},
	},
	groups = utility.dig_groups("bigitem", {
		attached_node=1,
		melt_around=2, torch=1,
		notify_construct=1, want_notify=1,
	}),
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,

	floodable = true,
	on_rotate = false,
	node_placement_prediction = "",

	_torches_node_floor = "torches:iron_torch",
	_torches_node_wall = "torches:iron_torch",
	_torches_node_ceiling = "torches:iron_torch",

  on_place = function(itemstack, placer, pt)
		return torches.put_torch(itemstack, placer, pt, true)
  end,

	on_flood = function(pos, oldnode, newnode)
		minetest.add_node(pos, {name="air"})
		minetest.sound_play("real_torch_extinguish", {pos=pos, max_hear_distance=16, gain=1}, true)
		return true
	end,

	on_construct = function(pos)
		breath.ignite_nearby_gas(pos)
		flowers.create_lilyspawner_near(pos)
		torchmelt.start_melting(pos)
	end,

	on_notify = function(pos, other)
		torchmelt.start_melting(pos)
	end,

	on_destruct = function(pos)
	end,
})



minetest.register_craft({
    output = "torches:iron_torch",
    recipe = {
        {'default:coal_lump'},
        {'default:steel_ingot'},
    }
})

minetest.register_craft({
    output = "torches:iron_torch",
    recipe = {
        {'default:coal_lump'},
        {'moreores:tin_ingot'},
    }
})


-- New tree for Xen. 
-- Turn this into the Sunfire Tree. UGH. This is so much to keep track of and MustTest's making me do it myself >:|
-- Ok, I guess it works how it's suppose to. The only thing left is to get the sapling to grow properly.

minetest.register_node("firetree:luminoustreesapling", {
	description = "Sunfire Tree Sapling",
	drawtype = "plantlike",
	tiles = {"dvd_luminoussapling.png"},
	inventory_image = "dvd_luminoussapling.png",
	wield_image = "dvd_luminoussapling.png",
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = utility.dig_groups("plant", {flammable=2, attached_node=1, sapling=1}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

 minetest.register_node("firetree:luminoustreeleaves", {
	description = "Sunfire Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
    light_source = 2,
	tiles = {"dvd_luminousleaves.png"},
	paramtype = "light",
	groups = utility.dig_groups("leaves", {
		leafdecay = 3,
		flammable = 2,
		leaves = 1,
	}),
  
	drop = {
		max_items = 1,
		items = {
			{items = {'firetree:luminoustreesapling'}, rarity = 14},
			{items = {"default:stick"}, rarity = 6},
			{items = {'firetree:luminoustreeleaves'}},
		}
	},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="firetree:luminoustreetrunk"}),
})

minetest.register_node("firetree:luminoustreetrunk", {
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},
	description = "Sunfire Tree Trunk",
	paramtype = "light",
	tiles = {'dvd_treetop.png', 'dvd_treetop.png', 'dvd_luminoustreetrunk.png', 'dvd_luminoustreetrunk.png', 'dvd_luminoustreetrunk.png', 'dvd_luminoustreetrunk.png',
	},
	 paramtype = "light",
	paramtype2 = "facedir",
	 light_source = 2,
	groups = utility.dig_groups("tree", {tree=1, flammable=2}),
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,

  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {"firetree:luminoustreeleaves"},
  }),
})

minetest.register_node("firetree:luminousplanks", {
	description = "Sunfire Tree Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"dvd_luminousplanks.png"},
	groups = utility.dig_groups("wood", {flammable=2, wood=1, wood_light=1}),
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
    output = "firetree:luminousplanks 4",
    type = "shapeless",
    recipe = {"firetree:luminoustreetrunk"},
})

stairs.register_stair_and_slab(
	"firetree_luminousplanks",
	"firetree:luminousplanks",
	{choppy=2, oddly_breakable_by_hand=2, flammable=2},
	{"dvd_luminousplanks.png"},
	"Sunfire Planks",
	default.node_sound_wood_defaults(),
	{stair_and_slab_only=true}
)

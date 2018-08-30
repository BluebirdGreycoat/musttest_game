
moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*30
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-2, y=0, z=-2}
local SCHEMATIC_MAXP = {x=2, y=10, z=2}
local SCHEMATIC_RELP = {x=-2, y=0, z=-2}



minetest.register_node("moretrees:poplar_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Poplar Tree",
    tiles = {
        "moretrees_poplar_trunk_top.png",
        "moretrees_poplar_trunk_top.png",
        "moretrees_poplar_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:poplar_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:poplar_leaves", {
    description = "Poplar Leaves",
    drawtype = "allfaces_optional",
    visual_scale = 1.3,
    tiles = {"moretrees_poplar_leaves.png"},
    paramtype = "light",
	waving = 1,
    groups = moretrees.leaves_groups,
    drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:poplar_sapling", "moretrees:poplar_leaves"),
    sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:poplar_tree"}),
})



minetest.register_node("moretrees:poplar_wood", {
    description = "Poplar Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_poplar_wood.png"},
    groups = moretrees.get_wood_groups({wood_light = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:poplar_sapling", {
    description = "Poplar Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",
    --visual_scale = 1.0,
    tiles = {"moretrees_poplar_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/poplar.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math.random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:poplar_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:poplar_leaves", math.random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:poplar_leaves", math.random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:poplar_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
    output = 'moretrees:poplar_wood 4',
    recipe = {
        {'moretrees:poplar_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:poplar_wood", 'group:stick', "moretrees:poplar_wood"},
        {"moretrees:poplar_wood", 'group:stick', "moretrees:poplar_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"default:stick", "moretrees:poplar_wood", "default:stick"},
        {"default:stick", "moretrees:poplar_wood", "default:stick"}
    }
})



stairs.register_stair_and_slab(
    "poplar",
    "moretrees:poplar_wood",
    moretrees.stair_groups,
    {"moretrees_poplar_wood.png"},
    "Poplar Plank",
    default.node_sound_wood_defaults()
)


moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*25
local SAPLING_TIME_MAX = 60*60
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-3, y=0, z=-3}
local SCHEMATIC_MAXP = {x=3, y=21, z=3}
local SCHEMATIC_RELP = {x=-3, y=0, z=-3}



minetest.register_node("moretrees:sequoia_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Sequoia Tree",
    tiles = {
        "moretrees_sequoia_trunk_top.png",
        "moretrees_sequoia_trunk_top.png",
        "moretrees_sequoia_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:sequoia_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:sequoia_leaves", {
    description = "Sequoia Leaves",
    drawtype = "allfaces_optional",
    visual_scale = 1.3,
    tiles = {"moretrees_sequoia_leaves.png"},
    paramtype = "light",
	waving = 1,
    groups = moretrees.leaves_groups,
    drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:sequoia_sapling", "moretrees:sequoia_leaves"),
    sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:sequoia_tree"}),
})



minetest.register_node("moretrees:sequoia_wood", {
    description = "Sequoia Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_sequoia_wood.png"},
    groups = moretrees.get_wood_groups({wood_dark = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:sequoia_sapling", {
    description = "Sequoia Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",
    --visual_scale = 1.0,
    tiles = {"moretrees_sequoia_sapling.png"},
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
		local path = moretrees.modpath .. "/schematics/sequoia.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math.random(-2, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:sequoia_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:sequoia_leaves", math.random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:sequoia_leaves", math.random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:sequoia_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
    output = 'moretrees:sequoia_wood 4',
    recipe = {
        {'moretrees:sequoia_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:sequoia_wood", 'group:stick', "moretrees:sequoia_wood"},
        {"moretrees:sequoia_wood", 'group:stick', "moretrees:sequoia_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"default:stick", "moretrees:sequoia_wood", "default:stick"},
        {"default:stick", "moretrees:sequoia_wood", "default:stick"}
    }
})



stairs.register_stair_and_slab(
    "sequoia",
    "moretrees:sequoia_wood",
    moretrees.stair_groups,
    {"moretrees_sequoia_wood.png"},
    "Sequoia Plank",
    default.node_sound_wood_defaults()
)


if not minetest.global_exists("moretrees") then moretrees = {} end
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*30
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-3, y=0, z=-3}
local SCHEMATIC_MAXP = {x=3, y=11, z=3}
local SCHEMATIC_RELP = {x=-3, y=0, z=-3}

-- Localize for performance.
local math_random = math.random



minetest.register_node("moretrees:birch_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Birch Tree",
    tiles = {
        "moretrees_birch_trunk_top.png",
        "moretrees_birch_trunk_top.png",
        "moretrees_birch_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:birch_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:birch_leaves", {
	description = "Birch Leaves",
	drawtype = "allfaces_optional",

	tiles = {"moretrees_birch_leaves.png"},
	paramtype = "light",
	groups = moretrees.leaves_groups,
	drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:birch_sapling", "moretrees:birch_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	waving = 1,
	movement_speed_multiplier = default.SLOW_SPEED,

	on_construct = enhanced_leafdecay.make_leaf_constructor({}),
	on_timer = enhanced_leafdecay.make_leaf_nodetimer({
		tree = "moretrees:birch_tree",
	}),
})



minetest.register_node("moretrees:birch_wood", {
    description = "Birch Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_birch_wood.png"},
    groups = moretrees.get_wood_groups({wood_light = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:birch_sapling", {
    description = "Birch Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",

    tiles = {"moretrees_birch_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:birch_tree", "moretrees:birch_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/birch.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math_random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:birch_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:birch_leaves", math_random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:birch_leaves", math_random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:birch_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
    output = 'moretrees:birch_wood 4',
    recipe = {
        {'moretrees:birch_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:birch_wood", 'group:stick', "moretrees:birch_wood"},
        {"moretrees:birch_wood", 'group:stick', "moretrees:birch_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"techcrafts:hinge_wood", "moretrees:birch_wood", "group:stick"},
        {"group:stick", "moretrees:birch_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "birch",
    "moretrees:birch_wood",
    moretrees.stair_groups,
    {"moretrees_birch_wood.png"},
    "Birch Plank",
    default.node_sound_wood_defaults()
)

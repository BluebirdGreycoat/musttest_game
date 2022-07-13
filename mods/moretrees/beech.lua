
moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*25
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-2, y=0, z=-2}
local SCHEMATIC_MAXP = {x=2, y=10, z=2}
local SCHEMATIC_RELP = {x=-2, y=0, z=-2}

-- Localize for performance.
local math_random = math.random



minetest.register_node("moretrees:beech_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Beech Tree",
    tiles = {
        "moretrees_beech_trunk_top.png",
        "moretrees_beech_trunk_top.png",
        "moretrees_beech_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:beech_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:beech_leaves", {
	description = "Beech Leaves",
	drawtype = "allfaces_optional",

	tiles = {"moretrees_beech_leaves.png"},
	paramtype = "light",
	groups = moretrees.leaves_groups,
	drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:beech_sapling", "moretrees:beech_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	waving = 1,
	movement_speed_multiplier = default.SLOW_SPEED,

	on_construct = enhanced_leafdecay.make_leaf_constructor({}),
	on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:beech_tree"}),
})



minetest.register_node("moretrees:beech_wood", {
    description = "Beech Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_beech_wood.png"},
    groups = moretrees.get_wood_groups({wood_light = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:beech_sapling", {
    description = "Beech Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",

    tiles = {"moretrees_beech_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:beech_tree", "moretrees:beech_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/beech.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math_random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:beech_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:beech_leaves", math_random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:beech_leaves", math_random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:beech_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
    output = 'moretrees:beech_wood 4',
    recipe = {
        {'moretrees:beech_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:beech_wood", 'group:stick', "moretrees:beech_wood"},
        {"moretrees:beech_wood", 'group:stick', "moretrees:beech_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"techcrafts:hinge_wood", "moretrees:beech_wood", "group:stick"},
        {"group:stick", "moretrees:beech_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "beech",
    "moretrees:beech_wood",
    moretrees.stair_groups,
    {"moretrees_beech_wood.png"},
    "Beech Plank",
    default.node_sound_wood_defaults()
)

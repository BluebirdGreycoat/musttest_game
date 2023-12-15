
if not minetest.global_exists("moretrees") then moretrees = {} end
local SAPLING_TIME_MIN = 60*20
local SAPLING_TIME_MAX = 60*40
local SAPLING_CHANCE = 20
local SCHEMATIC_MINP = {x=-4, y=0, z=-4}
local SCHEMATIC_MAXP = {x=4, y=15, z=4}
local SCHEMATIC_RELP = {x=-4, y=0, z=-4}

-- Localize for performance.
local math_random = math.random



minetest.register_node("moretrees:date_palm_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Date Palm Tree",
    tiles = {
        "moretrees_date_palm_trunk_top.png",
        "moretrees_date_palm_trunk_top.png",
        "moretrees_date_palm_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:date_palm_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:date_palm_leaves", {
	description = "Date Palm Leaves",
	drawtype = "allfaces_optional",

	tiles = {"moretrees_date_palm_leaves.png"},
	paramtype = "light",
	groups = moretrees.leaves_groups,
	drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:date_palm_sapling", "moretrees:date_palm_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	waving = 1,
	movement_speed_multiplier = default.SLOW_SPEED,

	on_construct = enhanced_leafdecay.make_leaf_constructor({}),
	on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:date_palm_tree"}),
})



minetest.register_node("moretrees:date_palm_wood", {
    description = "Date Palm Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_date_palm_wood.png"},
    groups = moretrees.get_wood_groups({wood_dark = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:date_palm_sapling", {
    description = "Date Palm Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",

    tiles = {"moretrees_date_palm_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:date_palm_tree", "moretrees:date_palm_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/date_palm.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math_random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:date_palm_tree")
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:date_palm_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
    output = 'moretrees:date_palm_wood 4',
    recipe = {
        {'moretrees:date_palm_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:date_palm_wood", 'group:stick', "moretrees:date_palm_wood"},
        {"moretrees:date_palm_wood", 'group:stick', "moretrees:date_palm_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"techcrafts:hinge_wood", "moretrees:date_palm_wood", "group:stick"},
        {"group:stick", "moretrees:date_palm_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "date_palm",
    "moretrees:date_palm_wood",
    moretrees.stair_groups,
    {"moretrees_date_palm_wood.png"},
    "Date Palm Plank",
    default.node_sound_wood_defaults()
)


if not minetest.global_exists("moretrees") then moretrees = {} end
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*30
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-3, y=0, z=-3}
local SCHEMATIC_MAXP = {x=3, y=12, z=3}
local SCHEMATIC_RELP = {x=-3, y=0, z=-3}

-- Localize for performance.
local math_random = math.random



minetest.register_node("moretrees:cedar_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Cedar Tree",
    tiles = {
        "moretrees_cedar_trunk_top.png",
        "moretrees_cedar_trunk_top.png",
        "moretrees_cedar_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:cedar_leaves",
      "moretrees:cedar_cone",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:cedar_leaves", {
	description = "Cedar Leaves",
	drawtype = "allfaces_optional",

	tiles = {"moretrees_cedar_leaves.png"},
	paramtype = "light",
	waving = 1,
	groups = moretrees.leaves_groups,
	drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:cedar_sapling", "moretrees:cedar_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,

	on_construct = enhanced_leafdecay.make_leaf_constructor({}),
	on_timer = enhanced_leafdecay.make_leaf_nodetimer({
		tree = "moretrees:cedar_tree",
	}),
})



minetest.register_node("moretrees:cedar_wood", {
    description = "Cedar Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_cedar_wood.png"},
    groups = moretrees.get_wood_groups({wood_light = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:cedar_sapling", {
    description = "Cedar Sapling\n\nWill not grow in deep caves.\nGrows nuts.",
    drawtype = "plantlike",

    tiles = {"moretrees_cedar_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:cedar_tree", "moretrees:cedar_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/cedar.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math_random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:cedar_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:cedar_leaves", math_random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:cedar_leaves", math_random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
        
        fruitscatter.scatter_fruit_under_leaves(
            pos,
            "moretrees:cedar_leaves",
            "moretrees:cedar_cone",
            SCHEMATIC_MINP,
            SCHEMATIC_MAXP,
            math_random(6, 10)
        )
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:cedar_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_node("moretrees:cedar_cone", {
	description = "Cedar Cone",
	drawtype = "plantlike",
	visual_scale = 0.8,
	tiles = {"moretrees_cedar_cone.png"},
	inventory_image = "moretrees_cedar_cone.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.2, -0.5, -0.2, 0.2, 0, 0.2},
	},
	groups = {fleshy=3, dig_immediate=3, flammable=2, leafdecay=3, leafdecay_drop=1},
	sounds = default.node_sound_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:cedar_tree"}),

	after_dig_node = hb4.fruitregrow.after_dig_node(),
	after_place_node = hb4.fruitregrow.after_place_node(),
	on_finish_collapse = hb4.fruitregrow.on_finish_collapse(),
})



minetest.register_craftitem("moretrees:cedar_nuts", {
	description = "Roasted Cedar Cone Nuts",
	inventory_image = "moretrees_cedar_nuts.png",
	on_use = minetest.item_eat(1),
	_xp_zerocost_drop = true,
	-- Nuts do not rot.
})



minetest.register_craft({
	type = "cooking",
	output = "moretrees:cedar_nuts 4",
	recipe = "moretrees:cedar_cone",
})



minetest.register_craft({
    output = 'moretrees:cedar_wood 4',
    recipe = {
        {'moretrees:cedar_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:cedar_wood", 'group:stick', "moretrees:cedar_wood"},
        {"moretrees:cedar_wood", 'group:stick', "moretrees:cedar_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"techcrafts:hinge_wood", "moretrees:cedar_wood", "group:stick"},
        {"group:stick", "moretrees:cedar_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "cedar",
    "moretrees:cedar_wood",
    moretrees.stair_groups,
    {"moretrees_cedar_wood.png"},
    "Cedar Plank",
    default.node_sound_wood_defaults()
)

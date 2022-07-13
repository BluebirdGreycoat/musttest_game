
moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*10
local SAPLING_TIME_MAX = 60*15
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-3, y=0, z=-3}
local SCHEMATIC_MAXP = {x=3, y=7, z=3}
local SCHEMATIC_RELP = {x=-3, y=0, z=-3}

-- Localize for performance.
local math_random = math.random



minetest.register_node("moretrees:apple_tree_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Apple Tree",
	tiles = {
		"moretrees_apple_tree_trunk_top.png",
		"moretrees_apple_tree_trunk_top.png",
		"moretrees_apple_tree_trunk.png"
	},
	paramtype2 = "facedir",
	groups = moretrees.tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:apple_tree_leaves",
			"moretrees:apple_tree_blossoms",
      "basictrees:tree_apple",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:apple_tree_leaves", {
	description = "Apple Tree Leaves",
	drawtype = "allfaces_optional",

	waving = 1,
	tiles = {"moretrees_apple_tree_leaves.png"},
	paramtype = "light",
	groups = moretrees.leaves_groups,
	drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:apple_tree_sapling", "moretrees:apple_tree_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:apple_tree_tree"}),
})



minetest.register_node("moretrees:apple_tree_wood", {
	description = "Apple Tree Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"moretrees_apple_tree_wood.png"},
	groups = moretrees.get_wood_groups({wood_light = 1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:apple_tree_sapling", {
	description = "Apple Tree Sapling\n\nWill not grow in deep caves.\nGrows lots of apples.",
	drawtype = "plantlike",

	tiles = {"moretrees_apple_tree_sapling.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = moretrees.sapling_selection_box,
	groups = moretrees.sapling_groups,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:apple_tree_tree", "moretrees:apple_tree_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/apple_tree.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math_random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:apple_tree_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:apple_tree_leaves", math_random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:apple_tree_leaves", math_random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
        
		fruitscatter.scatter_fruit_under_leaves(
			pos,
			"moretrees:apple_tree_leaves",
			"basictrees:tree_apple",
			SCHEMATIC_MINP,
			SCHEMATIC_MAXP,
			math_random(3, 6)
		)

		-- Randomly transform some of the leaves to blossoms.
		local minp = vector.add(pos, SCHEMATIC_MINP)
		local maxp = vector.add(pos, SCHEMATIC_MAXP)
		local p = {x=pos.x, y=pos.y, z=pos.z}
		for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
		for z = minp.z, maxp.z do
			if math_random(1, 5) == 1 then
				p.x = x
				p.y = y
				p.z = z
				local n = minetest.get_node(p).name
				if n == "moretrees:apple_tree_leaves" then
					minetest.set_node(p, {name="moretrees:apple_tree_blossoms"})
				end
			end
		end
		end
		end
	end,
    
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
			"moretrees:apple_tree_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
    output = 'moretrees:apple_tree_wood 4',
    recipe = {
        {'moretrees:apple_tree_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:apple_tree_wood", 'group:stick', "moretrees:apple_tree_wood"},
        {"moretrees:apple_tree_wood", 'group:stick', "moretrees:apple_tree_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"techcrafts:hinge_wood", "moretrees:apple_tree_wood", "group:stick"},
        {"group:stick", "moretrees:apple_tree_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "apple_tree",
    "moretrees:apple_tree_wood",
    moretrees.stair_groups,
    {"moretrees_apple_tree_wood.png"},
    "Apple Tree Plank",
    default.node_sound_wood_defaults()
)

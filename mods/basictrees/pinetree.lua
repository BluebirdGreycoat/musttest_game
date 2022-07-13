
basictrees = basictrees or {}
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*20
local SAPLING_CHANCE = 25
local SCHEMATIC_MINP = {x=-2, y=1, z=-2}
local SCHEMATIC_MAXP = {x=2, y=16, z=2}
local SCHEMATIC_RELP = {x=-2, y=-1, z=-2}

-- Localize for performance.
local math_random = math.random



minetest.register_node("basictrees:pine_trunk", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Pine Tree",
	tiles = {"default_pine_tree_top.png", "default_pine_tree_top.png", "default_pine_tree.png"},
	paramtype2 = "facedir",
	groups = basictrees.tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "basictrees:pine_cone", 
      "basictrees:pine_needles",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("basictrees:pine_wood", {
	description = "Pine Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_pine_wood.png"},
	groups = basictrees.get_wood_groups({wood_light = 1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("basictrees:pine_needles",{
	description = "Pine Needles",
	drawtype = "allfaces_optional",

	tiles = {"default_pine_needles.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = basictrees.leaves_groups,
	drop = basictrees.get_leafdrop_table(SAPLING_CHANCE, "basictrees:pine_sapling", "basictrees:pine_needles"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:pine_trunk"}),
})



minetest.register_node("basictrees:pine_sapling", {
	description = "Pine Tree Sapling\n\nWill not grow in deep caves.\nGrows nuts.",
	drawtype = "plantlike",

	tiles = {"default_pine_sapling.png"},
	inventory_image = "default_pine_sapling.png",
	wield_image = "default_pine_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = basictrees.sapling_selection_box,
	groups = basictrees.sapling_groups,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_timer = function(pos)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "basictrees:pine_trunk", "basictrees:pine_needles", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

        if not basictrees.can_grow(pos) then
            minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
            return
        end
        
				local treedef = {
					["angle"] = 45,
					["leaves"] = "basictrees:pine_needles",
					["rules_b"] = "&&GG--Gf--ffff--ffff--ffff--fff^^G&&--Gff--ff--ff--ff",
					["trunk_type"] = "single",
					["rules_c"] = "",
					["fruit_chance"] = 10,
					["fruit"] = "air",
					["iterations"] = 2,
					["rules_a"] = "Ta",
					["random_level"] = 1,
					["axiom"] = "TTa[B]TTd[B]TTd[B]Tdf",
					["thin_branches"] = true,
					["trunk"] = "basictrees:pine_trunk",
					["leaves2_chance"] = "5",
					["leaves2"] = "air",
					["rules_d"] = "Td",
				}

				minetest.remove_node(pos)
				minetest.spawn_tree(pos, treedef)

        snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
				ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
        fruitscatter.scatter_fruit_under_leaves(
            pos,
            "basictrees:pine_needles",
            "basictrees:pine_cone",
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
            "basictrees:pine_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_node("basictrees:pine_cone", {
	description = "Pine Cone",
	drawtype = "plantlike",
	visual_scale = 0.8,
	tiles = {"moretrees_pine_cone.png"},
	inventory_image = "moretrees_pine_cone.png",
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
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:pine_trunk"}),
})



minetest.register_craftitem("basictrees:pine_nuts", {
	description = "Roasted Pine Cone Nuts",
	inventory_image = "moretrees_pine_nuts.png",
	on_use = minetest.item_eat(1),
})



minetest.register_craft({
	type = "cooking",
	output = "basictrees:pine_nuts 4",
	recipe = "basictrees:pine_cone",
})



minetest.register_craft({
	output = 'basictrees:pine_wood 4',
	recipe = {
		{'basictrees:pine_trunk'},
	}
})



minetest.register_alias("default:pine_tree",    "basictrees:pine_trunk")
minetest.register_alias("default:pine_needles", "basictrees:pine_needles")
minetest.register_alias("default:pine_sapling", "basictrees:pine_sapling")
minetest.register_alias("default:pine_wood",    "basictrees:pine_wood")



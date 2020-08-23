
basictrees = basictrees or {}
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*25
local SAPLING_CHANCE = 25
local SCHEMATIC_MINP = {x=-2, y=1, z=-2}
local SCHEMATIC_MAXP = {x=2, y=15, z=2}
local SCHEMATIC_RELP = {x=-2, y=-1, z=-2}

-- Localize for performance.
local math_random = math.random



minetest.register_node("basictrees:jungletree_trunk", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Jungle Tree",
	tiles = {"default_jungletree_top.png", "default_jungletree_top.png", "default_jungletree.png"},
	paramtype2 = "facedir",
	groups = basictrees.tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "basictrees:jungletree_leaves",
      "group:dry_leaves",
    },
  }),
})

minetest.register_node("basictrees:jungletree_cube", {
	description = "Jungle Tree",
	tiles = {"default_jungletree_top.png", "default_jungletree_top.png", "default_jungletree.png"},
	paramtype2 = "facedir",
	groups = basictrees.cw_tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
	drop = "basictrees:jungletree_trunk",

  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "basictrees:jungletree_leaves",
			"basictrees:jungletree_leaves2",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("basictrees:jungletree_wood", {
	description = "Jungle Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_junglewood.png"},
	groups = basictrees.get_wood_groups({wood_dark = 1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("basictrees:jungletree_leaves", {
	description = "Jungle Tree Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	visual_scale = 1.3,
	tiles = {"default_jungleleaves.png"},
	--special_tiles = {"default_jungleleaves_simple.png"},
	paramtype = "light",
	groups = basictrees.leaves_groups,
	drop = basictrees.get_leafdrop_table(SAPLING_CHANCE, "basictrees:jungletree_sapling", "basictrees:jungletree_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:jungletree_trunk"}),
})

minetest.register_node("basictrees:jungletree_leaves2", {
	description = "Jungle Tree Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"default_jungleleaves.png"},
	--special_tiles = {"default_jungleleaves_simple.png"},
	paramtype = "light",
	groups = basictrees.cw_leaves_groups,
	drop = basictrees.get_leafdrop_table(SAPLING_CHANCE, "basictrees:jungletree_sapling", "basictrees:jungletree_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,

  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:jungletree_cube"}),
})



minetest.register_node("basictrees:jungletree_sapling", {
	description = "Jungle Tree Sapling\n\nWill not grow in deep caves.",
	drawtype = "plantlike",
	--visual_scale = 1.0,
	tiles = {"default_junglesapling.png"},
	inventory_image = "default_junglesapling.png",
	wield_image = "default_junglesapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = basictrees.sapling_selection_box,
	groups = basictrees.sapling_groups,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_timer = function(pos)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "basictrees:jungletree_trunk", "basictrees:jungletree_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

        if not basictrees.can_grow(pos) then
            minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
            return
        end
        
        local path = basictrees.modpath .. "/schematics/jungle_tree_from_sapling.mts"
        minetest.place_schematic(vector.add(pos, SCHEMATIC_RELP), path, "random", nil, false)
				hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "basictrees:jungletree_leaves", math_random(10, 30))
				hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "basictrees:jungletree_leaves", math_random(10, 30))
        snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
				ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
    end,

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,

	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "basictrees:jungletree_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
	output = 'basictrees:jungletree_wood 4',
	recipe = {
		{'basictrees:jungletree_trunk'},
	}
})



minetest.register_alias("default:jungletree",           "basictrees:jungletree_trunk")
minetest.register_alias("default:jungleleaves",         "basictrees:jungletree_leaves")
minetest.register_alias("default:junglesapling",        "basictrees:jungletree_sapling")
minetest.register_alias("default:junglewood",           "basictrees:jungletree_wood")
minetest.register_alias("basictrees:jungletree_tree",   "basictrees:jungletree_trunk")

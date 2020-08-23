
basictrees = basictrees or {}
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*30
local SAPLING_CHANCE = 25
local SCHEMATIC_MINP = {x=-4, y=1, z=-4}
local SCHEMATIC_MAXP = {x=4, y=6, z=4}
local SCHEMATIC_RELP = {x=-4, y=-1, z=-4}

-- Localize for performance.
local math_random = math.random



minetest.register_node("basictrees:acacia_trunk", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Acacia Tree",
	tiles = {"default_acacia_tree_top.png", "default_acacia_tree_top.png", "default_acacia_tree.png"},
	paramtype2 = "facedir",
	groups = basictrees.tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "basictrees:acacia_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("basictrees:acacia_wood", {
	description = "Acacia Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_acacia_wood.png"},
	groups = basictrees.get_wood_groups({wood_light = 1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("basictrees:acacia_leaves", {
	description = "Acacia Tree Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"default_acacia_leaves.png"},
	waving = 1,
	paramtype = "light",
	groups = basictrees.leaves_groups,
	drop = basictrees.get_leafdrop_table(SAPLING_CHANCE, "basictrees:acacia_sapling", "basictrees:acacia_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:acacia_trunk"}),
})



minetest.register_node("basictrees:acacia_sapling", {
	description = "Acacia Tree Sapling\n\nWill not grow in deep caves.",
	drawtype = "plantlike",
	--visual_scale = 1.0,
	tiles = {"default_acacia_sapling.png"},
	inventory_image = "default_acacia_sapling.png",
	wield_image = "default_acacia_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = basictrees.sapling_selection_box,
	groups = basictrees.sapling_groups,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_timer = function(pos)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "basictrees:acacia_trunk", "basictrees:acacia_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

        if not basictrees.can_grow(pos) then
            minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
            return
        end
        
        local path = basictrees.modpath .. "/schematics/acacia_tree_from_sapling.mts"
        minetest.place_schematic(vector.add(pos, SCHEMATIC_RELP), path, "random", nil, false)
        snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
				serveressentials.fix_acacia_tree(vector.add(pos, SCHEMATIC_MINP), vector.add(pos, SCHEMATIC_MAXP))
				ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
    end,

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,

	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "basictrees:acacia_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
	output = 'basictrees:acacia_wood 4',
	recipe = {
		{'basictrees:acacia_trunk'},
	}
})



minetest.register_alias("default:acacia_tree",      "basictrees:acacia_trunk")
minetest.register_alias("default:acacia_leaves",    "basictrees:acacia_leaves")
minetest.register_alias("default:acacia_sapling",   "basictrees:acacia_sapling")
minetest.register_alias("default:acacia_wood",      "basictrees:acacia_wood")




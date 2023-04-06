
if not minetest.global_exists("basictrees") then basictrees = {} end
local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*25
local SAPLING_CHANCE = 20
local SCHEMATIC_MINP = {x=-2, y=1, z=-2}
local SCHEMATIC_MAXP = {x=2, y=12, z=2}
local SCHEMATIC_RELP = {x=-2, y=-1, z=-2}

-- Localize for performance.
local math_random = math.random



minetest.register_node("basictrees:aspen_trunk", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Aspen Tree",
	tiles = {"default_aspen_tree_top.png", "default_aspen_tree_top.png", "default_aspen_tree.png"},
	paramtype2 = "facedir",
	groups = basictrees.tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "basictrees:aspen_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("basictrees:aspen_wood", {
	description = "Aspen Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_aspen_wood.png"},
	groups = basictrees.get_wood_groups({wood_light = 1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("basictrees:aspen_leaves", {
	description = "Aspen Leaves",
	drawtype = "allfaces_optional",

	tiles = {"default_aspen_leaves.png"},
	waving = 1,
	paramtype = "light",
	groups = basictrees.leaves_groups,
	drop = basictrees.get_leafdrop_table(SAPLING_CHANCE, "basictrees:aspen_sapling", "basictrees:aspen_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:aspen_trunk"}),
})



minetest.register_node("basictrees:aspen_sapling", {
	description = "Aspen Tree Sapling\n\nWill not grow in deep caves.",
	drawtype = "plantlike",

	tiles = {"default_aspen_sapling.png"},
	inventory_image = "default_aspen_sapling.png",
	wield_image = "default_aspen_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = basictrees.sapling_selection_box,
	groups = basictrees.sapling_groups,
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	on_timer = function(pos)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "basictrees:aspen_trunk", "basictrees:aspen_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

        if not basictrees.can_grow(pos) then
            minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
            return
        end
        
        local path = basictrees.modpath .. "/schematics/aspen_tree_from_sapling.mts"
        minetest.place_schematic(vector.add(pos, SCHEMATIC_RELP), path, "random", nil, false)
        snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
				ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
    end,

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,

	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "basictrees:aspen_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_craft({
	output = 'basictrees:aspen_wood 4',
	recipe = {
		{'basictrees:aspen_trunk'},
	}
})



minetest.register_alias("default:aspen_tree",       "basictrees:aspen_trunk")
minetest.register_alias("default:aspen_leaves",     "basictrees:aspen_leaves")
minetest.register_alias("default:aspen_wood",       "basictrees:aspen_wood")
minetest.register_alias("default:aspen_sapling",    "basictrees:aspen_sapling")




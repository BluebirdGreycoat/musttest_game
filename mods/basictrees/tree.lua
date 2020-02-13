
basictrees = basictrees or {}
local SAPLING_TIME_MIN = 60*10
local SAPLING_TIME_MAX = 60*20
local SAPLING_CHANCE = 20
local SCHEMATIC_MINP = {x=-2, y=1, z=-2}
local SCHEMATIC_MAXP = {x=2, y=6, z=2}
local SCHEMATIC_RELP = {x=-2, y=-1, z=-2}



minetest.register_node("basictrees:tree_trunk", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Tree",
	tiles = {"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
	paramtype2 = "facedir",
	groups = basictrees.tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "basictrees:tree_leaves", 
      "basictrees:tree_apple",
      "group:dry_leaves",
    },
  }),
})

-- Note: dead tree must drop itself, not regular tree, because otherwise if player
-- places the node, they won't be able to dig it by hand again, which will be
-- confusing.
minetest.register_node("basictrees:tree_trunk_dead", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

	description = "Dead Tree",
	tiles = {"default_tree_dead_top.png", "default_tree_dead_top.png", "default_tree_dead.png"},
	paramtype2 = "facedir",
	groups = basictrees.dead_tree_groups,
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
})



minetest.register_node("basictrees:tree_sapling", {
  description = "Tree Sapling\n\nWill not grow in deep caves.\nGrows apples.",
  drawtype = "plantlike",
  
  tiles = {"default_sapling.png"},
  inventory_image = "default_sapling.png",
  wield_image = "default_sapling.png",
  paramtype = "light",
  
  sunlight_propagates = true,
  walkable = false,
  
  selection_box = basictrees.sapling_selection_box,
  groups = basictrees.sapling_groups,
  sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  
  on_timer = function(pos)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "basictrees:tree_trunk", "basictrees:tree_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

    if not basictrees.can_grow(pos) then
      minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
      return
    end
    
    local path = basictrees.modpath .. "/schematics/apple_tree_from_sapling.mts"
    minetest.place_schematic(vector.add(pos, SCHEMATIC_RELP),
      path, "random", nil, false)
    snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
  end,

  on_construct = function(pos)
    minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
  end,

  on_place = function(itemstack, placer, pointed_thing)
    itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
      "basictrees:tree_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
    return itemstack
  end,
})



minetest.register_node("basictrees:tree_wood", {
	description = "Wooden Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_wood.png"},
	groups = basictrees.get_wood_groups({wood_light = 1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("basictrees:tree_leaves", {
	description = "Tree Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	visual_scale = 1.3,
	tiles = {"default_leaves.png"},
	--special_tiles = {"default_leaves_simple.png"},
	paramtype = "light",
	groups = basictrees.leaves_groups,
	drop = basictrees.get_leafdrop_table(SAPLING_CHANCE, "basictrees:tree_sapling", "basictrees:tree_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="basictrees:tree_trunk"}),
})





-- Sappling crafts.
minetest.register_craft({
	output = 'basictrees:tree_sapling',
	recipe = {
		{'default:mossycobble',	'default:sand',	          'default:gravel'        },
        {'default:dirt',		'default:junglegrass',    'default:dirt'          },
		{'default:gravel',		'default:sand',	          'default:mossycobble'   },
	}
})



minetest.register_craft({
	output = 'basictrees:tree_wood 4',
	recipe = {
		{'basictrees:tree_trunk'},
	}
})

minetest.register_craft({
	output = 'basictrees:tree_wood 4',
	recipe = {
		{'basictrees:tree_trunk_dead'},
	}
})



-- Aliases for compatibility.
minetest.register_alias("default:tree",     "basictrees:tree_trunk")
minetest.register_alias("default:sapling",  "basictrees:tree_sapling")
minetest.register_alias("default:wood",     "basictrees:tree_wood")
minetest.register_alias("default:leaves",   "basictrees:tree_leaves")
minetest.register_alias("default:apple",    "basictrees:tree_apple")




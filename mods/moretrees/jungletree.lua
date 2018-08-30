
moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*10
local SAPLING_TIME_MAX = 60*20
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-2, y=0, z=-2}
local SCHEMATIC_MAXP = {x=2, y=14, z=2}
local SCHEMATIC_RELP = {x=-2, y=0, z=-2}



local leafcolors = {
    {name="red", capitalized="Red"},
    {name="green", capitalized="Green"},
    {name="yellow", capitalized="Yellow"}
}



for k, v in pairs(leafcolors) do
    local name = v.name
    local capitalized = v.capitalized

    minetest.register_node("moretrees:jungletree_leaves_" .. name, {
        description = capitalized .. " Jungletree Leaves",
        drawtype = "allfaces_optional",
        visual_scale = 1.3,
        tiles = {"moretrees_jungletree_leaves_" .. name .. ".png"},
        paramtype = "light",
        groups = moretrees.leaves_groups,
        drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:jungletree_sapling", "moretrees:jungletree_leaves_" .. name),
        sounds = default.node_sound_leaves_defaults(),
	waving = 1,
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:jungletree_tree"}),
    })
end



minetest.register_node("moretrees:jungletree_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Jungletree Tree",
    tiles = {
        "moretrees_jungletree_trunk_top.png",
        "moretrees_jungletree_trunk_top.png",
        "moretrees_jungletree_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:jungletree_leaves_red",
      "moretrees:jungletree_leaves_green",
      "moretrees:jungletree_leaves_yellow",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:jungletree_sapling", {
    description = "Jungletree Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",
    --visual_scale = 1.0,
    tiles = {"moretrees_jungletree_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
      if not moretrees.can_grow(pos) then
        minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
        return
      end

      minetest.set_node(pos, {name='air'}) -- Remove sapling first.
          schems = {
              "jungletree_red.mts",
              "jungletree_yellow.mts",
              "jungletree_green.mts",
          }
          
      local path = moretrees.modpath .. "/schematics/" .. schems[math.random(1, #schems)]
      local schempos = vector.add(pos, SCHEMATIC_RELP)
      local subtract = math.random(0, math.random(0, 4))
      schempos.y = schempos.y - subtract
      minetest.place_schematic(schempos, path, "random", nil, false)
      trunkgen.generate_bole(pos, "moretrees:jungletree_tree")
      trunkgen.generate_jungletree_branches(
        pos, "moretrees:jungletree_tree",
        {"moretrees:jungletree_leaves_red", "moretrees:jungletree_leaves_green", "moretrees:jungletree_leaves_yellow"},
        3, 10-subtract)
			hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:jungletree_leaves_green", math.random(10, 30))
			hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:jungletree_leaves_red", math.random(10, 30))
			hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:jungletree_leaves_yellow", math.random(10, 30))

			hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:jungletree_leaves_green", math.random(10, 30))
			hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:jungletree_leaves_red", math.random(10, 30))
			hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:jungletree_leaves_yellow", math.random(10, 30))
      snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
    end,
    
    on_construct = function(pos)
      minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
    end,
    
    on_place = function(itemstack, placer, pointed_thing)
      itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
              "moretrees:jungletree_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
      return itemstack
    end,
})



minetest.register_node("moretrees:jungletree_wood", {
    description = "Fine Jungle Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_jungletree_wood.png"},
    groups = moretrees.get_wood_groups({wood_dark = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_craft({
    output = 'moretrees:jungletree_wood 4',
    recipe = {
        {'moretrees:jungletree_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_junglewood 4",
    recipe = {
        {"moretrees:jungletree_wood", 'group:stick', "moretrees:jungletree_wood"},
        {"moretrees:jungletree_wood", 'group:stick', "moretrees:jungletree_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_junglewood_closed",
    recipe = {
        {"default:stick", "moretrees:jungletree_wood", "default:stick"},
        {"default:stick", "moretrees:jungletree_wood", "default:stick"}
    }
})



stairs.register_stair_and_slab(
    "jungletree_wood",
    "moretrees:jungletree_wood",
    moretrees.stair_groups,
    {"moretrees_jungletree_wood.png"},
    "Fine Jungle",
    default.node_sound_wood_defaults()
)



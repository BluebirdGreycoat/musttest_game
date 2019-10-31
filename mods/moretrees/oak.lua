
moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*10
local SAPLING_TIME_MAX = 60*15
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-4, y=0, z=-4}
local SCHEMATIC_MAXP = {x=4, y=12, z=4}
local SCHEMATIC_RELP = {x=-4, y=0, z=-4}



minetest.register_node("moretrees:oak_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Oak Tree",
    tiles = {
        "moretrees_oak_trunk_top.png",
        "moretrees_oak_trunk_top.png",
        "moretrees_oak_trunk.png"
    },
    paramtype2 = "facedir",
    groups = moretrees.tree_groups,
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:oak_leaves",
      "moretrees:oak_acorn",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:oak_leaves", {
    description = "Oak Leaves",
    drawtype = "allfaces_optional",
    visual_scale = 1.3,
	waving = 1,
    tiles = {"moretrees_oak_leaves.png"},
    paramtype = "light",
    groups = moretrees.leaves_groups,
    drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:oak_sapling", "moretrees:oak_leaves"),
    sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:oak_tree"}),
})



minetest.register_node("moretrees:oak_wood", {
    description = "Oak Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_oak_wood.png"},
    groups = moretrees.get_wood_groups({wood_light = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:oak_sapling", {
    description = "Oak Sapling\n\nWill not grow in deep caves.\nGrows acorns.",
    drawtype = "plantlike",
    --visual_scale = 1.0,
    tiles = {"moretrees_oak_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:oak_tree", "moretrees:oak_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/oak.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math.random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:oak_tree")
		hb4.leafscatter.remove(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:oak_leaves", math.random(10, 30))
		hb4.leafscatter.add(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, "moretrees:oak_leaves", math.random(10, 30))
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
        
        fruitscatter.scatter_fruit_under_leaves(
            pos,
            "moretrees:oak_leaves",
            "moretrees:oak_acorn",
            SCHEMATIC_MINP,
            SCHEMATIC_MAXP,
            math.random(6, 10)
        )
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:oak_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_node("moretrees:oak_acorn", {
	description = "Acorn",
	drawtype = "plantlike",
	visual_scale = 0.8,
	tiles = {"moretrees_acorn.png"},
	inventory_image = "moretrees_acorn.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.2, -0.5, -0.2, 0.2, 0, 0.2},
	},
	-- Nuts do not rot.
	groups = {fleshy=3, dig_immediate=3, flammable=2, leafdecay=3, leafdecay_drop=1},
	sounds = default.node_sound_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:oak_tree"}),

	after_dig_node = hb4.fruitregrow.after_dig_node(),
	after_place_node = hb4.fruitregrow.after_place_node(),
	on_finish_collapse = hb4.fruitregrow.on_finish_collapse(),
})



minetest.register_craftitem("moretrees:acorn_muffin_batter", {
	description = "Acorn Muffin batter",
	inventory_image = "moretrees_acorn_muffin_batter.png",
	groups = {foodrot=1},
})



minetest.register_craftitem("moretrees:acorn_muffin", {
	description = "Acorn Muffin",
	inventory_image = "moretrees_acorn_muffin.png",
	on_use = minetest.item_eat(4),
	groups = {foodrot=1},
})



minetest.register_craft({
	type = "shapeless",
	output = "moretrees:acorn_muffin_batter",
	recipe = {
		"moretrees:oak_acorn",
		"moretrees:oak_acorn",
		"moretrees:oak_acorn",
		"moretrees:oak_acorn",
		"moretrees:coconut_milk",
	},
	replacements = {
		{ "moretrees:coconut_milk", "vessels:drinking_glass" },
	},
})



minetest.register_craft({
	type = "cooking",
	output = "moretrees:acorn_muffin 4",
	recipe = "moretrees:acorn_muffin_batter",
})



minetest.register_craft({
    output = 'moretrees:oak_wood 4',
    recipe = {
        {'moretrees:oak_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:oak_wood", 'group:stick', "moretrees:oak_wood"},
        {"moretrees:oak_wood", 'group:stick', "moretrees:oak_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"group:stick", "moretrees:oak_wood", "group:stick"},
        {"group:stick", "moretrees:oak_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "oak",
    "moretrees:oak_wood",
    moretrees.stair_groups,
    {"moretrees_oak_wood.png"},
    "Oak Plank",
    default.node_sound_wood_defaults()
)

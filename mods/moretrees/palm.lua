
moretrees = moretrees or {}
local SAPLING_TIME_MIN = 60*20
local SAPLING_TIME_MAX = 60*40
local SAPLING_CHANCE = 40
local SCHEMATIC_MINP = {x=-4, y=0, z=-4}
local SCHEMATIC_MAXP = {x=4, y=13, z=4}
local SCHEMATIC_RELP = {x=-4, y=0, z=-4}

-- Localize for performance.
local math_random = math.random



minetest.register_node("moretrees:palm_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

  description = "Palm Tree",
  tiles = {
      "moretrees_palm_trunk_top.png",
      "moretrees_palm_trunk_top.png",
      "moretrees_palm_trunk.png"
  },
  paramtype2 = "facedir",
  groups = moretrees.tree_groups,
  sounds = default.node_sound_wood_defaults(),
  on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "moretrees:palm_leaves",
      "moretrees:coconut",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("moretrees:palm_leaves", {
	description = "Palm Leaves",
	drawtype = "allfaces_optional",

	tiles = {"moretrees_palm_leaves.png"},
	paramtype = "light",
	waving = 1,
	groups = moretrees.leaves_groups,
	drop = moretrees.get_leafdrop_table(SAPLING_CHANCE, "moretrees:palm_sapling", "moretrees:palm_leaves"),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,

	on_construct = enhanced_leafdecay.make_leaf_constructor({}),
	on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:palm_tree"}),
})



minetest.register_node("moretrees:palm_wood", {
    description = "Palm Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"moretrees_palm_wood.png"},
    groups = moretrees.get_wood_groups({wood_dark = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("moretrees:palm_sapling", {
    description = "Palm Sapling\n\nWill not grow in deep caves.\nGrows coconuts.",
    drawtype = "plantlike",

    tiles = {"moretrees_palm_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = moretrees.sapling_selection_box,
    groups = moretrees.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "moretrees:palm_tree", "moretrees:palm_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

		if not moretrees.can_grow(pos) then
			minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
			return
		end

		minetest.set_node(pos, {name='air'}) -- Remove sapling first.
		local path = moretrees.modpath .. "/schematics/palm.mts"
		minetest.place_schematic(vector.add(vector.add(pos, {x=0, y=math_random(-1, 1), z=0}), SCHEMATIC_RELP), path, "random", nil, false)
		trunkgen.check_trunk(pos, 3, "moretrees:palm_tree")
		snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
		ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
        
        fruitscatter.scatter_fruit_under_leaves(
            pos,
            "moretrees:palm_leaves",
            "moretrees:coconut",
            SCHEMATIC_MINP,
            SCHEMATIC_MAXP,
            math_random(5, 6)
        )
	end,
    
    on_construct = function(pos)
		minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
	end,
    
    on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
            "moretrees:palm_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
		return itemstack
	end,
})



minetest.register_node("moretrees:coconut", {
	description = "Coconut",
	drawtype = "plantlike",
	visual_scale = 0.8,
	tiles = {"moretrees_coconut.png"},
	inventory_image = "moretrees_coconut.png",
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
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="moretrees:palm_tree"}),

	after_dig_node = hb4.fruitregrow.after_dig_node(),
	after_place_node = hb4.fruitregrow.after_place_node(),
	on_finish_collapse = hb4.fruitregrow.on_finish_collapse(),
})



minetest.register_craftitem("moretrees:raw_coconut", {
	description = "Raw Coconut",
	inventory_image = "moretrees_raw_coconut.png",
	on_use = minetest.item_eat(4),
	groups = {foodrot=1},
})



-- This food is stored in a glass and does not rot.
minetest.register_craftitem("moretrees:coconut_milk", {
	description = "Coconut Milk\n\nAn energy drink.\nConsume to refresh stamina.",
	inventory_image = "moretrees_coconut_milk.png",
	wield_image = "moretrees_coconut_milk.png",
	on_use = function(itemstack, user, pointed_thing)
		sprint.add_stamina(user, 6)
		user:get_inventory():add_item("main", ItemStack("vessels:drinking_glass"))
		local func = minetest.item_eat(1)
		return func(itemstack, user, pointed_thing)
	end,
})



local cutting_tools = {
	"default:axe_bronze",
	"default:axe_bronze2",
	"default:axe_diamond",
	"default:axe_mese",
	"default:axe_steel",
	"default:axe_stone",
	"gems:axe_amethyst",
	"gems:rf_axe_amethyst",
	"gems:axe_emerald",
	"gems:rf_axe_emerald",
	"gems:axe_ruby",
	"gems:rf_axe_ruby",
	"gems:axe_sapphire",
	"gems:rf_axe_sapphire",
	"moreores:axe_mithril",
	"moreores:axe_silver",
}



for i in ipairs(cutting_tools) do
	local tool = cutting_tools[i]
	minetest.register_craft({
		type = "shapeless",
		output = "moretrees:coconut_milk",
		recipe = {
			"moretrees:coconut",
			"vessels:drinking_glass",
			tool,
		},
		replacements = {
			{ "moretrees:coconut", "moretrees:raw_coconut" },
			{ tool, tool },
		}
	})
end



minetest.register_on_craft(function(...) moretrees.on_coconut_milk_craft(...) end)
moretrees.on_coconut_milk_craft = function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= "moretrees:coconut_milk" then
		return
	end

	local original
	local index
	for i = 1, player:get_inventory():get_size("craft") do
		for j in ipairs(cutting_tools) do
			local tool = cutting_tools[j]
			if old_craft_grid[i]:get_name() == tool then
				original = old_craft_grid[i]
				index = i
			end
		end
	end
	if not original then
		return
	end
	-- put the tool with metadata back in the craft grid
	craft_inv:set_stack("craft", index, original)
end



minetest.register_craft({
    output = 'moretrees:palm_wood 4',
    recipe = {
        {'moretrees:palm_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_wood 4",
    recipe = {
        {"moretrees:palm_wood", 'group:stick', "moretrees:palm_wood"},
        {"moretrees:palm_wood", 'group:stick', "moretrees:palm_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_wood_closed",
    recipe = {
        {"techcrafts:hinge_wood", "moretrees:palm_wood", "group:stick"},
        {"group:stick", "moretrees:palm_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "palm",
    "moretrees:palm_wood",
    moretrees.stair_groups,
    {"moretrees_palm_wood.png"},
    "Palm Plank",
    default.node_sound_wood_defaults()
)

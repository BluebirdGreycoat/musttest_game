
jungletree = jungletree or {}
jungletree.modpath = minetest.get_modpath("jungletree")



local SAPLING_TIME_MIN = 60*15
local SAPLING_TIME_MAX = 60*20
local SAPLING_CHANCE = 25
local SCHEMATIC_MINP = {x=-2, y=0, z=-2}
local SCHEMATIC_MAXP = {x=2, y=12, z=2}
local SCHEMATIC_RELP = {x=-2, y=0, z=-2}



jungletree.can_grow = function(pos)
	return basictrees.can_grow(pos)
end



jungletree.sapling_selection_box = {
    type = "fixed",
    fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3},
}



jungletree.sapling_groups = utility.dig_groups("plant", {
    flammable = 2,
    attached_node = 1,
    sapling = 1,
})



jungletree.tree_groups = utility.dig_groups("tree", {
    flammable = 2,
    tree = 1,
})



jungletree.get_wood_groups = function(extra)
    local groups = utility.dig_groups("wood", extra or {})
    groups.flammable = 2
    groups.wood = 1
    return groups
end



jungletree.stair_groups = utility.dig_groups("wood", {
    flammable = 2,
})



jungletree.leaves_groups = utility.dig_groups("leaves", {
    leafdecay = 3,
    flammable = 2,
    leaves = 1,
    green_leaves = 1,
})



jungletree.get_leafdrop_table = function(chance, sapling, leaves)
    local drop = {
		max_items = 1,
		items = {
			{items={sapling}, rarity=chance},
			{items={"default:stick"}, rarity=10},

			-- Player will get leaves only if he gets nothing else; this is because 'max_items' is 1.
			{items={leaves}},
		}
	}
    return drop
end



minetest.register_node("jungletree:jungletree_tree", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

  description = "White Jungletree",
  tiles = {
      "jungletree_jungletree_top.png",
      "jungletree_jungletree_top.png",
      "jungletree_jungletree_side.png"
  },
  paramtype2 = "facedir",
  groups = jungletree.tree_groups,
  sounds = default.node_sound_wood_defaults(),
  on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "jungletree:jungletree_leaves",
      "group:dry_leaves",
    },
  }),
})



minetest.register_node("jungletree:jungletree_leaves", {
  description = "Jungletree Leaves",
  drawtype = "allfaces_optional",
  visual_scale = 1.3,
  tiles = {"jungletree_jungletree_leaves.png"},
  paramtype = "light",
	waving = 1,
  groups = jungletree.leaves_groups,
  drop = jungletree.get_leafdrop_table(SAPLING_CHANCE, "jungletree:jungletree_sapling", "jungletree:jungletree_leaves"),
  sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="jungletree:jungletree_tree"}),
})



minetest.register_node("jungletree:jungletree_wood", {
    description = "Jungletree Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"jungletree_jungletree_wood.png"},
    groups = jungletree.get_wood_groups({wood_dark = 1}),
    sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("jungletree:jungletree_sapling", {
    description = "White Jungletree Sapling\n\nWill not grow in deep caves.",
    drawtype = "plantlike",
    --visual_scale = 1.0,
    tiles = {"jungletree_jungletree_sapling.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = jungletree.sapling_selection_box,
    groups = jungletree.sapling_groups,
    sounds = default.node_sound_leaves_defaults(),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

    on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "jungletree:jungletree_tree", "jungletree:jungletree_leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

      if not jungletree.can_grow(pos) then
        minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
        return
      end

      minetest.set_node(pos, {name='air'}) -- Remove sapling first.
      local path = jungletree.modpath .. "/schematics/jungletree_jungletree.mts"
      local schempos = vector.add(pos, SCHEMATIC_RELP)
      local subtract = math.random(0, math.random(0, 2))
      schempos.y = schempos.y - subtract
      minetest.place_schematic(schempos, path, "0", nil, false)
      trunkgen.generate_bole(pos, "jungletree:jungletree_tree")
      trunkgen.generate_jungletree_branches(
        pos,
        "jungletree:jungletree_tree",
        "jungletree:jungletree_leaves",
        4, 7-subtract)
      snowscatter.dump_snowdust_on_tree(pos, SCHEMATIC_MINP, SCHEMATIC_MAXP)
			ambiance.spawn_sound_beacon_inside_area("soundbeacon:trees", pos, SCHEMATIC_MINP, SCHEMATIC_MAXP, 40, 3)
    end,
    
    on_construct = function(pos)
      minetest.get_node_timer(pos):start(math.random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
    end,
    
    on_place = function(itemstack, placer, pointed_thing)
      itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
              "jungletree:jungletree_sapling", SCHEMATIC_MINP, SCHEMATIC_MAXP, 4)
      return itemstack
    end,
})



minetest.register_craft({
    output = 'jungletree:jungletree_wood 4',
    recipe = {
        {'jungletree:jungletree_tree'},
    }
})



minetest.register_craft({
    output = "default:fence_junglewood 4",
    recipe = {
        {"jungletree:jungletree_wood", 'group:stick', "jungletree:jungletree_wood"},
        {"jungletree:jungletree_wood", 'group:stick', "jungletree:jungletree_wood"},
    }
})



minetest.register_craft({
    output = "doors:gate_junglewood_closed",
    recipe = {
        {"group:stick", "jungletree:jungletree_wood", "group:stick"},
        {"group:stick", "jungletree:jungletree_wood", "group:stick"}
    }
})



stairs.register_stair_and_slab(
    "white_jungletree",
    "jungletree:jungletree_wood",
    jungletree.stair_groups,
    {"jungletree_jungletree_wood.png"},
    "Jungletree Plank",
    default.node_sound_wood_defaults()
)



local find_surface = function(xz, b, t)
	for j=t, b, -1 do
		local pos = {x=xz.x, y=j, z=xz.z}
		local n = minetest.get_node(pos).name
		if snow.is_snow(n) then
			local pb = {x=pos.x, y=pos.y-1, z=pos.z}
			local nb = minetest.get_node(pb).name
			if nb == "default:stone" then
				return pos, pb -- Position, position below.
			else
				break
			end
		elseif n == "default:stone" then
			break
		end
	end
end



local chose_sapling = function(pr, pos)
	local name = "jungletree:jungletree_sapling"
	minetest.set_node(pos, {name=name})
end



jungletree.generate_flowers = function(minp, maxp, seed)
	if maxp.y < -50 or minp.y > 300 then
		return
	end

	local pr = PseudoRandom(seed + 7192)
	local count = pr:next(1, 4)
	if count == 1 then
		local xz = {x=pr:next(minp.x, maxp.x), z=pr:next(minp.z, maxp.z)}
		local pos, posb = find_surface(xz, minp.y, maxp.y)

		-- Highlands only.
		if pos then
			if pos.y < 10 then return end
			chose_sapling(pr, pos)
			minetest.set_node(posb, {name="default:mossycobble"})
		end
	end
end



minetest.register_on_generated(function(minp, maxp, seed)
    jungletree.generate_flowers(minp, maxp, seed) end)

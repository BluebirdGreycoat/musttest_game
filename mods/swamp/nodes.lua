--[[
All node and sapling registrations
Copyright (C) 2023-2024 Atlante (AtlanteWork@gmail.com) and contributors

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
USA
--]]

-- This will not be available after load time
local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local S = minetest.get_translator(MODNAME)

minetest.register_node("swamp:dirt_with_swamp_grass", {
	description = S("Dirt with Swamp Grass"),
	tiles = {"swamp_swamp_grass.png", "swamp_mud.png",
		{name = "swamp_mud.png^swamp_swamp_grass_side.png",
		tileable_vertical = false}},
	groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
	soil = {
		base = "swamp:dirt_with_swamp_grass",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	}
})

minetest.register_node("swamp:root", {
	description = S("Root"),
	drawtype = "glasslike_framed_optional",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"swamp_root.png"},
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, falling_node = 1, float = 1, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("swamp:root_with_mud", {
	description = S("Root With Mud"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"swamp_root_with_mud.png"},
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, falling_node = 1, float = 1, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("swamp:mangrove_wood", {
	description = S("Mangrove Wood Planks"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"swamp_mangrove_wood.png"},
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("swamp:mud_brick", {
	description = S("Mud Bricks"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"swamp_mud_brick.png"},
	is_ground_content = false,
	groups = {cracky = 2, crumbly = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("swamp:mud_block", {
	description = S("Mud Blocks"),
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"swamp_mud_block.png"},
	is_ground_content = false,
	groups = {crumbly = 3, soil = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "sumpf", gain = 0.4},
	}),
})

minetest.register_node("swamp:mud", {
	description = S("Mud"),
	tiles = {"swamp_mud.png"},
	groups = {crumbly = 3, soil = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "sumpf", gain = 0.4},
	}),
})

minetest.register_node("swamp:mangrove_tree", {
	description = S("Mangrove Tree"),
	tiles = {"swamp_mangrove_tree_top.png", "swamp_mangrove_tree_top.png",
		"swamp_mangrove_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 3, oddly_breakable_by_hand = 1, flammable = 3},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("swamp:mangrove_leaves", {
	description = S("Mangrove Tree Leaves"),
	drawtype = "allfaces_optional",
	tiles = {"swamp_mangrove_leaves.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"swamp:mangrove_sapling"}, rarity = 20},
			{items = {"swamp:mangrove_leaves"}}
		}
	},
	sounds = default.node_sound_leaves_defaults(),
	after_place_node = default.after_place_leaves,
})

function swamp.grow_new_mangrove_sapling(pos)
	if not default.can_grow(pos) then
		-- try a bit later again
		minetest.get_node_timer(pos):start(math.random(150, 300))
		return
	end
	minetest.remove_node(pos)
	minetest.place_schematic({x = pos.x-2, y = pos.y, z = pos.z-3},
		MODPATH .. "/schematics/mangrove_tree_1.mts",
		"random", nil, false)
end

minetest.register_node("swamp:mangrove_sapling", {
	description = S("Mangrove Tree Sapling"),
	drawtype = "plantlike",
	tiles = {"swamp_mangrove_sapling.png"},
	inventory_image = "swamp_mangrove_sapling.png",
	wield_image = "swamp_mangrove_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	on_timer = swamp.grow_new_mangrove_sapling,
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
	},
	groups = {snappy = 2, dig_immediate = 3, flammable = 2,
		attached_node = 1, sapling = 1},
	sounds = default.node_sound_leaves_defaults(),

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(300, 1500))
	end,

	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
			"swamp:mangrove_sapling",
			-- minp, maxp to be checked, relative to sapling pos
			-- minp_relative.y = 1 because sapling pos has been checked
			{x = -4, y = 1, z = -4},
			{x = 4, y = 7, z = 4},
			-- maximum interval of interior volume check
			4)

		return itemstack
	end,
})

minetest.register_node("swamp:muddy_mud", {
    description = S("Muddy Mud"),
    tiles = {"swamp_muddy_mud.png"},
    drop = "swamp:muddy_mud",
    liquid_viscosity = 15,
    liquidtype = "source",
    liquid_alternative_flowing = "swamp:muddy_mud",
    liquid_alternative_source = "swamp:muddy_mud",
    liquid_renewable = false,
    liquid_range = 0,
    drowning = 1,
    walkable = false,
    climbable = false,
    groups = {crumbly = 3, soil = 1, liquid = 3, disable_jump = 1},
    sounds = default.node_sound_dirt_defaults({
        footstep = {name = "sumpf", gain = 0.4},
    }),
})

minetest.register_node("swamp:glass_bottle_with_water", {
    description = S("Water Glass Bottle"),
    drawtype = "plantlike",
    tiles = {"swamp_water_glass_bottle.png"},
    inventory_image = "swamp_water_glass_bottle.png",
    wield_image = "swamp_water_glass_bottle.png",
    paramtype = "light",
    is_ground_content = false,
    walkable = false,
    liquids_pointable = true,
    selection_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0.3, 0.25}
    },
    groups = {vessel = 1, dig_immediate = 3, attached_node = 1},
    sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("swamp:swamp_water_source", {
	description = S("Swamp Water Source"),
	drawtype = "liquid",
	tiles = {
		{
			name = "swamp_swamp_water_source_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
		{
			name = "swamp_swamp_water_source_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "swamp:swamp_water_flowing",
	liquid_alternative_source = "swamp:swamp_water_source",
	liquid_viscosity = 1,
	-- Not renewable to avoid horizontal spread of water sources in sloping
	-- rivers that can cause water to overflow riverbanks and cause floods.
	-- River water source is instead made renewable by the 'force renew'
	-- option used in the 'bucket' mod by the river water bucket.
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a = 128, r = 30, g = 80, b = 39},
	groups = {water = 3, liquid = 3, cools_lava = 1},
	sounds = default.node_sound_water_defaults(),
})

minetest.register_node("swamp:swamp_water_flowing", {
	description = S("Flowing Swamp Water"),
	drawtype = "flowingliquid",
	tiles = {"swamp_swamp_water.png"},
	special_tiles = {
		{
			name = "swamp_swamp_water_flowing_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
		{
			name = "swamp_swamp_water_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "swamp:swamp_water_flowing",
	liquid_alternative_source = "swamp:swamp_water_source",
	liquid_viscosity = 1,
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a = 128, r = 30, g = 80, b = 39},
	groups = {water = 3, liquid = 3, not_in_creative_inventory = 1,
		cools_lava = 1},
	sounds = default.node_sound_water_defaults(),
})

minetest.register_node("swamp:vine", {
	description = S("Swamp Vine"),
	drawtype = "signlike",
	tiles = {"swamp_vine.png"},
	inventory_image = "swamp_vine.png",
	wield_image = "swamp_vine.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted"
	},
	groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 2},
	legacy_wallmounted = true,
	sounds = default.node_sound_leaves_defaults()
})

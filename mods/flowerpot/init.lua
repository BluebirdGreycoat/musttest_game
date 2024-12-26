
--[[

  Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

  "flowerpot" is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of
  the license, or (at your option) any later version.

--]]

if not minetest.global_exists("flowerpot") then flowerpot = {} end
flowerpot.modpath = minetest.get_modpath("flowerpot")

-- Localize for performance.
local math_random = math.random

-- handle plant removal from flowerpot
-- Seems to be dead code, here.
--[[
local function flowerpot_on_punch(pos, node, puncher, pointed_thing)
	if puncher and not minetest.check_player_privs(puncher, "protection_bypass") then
		local name = puncher:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return false
		end
	end

	local nodedef = minetest.registered_nodes[node.name]
	local plant = nodedef.flowerpot_plantname
	assert(plant, "unknown plant in flowerpot: " .. node.name)

	minetest.sound_play(nodedef.sounds.dug, {pos = pos})
	minetest.handle_node_drops(pos, {plant}, puncher)
	minetest.swap_node(pos, {name = "flowerpot:empty"})
end
--]]

-- handle plant insertion into flowerpot
function flowerpot.on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	if not clicker or not clicker:is_player() then
		return itemstack
	end
	local pname = clicker:get_player_name()

	if minetest.test_protection(pos, pname) then
		return itemstack
	end

	local nodename = itemstack:get_name()
	if not nodename then
		return itemstack
	end

	local ndef = itemstack:get_definition()
	if not ndef then
		return itemstack
	end

	-- If item defines a table of possible alternative nodes to insert,
	-- then pick a random node from the table of possibilities.
	if type(ndef.flowerpot_insert) == "table" then
		if #(ndef.flowerpot_insert) > 0 then
			nodename = ndef.flowerpot_insert[math_random(1, #(ndef.flowerpot_insert))]
		end
	end
	if type(nodename) ~= "string" then
		return itemstack
	end

	-- Check that a potted version of this item actually exists.
	local name = "flowerpot:" .. nodename:gsub(":", "_")
	local def = minetest.registered_nodes[name]
	if not def then
		return itemstack
	end

	minetest.sound_play(def.sounds.place, {pos = pos}, true)
	minetest.swap_node(pos, {name = name})
	itemstack:take_item()
	return itemstack
end





local function get_tile(def)
	local tile = def.tiles[1]
	if type (tile) == "table" then
		return tile.name
	end
	return tile
end

function flowerpot.register_node(nodename, imagetransform)
	assert(nodename, "no nodename passed")
	local nodedef = minetest.registered_nodes[nodename]
	if not nodedef then
		minetest.log("error", nodename .. " is not a known node, unable to register flowerpot")
		return false
	end

	local fx = ""
	if imagetransform then
		fx = imagetransform
	end

	local desc = nodedef.description
	local name = nodedef.name:gsub(":", "_")
	local tiles = {}

	if nodedef.drawtype == "plantlike" or nodedef.drawtype == "firelike" then
		-- X-shaped plants, or similar.
		tiles = {
			{name = "flowerpot.png"},
			{name = get_tile(nodedef) .. fx},
			{name = "doors_blank.png"},
		}
	else
		-- Cubic plants (like cactus).
		tiles = {
			{name = "flowerpot.png"},
			{name = "doors_blank.png"},
			{name = get_tile(nodedef) .. fx},
		}
	end

	-- Drop rules. Drop results of `minetest.get_node_drops` by default,
	-- unless `flowerpot_drop` is present in the node definition.
	-- If `flowerpot_drop` is present, then drop that instead (must be a string).

	local drops = minetest.get_node_drops(nodename, "")
	local dropitems = {"flowerpot:empty"}

	if not nodedef.flowerpot_drop then
		for k, v in ipairs(drops) do
			table.insert(dropitems, v)
		end
	elseif type(nodedef.flowerpot_drop) == "string" then
		table.insert(dropitems, nodedef.flowerpot_drop)
	end

	minetest.register_node(":flowerpot:" .. name, {
		description = "Flowerpot With " .. utility.get_short_desc(desc),
		drawtype = "mesh",
		mesh = "flowerpot.obj",
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		on_rotate = function(...) return screwdriver.rotate_simple(...) end,
		sunlight_propagates = true,
		collision_box = {
			type = "fixed",
			fixed = {-1/4, -1/2, -1/4, 1/4, -1/8, 1/4},
		},
		selection_box = {
			type = "fixed",
			fixed = {-1/4, -1/2, -1/4, 1/4, 7/16, 1/4},
		},
		sounds = default.node_sound_defaults(),
		groups = {attached_node = 1, oddly_breakable_by_hand = 1, snappy = 3, not_in_creative_inventory = 1},
		flowerpot_plantname = nodename,

		-- Some flowers emit light.
		light_source = nodedef.light_source,

		drop = {
			max_items = #dropitems,
			items = {
				{
					items = dropitems,
					rarity = 1,
				},
			}
		},
	})
end



if not flowerpot.loaded then
	-- empty flowerpot
	minetest.register_node("flowerpot:empty", {
		description = "Flowerpot",
		drawtype = "mesh",
		paramtype2 = "facedir",
		on_rotate = function(...) return screwdriver.rotate_simple(...) end,
		mesh = "flowerpot.obj",
		inventory_image = "flowerpot_item.png",
		wield_image = "flowerpot_item.png",
		tiles = {
			{name = "flowerpot.png"},
			{name = "doors_blank.png"},
			{name = "doors_blank.png"},
		},
		paramtype = "light",
		sunlight_propagates = true,
		collision_box = {
			type = "fixed",
			fixed = {-1/4, -1/2, -1/4, 1/4, -1/8, 1/4},
		},
		selection_box = {
			type = "fixed",
			fixed = {-1/4, -1/2, -1/4, 1/4, -1/16, 1/4},
		},
		sounds = default.node_sound_defaults(),
		groups = {attached_node = 1, oddly_breakable_by_hand = 3, cracky = 1, dig_immediate = 3},
		on_rightclick = function(...) return flowerpot.on_rightclick(...) end,
	})

	-- craft
	minetest.register_craft({
		output = "flowerpot:empty",
		recipe = {
			{"default:clay_brick", "", "default:clay_brick"},
			{"", "default:clay_brick", ""},
		}
	})

	-- default farming nodes
	for _, node in pairs({
		-- These items don't exist in our version of MTG.
		--"default:acacia_bush_sapling",
		--"default:acacia_bush_stem",
		--"default:bush_sapling",
		--"default:bush_stem",

		"basictrees:acacia_sapling",
		"basictrees:aspen_sapling",
		"basictrees:pine_sapling",
		"basictrees:tree_sapling",
		"basictrees:jungletree_sapling",

		"default:cactus",
		"default:dry_grass_1",
		"default:dry_grass_2",
		"default:dry_grass_3",
		"default:dry_grass_4",
		"default:dry_grass_5",
		"default:dry_grass2_1",
		"default:dry_grass2_2",
		"default:dry_grass2_3",
		"default:dry_grass2_4",
		"default:dry_grass2_5",
		"default:dry_shrub",
		"default:dry_shrub2",
		"default:grass_1",
		"default:grass_2",
		"default:grass_3",
		"default:grass_4",
		"default:grass_5",

		-- Hanging grass variants are NOT used.

		"default:junglegrass",
		"default:coarsegrass",
		"default:papyrus",
		"default:marram_grass_1",
		"default:marram_grass_2",
		"default:marram_grass_3",

		"farming:cotton_1",
		"farming:cotton_2",
		"farming:cotton_3",
		"farming:cotton_4",
		"farming:cotton_5",
		"farming:cotton_6",
		"farming:cotton_7",
		"farming:cotton_8",
		"farming:wheat_1",
		"farming:wheat_2",
		"farming:wheat_3",
		"farming:wheat_4",
		"farming:wheat_5",
		"farming:wheat_6",
		"farming:wheat_7",
		"farming:wheat_8",

		"flowers:dandelion_white",
		"flowers:dandelion_yellow",
		"flowers:geranium",
		"flowers:chrysanthemum_green",
		"flowers:allium_pink",
		"flowers:rose",
		"flowers:rose_white",
		"flowers:zinnia_red",
		"flowers:tulip",
		"flowers:tulip_black",
		"flowers:viola",
		"flowers:desertrose_pink",
		"flowers:thornstalk",
		"flowers:desertrose_red",
		"flowers:foxglove_pink",
		"flowers:bluebell",
		"flowers:snapdragon",
		"flowers:forgetmenot",
		"flowers:poppy_orange",
		"flowers:iris_black",
		"flowers:daylily",
		"flowers:lupine_purple",
		"flowers:lupine_blue",
		"flowers:jack",

		"flowers:mushroom_brown",
		"flowers:mushroom_red",

		"flowers:delphinium",
		"flowers:thistle",
		"flowers:lazarus",
		"flowers:mannagrass",
		"flowers:lockspur",

		"nether:glowflower",
		"nether:grass_dried",
		"nether:grass_1",
		"nether:grass_2",
		"nether:grass_3",
		"nethervine:vine",

		"firetree:sapling",
		"jungletree:jungletree_sapling",

		"moretrees:apple_tree_sapling",
		"moretrees:beech_sapling",
		"moretrees:birch_sapling",
		"moretrees:cedar_sapling",
		"moretrees:date_palm_sapling",
		"moretrees:fir_sapling",
		"moretrees:jungletree_sapling",
		"moretrees:oak_sapling",
		"moretrees:palm_sapling",
		"moretrees:poplar_sapling",
		"moretrees:rubber_tree_sapling",
		"moretrees:sequoia_sapling",
		"moretrees:spruce_sapling",
		"moretrees:willow_sapling",

		"cavestuff:mycena",
		"cavestuff:fungus",

		"carrot:plant_1",
		"carrot:plant_2",
		"carrot:plant_3",
		"carrot:plant_4",
		"carrot:plant_5",
		"carrot:plant_6",
		"carrot:plant_7",
		"carrot:plant_8",

		"cucumber:cucumber_1",
		"cucumber:cucumber_2",
		"cucumber:cucumber_3",
		"cucumber:cucumber_4",

		"tomato:plant_1",
		"tomato:plant_2",
		"tomato:plant_3",
		"tomato:plant_4",
		"tomato:plant_5",
		"tomato:plant_6",
		"tomato:plant_7",
		"tomato:plant_8",

		"potatoes:potato_1",
		"potatoes:potato_2",
		"potatoes:potato_3",
		"potatoes:potato_4",
                
		"aloevera:aloe_plant_01",
		"aloevera:aloe_plant_02",
		"aloevera:aloe_plant_03",
		"aloevera:aloe_plant_04",

		"onions:allium_sprouts_1",
		"onions:allium_sprouts_2",
		"onions:allium_sprouts_3",
		"onions:allium_sprouts_4",

		"default:tvine_display",
	}) do
		flowerpot.register_node(node)
	end

	local c = "flowerpot:core"
	local f = flowerpot.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	flowerpot.loaded = true
end



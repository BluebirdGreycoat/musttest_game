--[[
Miscellaneous
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

local S = minetest.get_translator(minetest.get_current_modname())

function swamp.globalstep(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local speed = player:get_physics_override().speed
        local jump = player:get_physics_override().jump

        local player_pos = player:get_pos()
        local player_node_pos = {
            x = math.floor(player_pos.x + 0.5),
            y = math.floor(player_pos.y + 0.5) - 1,
            z = math.floor(player_pos.z + 0.5)
        }
        local player_node = minetest.get_node(player_node_pos)

        if player_node.name == "swamp:mud" then
            local two_blocks_down_pos = {x = player_node_pos.x, y = player_node_pos.y - 1, z = player_node_pos.z}
            local two_blocks_down_node = minetest.get_node(two_blocks_down_pos)

            if two_blocks_down_node.name == "swamp:mud" then
                player:set_physics_override({speed = 0.70, jump = 0.95})
            else
                player:set_physics_override({speed = speed, jump = jump})
            end
        end
    end
end

minetest.register_globalstep(function(dtime)
    swamp.globalstep(dtime)
end)

default.register_fence("swamp:fence_mangrove_wood", {
	description = S("Mangrove Wood Fence"),
	texture = "swamp_fence_mangrove_wood.png",
	inventory_image = "default_fence_overlay.png^swamp_mangrove_wood.png^" ..
				"default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^swamp_mangrove_wood.png^" ..
				"default_fence_overlay.png^[makealpha:255,126,126",
	material = "swamp:mangrove_wood",
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	sounds = default.node_sound_wood_defaults()
})

default.register_fence_rail("swamp:fence_rail_mangrove_wood", {
	description = S("Mangrove Wood Fence Rail"),
	texture = "swamp_fence_rail_mangrove_wood.png",
	inventory_image = "default_fence_rail_overlay.png^swamp_mangrove_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^swamp_mangrove_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "swamp:mangrove_wood",
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	sounds = default.node_sound_wood_defaults()
})

default.register_mesepost("swamp:mese_post_light_mangrove_wood", {
	description = S("Mangrove Wood Mese Post Light"),
	texture = "swamp_fence_mangrove_wood.png",
	material = "swamp:mangrove_wood",
})

if minetest.get_modpath("doors") then
    doors.register_fencegate("swamp:gate_mangrove_wood", {
        description = S("Mangrove Wood Fence Gate"),
        texture = "swamp_mangrove_wood.png",
        material = "swamp:mangrove_wood",
        groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2}
    })

    doors.register_trapdoor("swamp:mangrove_trapdoor", {
        description = S("Mangrove Trapdoor"),
        inventory_image = "swamp_mangrove_trapdoor.png",
        wield_image = "swamp_mangrove_trapdoor.png",
        tile_front = "swamp_mangrove_trapdoor.png",
        tile_side = "swamp_mangrove_trapdoor_side.png",
        gain_open = 0.06,
        gain_close = 0.13,
        groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, door = 1},
    })

    doors.register("swamp:mangrove_door", {
        tiles = {{ name = "swamp_doors_mangrove_door.png", backface_culling = true }},
        description = S("Mangrove Door"),
        inventory_image = "swamp_doors_item_mangrove.png",
        groups = {node = 1, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
        gain_open = 0.06,
        gain_close = 0.13,
        recipe = {
            {"swamp:mangrove_wood", "swamp:mangrove_wood"},
            {"swamp:mangrove_wood", "swamp:mangrove_wood"},
            {"swamp:mangrove_wood", "swamp:mangrove_wood"},
        }
    })
end

minetest.override_item("vessels:glass_bottle",{
    liquids_pointable = true,
})

if minetest.get_mapgen_setting("mg_name") == "v6" then
	default.register_leafdecay({
		trunks = {"swamp:mangrove_tree", "swamp:root"},
		leaves = {"swamp:mangrove_leaves", "swamp:vine"},
		radius = 3,
	})
end

if minetest.get_modpath("dungeon_loot") then
	dungeon_loot.register ({
		{name = "swamp:mud", chance = 0.1, count = {2, 9}},
		{name = "swamp:mangrove_sapling", chance = 0.3, count = {2, 4}},
		{name = "swamp:mud", chance = 0.3, count = {3, 12}},
		{name = "swamp:mangrove_leaves", chance = 0.3, count = {2, 8}},
	})
end

if minetest.get_modpath("flowerpot") then
	flowerpot.register_node("swamp:mangrove_sapling")
end

if minetest.get_modpath("bucket") then
	bucket.register_liquid(
		"swamp:swamp_water_source",
		"swamp:swamp_water_flowing",
		"swamp:bucket_swamp_water",
		"swamp_bucket_swamp_water.png",
		S("Swamp Water Bucket"),
		{tool = 1, water_bucket = 1},
		true
	)
end

-- Untested.
local function glass_bottle(name, swap_with, pos, puncher)
    local itemstack = puncher:get_wielded_item()
    local itemname = itemstack:get_name()

    local node = minetest.get_node_or_nil(pos)
    local node_def = node and minetest.registered_nodes[node.name]

    if itemname == name then
        if node_def and (node_def.drawtype == "liquid" or node_def.drawtype == "flowingliquid") then
            itemstack:take_item()
            puncher:set_wielded_item(itemstack)

            local inv = puncher:get_inventory()
            if inv:room_for_item("main", swap_with) then
                inv:add_item("main", swap_with)
            else
                minetest.add_item(pos, swap_with)
            end
        end
    end
end

function swamp.glass_bottle(pos, node, puncher)
    glass_bottle("vessels:glass_bottle", "swamp:glass_bottle_with_water", pos, puncher)
    glass_bottle("swamp:glass_bottle_with_water", "vessels:glass_bottle", pos, puncher)

    local itemstack = puncher:get_wielded_item()
    local itemname = itemstack:get_name()

    if itemname == "swamp:glass_bottle_with_water" then
        -- TODO: Probably check more soil nodes or similar nodes to dirt.
        if node.name == "default:dirt" then
            minetest.set_node(pos, {name = "swamp:mud"})

            itemstack:take_item()
            puncher:set_wielded_item(itemstack)

            local inv = puncher:get_inventory()
            if inv:room_for_item("main", "vessels:glass_bottle") then
                inv:add_item("main", "vessels:glass_bottle")
            else
                minetest.add_item(pos, "vessels:glass_bottle")
            end
        end
    end
end

minetest.register_on_punchnode(function(pos, node, puncher)
    swamp.glass_bottle(pos, node, puncher)
end)

--[[
Stairs and More Blocks support for mangrove tree and wood
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

if minetest.get_modpath("moreblocks") then
	stairsplus:register_all("mangrove_tree", "wood", "swamp:mangrove_tree", {
		description = S("Mangrove Tree"),
		tiles = {"swamp_mangrove_tree.png"},
		groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	    sounds = default.node_sound_wood_defaults(),
	})

	stairsplus:register_all("mangrove_wood", "wood", "swamp:mangrove_wood", {
		description = S("Mangrove Wood"),
		tiles = {"swamp_mangrove_wood.png"},
		groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	    sounds = default.node_sound_wood_defaults(),
	})
elseif minetest.get_modpath("stairs") then
	stairs.register_stair_and_slab("mangrove_wood", "swamp:mangrove_wood",
		{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
		{"swamp_mangrove_wood.png"},
		S("Mangrove Wood Stair"),
		S("Mangrove Wood Slab"),
		default.node_sound_wood_defaults())
end

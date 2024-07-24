--[[
Crafts for all nodes provided by the Swamp mod
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

minetest.register_craft({
	type = "fuel",
	recipe = "swamp:mangrove_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "swamp:root",
	burntime = 3,
})

minetest.register_craft({
	type = "fuel",
	recipe = "swamp:root_with_mud",
	burntime = 8,
})

minetest.register_craft({
	type = "fuel",
	recipe = "swamp:fence_mangrove_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "swamp:fence_rail_mangrove_wood",
	burntime = 4,
})

minetest.register_craft({
	output = "swamp:mangrove_wood 4",
	recipe = {
		{"swamp:mangrove_tree"},
	}
})

minetest.register_craft({
	output = "default:stick 6",
	recipe = {
		{"swamp:root"},
	}
})

minetest.register_craft({
	output = "default:stick 3",
	recipe = {
		{"swamp:root_with_mud"},
	}
})

minetest.register_craft({
	output = "swamp:mud_block",
	recipe = {
		{"swamp:mud", "farming:wheat"},
	}
})

minetest.register_craft({
	output = "swamp:mud_brick",
	recipe = {
		{"swamp:mud_block", "swamp:mud_block",},
		{"swamp:mud_block", "swamp:mud_block"},
	}
})

minetest.register_craft({
	output = "swamp:mangrove_trapdoor",
	recipe = {
		{"swamp:mangrove_wood", "swamp:mangrove_wood", "swamp:mangrove_wood"},
		{"swamp:mangrove_wood", "", "swamp:mangrove_wood"},
	}
})

--[[
=====================================================================
** More Ores **
By Calinou, with the help of Nore.

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
=====================================================================
--]]

local S
if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s) return s end
end

local modpath = minetest.get_modpath("moreores")

dofile(modpath .. "/_config.txt")
dofile(modpath .. "/tools.lua")

-- Utility functions
-- =================

local default_stone_sounds = default.node_sound_stone_defaults()
local default_metal_sounds = default.node_sound_metal_defaults()

local function get_recipe(c, name)
	if name == "sword" then
		return {{c}, {c}, {"group:stick"}}
	end
	if name == "shovel" then
		return {{c}, {"group:stick"}, {"group:stick"}}
	end
	if name == "axe" then
		return {{c, c}, {c, "group:stick"}, {"", "group:stick"}}
	end
	if name == "pick" then
		return {{c, c, c}, {"", "group:stick", ""}, {"", "group:stick", ""}}
	end
	if name == "hoe" then
		return {{c, c}, {"", "group:stick"}, {"", "group:stick"}}
	end
	if name == "block" then
		return {{c, c, c}, {c, c, c}, {c, c, c}}
	end
	if name == "lockedchest" then
		return {{"group:wood", "group:wood", "group:wood"}, {"group:wood", c, "group:wood"}, {"group:wood", "group:wood", "group:wood"}}
	end
end

local function add_ore(modname, description, mineral_name, oredef)
	local img_base = modname .. "_" .. mineral_name
	local toolimg_base = modname .. "_tool_"..mineral_name
	local tool_base = modname .. ":"
	local tool_post = "_" .. mineral_name
	local item_base = tool_base .. mineral_name
	local ingot = item_base .. "_ingot"
	local lump_item = item_base .. "_lump"
	local ingotcraft = ingot

	if oredef.makes.ore then
		local diggroup = "hardmineral"
		if mineral_name == "tin" then
			diggroup = "mineral"
		elseif mineral_name == "mithril" then
			diggroup = "obsidian"
		end

		minetest.register_node(modname .. ":mineral_" .. mineral_name, {
			description = S("%s Ore"):format(S(description)),
			tiles = {"default_stone.png^" .. modname .. "_mineral_" .. mineral_name .. ".png"},
			groups = utility.dig_groups(diggroup, {ore = 1}),
			sounds = default_stone_sounds,
			drop = lump_item,
			_tnt_drop = lump_item .. " 2",
			silverpick_drop = true,
			place_param2 = 10,
		})
		minetest.register_alias(
			modname .. ":mineral_" .. mineral_name .. "_mined",
			modname .. ":mineral_" .. mineral_name)
	end

	if oredef.makes.block then
		local block_item = item_base .. "_block"
		minetest.register_node(block_item, {
			description = S("%s Block"):format(S(description)),
			tiles = { img_base .. "_block.png" },
			groups = utility.dig_groups("block", {conductor = 1, block = 1}),
			sounds = default_metal_sounds,
		})
		minetest.register_alias(mineral_name.."_block", block_item)
		if oredef.makes.ingot then
			minetest.register_craft( {
				output = block_item,
				recipe = get_recipe(ingot, "block")
			})
			minetest.register_craft( {
				output = ingot .. " 9",
				recipe = {
					{ block_item }
				}
			})
		end
	end

	if oredef.makes.lump then
		minetest.register_craftitem(lump_item, {
			description = S("%s Lump"):format(S(description)),
			inventory_image = img_base .. "_lump.png",
		})
		minetest.register_alias(mineral_name .. "_lump", lump_item)
		if oredef.makes.ingot then
			minetest.register_craft({
				type = "cooking",
				output = ingot,
				recipe = lump_item
			})
		end
	end

	if oredef.makes.ingot then
		minetest.register_craftitem(ingot, {
			description = S("%s Ingot"):format(S(description)),
			inventory_image = img_base .. "_ingot.png",
            groups = {ingot = 1},
		})
		minetest.register_alias(mineral_name .. "_ingot", ingot)
	end

	oredef.oredef.ore_type = "scatter"
	oredef.oredef.ore = modname .. ":mineral_" .. mineral_name
	oredef.oredef.wherein = "default:stone"

	oregen.register_ore(oredef.oredef)
end

-- Add everything:
local modname = "moreores"

local oredefs = {
	silver = {
		description = "Silver",
		makes = {ore = true, block = true, lump = true, ingot = true, chest = false},
		oredef = {clust_scarcity = moreores_silver_chunk_size * moreores_silver_chunk_size * moreores_silver_chunk_size,
			clust_num_ores = moreores_silver_ore_per_chunk,
			clust_size     = moreores_silver_chunk_radius,
			y_min     = moreores_silver_min_depth,
			y_max     = moreores_silver_max_depth
			},
		tools = {
			pick = {
				cracky = {times = {[1] = 2.60, [2] = 1.00, [3] = 0.60}, uses = 100, maxlevel= 1}
			},
			hoe = {
				uses = 300
			},
			shovel = {
				crumbly = {times = {[1] = 1.10, [2] = 0.40, [3] = 0.25}, uses = 100, maxlevel= 1}
			},
			axe = {
				choppy = {times = {[1] = 2.50, [2] = 0.80, [3] = 0.50}, uses = 100, maxlevel= 1},
				fleshy = {times = {[2] = 1.10, [3] = 0.60}, uses = 100, maxlevel= 1}
			},
			sword = {
				fleshy = {times = {[2] = 0.70, [3] = 0.30}, uses = 100, maxlevel= 1},
				snappy = {times = {[2] = 0.70, [3] = 0.30}, uses = 100, maxlevel= 1},
				choppy = {times = {[3] = 0.80}, uses = 100, maxlevel= 0}
			},
		},
		full_punch_interval = 1.0,
		damage_groups = {fleshy = 6*500},
	},
	tin = {
		description = "Tin",
		makes = {ore = true, block = true, lump = true, ingot = true, chest = false},
		oredef = {clust_scarcity = moreores_tin_chunk_size * moreores_tin_chunk_size * moreores_tin_chunk_size,
			clust_num_ores = moreores_tin_ore_per_chunk,
			clust_size     = moreores_tin_chunk_radius,
			y_min     = moreores_tin_min_depth,
			y_max     = moreores_tin_max_depth
			},
		tools = {},
	},
	mithril = {
		description = "Mithril",
		makes = {ore = true, block = true, lump = true, ingot = true, chest = false},
		oredef = {clust_scarcity = moreores_mithril_chunk_size * moreores_mithril_chunk_size * moreores_mithril_chunk_size,
			clust_num_ores = moreores_mithril_ore_per_chunk,
			clust_size     = moreores_mithril_chunk_radius,
			y_min     = moreores_mithril_min_depth,
			y_max     = moreores_mithril_max_depth
			},
		tools = {
			pick = {
				cracky = {times={[1]=2.4, [2]=1.2, [3]=0.60}, uses = 200, maxlevel= 3}
			},
			hoe = {
				uses = 1000
			},
			shovel = {
				crumbly = {times = {[1] = 0.70, [2] = 0.35, [3] = 0.20}, uses = 200, maxlevel= 1}
			},
			axe = {
				choppy = {times = {[1] = 1.75, [2] = 0.45, [3] = 0.45}, uses = 200, maxlevel= 1},
				fleshy = {times = {[2] = 0.95, [3] = 0.30}, uses = 200, maxlevel= 1}
			},
			sword = {
				fleshy = {times = {[2] = 0.65, [3] = 0.25}, uses = 200, maxlevel= 1},
				snappy = {times = {[2] = 0.70, [3] = 0.25}, uses = 200, maxlevel= 1},
				choppy = {times = {[3] = 0.65}, uses = 200, maxlevel= 0}
			}
		},
		full_punch_interval = 0.45,
		damage_groups = {fleshy = 9*500},
	}
}

for orename,def in pairs(oredefs) do
	add_ore(modname, def.description, orename, def)
end



carts:register_rail(":carts:copperrail", {
	description = "Copper Rail",
	tiles = {
		"moreores_copper_rail.png", "moreores_copper_rail_curved.png",
		"moreores_copper_rail_t_junction.png", "moreores_copper_rail_crossing.png"
	},
	groups = carts:get_rail_groups(),
}, {})

minetest.register_craft({
	output = "carts:copperrail 16",
	recipe = {
		{"default:copper_ingot", "", "default:copper_ingot"},
		{"default:copper_ingot", "group:stick", "default:copper_ingot"},
		{"default:copper_ingot", "", "default:copper_ingot"},
	}
})



-- Added stairs registrations. By MustTest

stairs.register_stair_and_slab(
	"silver",
	"moreores:silver_block",
	{cracky = 1, level = 2},
	{"moreores_silver_block.png"},
	"Silver Block",
	default.node_sound_metal_defaults()
)

stairs.register_stair_and_slab(
	"tin",
	"moreores:tin_block",
	{cracky = 1, level = 2},
	{"moreores_tin_block.png"},
	"Tin Block",
	default.node_sound_metal_defaults()
)

stairs.register_stair_and_slab(
	"mithril",
	"moreores:mithril_block",
	{cracky = 1, level = 2},
	{"moreores_mithril_block.png"},
	"Mithril Block",
	default.node_sound_metal_defaults()
)

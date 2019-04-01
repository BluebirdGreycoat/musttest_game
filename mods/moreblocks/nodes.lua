--[[
More Blocks: node definitions

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
--]]

local S = moreblocks.intllib

local sound_wood = default.node_sound_wood_defaults()
local sound_stone = default.node_sound_stone_defaults()
local sound_glass = default.node_sound_glass_defaults()
local sound_leaves = default.node_sound_leaves_defaults()
local sound_metal = default.node_sound_metal_defaults()

local function tile_tiles(name)
	local tex = "moreblocks_" ..name.. ".png"
	return {tex, tex, tex, tex, tex.. "^[transformR90", tex.. "^[transformR90"}
end

local nodes = {
	-- Nodes available modified by MustTest.
	["wood_tile"] = {
		description = S("Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = {"default_wood.png^moreblocks_wood_tile.png",
		"default_wood.png^moreblocks_wood_tile.png",
		"default_wood.png^moreblocks_wood_tile.png",
		"default_wood.png^moreblocks_wood_tile.png",
		"default_wood.png^moreblocks_wood_tile.png^[transformR90",
		"default_wood.png^moreblocks_wood_tile.png^[transformR90"},
		sounds = sound_wood,
		paramtype2 = "facedir",
	},
	["wood_tile_center"] = {
		description = S("Centered Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = {"default_wood.png^moreblocks_wood_tile_center.png"},
		sounds = sound_wood,
		no_stairs = true,
	},
	["wood_tile_full"] = {
		description = S("Full Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = tile_tiles("wood_tile_full"),
		sounds = sound_wood,
	},
	["wood_tile_up"] = {
		description = S("Upwards Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = {"default_wood.png^moreblocks_wood_tile_up.png"},
		sounds = sound_wood,
		no_stairs = true,
		paramtype2 = "facedir",
	},
	["wood_tile_down"] = {
		description = S("Downwards Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = {"default_wood.png^[transformR180^moreblocks_wood_tile_up.png^[transformR180"},
		sounds = sound_wood,
		no_stairs = true,
		paramtype2 = "facedir",
	},
	["wood_tile_left"] = {
		description = S("Rightwards Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = {"default_wood.png^[transformR270^moreblocks_wood_tile_up.png^[transformR270"},
		sounds = sound_wood,
		no_stairs = true,
		paramtype2 = "facedir",
	},
	["wood_tile_right"] = {
		description = S("Leftwards Wooden Tile"),
		groups = utility.dig_groups("wood", {flammable = 3}),
		tiles = {"default_wood.png^[transformR90^moreblocks_wood_tile_up.png^[transformR90"},
		sounds = sound_wood,
		no_stairs = true,
		paramtype2 = "facedir",
	},

	["circle_stone_bricks"] = {
		description = S("Circle Stone"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
		no_stairs = true,
	},
	["circle_sandstone"] = {
		description = S("Circle Sandstone"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
		no_stairs = true,
	},
	["circle_desert_stone_bricks"] = {
		description = S("Circle Desert Stone"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
		no_stairs = true,
	},
	["grey_bricks"] = {
		description = S("Stone Bricks"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["coal_stone_bricks"] = {
		description = S("Coal Stone Bricks"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
		paramtype2 = "facedir",
		place_param2 = 0,
	},
	["iron_stone_bricks"] = {
		description = S("Iron Stone Bricks"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
		paramtype2 = "facedir",
		place_param2 = 0,
	},
	["stone_tile"] = {
		description = S("Stone Tile"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["split_stone_tile"] = {
		description = S("Split Stone Tile"),
		tiles = {"moreblocks_split_stone_tile_top.png",
			"moreblocks_split_stone_tile.png"},
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["split_stone_tile_alt"] = {
		description = S("Checkered Stone Tile"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
		no_stairs = true,
	},
	["tar"] = {
		description = S("Tar"),
		groups = utility.dig_groups("stone", {tar_block = 1}),
		sounds = sound_stone,
		-- Tar is treated as solid, rock-like node with road properties.
		--no_stairs = true,
		movement_speed_multiplier = default.ROAD_SPEED,
	},
	["plankstone"] = {
		description = S("Plankstone"),
		groups = utility.dig_groups("brick"),
		tiles = tile_tiles("plankstone"),
		sounds = sound_stone,
	},
	["coal_stone"] = {
		description = S("Coal Stone"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["iron_stone"] = {
		description = S("Iron Stone"),
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["coal_checker"] = {
		description = S("Coal Checker"),
		tiles = {"moreblocks_coal_checker.png"},
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["iron_checker"] = {
		description = S("Iron Checker"),
		tiles = {"moreblocks_iron_checker.png"},
		groups = utility.dig_groups("brick"),
		sounds = sound_stone,
	},
	["glow_glass"] = {
		description = S("Glow Glass"),
		drawtype = "glasslike_framed_optional",
		--tiles = {"moreblocks_glow_glass.png", "moreblocks_glow_glass_detail.png"},
		tiles = {"moreblocks_glow_glass.png"},
		paramtype = "light",
		sunlight_propagates = true,
		light_source = 11,
		groups = utility.dig_groups("glass"),
		sounds = sound_glass,
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments", "glowstone:glowing_dust"},
					rarity = 1,
				},
			}
		},
	},

	["super_glow_glass"] = {
		description = S("Super Glow Glass"),
		drawtype = "glasslike_framed_optional",
		--tiles = {"moreblocks_super_glow_glass.png", "moreblocks_super_glow_glass_detail.png"},
		tiles = {"moreblocks_super_glow_glass.png"},
		paramtype = "light",
		sunlight_propagates = true,
		light_source = 14,
		groups = utility.dig_groups("glass"),
		sounds = sound_glass,
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments", "glowstone:glowing_dust 2"},
					rarity = 1,
				},
			}
		},
	},

	["copperpatina"] = {
		description = S("Copper Patina Block"),
		groups = utility.dig_groups("block"),
		sounds = sound_metal,
	},
}

for name, def in pairs(nodes) do
	def.tiles = def.tiles or {"moreblocks_" .. name .. ".png"}
	minetest.register_node("moreblocks:" .. name, def)
	-- I don't need aliases. By MustTest
	--minetest.register_alias(name, "moreblocks:" ..name)
	if not def.no_stairs then
		local groups = utility.copy_builtin_groups(def.groups or {})

		assert(type(def.tiles) == "table")
		stairs.register_stair_and_slab(
			name,
			"moreblocks:" .. name,
			groups,
			def.tiles,
			def.description,
			def.sounds
		)

		--[[
		local groups = {}
		for k, v in pairs(def.groups) do groups[k] = v end
		stairsplus:register_all("moreblocks", name, "moreblocks:" ..name, {
			description = def.description,
			groups = groups,
			tiles = def.tiles,
			sunlight_propagates = def.sunlight_propagates,
			light_source = def.light_source,
			sounds = def.sounds,
		})
		--]]
	end
end



minetest.override_item("stairs:slab_super_glow_glass", {
	light_source = 14,
	sunlight_propagates = true,
})

minetest.override_item("stairs:stair_super_glow_glass", {
	light_source = 14,
	sunlight_propagates = true,
})

minetest.override_item("stairs:slab_glow_glass", {
	light_source = 11,
	sunlight_propagates = true,
})

minetest.override_item("stairs:stair_glow_glass", {
	light_source = 11,
	sunlight_propagates = true,
})


-- Items

--[[
minetest.register_craftitem("moreblocks:sweeper", {
	description = S("Sweeper"),
	inventory_image = "moreblocks_sweeper.png",
})

minetest.register_craftitem("moreblocks:nothing", {
	inventory_image = "invisible.png",
	on_use = function() end,
})
--]]


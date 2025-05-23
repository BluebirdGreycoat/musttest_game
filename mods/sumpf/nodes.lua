
minetest.register_node("sumpf:junglestone", {
	description = "Vegetation",
	tiles = {"sumpf_swampstone.png"},
	groups = {cracky=3, falling_node=1, float=1},
	sounds = default.node_sound_stone_defaults(),
})



-- This one doesn't make much sense.
--[[
minetest.register_node("sumpf:cobble", {
	description = "swamp cobble stone",
	tiles = {"sumpf_cobble.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})
--]]



-- Not really crazy about this texture.
--[[
minetest.register_node("sumpf:junglestonebrick", {
	description = "swamp stone brick",
	tiles = {"sumpf_swampstone_brick.png"},
	groups = {cracky=2, stone=1},
	sounds = default.node_sound_stone_defaults(),
})
--]]



minetest.register_node("sumpf:peat", {
	description = "Roots In Peat",
	tiles = {"sumpf_peat.png"},
	groups = {crumbly=3, falling_node=1, float=1},
	sounds = default.node_sound_sand_defaults({
		footstep = {name="sumpf", gain=0.4},
		place = {name="sumpf", gain=0.4},
		dig = {name="sumpf", gain=0.4},
		dug = {name="default_dirt_footstep", gain=0.25}
	}),
})

minetest.register_node("sumpf:kohle", {
	description = "Coal Ore",
	tiles = {"sumpf_swampstone.png^default_mineral_coal2.png"},
	groups = {cracky=3},
	drop = 'default:coal_lump',
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("sumpf:eisen", {
	description = "Iron Ore",
	tiles = {"sumpf_swampstone.png^default_mineral_iron2.png"},
	groups = {cracky=3},
	drop = 'default:iron_lump',
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("sumpf:sumpf", {
	description = "Vegetation",
	--~ tiles = {"sumpf.png"},
	tiles = {{name="sumpf.png", align_style="world", scale=2}},
	groups = {crumbly=3, soil=1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="sumpf", gain=0.4},
	}),
})

minetest.register_node("sumpf:sumpf2", {
	description = "Vegetation",
	tiles = {
		{name="sumpf.png", align_style="world", scale=2},
		"sumpf_swampstone.png",
		{name="sumpf_swampstone.png^sumpf_transition.png", tileable_vertical = false},
	},
	groups = {cracky=3, soil=1},
	sounds = default.node_sound_stone_defaults({
		footstep = {name="sumpf", gain=0.4},
	}),
})

minetest.register_node("sumpf:roofing", {
	description = "Grass Thatch",
	tiles = {"sumpf_roofing.png"},
	is_ground_content = false,
	groups = {snappy = 3, flammable = 1, level = 2},
	sounds = default.node_sound_leaves_defaults(),
	furnace_burntime = 13,
})



-- Non-16x16 texture.
--[[
minetest.register_node("sumpf:gras", {
	description = "swamp grass",
	tiles = {"sumpfgrass.png"},
	inventory_image = "sumpfgrass.png",
	drawtype = "plantlike",
	paramtype = "light",
	waving = 1,
	selection_box = {type = "fixed",fixed = {-1/3, -1/2, -1/3, 1/3, -1/5, 1/3},},
	buildable_to = true,
	walkable = false,
	groups = {snappy=3,flammable=3,flora=1,attached_node=1},
	sounds = default.node_sound_leaves_defaults(),
	furnace_burntime = 1,
})
--]]

minetest.register_alias("castle:pavement",      	"castle_masonry:pavement_brick")
minetest.register_alias("castle:pavement_brick",	"castle_masonry:pavement_brick")
minetest.register_alias("castle:roofslate",			"castle_masonry:roofslate")


-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

minetest.register_node("castle_masonry:pavement_brick", {
	description = S("Paving Stone"),
	drawtype = "normal",
	tiles = {"castle_pavement_brick.png"},
	groups = {cracky=2},
	paramtype = "light",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "castle_masonry:pavement_brick 4",
	recipe = {
		{"default:stone", "default:cobble"},
		{"default:cobble", "default:stone"},
	}
})


	stairs.register_stair_and_slab("pavement_brick", "castle_masonry:pavement_brick",
		{cracky=2},
		{"castle_pavement_brick.png"},
		S("Castle Pavement"),
		default.node_sound_stone_defaults()
	)





--[[
=====================================================================
** More Blocks **
By Calinou, with the help of ShadowNinja and VanessaE.

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
=====================================================================
--]]

moreblocks = {}

local S
if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s) return s end
end
moreblocks.intllib = S

local modpath = minetest.get_modpath("moreblocks")

-- Unnecessary stuff disabled, by MustTest.
dofile(modpath .. "/config.lua")
--dofile(modpath .. "/circular_saw.lua")
--dofile(modpath .. "/stairsplus/init.lua")
dofile(modpath .. "/nodes.lua")
--dofile(modpath .. "/redefinitions.lua")
dofile(modpath .. "/crafting.lua")
--dofile(modpath .. "/aliases.lua")

--[[
if minetest.setting_getbool("log_mods") then
	minetest.log("action", S("[moreblocks] loaded."))
end
--]]




minetest.register_node("moreblocks:red_coal_brick", {
	description = "Darkened Brick Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"moreblocks_coalbrick.png"},
	is_ground_content = false,
	groups = utility.dig_groups("brick", {brick = 1}),
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
    output = "moreblocks:red_coal_brick",
    type = "shapeless",
    recipe = {"default:brick", "dye:black"}
})

minetest.register_craft({
    output = "moreblocks:red_coal_brick",
    type = "shapeless",
    recipe = {"default:brick", "dye:grey"}
})

minetest.register_craft({
    output = "moreblocks:red_coal_brick",
    type = "shapeless",
    recipe = {"default:brick", "dye:dark_grey"}
})

stairs.register_stair_and_slab(
	"coal_redbrick",
	"moreblocks:red_coal_brick",
	{cracky = 3},
	{"moreblocks_coalbrick.png"},
	"Darkened Brick",
	default.node_sound_stone_defaults()
)






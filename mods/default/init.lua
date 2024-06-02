-- Minetest 0.4 mod: default
-- See README.txt for licensing and other information.

-- The API documentation in here was moved into game_api.txt

-- Definitions made by this mod that other mods can use too
if not minetest.global_exists("default") then default = {} end
default.modpath = minetest.get_modpath("default")
default.LIGHT_MAX = 15



dofile(default.modpath .. "/cactus.lua")
dofile(default.modpath .. "/papyrus.lua")
dofile(default.modpath .. "/nodes.lua")
dofile(default.modpath .. "/fences.lua")
dofile(default.modpath .. "/craftitems.lua")
dofile(default.modpath .. "/crafting.lua")
dofile(default.modpath .. "/tvine.lua")



function default.lava_death_messages()
	return {
		"<player> melted into a crisp.",
		"<player> burnt to ash.",
		"<player> stepped in something hot.",
		"<player> did a Gollum.",
	}
end

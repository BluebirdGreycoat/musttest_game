-- Minetest 0.4 mod: default
-- See README.txt for licensing and other information.

-- The API documentation in here was moved into game_api.txt

-- Definitions made by this mod that other mods can use too
default = default or {}
default.modpath = minetest.get_modpath("default")
default.LIGHT_MAX = 15



dofile(default.modpath .. "/cactus.lua")
dofile(default.modpath .. "/papyrus.lua")
dofile(default.modpath .. "/nodes.lua")
dofile(default.modpath .. "/craftitems.lua")
dofile(default.modpath .. "/crafting.lua")




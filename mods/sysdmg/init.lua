
-- Non-reloadable mod.
-- Data used at load-time only.
-- Stores the tables for armor/damage groups.
-- All in one spot for easy tweakings.
sysdmg = {}
sysdmg.modpath = minetest.get_modpath("sysdmg")

dofile(sysdmg.modpath .. "/armor.lua")
dofile(sysdmg.modpath .. "/weapons.lua")

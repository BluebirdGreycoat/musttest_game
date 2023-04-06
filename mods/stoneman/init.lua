
if not minetest.global_exists("stoneman") then stoneman = {} end
stoneman.modpath = minetest.get_modpath("stoneman")



dofile(stoneman.modpath .. "/stoneman.lua")


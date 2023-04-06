
if not minetest.global_exists("iceman") then iceman = {} end
iceman.modpath = minetest.get_modpath("iceman")



dofile(iceman.modpath .. "/iceman.lua")


if not minetest.global_exists("sheep") then sheep = {} end
sheep.modpath = minetest.get_modpath("sheep")



dofile(sheep.modpath .. "/sheep.lua")


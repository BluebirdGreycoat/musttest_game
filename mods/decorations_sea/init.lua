
if not minetest.global_exists("decorations_sea") then decorations_sea = {} end
decorations_sea.modpath = minetest.get_modpath("decorations_sea")

dofile(decorations_sea.modpath .. "/nodes.lua")
dofile(decorations_sea.modpath .. "/sand.lua")

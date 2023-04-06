
if not minetest.global_exists("nether") then nether = {} end
nether.modpath = minetest.get_modpath("nether")

reload.register_file("nether:core", nether.modpath .. "/functions.lua", true)
dofile(nether.modpath .. "/nodes.lua")

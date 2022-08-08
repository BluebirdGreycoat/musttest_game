
nether = nether or {}
nether.modpath = minetest.get_modpath("nether")

reload.register_file("nether:core", nether.modpath .. "/functions.lua", true)
dofile(nether.modpath .. "/nodes.lua")

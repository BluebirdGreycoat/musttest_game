
gems = gems or {}
gems.modpath = minetest.get_modpath("gems")

dofile(gems.modpath .. "/items.lua")
dofile(gems.modpath .. "/tools.lua")
dofile(gems.modpath .. "/crafts.lua")
dofile(gems.modpath .. "/oregen.lua")

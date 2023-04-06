
if not minetest.global_exists("basictrees") then basictrees = {} end
basictrees.modpath = minetest.get_modpath("basictrees")



dofile(basictrees.modpath .. "/common.lua")



-- Tree files.
dofile(basictrees.modpath .. "/tree.lua")
dofile(basictrees.modpath .. "/pinetree.lua")
dofile(basictrees.modpath .. "/jungletree.lua")
dofile(basictrees.modpath .. "/aspentree.lua")
dofile(basictrees.modpath .. "/acaciatree.lua")
dofile(basictrees.modpath .. "/mapgen.lua")


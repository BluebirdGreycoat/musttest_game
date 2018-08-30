
-- Everything in the mod is stored here.
moretrees = moretrees or {}
moretrees.modpath = minetest.get_modpath("moretrees")



dofile(moretrees.modpath .. "/common.lua")
dofile(moretrees.modpath .. "/apples.lua")
dofile(moretrees.modpath .. "/mapgen.lua")



-- Trees.
dofile(moretrees.modpath .. "/apple_tree.lua")
dofile(moretrees.modpath .. "/beech.lua")
dofile(moretrees.modpath .. "/birch.lua")
dofile(moretrees.modpath .. "/cedar.lua")
dofile(moretrees.modpath .. "/date_palm.lua")
dofile(moretrees.modpath .. "/fir.lua")
dofile(moretrees.modpath .. "/jungletree.lua")
dofile(moretrees.modpath .. "/oak.lua")
dofile(moretrees.modpath .. "/palm.lua")
dofile(moretrees.modpath .. "/poplar.lua")
dofile(moretrees.modpath .. "/rubber_tree.lua")
dofile(moretrees.modpath .. "/sequoia.lua")
dofile(moretrees.modpath .. "/spruce.lua")
dofile(moretrees.modpath .. "/willow.lua")



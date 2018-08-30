
grinder = grinder or {}
grinder.modpath = minetest.get_modpath("grinder")

if minetest.get_modpath("reload") and reload then
	reload.register_file("grinder:core", grinder.modpath .. "/functions.lua")
else
	dofile(grinder.modpath .. "/functions.lua")
end

dofile(grinder.modpath .. "/nodes.lua")
dofile(grinder.modpath .. "/crafts.lua")
dofile(grinder.modpath .. "/crusher.lua")

dofile(grinder.modpath .. "/v2.lua")

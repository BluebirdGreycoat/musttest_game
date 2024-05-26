
if not minetest.global_exists("dirtleaf") then dirtleaf = {} end
dirtleaf.modpath = minetest.get_modpath("dirtleaf")



dofile(dirtleaf.modpath .. "/dirtleaf.lua")

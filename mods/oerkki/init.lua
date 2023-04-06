
if not minetest.global_exists("oerkki") then oerkki = {} end
oerkki.modpath = minetest.get_modpath("oerkki")



dofile(oerkki.modpath .. "/oerkki.lua")
dofile(oerkki.modpath .. "/night_master.lua")

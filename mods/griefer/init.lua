
if not minetest.global_exists("griefer") then griefer = {} end
griefer.modpath = minetest.get_modpath("griefer")



dofile(griefer.modpath .. "/functions.lua")
dofile(griefer.modpath .. "/griefer.lua")
dofile(griefer.modpath .. "/elite.lua")
dofile(griefer.modpath .. "/items.lua")
dofile(griefer.modpath .. "/fireball.lua")

reload.register_optional("griefer:secrets",
	griefer.modpath .. "/secrets.sec")

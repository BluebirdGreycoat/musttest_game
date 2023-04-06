
if not minetest.global_exists("mese_crystals") then mese_crystals = {} end
mese_crystals.modpath = minetest.get_modpath("mese_crystals")


mese_crystals.growtime = 60*5
mese_crystals.longgrowtime = 60*30



dofile(mese_crystals.modpath .. "/items.lua")
dofile(mese_crystals.modpath .. "/tools.lua")
dofile(mese_crystals.modpath .. "/mapgen.lua")
dofile(mese_crystals.modpath .. "/crafting.lua")
dofile(mese_crystals.modpath .. "/farming.lua")



if not mese_crystals.run_once then
	local c = "mese_crystals:core"
	local f = mese_crystals.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	mese_crystals.run_once = true
end

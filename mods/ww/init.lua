
if not minetest.global_exists("ww") then ww = {} end
ww.modpath = minetest.get_modpath("ww")
ww.worldpath = minetest.get_worldpath()

if not ww.registered then
	-- Register the mapgen.
	minetest.register_mapgen_script(ww.modpath .. "/mapgen.lua")

	local c = "ww:core"
	local f = ww.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ww.registered = true
end

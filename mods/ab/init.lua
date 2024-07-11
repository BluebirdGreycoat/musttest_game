
if not minetest.global_exists("ab") then ab = {} end
ab.modpath = minetest.get_modpath("ab")
ab.worldpath = minetest.get_worldpath()

if not ab.registered then
	-- Register the mapgen.
	minetest.register_mapgen_script(ab.modpath .. "/mapgen.lua")

	local c = "ab:core"
	local f = ab.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	ab.registered = true
end

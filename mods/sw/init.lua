
if not minetest.global_exists("sw") then sw = {} end
sw.modpath = minetest.get_modpath("sw")
sw.worldpath = minetest.get_worldpath()

if not sw.registered then
	-- Register the mapgen.
	minetest.register_mapgen_script(sw.modpath .. "/mapgen.lua")

	local c = "sw:core"
	local f = sw.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sw.registered = true
end

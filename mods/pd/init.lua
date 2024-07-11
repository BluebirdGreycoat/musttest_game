
if not minetest.global_exists("pd") then pd = {} end
pd.modpath = minetest.get_modpath("pd")
pd.worldpath = minetest.get_worldpath()

if not pd.registered then
	-- Register the mapgen.
	minetest.register_mapgen_script(pd.modpath .. "/mapgen.lua")

	local c = "pd:core"
	local f = pd.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	pd.registered = true
end

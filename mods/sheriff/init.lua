
sheriff = sheriff or {}
sheriff.modpath = minetest.get_modpath("sheriff")



if not sheriff.loaded then
	-- Register reloadable mod.
	local c = "sheriff:core"
	local f = sheriff.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sheriff.loaded = true
end

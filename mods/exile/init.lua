
exile = exile or {}
exile.modpath = minetest.get_modpath("exile")

if not exile.registered then
	local c = "exile:core"
	local f = exile.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	exile.registered = true
end

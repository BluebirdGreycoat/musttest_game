
cdp = cdp or {}
cdp.modpath = minetest.get_modpath("tnt")

if not cdp.registered then
	-- Registered as reloadable in the init.lua file.
	cdp.registered = true
end


if not minetest.global_exists("obsidian_gateway") then obsidian_gateway = {} end
obsidian_gateway.modpath = minetest.get_modpath("obsidian_gateway")

dofile(obsidian_gateway.modpath .. "/gate.lua")
dofile(obsidian_gateway.modpath .. "/flame_staff.lua")
dofile(obsidian_gateway.modpath .. "/entity.lua")

if not obsidian_gateway.run_once then
	local c = "obsidian_gateway:core"
	local f = obsidian_gateway.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	obsidian_gateway.run_once = true
end

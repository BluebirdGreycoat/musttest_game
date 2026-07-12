--[[
Sprint mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
]]

if not minetest.global_exists("sprint") then sprint = {} end
sprint.modpath = minetest.get_modpath("sprint")

dofile(sprint.modpath .. "/esprint.lua")

if not sprint.registered then
	minetest.register_on_joinplayer(function(...)
		return sprint.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return sprint.on_leaveplayer(...)
	end)

	minetest.register_on_respawnplayer(function(...)
		return sprint.on_respawnplayer(...)
	end)

	minetest.register_globalstep(function(...)
		return sprint.globalstep(...)
	end)

	local c = "sprint:core"
	local f = sprint.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sprint.registered = true
end


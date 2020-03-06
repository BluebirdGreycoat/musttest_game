
static_spawnpoint = static_spawnpoint or {}
static_spawnpoint.modpath = minetest.get_modpath("static_spawnpoint")

-- Note: builtin includes this functionality, so we have to override it somehow.

local spawn = {x=-9223, y=4169, z=5861}

function static_spawnpoint.put_player_in_spawn(pref)
	pref:set_pos(spawn)
	return true
end

if not static_spawnpoint.registered then
	-- This depends on us being called *after* the builtin function is called!
	minetest.register_on_newplayer(function(...)
		return static_spawnpoint.put_player_in_spawn(...)
	end)

	local c = "static_spawnpoint:core"
	local f = static_spawnpoint.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	static_spawnpoint.registered = true
end

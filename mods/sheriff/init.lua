
sheriff = sheriff or {}
sheriff.modpath = minetest.get_modpath("sheriff")

local players = {
	"MustTest",
}

-- Let other mods query whether a give player is being punished.
function sheriff.player_punished(pname)
	if players[pname] then
		return true
	end
end

if not sheriff.loaded then
	-- Register reloadable mod.
	local c = "sheriff:core"
	local f = sheriff.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sheriff.loaded = true
end


-- Player modifiers mod for Enyekala.
-- Author of source code: MustTest/BlueBird51
-- License of source code: MIT

if not minetest.global_exists("pova") then pova = {} end
pova.modpath = minetest.get_modpath("pova")
pova.players = pova.players or {}



-- Set physics overrides.
function pova.set_physics_override(pref, overrides)
	pref:set_physics_override(overrides)
end



if not pova.registered then
	pova.registered = true

	-- Register mod reloadable.
	local c = "pova:core"
	local f = pova.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end

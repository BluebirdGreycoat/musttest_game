
if not minetest.global_exists("protector") then protector = {} end
protector.players = protector.players or {} -- Security contexts.
protector.player_guis = protector.player_guis or {} -- GUI contexts (not security).
protector.mod = "redo"
protector.modpath = minetest.get_modpath("protector")
protector.radius = 5 -- Radius is permanent and can never be changed.
protector.radius_small = 3 -- Must always be smaller than primary radius.
protector.max_share_count = 16 -- If you go this high you are stupid.
protector.PROTECTION_ENABLED = true
protector.flip = minetest.settings:get_bool("protector_flip") or false
protector.hurt = (tonumber(minetest.settings:get("protector_hurt")) or 0)
protector.display_time = 60*2
reload.install_simple_signals(protector)

dofile(protector.modpath .. "/hud.lua")
dofile(protector.modpath .. "/tool.lua")
dofile(protector.modpath .. "/formspec.lua")
dofile(protector.modpath .. "/functions.lua")
dofile(protector.modpath .. "/memlist.lua")
dofile(protector.modpath .. "/override.lua")
dofile(protector.modpath .. "/nodes.lua")
dofile(protector.modpath .. "/crafts.lua")
dofile(protector.modpath .. "/displayent.lua")

if not protector.registered then
	local c = "protector:core"
	local f = protector.modpath .. "/init.lua"
	reload.register_file(c, f, false)
	protector.registered = true

	-- If name entered or button press
	minetest.register_on_player_receive_fields(function(...)
		return protector.on_receive_fields(...)
	end)

	minetest.register_privilege("delprotect", {
		description = "Ignore player protection.",
		give_to_singleplayer = false,
	})
end

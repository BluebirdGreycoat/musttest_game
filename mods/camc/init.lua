
if not minetest.global_exists("camc") then camc = {} end
camc.modpath = minetest.get_modpath("camc")

camc.HAWKCAM_PLAYER = "Hawkeye"
camc.CAMERA_BURIED_NUM_RETRIES = 20
camc.RANDOM_HAUNT_TIME_SECONDS = 30
camc.RANDOM_EXPLORE_TIME_SECONDS = 45
camc.CAMERA_FOLLOW_DISTANCE = 20
camc.CAMERA_ACTIVITY_CHECK_SECONDS = 60*2

dofile(camc.modpath .. "/utils.lua")
dofile(camc.modpath .. "/functions.lua")
dofile(camc.modpath .. "/chatcmd.lua")
dofile(camc.modpath .. "/follow.lua")
dofile(camc.modpath .. "/explore.lua")
dofile(camc.modpath .. "/overlay.lua")

reload.register_callback("on_mod_reload", "camc", function(...)
	camc.on_mod_reload(...)
end)

if not camc.run_once then
	camc.run_once = true

	local c = "camc:core"
	local f = camc.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	minetest.register_privilege("camc", {
		description = "Identifies this account as a remote camera bot.",
		give_to_singleplayer = false,
		give_to_admin = false,
	})

	minetest.register_chatcommand("hawkeye", {
		params = "[variable command options]",
		description = "Camera control.",
		privs = {},

		show_help = function(pname)
			camc.on_show_help(pname)
		end,

		func = function(pname, param)
			camc.on_chatcommand(pname, param)
		end,
	})

	minetest.register_on_joinplayer(function(...)
		return camc.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return camc.on_leaveplayer(...)
	end)

	camc.start_camera_checks()
end

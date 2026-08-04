
if not minetest.global_exists("camc") then camc = {} end
camc.modpath = minetest.get_modpath("camc")

camc.HAWKCAM_PLAYER = "Hawkeye"
camc.CAMERA_BURIED_NUM_RETRIES = 20
camc.RANDOM_HAUNT_TIME_SECONDS = 30

dofile(camc.modpath .. "/utils.lua")
dofile(camc.modpath .. "/functions.lua")
dofile(camc.modpath .. "/chatcmd.lua")
dofile(camc.modpath .. "/follow.lua")

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
end

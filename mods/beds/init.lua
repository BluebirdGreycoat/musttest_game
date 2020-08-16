beds = {}
beds.modpath = minetest.get_modpath("beds")
beds.player = {}
beds.pos = {}
beds.spawn = {}
beds.storage = minetest.get_mod_storage()

beds.formspec = "size[8,15;true]" ..
	"bgcolor[#080808BB; true]" ..
	"button_exit[2,12;4,0.75;leave;Leave Bed]"

local modpath = minetest.get_modpath("beds")

-- Load files

dofile(modpath .. "/functions.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/beds.lua")
dofile(modpath .. "/spawns.lua")

minetest.register_privilege("nobeds", {
	description = "Player does not require sleep.",
	give_to_singleplayer = false,
})

minetest.register_on_respawnplayer(function(...)
	return beds.on_respawnplayer(...)
end)

minetest.register_on_joinplayer(function(...)
	return beds.on_joinplayer(...)
end)

minetest.register_on_leaveplayer(function(...)
	return beds.on_leaveplayer(...)
end)

minetest.register_on_player_receive_fields(function(...)
	return beds.on_player_receive_fields(...)
end)

minetest.register_chatcommand("chkbed", {
	params = "",
	description = "Query the status of your own bed.",
	privs = {},
	func = function(pname, param)
		beds.report_respawn_status(pname)
		return true
	end,
})

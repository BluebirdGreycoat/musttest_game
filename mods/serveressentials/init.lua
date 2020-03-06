
serveressentials = serveressentials or {}
serveressentials.modpath = minetest.get_modpath("serveressentials")

-- Outback's reset timeout in realtime days.
serveressentials.reset_timeout = 30

-- Can be gotten once only, at load time.
if not serveressentials.modstorage then
	serveressentials.modstorage = minetest.get_mod_storage()
end



dofile(serveressentials.modpath .. "/outback.lua")
dofile(serveressentials.modpath .. "/rebuild.lua")
dofile(serveressentials.modpath .. "/acacia.lua")
dofile(serveressentials.modpath .. "/utility.lua")
dofile(serveressentials.modpath .. "/whereis.lua")
dofile(serveressentials.modpath .. "/teleport.lua")



if not serveressentials.registered then
	assert(minetest.registered_chatcommands["teleport"])
	minetest.override_chatcommand("teleport", {
		func = function(name, param)
			wield3d.on_teleport()
			local result, str = serveressentials.do_teleport(name, param)
			minetest.chat_send_player(name, "# Server: " .. str)
		end,
	})

	minetest.register_privilege("whereis", {
		description = "Player may use the /whereis command to locate other players.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("whereis", {
		params = "[<player>]",
		description = "Locate a player or the caller.",
		privs = {whereis=true},

		func = function(...)
			return serveressentials.whereis(...)
		end
	})

	local c = "serveressentials:core"
	local f = serveressentials.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	serveressentials.registered = true
end






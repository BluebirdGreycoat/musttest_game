
if not minetest.global_exists("serveressentials") then serveressentials = {} end
serveressentials.modpath = minetest.get_modpath("serveressentials")

-- Outback's reset timeout in realtime days.
serveressentials.reset_timeout = 30
serveressentials.midfeld_reset_timeout = 30*2

-- Can be gotten once only, at load time.
if not serveressentials.modstorage then
	serveressentials.modstorage = minetest.get_mod_storage()
end



dofile(serveressentials.modpath .. "/outback.lua")
dofile(serveressentials.modpath .. "/gaterealm.lua")
dofile(serveressentials.modpath .. "/rebuild.lua")
dofile(serveressentials.modpath .. "/acacia.lua")
dofile(serveressentials.modpath .. "/utility.lua")
dofile(serveressentials.modpath .. "/whereis.lua")
dofile(serveressentials.modpath .. "/teleport.lua")
dofile(serveressentials.modpath .. "/recall.lua")
dofile(serveressentials.modpath .. "/suicide.lua")



function serveressentials.do_rename(pname, param)
	local tokens = param:split(" ")
	if #tokens ~= 2 then
		minetest.chat_send_player(pname, "# Server: Invalid usage.")
		return
	end

	rename.rename_player(rename.grn(tokens[1]), tokens[2], pname)
end



if not serveressentials.registered then
	-- Overriding the teleport chat-command is necessary in order to let admins
	-- use realm-relative coordinates. It also prevents admins from accidentally
	-- teleporting into "unallocated" parts of the world, which can damage* the
	-- map and possibly require use of WorldEdit to fix.
	--
	-- *I.e. cause to be generated chunks that shouldn't be generated, which can
	-- cause a cascade of lighting issues that ruin any terrain below. Note that
	-- this works in concert with the 'rc' (RealmControl) code.
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

	minetest.register_chatcommand("rename", {
		params = "<player> <alias>",
		description = "Rename a player.",
		privs = {server=true},

		func = function(...)
			return serveressentials.do_rename(...)
		end
	})

	local c = "serveressentials:core"
	local f = serveressentials.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	dofile(serveressentials.modpath .. "/defenestrate.lua")

	serveressentials.registered = true
end






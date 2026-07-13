
if not minetest.global_exists("shout") then shout = {} end
shout.modpath = minetest.get_modpath("shout")
shout.worldpath = minetest.get_worldpath()
shout.datafile = shout.worldpath .. "/hints.txt"

dofile(shout.modpath .. "/builtin_tips.lua")
dofile(shout.modpath .. "/hints.lua")
--dofile(shout.modpath .. "/channel.lua")
--dofile(shout.modpath .. "/xchannel.lua")
dofile(shout.modpath .. "/shout.lua")
--dofile(shout.modpath .. "/create.lua")



if not shout.run_once then
	-- Post 'startup complete' message only in multiplayer.
	if not minetest.is_singleplayer() then
		minetest.after(0, function()
			minetest.chat_send_all("# Server: Startup complete.")
		end)
	end

	-- Load persistent channels. This is an array list of all persistent channel names.
	--shout.persistent_channels = shout.MODSTORAGE:get_keys()

	minetest.register_chatcommand("shout", {
		params = "<message>",
		description = "Yell a message to everyone on the server. You can also prepend your chat with '!'.",
		privs = {shout=true},
		func = function(name, param)
			shout.shout(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("say", {
		params = "<message>",
		description = "Whisper a message to everyone nearby. You can also prepend your chat with '$'.",
		privs = {}, -- Does NOT require shout.
		func = function(name, param)
			shout.whisper(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("spoof", {
		params = "[target] <message>",
		description = "Send an anonymous message to everyone nearby.",
		privs = {}, -- Does NOT require shout.
		show_help = function(pname)
			shout.spoof(pname, "", true)
		end,
		func = function(pname, param)
			shout.spoof(pname, chat_core.rewrite_message(param))
			return true
		end,
	})

	local function show_depreciation_help(pname, newcommand)
		minetest.chat_send_player(pname, "# Server: This command is replaced by /" .. newcommand .. ".")
		minetest.chat_send_player(pname, "# Server: Please read /help " .. newcommand .. ".")
	end

	minetest.register_chatcommand("channel", {
		params = "",
		show_help = function(pname)
			show_depreciation_help(pname, "sanctum")
		end,
		description = "Depreciated command.",
		privs = {},
		func = function(pname, param)
			show_depreciation_help(pname, "sanctum")
		end,
	})

	minetest.register_chatcommand("xchannel", {
		params = "",
		description = "Depreciated command.",
		privs = {},
		func = function(pname, param)
			show_depreciation_help(pname, "sanctum")
		end,
	})

	minetest.register_chatcommand("xinvert", {
		params = "",
		description = "Depreciated command.",
		privs = {},
		func = function(pname, param)
			show_depreciation_help(pname, "xalways")
		end,
	})

	--[[
	minetest.register_chatcommand("x", {
		params = "<message>",
		description = "Send a message only to specific channel(s). Also called group DM rooms.",
		privs = {},
		func = function(name, param)
			shout.x_specific(name, chat_core.rewrite_message(param))
			return true
		end,
	})
	--]]

	minetest.register_chatcommand("hint_add", {
		params = "<message>",
		description = "Add a hint message to the hint list. Example between quotes: '/hint_add This is a hint message. Another sentance.'",
		privs = {server=true},
		func = function(name, param)
			shout.hint_add(name, param)
			return true
		end,
	})

	--[[
	minetest.register_chatcommand("create_channel", {
		params = "<channel> <password>",
		description = "Create a persistent channel with a password. Only players with the password can join.",
		privs = {},
		func = function(name, param)
			shout.create_channel(name, param)
			return true
		end,
	})

	minetest.register_chatcommand("delete_channel", {
		params = "<channel>",
		description = "Delete a persistent channel. Only the channel owner can do this.",
		privs = {},
		func = function(name, param)
			shout.delete_channel(name, param)
			return true
		end,
	})
	--]]

	-- Start hints. A hint is written into public chat every so often.
	-- But not too often, or it becomes annoying.
	shout.start_hints()

	-- Channel leave/join functions.
	--[[
	minetest.register_on_joinplayer(function(...)
		return shout.channel_on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...)
		return shout.channel_on_leaveplayer(...) end)
	--]]

	local c = "shout:core"
	local f = shout.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	shout.run_once = true
end

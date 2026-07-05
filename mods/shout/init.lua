
if not minetest.global_exists("shout") then shout = {} end
shout.modpath = minetest.get_modpath("shout")
shout.worldpath = minetest.get_worldpath()
shout.datafile = shout.worldpath .. "/hints.txt"

dofile(shout.modpath .. "/builtin_tips.lua")
dofile(shout.modpath .. "/hints.lua")
dofile(shout.modpath .. "/channel.lua")
dofile(shout.modpath .. "/shout.lua")



if not shout.run_once then
	-- Post 'startup complete' message only in multiplayer.
	if not minetest.is_singleplayer() then
		minetest.after(0, function()
			minetest.chat_send_all("# Server: Startup complete.")
		end)
	end

	minetest.register_chatcommand("shout", {
		params = "<message>",
		description = "Yell a message to everyone on the server. You can also prepend your chat with '!'.",
		privs = {shout=true},
		func = function(name, param)
			shout.shout(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("channel", {
		params = "<join|leave> <channelname>",
		description = "Join or leave open channels.",
		privs = {},
		func = function(name, param)
			shout.channel_command(name, param)
			return true
		end,
	})

	minetest.register_chatcommand("x", {
		params = "<message>",
		description = "Speak on open channel(s).",
		privs = {}, -- Specifically does not require 'shout'
		func = function(name, param)
			shout.x(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("xinvert", {
		params = "",
		description = "Toggle whether /x is required for channel speak.",
		privs = {},
		func = function(name, param)
			shout.xinvert(name, param)
			return true
		end,
	})

	minetest.register_chatcommand("hint_add", {
		params = "<message>",
		description = "Add a hint message to the hint list. Example between quotes: '/hint_add This is a hint message. Another sentance.'",
		privs = {server=true},
		func = function(name, param)
			shout.hint_add(name, param)
			return true
		end,
	})

	-- Start hints. A hint is written into public chat every so often.
	-- But not too often, or it becomes annoying.
	shout.start_hints()

	-- Channel leave/join functions.
	minetest.register_on_joinplayer(function(...)
		return shout.channel_on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...)
		return shout.channel_on_leaveplayer(...) end)

	local c = "shout:core"
	local f = shout.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	shout.run_once = true
end

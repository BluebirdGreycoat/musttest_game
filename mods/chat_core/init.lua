--------------------------------------------------------------------------------
-- Core Chat System for Must Test Survival
-- Author: GoldFireUn
-- License: MIT
--------------------------------------------------------------------------------

if not minetest.global_exists("chat_core") then chat_core = {} end
chat_core.modpath = minetest.get_modpath("chat_core")
chat_core.players = chat_core.players or {}
reload.install_simple_signals(chat_core)

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round

dofile(chat_core.modpath .. "/functions.lua")

if not chat_core.registered then
	local c = "chat_core:core"
	local f = chat_core.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	minetest.register_chatcommand("me", {
		params = "<action>",
		description = "Perform an action (emote). Only visible to others who can see you.",
		privs = {}, -- Expressly does NOT require 'shout', visible only at close range.
		func = function(name, param)
			chat_core.handle_command_me(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("msg", {
		params = "<player> <message>",
		description = "Send a private message to another player.",
		privs = {}, -- Private messages don't require access to the global chat.
		func = function(name, param)
			chat_core.handle_command_msg(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	minetest.register_chatcommand("r", {
		params = "<message>",
		description = "Reply via PM to the last player to send you a PM.",
		privs = {}, -- Private messages don't require access to the global chat.
		func = function(name, param)
			chat_core.handle_command_r(name, chat_core.rewrite_message(param))
			return true
		end,
	})

	-- This should be the only handler registered. Only one handler can be registered.
	minetest.register_on_chat_message(function(name, message)
		chat_core.on_chat_message(name, chat_core.rewrite_message(message))
		return true -- Don't send message automatically, we already did this.
	end)

	minetest.register_on_joinplayer(function(...) return chat_core.on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...) return chat_core.on_leaveplayer(...) end)

	chat_core.registered = true
end




if not minetest.global_exists("chat_channels") then chat_channels = {} end
chat_channels.modpath = minetest.get_modpath("chat_channels")
reload.install_simple_signals(chat_channels)

dofile(chat_channels.modpath .. "/functions.lua")

-- Shorten.
local CC = chat_channels

minetest.after(0, function()
	passport.register_callback("on_passport_first_use", "chat_channels", CC.on_key_firsttime_use)
end)



if not CC.run_once then
	CC.PLAYERS = {} -- Player names as keys. Contains subtables.
	CC.ACTIVE_CHANNELS = {} -- Array of subtables.
	CC.SYSTEM_CHANNELS = {} -- Set of channel names.
	CC.MOD_STORAGE = minetest.get_mod_storage()



	minetest.register_chatcommand("sanctum", {
		params = "[variable command options]",
		description = "Primary command allowing you to manipulate your little bit of the Known Net.",

		-- Privs required are handled at a deeper level.
		privs = {},

		show_help = function(pname)
			CC.on_show_sanctum_help(pname)
		end,

		func = function(pname, param)
			CC.on_sanctum_chatcommand(pname, param)
			return true
		end,
	})



	minetest.register_chatcommand("x", {
		params = "<message>",
		description = "Send text only to specific (elsewhere defined) sanctums in the Known Net.",

		-- Privs required are handled at a deeper level.
		privs = {},

		show_help = function(pname)
			CC.on_show_x_help(pname)
		end,

		func = function(pname, param)
			CC.on_xspeak_chatcommand(pname, chat_core.rewrite_message(param))
			return true
		end,
	})



	minetest.register_chatcommand("xalways", {
		params = "[on|off]",
		description = "Choose whether /x is necessary to speak in private sanctums of the Known Net.",

		privs = {},

		show_help = function(pname)
			CC.on_show_xalways_help(pname)
		end,

		func = function(pname, param)
			CC.on_xalways_chatcommand(pname, param)
			return true
		end,
	})



	-- Channel leave/join functions.
	minetest.register_on_joinplayer(function(...)
		return CC.on_joinplayer(...) end)
	minetest.register_on_leaveplayer(function(...)
		return CC.on_leaveplayer(...) end)



	CC.create_system_channel("global", {
		public_chatlog = true,
		need_shout_priv = true,
		anticurse = true,
		enable_gagging = true,
		requires_minimum_poc = true,
		description = "Global channel for general communication.",
	})

	CC.create_system_channel("newbies", {
		public_chatlog = true,
		need_shout_priv = true,
		anticurse = true,
		enable_gagging = true,
		description = "Newbies' help channel.",
	})

	CC.create_system_channel("citizens", {
		enable_gagging = true,
		requires_minimum_key = true,
		description = "Semiprivate channel for citizens who possess a Key of Citizenship.",
		xspeak_allowed = true,
	})

	CC.create_system_channel("announce", {
		public_chatlog = true,
		no_player_chat = true,
		description = "General (uncategorized) system announcements.",
	})

	CC.create_system_channel("bones", {
		public_chatlog = true,
		no_player_chat = true,
		description = "Death reports and bonebox locations.",
	})

	CC.create_system_channel("hints", {
		public_chatlog = true,
		no_player_chat = true,
		description = "Periodic 'helpful' messages from the server. Mostly only useful for newbies.",
	})

	CC.create_system_channel("mapgen", {
		public_chatlog = true,
		no_player_chat = true,
		description = "Mapgen activity.",
	})



	CC.register_callback("player_join_channel", "chat_channels", function(...)
		CC.on_player_join_channel(...)
	end)

	CC.register_callback("player_leave_channel", "chat_channels", function(...)
		CC.on_player_leave_channel(...)
	end)

	CC.register_callback("on_channel_deleted", "chat_channels", function(...)
		CC.on_channel_deleted(...)
	end)



	local c = "chat_channels:core"
	local f = CC.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	CC.run_once = true
end

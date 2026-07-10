
if not minetest.global_exists("chat_channels") then chat_channels = {} end
chat_channels.modpath = minetest.get_modpath("chat_channels")

-- Advance this if making a major breaking change requiring everyone to be re-initialized.
local SANCTUM_VERSION = 2

local MAX_CHANNEL_COUNT = 128
local XSPEAK_COLOR = core.get_color_escape_sequence("#a8ff00")

-- Shorten.
local CC = chat_channels

CC.REASON_CODES = {
	NO_SHOUT_PRIV = 10,
	PLAYER_GAGGED = 11,
	WRONG_PASSWORD = 12,
	NEED_MINIMUM_POC = 13,
	NEED_KEY = 14,
	CHANNEL_NOT_EXIST = 15,
}



local function channels_intersect(t1, t2)
	for _, k1 in ipairs(t1) do
		for _, k2 in ipairs(t2) do
			if k1 == k2 then
				return true
			end
		end
	end
end



-- Send server response chat to specific player.
local function system_response(pname, message)
	minetest.chat_send_player(pname, "# Server: " .. message)
end



-- Send server response to specific player and play error sound.
local function system_error(pname, errmsg)
	minetest.chat_send_player(pname, "# Server: " .. errmsg)
	easyvend.sound_error(pname)
end



-- Returns the index of a named channel in ACTIVE_CHANNELS, otherwise nil.
function CC.index_of_active_channel(name)
	for k, v in ipairs(CC.ACTIVE_CHANNELS) do
		if v.name == name then
			return k
		end
	end
end



-- Returns player-ref if and only if player exists in the game (pref is accessible).
-- Otherwise, nil.
function CC.check_player_existence(pname)
	return minetest.get_player_by_name(pname)
end



-- Called to notify code whenever something happens internally.
function CC.run_callbacks(name, params)
	for _, cb in ipairs(CC.CALLBACKS) do
		if cb.name == name and cb.action then
			cb.action(params)
		end
	end
end



function CC.register_callback(name, func)
	table.insert(CC.CALLBACKS, {name=name, action=func})
end



-- Returns player-ref if and only if player exists in the game (pref is accessible).
-- Otherwise, nil.
-- Called from chatcommand handlers to complain loudly if player doesn't exist.
function CC.get_pref_complain_if_inexistent(pname)
	local pref = CC.check_player_existence(pname)
	if not pref then
		system_response(pname, "You failed the existence test.")
	end
	return pref
end



-- Shall return TRUE if and only if player has already received first-time initialization.
function CC.is_player_initialized(pname, pref)
	local pmeta = pref:get_meta()
	if pmeta:get_int("sanctum_init") == SANCTUM_VERSION then
		return true
	end
end



-- Shall return a table with player info: read from CC.PLAYERS first, player meta second.
-- Second return value will be TRUE if a default table was returned! (Player info corrupt or missing.)
function CC.get_player_info_read_or_default(pname, pref)
	if CC.PLAYERS[pname] then
		-- Prevent accidental modification.
		return table.copy(CC.PLAYERS[pname])
	end

	if not pref then
		pref = minetest.get_player_by_name(pname)
	end

	local pmeta = pref:get_meta()
	local data = pmeta:get_string("sanctum_info")
	local pinfo = minetest.deserialize(data)
	local default = CC.get_default_pinfo_table()

	if not pinfo or type(pinfo) ~= "table" then
		return default, true
	end

	-- Check that the pinfo table schema matches the default table.
	for k, v in pairs(default) do
		if type(pinfo[k]) ~= type(v) then
			return default, true
		end
	end

	return pinfo
end



function CC.save_pinfo_to_player_meta(pname, pref, pinfo)
	if not pref then
		pref = minetest.get_player_by_name(pname)
	end

	local pmeta = pref:get_meta()
	local serialized = minetest.serialize(pinfo)
	pmeta:set_string("sanctum_info", serialized)
end



-- Return TRUE if channel name is ok.
function CC.is_channelname_ok(channelname)
	if channelname:find("^[_%w]+$") then
		return true
	end
end



-- Return TRUE if password is ok.
function CC.is_password_ok(password)
	if password:find("^[_%w]+$") then
		return true
	end
end



-- Parse comma-delimited channel names from param string.
-- Returns array table.
function CC.get_channelnames_from_param(param)
	return param:split(",")
end



-- Shall return TRUE if player is allowed to join a channel (does not actually join the player).
-- Disregards whether the player is already a member or not.
-- If the player CANNOT join this channel, the second return value will be the reason enum.
function CC.player_may_join_sanctum(pname, pref, cinfo, provided_password)
	local pinfo = CC.get_player_info_read_or_default(pname, pref)

	if cinfo.need_shout_priv then
		if not minetest.check_player_privs(pname, {shout=true}) then
			return nil, CC.REASON_CODES.NO_SHOUT_PRIV
		end
	end

	-- Admin does not need password to join channels.
	if not gdac.player_is_admin(pname) then
		-- Channel owner can always join without password.
		if (cinfo.owner or "") ~= pname then
			if provided_password and provided_password ~= "" then
				if (cinfo.password or "") ~= provided_password then
					return nil, CC.REASON_CODES.WRONG_PASSWORD
				end
			else
				if (cinfo.password or "") ~= (pinfo.sanctum_passwords[cinfo.name] or "") then
					return nil, CC.REASON_CODES.WRONG_PASSWORD
				end
			end
		end
	end

	if cinfo.requires_minimum_poc then
		if not (passport.player_has_key(pname) or passport.player_has_poc(pname)) then
			return nil, CC.REASON_CODES.NEED_MINIMUM_POC
		end
	end

	if cinfo.requires_minimum_key then
		if not passport.player_has_key(pname) then
			return nil, CC.REASON_CODES.NEED_KEY
		end
	end

	return true
end



-- Add information about a channel to a (player's) channel info table.
-- If the pinfo table is saved back to the player, this effectively means they have joined the channel.
function CC.add_sanctum_to_pinfo_table(cinfo, pinfo)
	pinfo.joined_sanctums[cinfo.name] = true
	pinfo.sanctum_passwords[cinfo.name] = nil -- Stale data.
	pinfo.xspeak_channels[cinfo.name] = nil -- Stale

	if cinfo.password and cinfo.password ~= "" then
		pinfo.sanctum_passwords[cinfo.name] = cinfo.password
	end
end



-- Remove information about a channel from a (player's) channel info table.
-- If the pinfo table is saved back to the player, this effectively means they have left the channel.
function CC.remove_sanctum_from_pinfo_table(cinfo, pinfo)
	pinfo.joined_sanctums[cinfo.name] = nil
	pinfo.sanctum_passwords[cinfo.name] = nil
	pinfo.xspeak_channels[cinfo.name] = nil
end



-- This function reads the current list of system channels,
-- and adds all system channels the player is eligible to join.
-- Returns: set of channels player allowed to join. Set NOT allowed to join.
-- The ineligible set will contain REASON_CODES.
function CC.add_system_channels_to_pinfo_table(pname, pref, pinfo)
	-- These will be sets of channel names.
	local successful_joins = {}
	local ineligible_joins = {}

	local function process_channel_eligibility(channel_info)
		local may_join, reason_code = CC.player_may_join_sanctum(pname, pref, channel_info)
		if may_join then
			CC.add_sanctum_to_pinfo_table(channel_info, pinfo)
			successful_joins[channel_info.name] = true
		else
			ineligible_joins[channel_info.name] = reason_code
		end
	end

	-- SYSTEM_CHANNELS is a set of channel names and is always populated.
	-- It contains no other data.
	for cname, _ in pairs(CC.SYSTEM_CHANNELS) do
		local cinfo = CC.get_channel_info_load_if_needed(cname)
		if cinfo then
			process_channel_eligibility(cinfo)
		end
	end

	return successful_joins, ineligible_joins
end



-- Returns a default, empty pinfo table.
-- This is what gets serialized in player metadata.
-- Bump SANCTUM_VERSION if this table changes.
function CC.get_default_pinfo_table()
	local pinfo = {
		joined_sanctums = {}, -- Set of channel names as keys.
		sanctum_passwords = {}, -- Channel names are keys, values are passwords.
		xspeak_channels = {}, -- Set of channel names as keys.
	}

	-- Table copy not needed, it's always a new table.
	return pinfo
end



-- Called to initialize new players, or re-initialize old players on version upgrade.
function CC.initialize_firsttime_player(pname, pref)
	local pmeta = pref:get_meta()

	local pinfo = CC.get_default_pinfo_table()
	local goodjoins, badjoins = CC.add_system_channels_to_pinfo_table(pname, pref, pinfo)

	local serialized = minetest.serialize(pinfo)
	pmeta:set_string("sanctum_info", serialized)
	pmeta:set_int("sanctum_init", SANCTUM_VERSION)

	for cname, _ in pairs(goodjoins) do
		CC.run_callbacks("player_join_channel", {pname=pname, channel=cname})
	end
end



-- Called when player joins game.
function CC.on_joinplayer(pref)
	local pname = pref:get_player_name()
	local firsttime = false

	if not CC.is_player_initialized(pname, pref) then
		CC.initialize_firsttime_player(pname, pref)
		firsttime = true
	end

	local pinfo, is_default = CC.get_player_info_read_or_default(pname, pref)

	if is_default then
		CC.initialize_firsttime_player(pname, pref)
		pinfo = CC.get_player_info_read_or_default(pname, pref)
		firsttime = true
	end

	CC.PLAYERS[pname] = pinfo or CC.get_default_pinfo_table()

	if not firsttime then
		local channels = CC.get_player_enabled_channels(pname, true)
		local list = table.concat(channels, ", ")

		if not gdac.player_is_admin(pname) then
			local msg = "# Server: <" .. rename.gpn(pname) .. "> is in channels: {" .. list .. "}."
			CC.notify_channels_system_message(channels, msg)
		else
			system_response(pname, "You are in channels: {" .. list .. "}.")
		end
	end
end



-- Called when player leaves game (not called for connected players on shutdown).
function CC.on_leaveplayer(pref)
	local pname = pref:get_player_name()
	CC.PLAYERS[pname] = nil
end



function CC.print_channel_status(pname, only_writable)
	local channels, badchan = CC.get_player_enabled_channels(pname, only_writable)
	if #channels == 0 then
		system_response(pname, "You are not subscribed to any usable channels.")
		return
	end

	local count = #channels
	local list = table.concat(channels, ", ")
	system_response(pname, "You are in channels (" .. count .. "): {" .. list .. "}.")

	local goodxchan = CC.get_player_enabled_channels(pname, only_writable, true)
	if #goodxchan > 0 then
		local list = table.concat(goodxchan, ", ")
		system_response(pname, "You have X-speak enabled for these channels: {" .. list .. "}.")
	end

	-- Bad channel table is a SET dict!
	if next(badchan) then
		local badchan2 = {}
		for k, v in pairs(badchan) do
			table.insert(badchan2, k)
		end
		local list = table.concat(badchan2, ", ")
		system_response(pname, "You have stale channel info in your datafile:")
		system_response(pname, "You no longer have access to the following: {" .. list .. "}.")
	end
end



-- Shall return TRUE if and only if player is allowed to create/delete/manipulate channels.
function CC.player_may_create_channels(pname)
	if passport.player_has_key(pname) or gdac.player_is_admin(pname) then
		return true
	end
end



CC.COMMAND_VERBS = {
	list = {
		params = "[all]",
		description = "List registered channels.",
		action = function(pname, param)
			system_response(pname, "The following system channels are available to you:")

			for cname, _ in pairs(CC.SYSTEM_CHANNELS) do
				local cinfo = CC.get_channel_info_load_if_needed(cname)
				if not CC.player_may_join_sanctum(pname, nil, cinfo) then
					goto next_item
				end

				system_response(pname, "  {" .. cinfo.name .. "}: " .. cinfo.description)
				if cinfo.public_chatlog then
					system_response(pname, "    Chat here is published publicly.")
				end
				if cinfo.need_shout_priv then
					system_response(pname, "    The 'shout' priv is required in this channel.")
				end
				if cinfo.enable_gagging then
					system_response(pname, "    You can gag players here (and be gagged yourself).")
				end
				if cinfo.anticurse then
					system_response(pname, "    Curse filtering is enabled.")
				end
				if cinfo.no_player_chat then
					system_response(pname, "    This is a read-only channel. Chat will never be sent here.")
				end
				if cinfo.password and cinfo.password ~= "" then
					system_response(pname, "    Channel is password-protected.")
				end

				::next_item::
			end

			if param ~= "all" then
				return
			end

			system_response(pname, "The following user channels exist:")

			local all_keys = CC.MOD_STORAGE:get_keys()
			for _, key in ipairs(all_keys) do
				if key:find("^channel:") then
					local cname = key:sub(9)
					if CC.SYSTEM_CHANNELS[cname] then
						goto next_item
					end

					local cinfo = CC.get_channel_info_load_if_needed(cname)

					local desc = "No description provided."
					if cinfo.description then
						desc = cinfo.description
					end

					system_response(pname, "  {" .. cinfo.name .. "}: " .. desc)
				end

				::next_item::
			end
		end,
	},

	status = {
		params = "[all]",
		description = "Query your channel status.",
		action = function(pname, param)
			local only_writable = true
			if param:lower() == "all" then
				only_writable = false
				system_response(pname, "Including non-writable channels:")
			end
			CC.print_channel_status(pname, only_writable)

			if CC.xspeak_replaces_normalchat(pname) then
				system_response(pname, "X-speak is currently enabled.")
			end
		end,
	},

	join = {
		params = "<channel> [password]",
		description = "Join a channel.",
		action = function(pname, param)
			local tokens = param:split(" ")
			if #tokens < 1 or #tokens > 2 then
				system_error(pname, "Invalid command invocation.")
				return
			end

			local channel_name = tokens[1]:trim()
			local provided_password = (tokens[2] or ""):trim()

			if not CC.is_channelname_ok(channel_name) then
				system_error(pname, "Invalid sanctum identity token.")
				return
			end

			if provided_password ~= "" then
				if not CC.is_password_ok(provided_password) then
					system_error(pname, "Only alphanumeric characters may be used in passwords.")
					return
				end
			end

			local cinfo = CC.get_channel_info_load_if_needed(channel_name)
			if not cinfo then
				system_error(pname, "That sanctum, {" .. channel_name .. "}, does not exist.")
				return
			end

			local current_channels = CC.get_player_enabled_channels(pname)
			if #current_channels >= MAX_CHANNEL_COUNT then
				system_error(pname, "You are already in too many channels at once. You need to clear out your trash.")
				return
			end

			if table.keyof(current_channels, cinfo.name) then
				system_error(pname, "You are already an upstanding member of {" .. cinfo.name .. "}. Supposedly.")
				return
			end

			local may_join, reason = CC.player_may_join_sanctum(pname, nil, cinfo, provided_password)
			if not may_join then
				local channel_says = CC.get_channel_says_from_reason(reason)
				system_error(pname, "You may not join {" .. cinfo.name .. "}. The sanctum says: " .. channel_says)
				return
			end

			CC.do_join_channel(pname, cinfo.name)
			system_response(pname, "You have entered the {" .. cinfo.name .. "} channel.")
		end,
	},

	leave = {
		params = "<channel>",
		description = "Leave a channel.",
		action = function(pname, param)
			if not CC.is_channelname_ok(param) then
				system_error(pname, "Invalid sanctum identity token.")
				return
			end

			local cinfo = CC.get_channel_info_load_if_needed(param)
			local pinfo = CC.get_player_info_read_or_default(pname)

			if not cinfo then
				system_error(pname, "That sanctum, {" .. param .. "}, does not exist.")
				if pinfo.joined_sanctums[param] then
					pinfo.joined_sanctums[param] = nil
					pinfo.sanctum_passwords[param] = nil
					pinfo.xspeak_channels[param] = nil
					CC.save_pinfo_to_player_meta(pname, nil, pinfo)
					CC.PLAYERS[pname] = pinfo
					system_response(pname, "You weren't supposed to be a member of {" .. param .. "} anyway. Get ye gone!")
				end
				return
			end

			if not pinfo.joined_sanctums[cinfo.name] then
				system_error(pname, "You aren't a member of {" .. cinfo.name .. "}. Can't leave.")
				return
			end

			if not CC.player_may_join_sanctum(pname, nil, cinfo) then
				system_response(pname, "You aren't supposed to be a member of {" .. cinfo.name .. "} anyway. Begon.")
				-- No return here.
			end

			CC.do_leave_channel(pname, cinfo.name)
			system_response(pname, "You have departed the {" .. cinfo.name .. "} channel.")

			local remaining_channels = CC.get_player_enabled_channels(pname, true)
			if #remaining_channels == 0 then
				system_response(pname, "Warning: you have left ALL channels. You may have difficulty speaking around your self-imposed gag.")
			end
		end,
	},

	who = {
		params = "<user>",
		description = "Query which channels another user belongs to.",
		action = function(pname, param)
			if #param == 0 then
				system_error(pname, "No username provided.")
				return
			end

			if not minetest.player_exists(param) then
				system_error(pname, "Boo. That dweeb doesn't exist. Better luck on your spelling, next time.")
				return
			end

			if gdac.player_is_admin(param) then
				system_error(pname, "He hides for \"reasons.\"")
				return
			end

			if not CC.player_may_create_channels(pname) then
				system_error(pname, "That function requires a Key of Citizenship.")
				return
			end

			local their_channels = CC.get_player_enabled_channels(param, true)
			local count = #their_channels
			local list = table.concat(their_channels, ", ")
			system_response(pname, "User <" .. rename.gpn(param) .. "> is in channels (" .. count .. "): {" .. list .. "}.")
		end,
	},

	create = {
		params = "<channel> [password]",
		description = "Create new channel with optional password.",
		action = function(pname, param)
			local tokens = param:split(" ")
			local channel_name = tokens[1]
			local channel_password = (tokens[2] or ""):trim()

			if not CC.is_channelname_ok(channel_name) then
				system_error(pname, "Invalid channel identifier.")
				return
			end

			if channel_password ~= "" then
				if not CC.is_password_ok(channel_password) then
					system_error(pname, "Only alphanumeric characters may be used in passwords.")
					return
				end
			end

			if CC.get_channel_info_load_if_needed(channel_name) then
				system_error(pname, "Channel aready exists.")
				return
			end

			if not CC.player_may_create_channels(pname) then
				system_error(pname, "This function requires a Key of Citizenship.")
				return
			end

			CC.create_user_channel(pname, channel_name, channel_password)

			local cinfo = CC.get_channel_info_load_if_needed(channel_name)
			system_response(pname, "Created channel {" .. cinfo.name .. "}.")
		end,
	},

	what = {
		params = "<channel>",
		description = "Query information about a channel.",
		action = function(pname, param)
			local cinfo = CC.get_channel_info_load_if_needed(param)
			if not cinfo then
				system_response(pname, "Channel {" .. param .. "} doesn't exist.")
				return
			end

			if cinfo.is_system or not cinfo.is_user then
				system_response(pname, "Channel {" .. cinfo.name .. "}: system channel.")
				if cinfo.description and cinfo.description ~= "" then
					system_response(pname, cinfo.description)
				end
				return
			end

			local timestamp = ""
			if cinfo.time then
				timestamp = " on " .. os.date("%Y-%m-%d", cinfo.time)
			end

			system_response(pname, "Channel {" .. cinfo.name .. "} was created by <" .. rename.gpn(cinfo.owner) .. ">" .. timestamp .. ".")
			system_response(pname, (cinfo.description and cinfo.description ~= "" and cinfo.description or "No description provided."))

			if cinfo.password and cinfo.password ~= "" then
				system_response(pname, "Channel is password-protected.")
			else
				system_response(pname, "Channel NOT password-protected.")
			end
		end,
	},

	delete = {
		params = "<channel>",
		description = "Delete user-created channel.",
		action = function(pname, param)
			local cinfo = CC.get_channel_info_load_if_needed(param)
			if not cinfo then
				system_error(pname, "Channel {" .. param .. "} doesn't exist. Go delete yourself.")
				return
			end

			if cinfo.is_system or not cinfo.is_user then
				system_error(pname, "Cannot delete system channel {" .. cinfo.name .. "}. Who do you think you are?")
				return
			end

			if not gdac.player_is_admin(pname) then
				if (cinfo.owner or "") ~= pname then
					system_error(pname, "You're not the owner of {" .. cinfo.name .. "}. Sorry!")
					return
				end
			end

			if not CC.player_may_create_channels(pname) then
				system_error(pname, "If you can't create channels, you probably shouldn't be allowed to delete them.")
				return
			end

			CC.delete_user_channel(cinfo.name)
			system_response(pname, "Deleted sanctum {" .. param .. "}. Bye!")
		end,
	},

	describe = {
		params = "<channel> <description ...>",
		description = "Set sanctum description string.",
		action = function(pname, param)
			local tokens = param:split(" ")

			if #tokens < 2 then
				system_error(pname, "Inappropriate command invocation.")
				return
			end

			local channel_name = tokens[1]
			local channel_desc = chat_core.rewrite_message(param:sub(channel_name:len() + 2):trim())

			if #channel_desc == 0 then
				system_error(pname, "No description string provided.")
				return
			end

			if not CC.is_channelname_ok(channel_name) then
				system_error(pname, "Invalid channel identity token.")
				return
			end

			local cinfo = CC.get_channel_info_load_if_needed(channel_name)
			if not cinfo then
				system_error(pname, "Channel not found. Check your keyboard for broken keys.")
				return
			end

			if cinfo.is_system or not cinfo.is_user then
				system_error(pname, "Cannot change description of system channel. Nice try.")
				return
			end

			if not gdac.player_is_admin(pname) then
				if (cinfo.owner or "") ~= pname then
					system_error(pname, "You are not the owner of channel {" .. cinfo.name .. "}.")
					return
				end
			end

			if not CC.is_language_ok(pname, channel_desc) then
				system_error(pname, "Um ... no.")
				return
			end

			cinfo.description = channel_desc
			CC.rewrite_user_channel(cinfo.name, cinfo)
			system_response(pname, "Updated description for {" .. cinfo.name .. "}: \"" .. cinfo.description .. "\".")
		end,
	},

	xadd = {
		params = "<channel>",
		description = "Turn on X-speak for specific channel.",
		action = function(pname, param)
			if not CC.is_channelname_ok(param) then
				system_error(pname, "Invalid channel identity token.")
				return
			end

			if not passport.player_has_key(pname) then
				system_error(pname, "This function requires a Key of Citizenship.")
				return
			end

			local pinfo = CC.get_player_info_read_or_default(pname)
			local cinfo = CC.get_channel_info_load_if_needed(param)
			if not cinfo then
				system_error(pname, "That channel does not even exist! Stop trolling.")
				return
			end

			if not cinfo.xspeak_allowed then
				system_error(pname, "The sanctum {" .. cinfo.name .. "} does not permit X-speak.")
				return
			end

			local goodchan, badchan = CC.get_player_enabled_channels(pname, true)
			if not table.keyof(goodchan, param) then
				system_error(pname, "You need to join the channel, first. It's called bureaucracy.")
				return
			end

			if pinfo.xspeak_channels[cinfo.name] then
				system_response(pname, "X-speak already enabled for {" .. cinfo.name .. "}. Nothing to be done.")
				return
			end

			CC.do_enable_player_xspeak(pname, param)
			system_response(pname, "Enabling X-speak on {" .. cinfo.name .. "}.")

			local remaining_xspeak_channels = CC.get_player_enabled_channels(pname, true, true)
			if #remaining_xspeak_channels > 0 then
				local list = table.concat(remaining_xspeak_channels, ", ")
				system_response(pname, "X-speak is enabled for the following: {" .. list .. "}.")
			end
		end,
	},

	xdel = {
		params = "<channel>",
		description = "Turn off X-speak for specific channel.",
		action = function(pname, param)
			if not CC.is_channelname_ok(param) then
				system_error(pname, "Invalid channel identity token.")
				return
			end

			local pinfo = CC.get_player_info_read_or_default(pname)
			local goodchan, badchan = CC.get_player_enabled_channels(pname, true)
			if not table.keyof(goodchan, param) then
				if badchan[param] then
					local reason = CC.get_channel_says_from_reason(badchan[param])
					system_response(pname, "What? You're not a member of {" .. param .. "}. Sanctum says: " .. reason .. " Bye!")
				else
					system_response(pname, "Well, that's awkward. Somebody nuked the data.")
				end
				-- No return.
			end

			local cinfo = CC.get_channel_info_load_if_needed(param)
			if not cinfo then
				system_response(pname, "That channel was dead anyway. Get ye gone from it.")
				-- No return.
			end

			if pinfo.xspeak_channels[param] then
				CC.do_disable_player_xspeak(pname, param)
				system_response(pname, "Disabling X-speak on {" .. param .. "}.")
			else
				system_response(pname, "X-speak wasn't enabled on {" .. param .. "}. Nothing to be done.")
			end

			local remaining_xspeak_channels = CC.get_player_enabled_channels(pname, true, true)
			if #remaining_xspeak_channels == 0 then
				system_response(pname, "X-speak is no longer in use for any channel.")
			else
				local list = table.concat(remaining_xspeak_channels, ", ")
				system_response(pname, "X-speak is still enabled for the following: {" .. list .. "}.")
			end
		end,
	},
}
CC.COMMAND_VERBS["part"] = CC.COMMAND_VERBS["leave"]
CC.COMMAND_VERBS["mute"] = CC.COMMAND_VERBS["leave"]
CC.COMMAND_VERBS["remove"] = CC.COMMAND_VERBS["delete"]
CC.COMMAND_VERBS["query"] = CC.COMMAND_VERBS["what"]



function CC.is_language_ok(pname, message)
	if anticurse.check(pname, message, "foul") then
		return
	elseif anticurse.check(pname, message, "curse") then
		return
	end

	return true
end



-- Called when player types a /sanctum chatcommand.
function CC.on_sanctum_chatcommand(pname, param)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	local tokens = param:split(" ")

	if param:len() == 0 or #tokens == 0 then
		system_error(pname, "Missing command verb.")
		return
	end

	local verb = tokens[1]:lower()
	if not CC.COMMAND_VERBS[verb] then
		system_error(pname, "Unknown command verb.")
		return
	end

	-- Execute the subcommand.
	local command_info = CC.COMMAND_VERBS[verb]
	if command_info.action then
		command_info.action(pname, param:sub(verb:len() + 2):trim())
	end
end



-- Called when player requests 'help' on /sanctum chatcommand.
function CC.on_show_sanctum_help(pname)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	system_response(pname, "The following sub-commands are available:")
	for verb, def in pairs(CC.COMMAND_VERBS) do
		local args = def.params and def.params ~= "" and (" " .. def.params .. ": ") or ": "
		local desc = def.description or "No description provided."
		system_response(pname, "    /sanctum " .. verb .. args .. desc)
	end

	local helplines = {
		"",
		"--->  S.A.N.C.T.U.M.  <---",
		"* Sanctified Auto-Net Comms with Unfulfilled Messaging *",
		"",
		"This system is responsible for taking over the server's aging communication module.",
		"It's also going to be responsible for the reasons why nobody can hear you anymore.",
		"To understand SANCTUM, simply understand there is no such thing as global chat.",
		"All communication passes through one or more channels, which players subscribe to.",
		"By default, new users are auto-subscribed to the {newbies} channel.",
		"As the user advances, more channels are unlocked. Eventually you'll make your own.",
		"On top of these channels (sometimes called sanctums) an X-speak layer is bolted on.",
		"This layer replaces the group-DM channels you might have stumbled on at one time.",
		"To make full use of the X-speak system, refer to the /x and /xalways chatcommands.",
		"I hope this made sense. Learn to embrace the bureaucracy.",
		"                                                              --- The Archwizard.",
	}

	for _, line in ipairs(helplines) do
		system_response(pname, line)
	end
end



-- Returns TRUE if player's X-speak replaces default chat (/x is not being required).
function CC.xspeak_replaces_normalchat(pname_or_pref)
	if type(pname_or_pref) == "string" then
		pname_or_pref = minetest.get_player_by_name(pname_or_pref)
	end

	local pref = pname_or_pref
	if not pref or not pref:is_player() then
		return
	end

	local pmeta = pref:get_meta()
	if not pmeta then
		return
	end

	-- Any value other than 0 means X-speak override is enabled.
	if pmeta:get_int("xspeak_override") ~= 0 then
		return true
	end
end



-- Called in response to /x OR normalchat when X-speak override is enabled.
-- NOT called directly in either case.
function CC.handle_on_xspeak(pname, param, is_chatcommand)
	CC.process_chat_message(pname, param, {is_xspeak=true, is_chatcommand=is_chatcommand})
end



-- Called when player uses restricted /x (group DM) communication. (X-speak.)
-- Called from chatcommand ONLY.
function CC.on_xspeak_chatcommand(pname, param)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	CC.handle_on_xspeak(pname, param, true)
end



-- Called when player uses X-speak WITHOUT using the /x chatcommand specifically.
function CC.on_xspeak_normalchat(pname, param)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	CC.handle_on_xspeak(pname, param, false)
end



function CC.get_channel_says_from_reason(reason)
	local channel_says = "lol no."

	if reason == CC.REASON_CODES.NO_SHOUT_PRIV then
		channel_says = "shout priv required."
	elseif reason == CC.REASON_CODES.WRONG_PASSWORD then
		channel_says = "wrong password."
	elseif reason == CC.REASON_CODES.NEED_MINIMUM_POC then
		channel_says = "you need at least proof of citizenship."
	elseif reason == CC.REASON_CODES.NEED_KEY then
		channel_says = "you are not elite enough."
	elseif reason == CC.REASON_CODES.PLAYER_GAGGED then
		channel_says = "you're gagged, bro."
	elseif reason == CC.REASON_CODES.CHANNEL_NOT_EXIST then
		channel_says = "I don't exist. Honest."
	end

	return channel_says
end



function CC.process_chat_message(pname, message, params)
	-- Simplify a little.
	if not params then
		params = {}
	end

	local log_public_chat = false
	local do_anticurse_check = false
	local requires_shout_priv = false
	local need_gag_check = false

	local the_mark_of_cain = chat_core.generate_coord_string(pname)
	local connected_players = minetest.get_connected_players()
	local player_channels, invalid_channels = CC.get_player_enabled_channels(pname, true, params.is_xspeak)

	-- If player is in any channel invalid for them, block chat.
	for cname, reason in pairs(invalid_channels) do
		local channel_says = CC.get_channel_says_from_reason(reason)

		system_error(pname, "You may not speak on {" .. cname .. "}. The sanctum says: " .. channel_says)
		system_error(pname, "You'll need to leave {" .. cname .. "} before you can speak.")
		return
	end

	-- Check this AFTER checking for invalid channels.
	-- Reason is that all of a player's channels could be invalid, but if we don't do the
	-- check for invalid channels first, they would not get feedback explaining the problem.
	if #player_channels == 0 then
		system_error(pname, "Screaming into the Void, I see.")
		if params.is_xspeak then
			system_response(pname, "You seem to be trying to use X-speak. Consider NOT.")
			system_response(pname, "Alternatively, create an X-speak channel.")
		else
			system_response(pname, "You need to be a member of at least one channel in order to talk!")
		end
		return
	end

	-- Collect channel settings.
	for _, cname in ipairs(player_channels) do
		local cinfo = CC.get_channel_info_load_if_needed(cname)

		-- No need to be a Karen over speech that's not in the public chatlog.
		if cinfo.anticurse then
			do_anticurse_check = true
		end

		-- If any channel is public then player's chat is logged to the website.
		if cinfo.public_chatlog then
			log_public_chat = true
		end

		-- Check if any channel needs the shout priv.
		if cinfo.need_shout_priv then
			requires_shout_priv = true
		end

		-- Check if any channel allows gagging (if yes, player can be gagged).
		if cinfo.enable_gagging then
			need_gag_check = true
		end
	end

	-- Toading only affects the public channels.
	if requires_shout_priv or log_public_chat then
		message = toad.modify_chat(pname, message)
	end

	if need_gag_check then
		if command_tokens.mute.player_muted(pname) then
			system_response(pname, shout.get_gag_message())
			-- Player is muted.
			return
		end
	end

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	if do_anticurse_check then
		-- If this succeeds player was kicked or muted or something.
		if chat_core.check_language(pname, message) then return end
	end

	-- Collect receiving players.
	-- The player who sent the message always receives it.
	local receiving_players = {}
	for _, to_pref in ipairs(connected_players) do
		local to_pname = to_pref:get_player_name()
		local to_channels = CC.get_player_enabled_channels(to_pname, true, params.is_xspeak)

		if channels_intersect(to_channels, player_channels) then
			table.insert(receiving_players, to_pref)
		end
	end

	local prename = "<"
	local postname = ">"
	local msg_color = ""

	if params.is_xspeak then
		prename = "«"
		postname = "»"
		msg_color = XSPEAK_COLOR
	end

	chat_core.send_all_ex({
		from = pname,
		prename = prename,
		actname = rename.gpn(pname),
		postname = the_mark_of_cain .. postname .. " ",
		message = msg_color .. message,
		alwaysecho = false,
		allplayers = receiving_players
	})

	-- Log, if player is in a public channel.
	if log_public_chat then
		chat_logging.log_public_chat(pname, message, the_mark_of_cain)
	end

	player_labels.on_chat_message(pname, message)
	afk.reset_timeout(pname)
end



-- Called whenever player chats normally (not whisper, not shout, not X-speak).
function CC.on_chat_message(pname, message)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	CC.process_chat_message(pname, message)
end



function CC.enable_xalways(pname)
	local pref = minetest.get_player_by_name(pname)
	pref:get_meta():set_int("xspeak_override", 1)
end



function CC.disable_xalways(pname)
	local pref = minetest.get_player_by_name(pname)
	pref:get_meta():set_int("xspeak_override", 0)
end



-- Called whenever player uses /xalways chatcommand.
function CC.on_xalways_chatcommand(pname, param)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	local enabled = CC.xspeak_replaces_normalchat

	if param == "" then
		if enabled(pname) then
			CC.disable_xalways(pname)
			system_response(pname, "X-speak disabled. Standard chat restored.")
		else
			CC.enable_xalways(pname)
			system_response(pname, "Standard outgoing chat restricted to private sanctums.")
		end
		return
	end

	if param == "on" then
		if enabled(pname) then
			system_response(pname, "Outgoing chat is already confined to private sanctums. X-speak enabled.")
		else
			CC.enable_xalways(pname)
			system_response(pname, "Standard outgoing chat now restricted to private sanctums.")
		end
		return
	end

	if param == "off" then
		if enabled(pname) then
			CC.disable_xalways(pname)
			system_response(pname, "X-speak disabled. Standard chat restored.")
		else
			system_response(pname, "Outgoing chat is already standard. X-speak not enabled.")
		end
		return
	end
end



function CC.get_x_helplines()
	local helplines = {
		"Enabling X-speak allows you to communicate in select channels without having to do /x.",
		"This does come with the downside that you can't chat (normally) in all joined channels until you turn the setting off.",
		"Example usages:",
		"    /xalways on",
		"    /xalways off",
		"    /xalways",
		"    /x You're a dweeb, RandomUser1!",
		"If X-speak is enabled, all your chat is processed as if you had typed /x at the start of the message.",
		"If X-speak is NOT enabled, then you must type /x in order to use this feature.",
		"The X-speak setting is persistent across logins and server restarts.",
	}

	return helplines
end



-- Called when player requests help on /xalways chatcommand.
function CC.on_show_xalways_help(pname)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	for _, line in ipairs(CC.get_x_helplines()) do
		system_response(pname, line)
	end
end



-- Called when player requests help on the /x chatcommand.
function CC.on_show_x_help(pname)
	local pref = CC.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	for _, line in ipairs(CC.get_x_helplines()) do
		system_response(pname, line)
	end
end



-- Load channel into ACTIVE_CHANNELS, if exists.
-- Returns TRUE if and only if the named channel existed and was loaded.
-- If channel is already loaded, overwrites what's in ACTIVE_CHANNELS.
function CC.load_or_reload_channel(name)
	local key = "channel:" .. name
	if not CC.MOD_STORAGE:contains(key) then
		return
	end

	local data = CC.MOD_STORAGE:get_string(key)
	local info = minetest.deserialize(data)
	if not info or type(info) ~= "table" then
		return
	end

	-- Make sure we loaded what I thought we did.
	if not info.name then
		return
	end
	if info.name ~= name then
		return
	end

	-- Add or replace.
	local index = CC.index_of_active_channel(name)
	if not index then
		table.insert(CC.ACTIVE_CHANNELS, info)
	else
		CC.ACTIVE_CHANNELS[index] = info
	end

	return true
end



-- Called if parameters on a user channel are to be changed.
-- Rewrites what's in ACTIVE_CHANNELS (if exists) and updates MOD_STORAGE.
function CC.rewrite_user_channel(cname, cinfo)
	cinfo.name = cname
	cinfo.is_system = nil
	cinfo.is_user = true

	local index = CC.index_of_active_channel(cname)
	if index then
		CC.ACTIVE_CHANNELS[index] = cinfo
	end

	-- Always replace.
	local serialized = minetest.serialize(cinfo)
	local key = "channel:" .. cname
	CC.MOD_STORAGE:set_string(key, serialized)
end



-- Unconditionally create a system channel, overwriting anything else.
function CC.create_system_channel(name, params)
	local info = table.copy(params)
	info.name = name
	info.is_system = true

	-- Always replace.
	local serialized = minetest.serialize(info)
	local key = "channel:" .. name
	CC.MOD_STORAGE:set_string(key, serialized)
	CC.SYSTEM_CHANNELS[name] = true
end



-- Unconditionally create a USER channel, overwriting anything else.
function CC.create_user_channel(pname, channel_name, channel_password)
	local info = {}
	info.name = channel_name
	info.is_user = true
	info.owner = pname
	info.time = os.time()
	info.requires_minimum_key = true
	info.xspeak_allowed = true

	if channel_password and channel_password ~= "" then
		info.password = channel_password
	end

	-- Always replace.
	local serialized = minetest.serialize(info)
	local key = "channel:" .. channel_name
	CC.MOD_STORAGE:set_string(key, serialized)
end



-- Unconditionally delete a USER channel.
function CC.delete_user_channel(channel_name)
	if CC.SYSTEM_CHANNELS[channel_name] then
		return
	end

	local index = CC.index_of_active_channel(channel_name)
	if index then
		table.remove(CC.ACTIVE_CHANNELS, index)
	end

	local key = "channel:" .. channel_name
	CC.MOD_STORAGE:set_string(key, nil)

	CC.run_callbacks("on_channel_deleted", {channel=channel_name})
end



-- Get channel info table, loading it if needed (but NOT creating it).
-- Returns nil if named channel was never created yet.
function CC.get_channel_info_load_if_needed(channelname)
	local index = CC.index_of_active_channel(channelname)
	if index then
		return CC.ACTIVE_CHANNELS[index]
	end

	CC.load_or_reload_channel(channelname)

	index = CC.index_of_active_channel(channelname)
	if index then
		return CC.ACTIVE_CHANNELS[index]
	end
end



-- Get an (array) list of all channels the player is currently a member of.
-- EXCLUDE channels they actually can't join. (They could have stale data in their player meta.)
-- E.g. this is called from the /status chatcommand.
-- Never returns nil; returns an empty table if player doesn't exist.
-- Second return value is SET of invalid player channels with REASON_CODES values.
function CC.get_player_enabled_channels(pname, only_writable, only_xspeak)
	local pinfo = CC.get_player_info_read_or_default(pname)

	local channels = {}
	local invalid_channels = {}

	for cname, _ in pairs(pinfo.joined_sanctums) do
		local cinfo = CC.get_channel_info_load_if_needed(cname)

		-- Channel might have been deleted.
		if not cinfo then
			invalid_channels[cname] = CC.REASON_CODES.CHANNEL_NOT_EXIST
			goto next_item
		end

		-- If requesting only writable channels, skip the non-writable ones.
		if cinfo.no_player_chat and only_writable then
			goto next_item
		end

		-- If requesting only X-speak channels, skip the non-x-speak ones.
		if only_xspeak and not pinfo.xspeak_channels[cname] then
			goto next_item
		end

		local may_join, reason_code = CC.player_may_join_sanctum(pname, nil, cinfo)
		if may_join then
			table.insert(channels, cinfo.name)
		else
			invalid_channels[cinfo.name] = reason_code
		end

		::next_item::
	end

	return channels, invalid_channels
end



-- Get an (array) list of all players who are joined to at least one channel in the (array) list of channels given.
-- E.g. this is called from the /status chatcommand.
function CC.get_players_in_overlapping_channels(ichan, only_writable)
	local all_players = minetest.get_connected_players()

	local overlapping_players = {}

	for k, v in ipairs(all_players) do
		local ochan = CC.get_player_enabled_channels(v:get_player_name(), only_writable)
		if channels_intersect(ichan, ochan) then
			table.insert(overlapping_players, v)
		end
	end

	return overlapping_players
end



-- Use this only to send server messages to all players in a channel.
-- NOT intended for player-to-player chat.
function CC.notify_channels_system_message(channels, message)
	local players = minetest.get_connected_players()

	-- Send message to all players in the same channel.
	for _, v in ipairs(players) do
		local pname = v:get_player_name()
		local arraylist = CC.get_player_enabled_channels(pname)
		if channels_intersect(arraylist, channels) then
			minetest.chat_send_player(pname, message)
		end
	end
end



-- Unconditionally cause the player to join a channel.
-- E.g., this is called to add a player to a channel when game conditions are met.
-- Don't call this from outside directly.
function CC.do_join_channel(pname, channel_name)
	local cinfo = CC.get_channel_info_load_if_needed(channel_name)
	local pinfo = CC.get_player_info_read_or_default(pname)

	local already_joined = false
	if pinfo.joined_sanctums[channel_name] then
		already_joined = true
	end

	CC.add_sanctum_to_pinfo_table(cinfo, pinfo)
	CC.save_pinfo_to_player_meta(pname, nil, pinfo)

	CC.PLAYERS[pname] = pinfo

	if not already_joined then
		CC.run_callbacks("player_join_channel", {pname=pname, channel=channel_name})
	end
end



-- Unconditionally cause the player to leave a channel.
-- Don't call this from outside directly.
function CC.do_leave_channel(pname, channel_name)
	local cinfo = CC.get_channel_info_load_if_needed(channel_name)
	local pinfo = CC.get_player_info_read_or_default(pname)

	local already_left = false
	if not pinfo.joined_sanctums[channel_name] then
		already_left = true
	end

	CC.remove_sanctum_from_pinfo_table(cinfo, pinfo)
	CC.save_pinfo_to_player_meta(pname, nil, pinfo)

	CC.PLAYERS[pname] = pinfo

	if not already_left then
		CC.run_callbacks("player_leave_channel", {pname=pname, channel=channel_name})
	end
end



-- Unconditionally enable player's X-speak for a channel.
function CC.do_enable_player_xspeak(pname, cname)
	local pinfo = CC.get_player_info_read_or_default(pname)

	pinfo.xspeak_channels[cname] = true
	CC.save_pinfo_to_player_meta(pname, nil, pinfo)

	CC.PLAYERS[pname] = pinfo
end



-- Unconditionally disable player's X-speak for a channel.
function CC.do_disable_player_xspeak(pname, cname)
	local pinfo = CC.get_player_info_read_or_default(pname)

	pinfo.xspeak_channels[cname] = nil
	CC.save_pinfo_to_player_meta(pname, nil, pinfo)

	CC.PLAYERS[pname] = pinfo
end



-- Called when player uses their Key for the first time.
function CC.on_key_firsttime_use(pname)
	CC.do_join_channel(pname, "citizens")
	CC.do_join_channel(pname, "global")
	CC.do_leave_channel(pname, "newbies")
end



-- Called when player uses their PoC for the first time.
function CC.on_poc_firsttime_use(pname)
	CC.do_join_channel(pname, "global")
end



-- Called when player returns to the outback somehow.
function CC.on_return_to_outback(pname)
	CC.do_join_channel(pname, "newbies")
end



-- Callback function. Runs from callback system.
function CC.on_player_join_channel(params)
	if gdac.player_is_admin(params.pname) then
		return
	end

	local cinfo = CC.get_channel_info_load_if_needed(params.channel)
	if not cinfo then
		return
	end

	if not cinfo.no_player_chat then -- Don't announce on readonly channels.
		local msg = "# Server: <" .. rename.gpn(params.pname) .. "> has joined channel: {" .. params.channel .. "}."
		CC.notify_channels_system_message({[1]=params.channel}, msg)
	end
end



-- Callback function. Runs from callback system.
function CC.on_player_leave_channel(params)
	if gdac.player_is_admin(params.pname) then
		return
	end

	local cinfo = CC.get_channel_info_load_if_needed(params.channel)
	if not cinfo then
		return
	end

	if not cinfo.no_player_chat then -- Don't announce on readonly channels.
		local msg = "# Server: <" .. rename.gpn(params.pname) .. "> has left channel: {" .. params.channel .. "}."
		CC.notify_channels_system_message({[1]=params.channel}, msg)
		system_response(pname, "You have left channel {" .. params.channel .. "}.")
	end
end



function CC.on_channel_deleted(params)
	local players = minetest.get_connected_players()
	for _, pref in ipairs(players) do
		local pname = pref:get_player_name()
		local pinfo = CC.get_player_info_read_or_default(pname, pref)

		if pinfo.joined_sanctums[params.channel] then
			system_response(pname, "Channel {" .. params.channel .. "} was deleted while you were part of it.")
			system_response(pname, "You are no longer a member of {" .. params.channel .. "}.")

			pinfo.joined_sanctums[params.channel] = nil
			pinfo.sanctum_passwords[params.channel] = nil
			pinfo.xspeak_channels[params.channel] = nil
			CC.save_pinfo_to_player_meta(pname, pref, pinfo)
			CC.PLAYERS[pname] = pinfo
		end
	end
end



if not CC.run_once then
	CC.PLAYERS = {} -- Player names as keys. Contains subtables.
	CC.ACTIVE_CHANNELS = {} -- Array of subtables.
	CC.SYSTEM_CHANNELS = {} -- Set of channel names.
	CC.MOD_STORAGE = minetest.get_mod_storage()
	CC.CALLBACKS = {} -- Callbacks. Indexed array of subtables.



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



	CC.register_callback("player_join_channel", function(...)
		CC.on_player_join_channel(...)
	end)

	CC.register_callback("player_leave_channel", function(...)
		CC.on_player_leave_channel(...)
	end)

	CC.register_callback("on_channel_deleted", function(...)
		CC.on_channel_deleted(...)
	end)



	local c = "chat_channels:core"
	local f = CC.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	CC.run_once = true
end

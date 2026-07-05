
shout.players = shout.players or {}

local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")
local TEAM_COLOR = core.get_color_escape_sequence("#a8ff00")
local WHITE = core.get_color_escape_sequence("#ffffff")

local BUILTIN_ESSENTIAL_CHANNELS = {
	{name="global", public_chatlog=true, need_shout_priv=true, anticurse=true, enable_gag=true},
	{name="newbies", public_chatlog=true, need_shout_priv=true, anticurse=true, enable_gag=true},
	{name="citizens", enable_gag=true},
	{name="announce", no_player_chat=true},
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



-- Get player's current "in-memory" channel names (as an array), or nil.
function shout.get_player_channels(pname)
	if shout.players[pname] and #shout.players[pname] > 0 then
		return shout.players[pname]
	end
end



function shout.get_channel_info(channelname)
	for _, v in ipairs(BUILTIN_ESSENTIAL_CHANNELS) do
		if v.name == channelname then
			return v
		end
	end

	-- Otherwise return default information.
	return {name=channelname}
end



-- Get an array list of all players in a list of channels.
function shout.get_players_in_channels(channels)
	local players = minetest.get_connected_players()
	local result = {}
	for k, v in ipairs(players) do
		local pname = v:get_player_name()
		local arraylist = shout.get_player_channels(pname)
		if arraylist then
			if channels_intersect(arraylist, channels) then
				result[#result+1] = pname
			end
		end
	end
	return result
end



-- Use this only to send server messages to all players in a channel.
function shout.notify_channel(channel, message)
	local players = minetest.get_connected_players()

	-- Send message to all players in the same channel.
	for _, v in ipairs(players) do
		local pname = v:get_player_name()
		local arraylist = shout.get_player_channels(pname)
		if arraylist then
			for _, arrayentry in ipairs(arraylist) do
				if arrayentry == channel then
					minetest.chat_send_player(pname, message)
					break
				end
			end
		end
	end
end



-- let player join, leave channels
function shout.channel_on_chatcommand(pname, cmdparams)
	cmdparams = string.trim(cmdparams)

	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	local tokens = string.split(cmdparams, " ")
	local join_or_leave = tokens[1]
	local channel_name = tokens[2]

	if #tokens == 0 then
		shout.show_channel_status(pname)
		return
	end

	if not passport.player_has_key(pname) then
		minetest.chat_send_player(pname, "# Server: Joining or leaving channels requires a Key of Citizenship.")
		return
	end

	if not (#tokens == 2 and join_or_leave and channel_name and channel_name:len() > 0) then
		minetest.chat_send_player(pname, "# Server: Invalid command syntax.")
		return
	end

	if not (join_or_leave == "join" or join_or_leave == "leave") then
		minetest.chat_send_player(pname, "# Server: Unrecognized verb.")
		return
	end

	-- Require channel names to match specific format.
	if not string.find(channel_name, "^[,_%w]+$") then
		minetest.chat_send_player(pname,
			"# Server: Only alphanumeric characters and underscores may be used in channel names.")
		easyvend.sound_error(pname)
		return
	end

	local boolean_joinleave = true
	if join_or_leave == "leave" then
		boolean_joinleave = false
	end

	local channelnames = channel_name:split(",")
	for _, v in ipairs(channelnames) do
		shout.channel_handle_joinleave(pname, v, boolean_joinleave, false)
	end

	shout.show_channel_status(pname)
end



function shout.channel_handle_joinleave(pname, channel_name, is_join, is_server_action)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then return end

	local pmeta = player:get_meta()
	local channel_data = pmeta:get_string("active_channel")
	local channel_array = minetest.deserialize(channel_data)

	if not (type(channel_array) == "table" and #channel_array > 0) then
		channel_array = {}
	end

	-- Convert to dict for easier logic.
	local channel_dict = {}
	for _, v in ipairs(channel_array) do
		channel_dict[v] = true
	end

	local is_changed = false

	if is_join then
		if not channel_dict[channel_name] then
			channel_dict[channel_name] = true
			is_changed = true
		end
	else
		if channel_dict[channel_name] then
			channel_dict[channel_name] = nil
			is_changed = true
		end
	end

	-- Convert back to array.
	channel_array = {}
	for k, _ in pairs(channel_dict) do
		channel_array[#channel_array + 1] = k
	end

	-- Error if too many entries.
	if #channel_array > 16 then
		minetest.chat_send_player(pname, "# Server: Cannot join too many channels!")
		easyvend.sound_error(pname)
		return
	end

	-- Persist.
	if is_changed then
		shout.players[pname] = channel_array
		player:get_meta():set_string("active_channel", minetest.serialize(channel_array))
	end

	-- Report status.
	if is_changed then
		if is_join then
			minetest.chat_send_player(pname, "# Server: You have joined channel '" .. channel_name .. "'.")
		else
			minetest.chat_send_player(pname, "# Server: You have left channel '" .. channel_name .. "'.")
		end
	else
		-- If we get here, nothing changed.
		if not is_server_action then
			if is_join then
				minetest.chat_send_player(pname, "# Server: You are already in channel '" .. channel_name .. "'.")
			else
				minetest.chat_send_player(pname, "# Server: You were not in channel '" .. channel_name .. "'.")
			end
		end
	end
end



-- let player put a message onto a channel
-- this is called when player chats, always
function shout.x(pname, param)
	if not shout.get_player_channels(pname) then
		minetest.chat_send_player(pname, "# Server: No open communication channels.")
		easyvend.sound_error(pname)
		return
	end

	if #param < 1 then
		minetest.chat_send_player(pname, "# Server: Empty message.")
		easyvend.sound_error(pname)
		return
	end

	-- Allow player to use channel speak even while gagged.
	-- Rational: if the gagged player is on a channel with others,
	-- then probably they're in a group together, or are related.
	-- Chat between such shouldn't be blocked.
	--[[
	if command_tokens.mute.player_muted(pname) then
		minetest.chat_send_player(pname, "# Server: You cannot talk while gagged!")
		easyvend.sound_error(pname)
		return
	end
	--]]

	local log_public_chat = false
	local do_anticurse_check = false
	local requires_shout_priv = false
	local need_gag_check = false

	local channels = shout.get_player_channels(pname)
	local themarkofcain = chat_core.generate_coord_string(pname)
	local connected_players = minetest.get_connected_players()

	local receiving_players = {}

	-- Check if user is in any channels requiring special privs.
	for _, cname in ipairs(channels) do
		local cinfo = shout.get_channel_info(cname)

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
		if cinfo.enable_gag then
			need_gag_check = true
		end
	end

	-- Global chat requires 'shout' priv.
	if requires_shout_priv then
		if not minetest.check_player_privs(pname, {shout=true}) then
			minetest.chat_send_player(pname, "# Server: You are in a channel requiring the 'shout' priv.")
			-- Player doesn't have shout priv.
			return
		end
	end

	if need_gag_check then
		if command_tokens.mute.player_muted(pname) then
			minetest.chat_send_player(pname, "# Server: You are currently gagged.")
			-- Player is muted.
			return
		end
	end

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	if do_anticurse_check then
		-- If this succeeds player was kicked or muted or something.
		if chat_core.check_language(pname, param) then return end
	end

	--if chat_core.check_language(pname, param, channels) then return end

	-- Send message to all players in the same channel.
	-- The player who sent the message always receives it.
	for _, v in ipairs(connected_players) do
		local to_pname = v:get_player_name()
		local to_channels = shout.get_player_channels(to_pname)

		if to_channels then
			if channels_intersect(to_channels, channels) then
				receiving_players[#receiving_players + 1] = v
			end
		end
	end

	-- Handles chat filters, colorization, distance, etc.
	chat_core.send_all_ex({
		from = pname,
		prename = "<!",
		actname = rename.gpn(pname),
		postname = themarkofcain .. "!> ",
		message = param,
		alwaysecho = false,
		allplayers = receiving_players
	})

	-- Log, if player is in a public channel.
	if log_public_chat then
		chat_logging.log_public_chat(pname, param, themarkofcain)
	end

	-- Prevent temptation >:D
	--minetest.chat_send_all(SHOUT_COLOR .. "<!" .. dname .. mk .. "!> " .. param)
	--chat_logging.log_public_shout(pname, param, shout.channelmk)
	--chat_logging.log_team_chat(pname, stats, param, channels)

	player_labels.on_chat_message(pname, param)
	afk.reset_timeout(pname)
end



-- Join channel on login.
function shout.channel_on_joinplayer(player)
	local pname = player:get_player_name()
	--if not shout.get_player_channels(pname) then
	--	minetest.after(0, function()
	--local pref = minetest.get_player_by_name(pname)
	--if not pref then return end

	local data = player:get_meta():get_string("active_channel")
	if data and data ~= "" then
		local arraylist = minetest.deserialize(data)
		if type(arraylist) == "table" and #arraylist > 0 then
			shout.players[pname] = arraylist
			-- No need to announce.
			--[[
			for _, arrayentry in ipairs(arraylist) do
				shout.channel_do_joinleave(pname, arrayentry, true, false, true)
			end
			--]]
		end
	end

	-- Set up first-time channels.
	if not data or data == "" then
		shout.channel_handle_joinleave(pname, "global", true, true)
		shout.channel_handle_joinleave(pname, "announce", true, true)

		if passport.player_has_key(pname) then
			shout.channel_handle_joinleave(pname, "citizens", true, true)
		else
			shout.channel_handle_joinleave(pname, "newbies", true, true)
		end
	end
	--	end)
	--end
end



-- Leave channel on logout.
function shout.channel_on_leaveplayer(player)
	local pname = player:get_player_name()
	-- No need to announce.
	--[[
	local arraylist = shout.get_player_channels(pname)
	if arraylist then
		for _, arrayentry in ipairs(arraylist) do
			shout.channel_do_joinleave(pname, arrayentry, false)
		end
	end
	--]]
	shout.players[pname] = nil
end



--[[
function shout.xinvert(pname, param)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then return end

	local status = player:get_meta():get_int("xinvert")
	if status == 0 then
		status = 1
		minetest.chat_send_player(pname, "# Server: All chat messages restricted to channels.")
	else
		status = 0
		minetest.chat_send_player(pname, "# Server: Global chat restored.")
	end
	player:get_meta():set_int("xinvert", status)
end
--]]



function shout.show_channel_status(pname)
	local channels = shout.get_player_channels(pname)
	if not channels or #channels == 0 then
		minetest.chat_send_player(pname, "# Server: You are not subscribed to any channels.")
		return
	end
	local count = #channels
	local list = table.concat(channels, ", ")
	minetest.chat_send_player(pname, "# Server: You are in channels (" .. count .. "): {" .. list .. "}.")
end


shout.players = shout.players or {}

local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")
local TEAM_COLOR = core.get_color_escape_sequence("#a8ff00")
local WHITE = core.get_color_escape_sequence("#ffffff")



-- Get player's current "in-memory" channel name, or nil.
function shout.player_channel(pname)
	if shout.players[pname] and shout.players[pname] ~= "" then
		return shout.players[pname]
	end
end



-- Get list of all players in a channel.
function shout.channel_players(channel)
	local players = minetest.get_connected_players()
	local result = {}
	for k, v in ipairs(players) do
		local n = v:get_player_name()
		if shout.players[n] and shout.players[n] == channel then
			result[#result+1] = n
		end
	end
	return result
end



-- Use this only to send server messages to all players in a channel.
-- This bypasses players' chat filters.
function shout.notify_channel(channel, message)
	local players = minetest.get_connected_players()

	-- Send message to all players in the same channel.
	for k, v in ipairs(players) do
		local n = v:get_player_name()
		if shout.players[n] and shout.players[n] == channel then
			minetest.chat_send_player(n, TEAM_COLOR .. message)
		end
	end
end



-- let player join, leave channels
function shout.channel(name, param, on_join, on_leave)
	param = string.trim(param)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	if shout.players[name] and shout.players[name] ~= "" and param ~= shout.players[name] then
		shout.notify_channel(shout.players[name],
			"# Server: User <" .. rename.gpn(name) .. "> has left channel '" ..
			shout.players[name] .. "'.")
	end

	if param == "" then
		if not on_join then
			if shout.players[name] then
				minetest.chat_send_player(name, "# Server: Channel cleared.")
			else
				minetest.chat_send_player(name, "# Server: Not on any channel.")
			end
		end

		shout.players[name] = nil
		if not on_leave then
			player:get_meta():set_string("active_channel", "")
		end
		return
	end

	if not on_join then
		if shout.players[name] and shout.players[name] == param then
			minetest.chat_send_player(name,
				"# Server: Already on channel '" .. param .. "'.")
			return
		end
	end

	-- Require channel names to match specific format.
	if not string.find(param, "^[_%w]+$") then
		minetest.chat_send_player(name,
			"# Server: Invalid channel name! Use only alphanumeric characters and underscores.")
		easyvend.sound_error(name)
		return
	end

	-- Only print this if called by explicit chatcommand.
	if not on_join then
		minetest.chat_send_player(name, "# Server: Chat channel set to '" .. param .. "'.")
	end

	shout.players[name] = param
	player:get_meta():set_string("active_channel", param)
	shout.notify_channel(shout.players[name],
		"# Server: User <" .. rename.gpn(name) .. "> has joined channel '" ..
		shout.players[name] .. "'.")
end



-- let player put a message onto a channel
function shout.x(name, param)
	param = string.trim(param)
	if not shout.players[name] then
		minetest.chat_send_player(name, "# Server: You have not specified a channel.")
		easyvend.sound_error(name)
		return
	end

	if #param < 1 then
		minetest.chat_send_player(name, "# Server: No message specified.")
		easyvend.sound_error(name)
		return
	end

	-- Allow player to use channel speak even while gagged.
	-- Rational: if the gagged player is on a channel with others,
	-- then probably they're in a group together, or are related.
	-- Chat between such shouldn't be blocked.
	--[[
	if command_tokens.mute.player_muted(name) then
		minetest.chat_send_player(name, "# Server: You cannot talk while gagged!")
		easyvend.sound_error(name)
		return
	end
	--]]

	local stats = chat_core.player_status(name)
	local dname = rename.gpn(name)
	local channel = shout.players[name]
	local players = minetest.get_connected_players()

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	if chat_core.check_language(name, param, channel) then return end

	local mk = chat_core.generate_coord_string(name)

	-- Send message to all players in the same channel.
	-- The player who sent the message always receives it.
	for k, v in ipairs(players) do
		local n = v:get_player_name()
		if shout.players[n] and shout.players[n] == channel then
			local ignored = false

			-- Don't send teamchat if player is ignored.
			if chat_controls.player_ignored(n, name) then
				ignored = true
			end

			if not ignored then
				minetest.chat_send_player(n, stats .. "<!" .. chat_core.nametag_color .. rename.gpn(name) .. WHITE .. mk .. "!> " .. TEAM_COLOR .. param)
			end
		end
	end

	--minetest.chat_send_all(SHOUT_COLOR .. "<!" .. dname .. mk .. "!> " .. param)
	--chat_logging.log_public_shout(name, param, shout.channelmk)

	chat_logging.log_team_chat(name, stats, param, channel)
	afk.reset_timeout(name)
end



-- Join channel on login, if no channel currently set.
function shout.join_channel(player)
	local pname = player:get_player_name()
	if not shout.player_channel(pname) then
		local channel = player:get_meta():get_string("active_channel")
		if channel and channel ~= "" then
			minetest.after(0, function() shout.channel(pname, channel, true) end)
		end
	end
end



-- Leave channel on logout, if a channel is currently set.
function shout.leave_channel(player)
	local pname = player:get_player_name()
	local curchan = shout.player_channel(pname)
	if curchan and curchan ~= "" then
		shout.channel(pname, "", false, true)
	end
end

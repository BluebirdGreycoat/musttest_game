
shout.players = shout.players or {}

local SHOUT_COLOR = core.get_color_escape_sequence("#ff2a00")
local TEAM_COLOR = core.get_color_escape_sequence("#a8ff00")
local WHITE = core.get_color_escape_sequence("#ffffff")



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
function shout.player_channel(pname)
	if shout.players[pname] and #shout.players[pname] > 0 then
		return shout.players[pname]
	end
end



-- Get an array list of all players in a list of channels.
function shout.channel_players(channels)
	local players = minetest.get_connected_players()
	local result = {}
	for k, v in ipairs(players) do
		local pname = v:get_player_name()
		local arraylist = shout.player_channel(pname)
		if arraylist then
			if channels_intersect(arraylist, channels) then
				result[#result+1] = pname
			end
		end
	end
	return result
end



-- Use this only to send server messages to all players in a channel.
-- This bypasses players' chat filters.
function shout.notify_channel(channel, message)
	local players = minetest.get_connected_players()

	-- Send message to all players in the same channel.
	for _, v in ipairs(players) do
		local pname = v:get_player_name()
		local arraylist = shout.player_channel(pname)
		if arraylist then
			for _, arrayentry in ipairs(arraylist) do
				if arrayentry == channel then
					minetest.chat_send_player(pname, TEAM_COLOR .. message)
					break
				end
			end
		end
	end
end



-- let player join, leave channels
function shout.channel_command(pname, cmdparams)
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

	if not (#tokens == 2 and join_or_leave and channel_name and channel_name:len() > 0) then
		minetest.chat_send_player(pname, "# Server: Invalid command syntax.")
		return
	end

	if not (join_or_leave == "join" or join_or_leave == "leave") then
		minetest.chat_send_player(pname, "# Server: Unrecognized verb.")
		return
	end

	-- Require channel names to match specific format.
	if not string.find(channel_name, "^[_%w]+$") then
		minetest.chat_send_player(pname,
			"# Server: Only alphanumeric characters and underscores may be used in channel names.")
		easyvend.sound_error(pname)
		return
	end

	local boolean_joinleave = true
	if join_or_leave == "leave" then
		boolean_joinleave = false
	end

	shout.channel_do_joinleave(pname, channel_name, boolean_joinleave, true)
end



function shout.channel_do_joinleave(pname, channel_name, is_join, is_chatcommand, always_report)
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

	-- Persist.
	if is_chatcommand and is_changed then
		shout.players[pname] = channel_array
		player:get_meta():set_string("active_channel", minetest.serialize(channel_array))
	end

	-- Report status.
	if is_changed or always_report then
		local join_str = "joined"
		if not is_join then join_str = "left" end

		shout.notify_channel(channel_name, "# Server: <" .. rename.gpn(pname) ..
			"> has " .. join_str .. " channel '" .. channel_name .. "'.")

		if is_chatcommand and not is_join then
			minetest.chat_send_player(pname, "# Server: You have left channel '" .. channel_name .. "'.")
		end
	elseif not is_changed and is_chatcommand then
		-- If we get here, nothing changed.
		if is_join then
			minetest.chat_send_player(pname, "# Server: You are already in channel '" .. channel_name .. "'.")
		else
			minetest.chat_send_player(pname, "# Server: You were not in channel '" .. channel_name .. "'.")
		end
	end
end



-- let player put a message onto a channel
function shout.x(pname, param)
	param = string.trim(param)
	if not shout.player_channel(pname) then
		minetest.chat_send_player(pname, "# Server: No open communication channels.")
		easyvend.sound_error(pname)
		return
	end

	if #param < 1 then
		minetest.chat_send_player(pname, "# Server: No message.")
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

	local stats = chat_core.player_status(pname)
	local dname = rename.gpn(pname)
	local channels = shout.player_channel(pname)
	local players = minetest.get_connected_players()

	-- If this succeeds, the player was either kicked, or muted and a message about that sent to everyone else.
	-- No need to be a Karen over speech since it's not in the public chatlog.
	--if chat_core.check_language(pname, param, channels) then return end

	local mk = chat_core.generate_coord_string(pname)

	local allplayers = {}

	-- Send message to all players in the same channel.
	-- The player who sent the message always receives it.
	for _, v in ipairs(players) do
		local to_pname = v:get_player_name()
		local to_channels = shout.player_channel(to_pname)

		if to_channels then
			if channels_intersect(to_channels, channels) then
				allplayers[#allplayers + 1] = v
			end
		end
	end

	-- Handles chat filters, colorization, distance, etc.
	chat_core.send_all_ex(pname, stats .. "<!", rename.gpn(pname), mk .. "!> ", param, false, allplayers)

	-- Prevent temptation >:D
	--minetest.chat_send_all(SHOUT_COLOR .. "<!" .. dname .. mk .. "!> " .. param)
	--chat_logging.log_public_shout(pname, param, shout.channelmk)
	--chat_logging.log_team_chat(pname, stats, param, channels)

	afk.reset_timeout(pname)
end



-- Join channel on login.
function shout.join_channel(player)
	local pname = player:get_player_name()
	if not shout.player_channel(pname) then
		minetest.after(0, function()
			local pref = minetest.get_player_by_name(pname)
			if not pref then return end

			local data = pref:get_meta():get_string("active_channel")
			if data and data ~= "" then
				local arraylist = minetest.deserialize(data)
				if type(arraylist) == "table" and #arraylist > 0 then
					shout.players[pname] = arraylist
					for _, arrayentry in ipairs(arraylist) do
						shout.channel_do_joinleave(pname, arrayentry, true, false, true)
					end
				end
			end
		end)
	end
end



-- Leave channel on logout.
function shout.leave_channel(player)
	local pname = player:get_player_name()
	local arraylist = shout.player_channel(pname)
	if arraylist then
		for _, arrayentry in ipairs(arraylist) do
			shout.channel_do_joinleave(pname, arrayentry, false)
		end
	end
	shout.players[pname] = nil
end



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



function shout.show_channel_status(pname)
	local channels = shout.player_channel(pname)
	local count = #channels
	local list = table.concat(channels, ", ")
	minetest.chat_send_player(pname, "# Server: You are in channels (" .. count .. "): {" .. list .. "}.")
end

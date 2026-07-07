
-- Expected to return an array table.
function shout.get_x_channels(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then return {} end

	local data = pref:get_meta():get_string("active_xchannel")
	local channels = minetest.deserialize(data)

	if type(channels) == "table" then
		return channels
	end

	return {}
end



function shout.x_invert(pname, param)
	local response = minetest.chat_send_player
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then return end

	local status = player:get_meta():get_int("xinvert")
	if status == 0 then
		status = 1
		local rooms = shout.get_x_channels(pname)
		response(pname, "# Server: Outgoing chat restricted to group DM rooms.")
		response(pname, "# Server: You are currently speaking in rooms (" .. #rooms .. "): {" .. table.concat(rooms, ", ") .. "}.")
	else
		status = 0
		response(pname, "# Server: Normal chat restored.")
		shout.show_channel_status(pname)
	end
	player:get_meta():set_int("xinvert", status)
end



-- Called when player uses chat command to put a message into a specific (previously chosen) channel.
function shout.x_specific(pname, param)
	local response = minetest.chat_send_player
	local player_channels = shout.get_x_channels(pname)
	if #player_channels == 0 then
		response(pname, "# Server: You are not part of any group DM rooms. There's nowhere to speak!")
		easyvend.sound_error(pname)
		return
	end

	if #param < 1 then
		response(pname, "# Server: Empty message.")
		easyvend.sound_error(pname)
		return
	end

	shout.x2(pname, param, player_channels)
end



function shout.x_choose(pname, param)
	local response = minetest.chat_send_player
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		response(pname, "# Server: You failed the existence test.")
		easyvend.sound_error(pname)
		return
	end

	local tokens = param:split(" ")
	if #tokens ~= 2 then
		response(pname, "# Server: Invalid command invocation.")
		easyvend.sound_error(pname)
		return
	end

	local addremove = tokens[1]
	local channelstring = tokens[2]

	local command_verbs = {
		enter = "add",
		add = "add",
		join = "add",
		enable = "add",
		remove = "remove",
		part = "remove",
		disable = "remove",
		leave = "remove",
	}

	if not command_verbs[addremove] then
		response(pname, "# Server: Unrecognized verb.")
		easyvend.sound_error(pname)
		return
	end

	local channels = channelstring:split(",")
	for k, v in ipairs(channels) do
		if not v:find("^[,_%w]+$") then
			report("# Server: Only alphanumeric characters and underscores may be used in channel names.")
			easyvend.sound_error(pname)
			return
		end
	end

	local curdata = pref:get_meta():get_string("active_xchannel")
	local curchan = minetest.deserialize(curdata) or {} -- Array table, always.
	local changed_ones = {}

	for k, v in ipairs(channels) do
		if command_verbs[addremove] == "remove" then
			-- Removing channels.
			local index = table.keyof(curchan, v)
			if index then
				table.insert(changed_ones, v)
				table.remove(curchan, index)
			end
		else
			-- Adding channels.
			local index = table.keyof(curchan, v)
			if not index then
				table.insert(changed_ones, v)
				table.insert(curchan, v)
			end
		end
	end

	pref:get_meta():set_string("active_xchannel", minetest.serialize(curchan))

	local verb = "added"
	if command_verbs[addremove] == "remove" then verb = "removed" end
	response("# Server: You have " .. verb .. " group DM rooms (" .. #changed_ones .. "): {" .. table.concat(changed_ones, ", ") .. "}.")
end

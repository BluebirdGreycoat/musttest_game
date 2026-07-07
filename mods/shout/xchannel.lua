
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
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then return end

	local status = player:get_meta():get_int("xinvert")
	if status == 0 then
		status = 1
		local rooms = shout.get_x_channels(pname)
		minetest.chat_send_player(pname, "# Server: Outgoing chat restricted to group DM rooms.")
		minetest.chat_send_player(pname, "# Server: You are currently speaking in rooms (" .. #rooms .. "): {" .. table.concat(rooms, ", ") .. "}.")
	else
		status = 0
		minetest.chat_send_player(pname, "# Server: Normal chat restored.")
		shout.show_channel_status(pname)
	end
	player:get_meta():set_int("xinvert", status)
end



-- Called when player uses chat command to put a message into a specific (previously chosen) channel.
function shout.x_specific(pname, param)
	local player_channels = shout.strip_readonly_channels(shout.get_x_channels(pname))
	if #player_channels == 0 then
		minetest.chat_send_player(pname, "# Server: You are not part of any group DM rooms. There's nowhere to speak!")
		easyvend.sound_error(pname)
		return
	end

	if #param < 1 then
		minetest.chat_send_player(pname, "# Server: Empty message.")
		easyvend.sound_error(pname)
		return
	end

	shout.x2(pname, param, player_channels)
end

function shout.x_choose(pname, param)
end


-- Private mod storage is fundamentally incompatible with mod reloadability.
shout.MODSTORAGE = shout.MODSTORAGE or minetest.get_mod_storage()



function shout.create_channel(pname, param)
	local user = minetest.get_player_by_name(pname)
	if not user or not user:is_player() then
		minetest.chat_send_player(pname, "# Server: You failed the existence check.")
		easyvend.sound_error(pname)
		return
	end

	if not passport.player_has_key(pname) then
		minetest.chat_send_player(pname, "# Server: You must have a Key of Citizenship to create channels.")
		easyvend.sound_error(pname)
		return
	end

	local tokens = param:split(" ")
	if #tokens ~= 2 then
		minetest.chat_send_player(pname, "# Server: Invalid command invocation.")
		easyvend.sound_error(pname)
		return
	end

	local channel_name = tokens[1]
	local channel_password = tokens[2]

	if not string.find(channel_name, "^[,_%w]+$") then
		minetest.chat_send_player(pname, "# Server: Invalid channel name. (Only alphanumeric characters and underscores may be used.)")
		easyvend.sound_error(pname)
		return
	end

	if not string.find(channel_password, "^[,_%w]+$") then
		minetest.chat_send_player(pname, "# Server: Invalid password. (Only alphanumeric characters and underscores may be used.)")
		easyvend.sound_error(pname)
		return
	end

	local old_channel_info = shout.get_channel_info(channel_name)

	if shout.MODSTORAGE:contains(channel_name) or old_channel_info.is_system then
		minetest.chat_send_player(pname, "# Server: Channel already exists.")
		easyvend.sound_error(pname)
		return
	end

	local new_channel_info = {
		name = channel_name,
		owner = pname,
		time = os.time(),
		password = channel_password,
	}

	shout.MODSTORAGE:set_string(channel_name, minetest.serialize(new_channel_info))
	minetest.chat_send_player(pname, "# Server: Created channel '" .. channel_name .. "' owned by you.")
end



function shout.delete_channel(pname, param)
	local user = minetest.get_player_by_name(pname)
	if not user or not user:is_player() then
		minetest.chat_send_player(pname, "# Server: You failed the existence check.")
		easyvend.sound_error(pname)
		return
	end

	if not passport.player_has_key(pname) then
		minetest.chat_send_player(pname, "# Server: You must have a Key of Citizenship to delete channels.")
		easyvend.sound_error(pname)
		return
	end

	local channel_name = param

	if not string.find(channel_name, "^[,_%w]+$") then
		minetest.chat_send_player(pname, "# Server: Invalid channel name. (Only alphanumeric characters and underscores may be used.)")
		easyvend.sound_error(pname)
		return
	end

	local old_channel_info = shout.get_channel_info(channel_name)

	if old_channel_info.is_system then
		minetest.chat_send_player(pname, "# Server: That is a system channel. Cannot delete.")
		easyvend.sound_error(pname)
		return
	end

	if not shout.MODSTORAGE:contains(channel_name) then
		minetest.chat_send_player(pname, "# Server: Channel does not exist, or is ephemeral.")
		easyvend.sound_error(pname)
		return
	end

	if not old_channel_info.owner or old_channel_info.owner ~= pname then
		minetest.chat_send_player(pname, "# Server: You are not the owner of the channel.")
		easyvend.sound_error(pname)
		return
	end

	shout.MODSTORAGE:set_string(channel_name, nil)
	minetest.chat_send_player(pname, "# Server: Deleted channel '" .. channel_name .. "'.")
end

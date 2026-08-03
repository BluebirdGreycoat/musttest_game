
function camc.snap_to(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local pcam = minetest.get_player_by_name("Hawkeye")
	if not pcam then
		return
	end
	if not camc.player_is_camera(pcam) then
		return
	end

	local to_pos = pref:get_pos()

	rc.notify_realm_update(pcam, to_pos)

	pcam:set_pos(to_pos)
	pcam:set_look_horizontal(pref:get_look_horizontal())
	pcam:set_look_vertical(pref:get_look_vertical())

	return true
end

-- Send server response to specific player and play error sound.
function camc.system_error(pname, errmsg)
	minetest.chat_send_player(pname, "# Server: " .. errmsg)
	easyvend.sound_error(pname)
end

function camc.system_response(pname, message)
	minetest.chat_send_player(pname, "# Server: " .. message)
end

function camc.check_player_existence(pname)
	return minetest.get_player_by_name(pname)
end

function camc.get_pref_complain_if_inexistent(pname)
	local pref = camc.check_player_existence(pname)
	if not pref then
		camc.system_response(pname, "You failed the existence test.")
	end
	return pref
end

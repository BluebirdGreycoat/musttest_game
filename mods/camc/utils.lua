
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

local function calc_look_at(player_pos, _player_yaw, _player_pitch)
	-- Place the camera some distance away, slightly above the player,
	-- at a random angle around them, and compute yaw/pitch so it looks
	-- directly at the player (downward).

	local distance = 9     -- horizontal distance from player
	local height   = 3.5   -- how far above the player

	local angle = math.random() * math.pi * 2

	local offset = vector.new(
		math.cos(angle) * distance,
		height,
		math.sin(angle) * distance
	)

	local cam_pos = vector.add(player_pos, offset)

	-- Direction from camera to player (normalized)
	local dir = vector.direction(cam_pos, player_pos)

	local yaw   = minetest.dir_to_yaw(dir)
	local pitch = math.asin(-dir.y)

	return cam_pos, yaw, pitch
end

function camc.look_at(pname)
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

	local target_p = pref:get_pos()
	local yaw = pref:get_look_horizontal()
	local pitch = pref:get_look_vertical()
	local cam_pos = vector.copy(target_p)

	cam_pos, yaw, pitch = calc_look_at(target_p, yaw, pitch)

	rc.notify_realm_update(pcam, cam_pos)
	pcam:set_pos(cam_pos)
	pcam:set_look_horizontal(yaw)
	pcam:set_look_vertical(pitch)

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

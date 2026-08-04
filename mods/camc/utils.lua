
function camc.snap_to(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
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

local function calc_look_at(player_pos, randomize)
	-- Place the camera some distance away, slightly above the player,
	-- at a random angle around them, and compute yaw/pitch so it looks
	-- directly at the player (downward).

	local distance = 9     -- horizontal distance from player
	local height   = 3.5   -- how far above the player

	if randomize then
		distance = math.random(2, 10)
		height = math.random(-5, 5)
	end

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

function camc.look_at(target)
	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		return
	end
	if not camc.player_is_camera(pcam) then
		return
	end

	local target_p
	if type(target) == "string" then
		local pref = minetest.get_player_by_name(target)
		if not pref then
			return
		end
		target_p = pref:get_pos()
	elseif type(target) == "table" and target.x and target.y and target.z then
		target_p = target
	elseif type(target) == "userdata" then
		target_p = target:get_pos()
	end
	if not target_p then
		return
	end

	local cam_pos, yaw, pitch = calc_look_at(target_p)

	local function head_pos(cam_pos)
		return vector.add(cam_pos, {x=0, y=1, z=0})
	end

	-- If camera is buried, try a few times to find a good spot.
	if minetest.get_node(head_pos(cam_pos)).name ~= "air" then
		for k = 1, camc.CAMERA_BURIED_NUM_RETRIES do
			cam_pos, yaw, pitch = calc_look_at(target_p, true)
			if minetest.get_node(head_pos(cam_pos)).name == "air" then
				break
			end
		end
	end

	if not rc.is_valid_realm_pos(cam_pos) then
		return
	end

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

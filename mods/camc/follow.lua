
camc.FOLLOW_TARGET = camc.FOLLOW_TARGET or ""

function camc.set_following(pname)
	camc.FOLLOW_TARGET = pname or ""
	if camc.FOLLOW_TARGET ~= "" then
		return camc.periodic_follow_check()
	end
end

local function calc_look_at(player_pos, cam_pos)
	-- Direction from camera to player (normalized)
	local dir = vector.direction(cam_pos, player_pos)

	local yaw   = minetest.dir_to_yaw(dir)
	local pitch = math.asin(-dir.y)

	return yaw, pitch
end

function camc.periodic_follow_check()
	local pname = camc.FOLLOW_TARGET or ""
	if pname == "" then
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref then
		camc.set_following(nil)
		return
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		camc.set_following(nil)
		return
	end
	if not camc.player_is_camera(pcam) then
		camc.set_following(nil)
		return
	end

	local player_pos = pref:get_pos()
	local cam_pos = pcam:get_pos()

	-- If player is far away, teleported, etc., just jump camera to them.
	if vector.distance(player_pos, cam_pos) > 20 then
		if not camc.look_at(pname) then
			return
		end
	else
		local yaw, pitch = calc_look_at(player_pos, cam_pos)

		pcam:set_look_horizontal(yaw)
		pcam:set_look_vertical(pitch)
	end

	minetest.after(0, camc.periodic_follow_check)
	return true
end

function camc.follow_player(pname)
	return camc.set_following(pname)
end

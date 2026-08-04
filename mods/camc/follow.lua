
camc.FOLLOW_TARGET = ""

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
		camc.FOLLOW_TARGET = ""
		return
	end

	local pcam = minetest.get_player_by_name("Hawkeye")
	if not pcam then
		camc.FOLLOW_TARGET = ""
		return
	end
	if not camc.player_is_camera(pcam) then
		camc.FOLLOW_TARGET = ""
		return
	end

	local to_pos = pref:get_pos()

	--rc.notify_realm_update(pcam, to_pos)
	--pcam:set_pos(to_pos)

	local yaw, pitch = calc_look_at(pref:get_pos(), pcam:get_pos())

	pcam:set_look_horizontal(yaw)
	pcam:set_look_vertical(pitch)

	minetest.after(0.1, camc.periodic_follow_check)

	return true
end

function camc.follow_player(pname)
	camc.set_following(pname)
end


camc.FOLLOW_TARGET = camc.FOLLOW_TARGET or ""
camc.FOLLOW_MODE = camc.FOLLOW_MODE or 0 -- Mode 1, camera is allowed to switch players.

function camc.set_following(pname, mode)
	camc.FOLLOW_TARGET = pname or ""
	camc.FOLLOW_MODE = mode or 0
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
	-- This also triggers if the followed player changes to someone else.
	if vector.distance(player_pos, cam_pos) > 20 then
		if not camc.look_at(pname) then
			camc.set_following(nil)
			return
		end
	else
		local yaw, pitch = calc_look_at(player_pos, cam_pos)

		pcam:set_look_horizontal(yaw)
		pcam:set_look_vertical(pitch)
	end

	minetest.after(0, function() camc.periodic_follow_check() end)
	return true
end

function camc.follow_player(pname)
	return camc.set_following(pname)
end

local function get_random_haunt_target()
	local players = minetest.get_connected_players()
	local valid = {}
	for _, v in ipairs(players) do
		if not gdac.player_is_admin(v) and not camc.player_is_camera(v) then
			valid[#valid + 1] = v
		end
	end
	if #valid > 0 then
		return valid[math.random(1, #valid)]:get_player_name()
	end
end

function camc.update_haunt_target()
	if camc.FOLLOW_TARGET == "" or camc.FOLLOW_MODE ~= 1 then
		return
	end

	local pname = get_random_haunt_target()
	if pname then
		camc.FOLLOW_TARGET = pname
	end

	minetest.after(camc.RANDOM_HAUNT_TIME_SECONDS, function() camc.update_haunt_target() end)
end

function camc.start_haunting()
	local pname = get_random_haunt_target()
	if pname then
		local ok = camc.set_following(pname, 1)
		minetest.after(camc.RANDOM_HAUNT_TIME_SECONDS, function() camc.update_haunt_target() end)
		return ok
	end
end


camc.FOLLOW_TARGET = camc.FOLLOW_TARGET or ""
camc.FOLLOW_MODE = camc.FOLLOW_MODE or 0 -- Mode 1, camera is allowed to switch players.

local function get_random_haunt_target()
	local players = minetest.get_connected_players()
	local valid = {}

	for _, v in ipairs(players) do
		if not gdac.player_is_admin(v) and not camc.player_is_camera(v) then
			-- AFK players are boring to look at.
			local pname = v:get_player_name()
			if afk.seconds_since_action(pname) < 60 then
				-- Ignore players with nametag off.
				if player_labels.query_nametag_onoff(pname) == true then
					valid[#valid + 1] = v
				end
			end
		end
	end

	if #valid > 0 then
		return valid[math.random(1, #valid)]:get_player_name()
	end
end

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

function camc.periodic_follow_check(params)
	if not params then
		params = {}
	end

	local delayafter = 0
	local pname = camc.FOLLOW_TARGET or ""
	if pname == "" then
		camc.set_following(nil)
		--camc.system_response("MustTest", "Target nil'ed.")
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref then
		-- Haunted player logged off.
		if camc.FOLLOW_MODE == 1 then
			local ntarget = get_random_haunt_target()
			if ntarget then
				camc.FOLLOW_TARGET = ntarget
			end
			delayafter = 10
		else
			camc.set_following(nil)
			--camc.system_response("MustTest", "Target logged off.")
			return
		end
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		camc.set_following(nil)
		--camc.system_response("MustTest", "Camera missing.")
		return
	end
	if not camc.player_is_camera(pcam) then
		camc.set_following(nil)
		--camc.system_response("MustTest", "Camera missing.")
		return
	end

	if pref then
		local player_pos = pref:get_pos()
		local cam_pos = pcam:get_pos()
		local DIST = camc.CAMERA_FOLLOW_DISTANCE

		-- If player is far away, teleported, etc., just jump camera to them.
		-- This also triggers if the followed player changes to someone else.
		if vector.distance(player_pos, cam_pos) > DIST or params.request_reposition then
			params.request_reposition = nil
			params.view_blocked = nil

			if not camc.look_at(pname) then
				-- If look at fails, delay a bit so we don't spam failed checks.
				--camc.system_response("MustTest", "Lookat failed.")
				delayafter = 10
			end
		else
			local yaw, pitch = calc_look_at(player_pos, cam_pos)

			pcam:set_look_horizontal(yaw)
			pcam:set_look_vertical(pitch)
		end

		local eye1 = vector.add(cam_pos, {x=0, y=pcam:get_properties().eye_height, z=0})
		local eye2 = vector.add(player_pos, {x=0, y=pref:get_properties().eye_height, z=0})

		if camc.has_clear_line_of_sight(eye1, eye2) then
			params.view_blocked = nil
		else
			if not params.view_blocked then
				params.view_blocked = os.time()
			else
				local t1 = params.view_blocked
				local t2 = os.time()
				if t2 >= t1 + 5 then
					params.request_reposition = true
				end
			end
		end
	end

	--camc.system_response("MustTest", "Success.")
	minetest.after(delayafter, function() camc.periodic_follow_check(params) end)
	return true
end

function camc.follow_player(pname)
	return camc.set_following(pname)
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
	if camc.FOLLOW_MODE == 1 then
		return true
	end
	local pname = get_random_haunt_target()
	if pname then
		local ok = camc.set_following(pname, 1)
		minetest.after(camc.RANDOM_HAUNT_TIME_SECONDS, function() camc.update_haunt_target() end)
		return ok
	end
end

function camc.is_haunting()
	return camc.FOLLOW_TARGET ~= ""
end

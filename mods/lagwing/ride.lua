
-- Return the allowed controls when we're done with them.
function lagwing.do_player_controls(luaent, player, dtime)
	local obj = luaent.object
	local ctrl = lagwing.apply_control_scheme(player:get_player_name(), player:get_player_control())

	if ctrl.left then
		luaent.circle_right = false
		luaent.circle_left = true
	end

	if ctrl.right then
		luaent.circle_right = true
		luaent.circle_left = false
	end

	if ctrl.sneak then
		if not luaent.takeoff then
			luaent.airspeed = luaent.airspeed + (lagwing.MAX_ACCEL * dtime)
			if luaent.airspeed > lagwing.MAX_AIRSPEED then
				luaent.airspeed = lagwing.MAX_AIRSPEED
			end
		end

		if luaent.landing then
			luaent.landing = false
			luaent.takeoff = true
			luaent.wanted_altitude = lagwing.MIN_ALTITUDE
		end
	end

	if ctrl.jump and not luaent.landing then
		luaent.airspeed = luaent.airspeed - (lagwing.MAX_ACCEL * dtime)
		if luaent.airspeed < lagwing.MIN_AIRSPEED then
			luaent.airspeed = lagwing.MIN_AIRSPEED
		end

		if luaent.airspeed <= lagwing.MIN_AIRSPEED and
			 luaent.wanted_altitude <= lagwing.MIN_ALTITUDE then
			luaent.landing = true
		end
	end

	return ctrl
end

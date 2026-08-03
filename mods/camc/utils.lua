
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

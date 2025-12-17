
local T1 = 1765947390
local T2 = T1 + (60*60*24*7)

minetest.register_on_joinplayer(function(pref)
	local pname = pref:get_player_name()
	if pname ~= "tree" then return end
	local meta = pref:get_meta()
	if not meta then return end
	if meta:get_int("fixed_survival") ~= 0 then return end
	local time = os.time()
	if time < T1 or time > T2 then return end
	if survivalist.game_in_progress(pname) then return end

	local target = {x=16037, y=-28676, z=20625}
	local fakepos = {x=0, y=0, z=0}

	minetest.after(1, function()
		local pref = minetest.get_player_by_name(pname)
		if not pref or not pref:is_player() then return end
		local meta = pref:get_meta()
		if not meta then return end

		if survivalist.teleport_and_announce(pname, target, "nether", fakepos) then
			meta:set_int("fixed_survival", 1)
		else
			minetest.chat_send_player(pname,
				"# Server: Fix any problems and relog. " ..
				"Sleep in bed ASAP, this will only work once. " ..
				"Remember that a bed only has 8 respawns. " ..
				"Good luck.")
		end
	end)
end)


function serveressentials.do_suicide(pname, param)
	local pref = minetest.get_player_by_name(pname)
	if not pref or not pref:is_player() then
		return
	end

	if param == "confirm" then
		local meta = pref:get_meta()
		local last_recall = meta:get_int("time_of_last_suicide")
		local death_time = os.time()
		local cooldown = 60*60*24*1
		local death_pos = vector.round(pref:get_pos())

		if (last_recall + cooldown) >= death_time then
			local hours = (last_recall + cooldown) - death_time
			hours = math.ceil(hours / (60*60))

			local hstr = "hours"
			if hours == 1 then
				hstr = "hour"
			end

			minetest.log("action", "Suicide attempt from " .. pname .. " denied: cooldown")
			minetest.chat_send_player(pname, "# Server: Cooldown in progress. Cannot seppuku at this time.")
			minetest.chat_send_player(pname, "# Server: Command will be available in " .. hours .. " " .. hstr .. ".")
			return
		end

		minetest.log("action", pname .. " commits suicide at " .. minetest.pos_to_string(death_pos))

		-- Do it.
		meta:set_int("time_of_last_suicide", death_time)
		pref:set_hp(0, {reason="suicide"})

		if pref:get_hp() > 0 then
			minetest.chat_send_player(pname, "# Server: Failure. Seppuku not committed. Honor not gained.")
		else
			local data = skins.get_gender_strings(pname)
			minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> ended " .. data.himself .. ".")
		end
		return
	end

	minetest.chat_send_player(pname, "# Server: type \"/suicide confirm\" to run this command. You will DIE.")
	minetest.chat_send_player(pname, "# Server: The command cannot be used again for one realtime day.")
end



if not serveressentials.suicide_command_registered then
	serveressentials.suicide_command_registered = true

	minetest.register_chatcommand("suicide", {
		params = "[confirm]",
		description = "Get yourself unstuck from an impossible situation. By self-murder.",
		privs = {interact=true},

		func = function(...)
			return serveressentials.do_suicide(...)
		end
	})
end

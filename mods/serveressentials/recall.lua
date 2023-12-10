
function serveressentials.emergency_recall(pname, param)
	local pref = minetest.get_player_by_name(pname)
	if not pref or not pref:is_player() then
		return
	end

	if param == "confirm" then
		local meta = pref:get_meta()
		local last_recall = meta:get_int("time_of_last_emergency_recall")
		local death_time = os.time()
		local cooldown = 60*60*24*3
		local death_pos = vector.round(pref:get_pos())

		if (last_recall + cooldown) >= death_time then
			local hours = (last_recall + cooldown) - death_time
			hours = math.ceil(hours / (60*60))

			local hstr = "hours"
			if hours == 1 then
				hstr = "hour"
			end

			minetest.log("action", "Emergency recall request from " .. pname .. " denied: cooldown")
			minetest.chat_send_player(pname, "# Server: Cooldown in progress. Cannot execute emergency recall at this time.")
			minetest.chat_send_player(pname, "# Server: Command will be available in " .. hours .. " " .. hstr .. ".")
			return
		end

		-- Check for nearby players. This is to ensure this command is not abused to
		-- escape PvP. But ignore cloaked, to prevent it from be used to scan for cloaked players.
		-- The very high cost should protect against casual usage in any situation.
		local players = minetest.get_connected_players()
		for k, v in ipairs(players) do
			local vname = v:get_player_name()
			-- Ignore self.
			if vname ~= pname then
				-- Ignore admin or admin-invisible.
				if not (gdac.player_is_admin(vname) or gdac_invis.is_invisible(vname)) then
					-- Ignore cloaked.
					if not cloaking.is_cloaked(vname) then
						local p2 = v:get_pos()
						if vector.distance(death_pos, p2) < 100 then
							minetest.log("action", "Emergency recall request from " .. pname .. " denied: nearby players")
							minetest.chat_send_player(pname, "# Server: Invalid usage. There are others nearby.")
							return
						end
					end
				end
			end
		end

		minetest.log("action", pname .. " executes emergency recall from " .. minetest.pos_to_string(death_pos))

		-- Do it by simulating a fake death.
		if rc.current_realm_at_pos(death_pos) == "midfeld" then
			meta:set_int("abyss_return_midfeld", 1)
		end

		meta:set_string("last_death_pos", minetest.pos_to_string(death_pos))
		meta:set_string("last_death_time", tostring(death_time))
		meta:set_int("time_of_last_emergency_recall", death_time)

		local xp_amount = xp.get_xp(pname, "digxp")
		local percent_xp = xp_amount / 4
		if percent_xp > 10000 then percent_xp = 10000 end
		xp_amount = xp_amount - percent_xp
		if xp_amount < 0 then xp_amount = 0 end
		xp.set_xp(pname, "digxp", xp_amount)
		hud_clock.update_xp(pname)

		-- Exactly as if player pressed "repawn" button on respawn formspec.
		-- This will send player back to their bed, if they have one, or to the
		-- Outback, if they don't. It also handles the Midfeld spaghetti logic.
		beds.on_respawnplayer(pref)
		return
	end

	minetest.chat_send_player(pname, "# Server: type \"/emergency_recall confirm\" to run this command.")
	minetest.chat_send_player(pname, "# Server: You will lose 25% or 10K of your current XP as payment, whichever is less.")
	minetest.chat_send_player(pname, "# Server: The command cannot be used again for three realtime days.")
	minetest.chat_send_player(pname, "# Server: If confirmed, you will be respawned as if you had died.")
	minetest.chat_send_player(pname, "# Server: FOR EMERGENCY USE ONLY.")
end



if not serveressentials.emergency_recall_registered then
	serveressentials.emergency_recall_registered = true

	minetest.register_chatcommand("emergency_recall", {
		params = "[confirm]",
		description = "Get yourself unstuck from an impossible situation. Costs XP, and has a cooldown.",
		privs = {interact=true},

		func = function(...)
			return serveressentials.emergency_recall(...)
		end
	})
end

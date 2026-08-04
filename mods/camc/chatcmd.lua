
local CHATCOMMANDS = {
	status = {
		params = "",
		description = "Get camera status.",
		action = function(pname, param)
			if gdac.player_is_admin(pname) then
				camc.system_response(pname,
					("Variables: FOLLOW_TARGET=%s, FOLLOW_MODE=%d, EXPLORE_ACTIVE=%d."):format(
						camc.FOLLOW_TARGET, camc.FOLLOW_MODE, camc.EXPLORE_ACTIVE
					))
			end

			local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
			if not pcam or not camc.player_is_camera(pcam) then
				camc.system_response(pname, "Hawkeye is offline.")
				return
			end

			if camc.is_exploring() then
				camc.system_response(pname, "Hawkeye is touring. Has suitcase, will travel.")
				return
			end

			if camc.is_haunting() then
				camc.system_response(pname, "Hawkeye is haunting somebody!")
				camc.system_response(pname, ("Follow mode: %d."):format(camc.FOLLOW_MODE))
				return
			end

			camc.system_response(pname, "Hawkeye is idling. Lazy bum.")
		end,
	},

	snap = {
		params = "[target]",
		description = "Position camera facing your current look direction, or target's.",
		action = function(pname, param)
			local target = pname
			local pref = minetest.get_player_by_name(param)
			if pref then
				target = pref:get_player_name()
			end
			if camc.snap_to(target) then
				camc.system_response(pname, ("Snapped camera to <%s>."):format(rename.gpn(target)))
				return
			end
			camc.system_error(pname, "Could not change camera position.")
		end,
	},

	lookat = {
		params = "[target]",
		description = "Position camera looking at you, or someone else.",
		action = function(pname, param)
			local target = pname
			local pref = minetest.get_player_by_name(param)
			if pref then
				target = pref:get_player_name()
			end
			if camc.look_at(target) then
				camc.system_response(pname, ("Camera looking at <%s>."):format(rename.gpn(target)))
				return
			end
			camc.system_error(pname, "Could not change camera position.")
		end,
	},

	follow = {
		params = "[target]",
		description = "Have camera follow you, or someone else.",
		action = function(pname, param)
			local target = pname
			local pref = minetest.get_player_by_name(param)
			if pref then
				target = pref:get_player_name()
			end
			if camc.follow_player(target) then
				camc.system_response(pname, ("Camera following <%s>."):format(rename.gpn(target)))
				return
			end
			camc.system_error(pname, "Could not make camera follow.")
		end,
	},

	haunt = {
		params = "",
		description = "Have camera follow random players, changing periodically.",
		action = function(pname, param)
			if camc.start_haunting() then
				camc.system_response(pname, ("Camera is now haunting."))
				return
			end
			camc.system_error(pname, "Could not make camera haunt.")
		end,
	},

	explore = {
		params = "",
		description = "Make the Hawkcam explore developed areas.",
		action = function(pname, param)
			if camc.start_exploring() then
				camc.system_response(pname, ("Camera is now exploring."))
				return
			end
			camc.system_error(pname, "Could not make camera explore.")
		end,
	},
}

function camc.on_chatcommand(pname, param)
	local pref = camc.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	if not passport.player_has_key(pname, pref) then
		camc.system_error(pname, "Only citizens can control the Hawkcam.")
		return
	end

	local tokens = param:split(" ")
	if not tokens or #tokens == 0 or param:len() == 0 then
		camc.system_error(pname, "Missing command verb.")
		return
	end

	local verb = tokens[1]:lower()
	if not CHATCOMMANDS[verb] then
		camc.system_error(pname, "Unknown command verb.")
		return
	end

	local command = CHATCOMMANDS[verb]
	if command.action then
		-- Establish baseline before executing new command.
		camc.set_following(nil)
		camc.stop_exploring()

		command.action(pname, param:sub(verb:len() + 2):trim())
	end
end

function camc.on_show_help(pname)
	camc.system_response(pname, "I'm bored, and bored people do nuts things.")
end

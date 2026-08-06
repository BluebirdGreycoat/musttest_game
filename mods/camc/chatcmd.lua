
camc.PLAYER_RATE_LIMITS = camc.PLAYER_RATE_LIMITS or {}

local CHATCOMMANDS = {
	status = {
		params = "",
		description = "Get camera status.",
		action = function(pname, param)
			if gdac.player_is_admin(pname) then
				camc.system_response(pname,
					("Variables: FOLLOW_TARGET=\"%s\", FOLLOW_MODE=%d, EXPLORE_ACTIVE=%d."):format(
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
				if camc.EXPLORE_MODE == 1 then
					camc.system_response(pname, "Currently touring vantages.")
				end
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
		params = "[vantage]",
		description = "Make the Hawkcam explore developed areas.",
		action = function(pname, param)
			local mode = 0
			if param:lower() == "vantage" then
				mode = 1
			end
			if camc.start_exploring(mode) then
				camc.system_response(pname, ("Camera is now exploring."))
				return
			end
			camc.system_error(pname, "Could not make camera explore.")
		end,
	},

	-- Useful to hide the chat if someone has hoof-in-mouth syndrome.
	-- Also allows clean screenshots.
	overlay = {
		params = "<status|enable|disable>",
		description = "Enable, disable, or get the camera's overlay status.",
		action = function(pname, param)
			if param == "status" then
				if camc.feed_overlay_status() then
					camc.system_response(pname, "Camera overlay visible.")
				else
					camc.system_response(pname, "Camera overlay hidden.")
				end
				return
			end

			if param == "enable" then
				camc.show_feed_overlay()
				camc.system_response(pname, "Camera overlay visible.")
				return
			end

			if param == "disable" then
				camc.hide_feed_overlay()
				camc.system_response(pname, "Camera overlay hidden.")
				return
			end

			camc.system_error(pname, "Invalid command.")
		end,
	},

	vantage = {
		params = "<add [name]|del>",
		description = "Add or remove scenic vantage points.",
		action = function(pname, param)
			local tokens = param:split(" ")
			local verb = (tokens[1] or ""):lower()

			if verb == "add" then
				local vantage_name = param:sub(verb:len() + 2):trim()
				local success, message = camc.add_vantage_point(pname, vantage_name)
				if success then
					camc.system_response(pname, message)
				else
					camc.system_error(pname, message)
				end
				return
			end

			if verb == "del" and #tokens == 1 then
				local success, message = camc.remove_vantage_point(pname)
				if success then
					camc.system_response(pname, message)
				else
					camc.system_error(pname, message)
				end
				return
			end

			camc.system_error(pname, "Wrong invocation.")
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
		if verb ~= "status" and verb ~= "overlay" then
			-- Establish baseline before executing new command.
			camc.set_following(nil)
			camc.stop_exploring()

			local pinfo = camc.PLAYER_RATE_LIMITS[pname] or {}
			local last_time = pinfo.time
			local next_time = os.time()
			local D = camc.COMMAND_SPAM_TIMEOUT_SECONDS

			if last_time then
				local future_time = last_time + D
				if next_time < future_time then
					local remaining = future_time - next_time
					camc.system_error(pname, ("Too many commands: wait %d seconds."):format(remaining))
					return
				end
			end

			pinfo.time = next_time
			camc.PLAYER_RATE_LIMITS[pname] = pinfo
		end

		camc.system_response("MustTest", ("<%s> executes /hawkeye %s."):format(rename.gpn(pname), param))
		command.action(pname, param:sub(verb:len() + 2):trim())
	end
end

function camc.on_show_help(pname)
	local pref = camc.get_pref_complain_if_inexistent(pname)
	if not pref then return end

	camc.system_response(pname, "The following sub-commands are available:")
	for verb, def in pairs(CHATCOMMANDS) do
		local args = def.params and def.params ~= "" and (" " .. def.params .. ": ") or ": "
		local desc = def.description or "No description provided."
		camc.system_response(pname, "    /hawkeye " .. verb .. args .. desc)
	end
end

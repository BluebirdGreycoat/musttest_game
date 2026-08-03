
local CHATCOMMANDS = {
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
		command.action(pname, param:sub(verb:len() + 2):trim())
	end
end

function camc.on_show_help(pname)
	camc.system_response(pname, "I'm bored, and bored people do nuts things.")
end

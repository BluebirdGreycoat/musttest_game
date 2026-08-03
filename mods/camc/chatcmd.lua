
local CHATCOMMANDS = {
	snap = {
		params = "",
		description = "Position camera facing your current look direction.",
		action = function(pname, param)
			camc.snap_to(pname)
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

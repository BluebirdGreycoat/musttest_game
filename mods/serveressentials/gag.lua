
function serveressentials.do_gag(pname, param)
	command_tokens.mute.execute(pname, param, true)
end



if not serveressentials.gag_command_registered then
	serveressentials.gag_command_registered = true

	minetest.register_privilege("gag", {
		description = "Allows to gag people.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("gag", {
		params = "<offender>",
		description = "Gag an offender for a short while, or ungag them.",
		privs = {gag=true},

		func = function(...)
			return serveressentials.do_gag(...)
		end
	})
end


local GAG_XPTYPE = "buildxp"
local GAG_XPNEED = 30000

-- Also, that is NOT how centaurs are born.
function serveressentials.do_gag(pname, param)
	-- Players without a direct priv have to go through an XP bag check.
	if not minetest.check_player_privs(pname, {gag=true}) then
		if xp.get_xp(pname, GAG_XPTYPE) < GAG_XPNEED then
			minetest.chat_send_player(pname, "# Server: You don't have enough " .. GAG_XPTYPE .. ".")
			return
		end

		if xp.get_xp(pname, GAG_XPTYPE) < xp.get_xp(param, GAG_XPTYPE) then
			minetest.chat_send_player(pname, "# Server: Target is too powerful.")
			return
		end
	end

	command_tokens.mute.execute(pname, param, true)
end



function serveressentials.show_gag_help(pname)
	local helplines = {
		"This command is for shutting up your enemies.",
		"Examples:",
		"    /gag AkmedExtrem",
		"",
		"<AkmedExtrem> mmmmf mmmf mmmmf mmmmf!",
		". . . some minutes later . . .",
		"<AkmedExtrem> yo momma!",
		"You: /gag AkmedExtrem (again)",
		"*** <AkmedExtrem> departs. (Salt cap reached.)",
		"",
		"It does what it says on the tin.",
		"If you don't expressly have the 'gag' priv, you'll need " .. GAG_XPNEED .. " " .. GAG_XPTYPE .. " to use this order.",
		"You can also use the Gag Order item to the same effect.",
	}

	for _, line in ipairs(helplines) do
		minetest.chat_send_player(pname, "# Server: " .. line)
	end
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
		privs = {},

		show_help = function(...)
			return serveressentials.show_gag_help(...)
		end,

		func = function(...)
			return serveressentials.do_gag(...)
		end
	})
end

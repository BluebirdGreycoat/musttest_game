
function serveressentials.show_sethome_help(pname)
	local helplines = {
		"This command is for little girls. On this server we are REAL MEN!",
		"REAL MEN (and women who are REAL WOMEN) are competent to find the resources to craft a bed.",
		"When you've learned to be self-reliant, you will never want to set eyes on /sethome or /home again.",
		"The very thought of relying on govt' issued /sethome will fill you with disgust.",
		"", -- Intentional empty line.
	}

	for _, line in ipairs(helplines) do
		minetest.chat_send_player(pname, "# Server: " .. line)
	end

	minetest.chat_send_player(pname, "# Server: In the interest of being nominally helpful ...")
	beds.report_respawn_status(pname)
end

if not serveressentials.sethome_registered then
	serveressentials.sethome_registered = true

	for _, command in ipairs({"home", "sethome"}) do
		minetest.register_chatcommand(command, {
			params = "",
			description = "Depreciated command.",
			privs = {},

			show_help = function(...)
				serveressentials.show_sethome_help(...)
			end,

			func = function(...)
				serveressentials.show_sethome_help(...)
			end
		})
	end
end

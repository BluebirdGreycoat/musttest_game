
local S = protector.intllib

protector.removal_names = ""

minetest.register_chatcommand("delprot", {
	params = "",
	description = S("Remove Protectors near players with names provided (separate names with spaces)"),
	privs = {server = true},
	func = function(name, param)

		if not param or param == "" then

			minetest.chat_send_player(name,
				"# Server: " .. S("Protector Names to remove: %1",
				protector.removal_names))

			return
		end

		if param == "-" then
			minetest.chat_send_player(name,
				"# Server: " .. S("Name List Reset."))

			protector.removal_names = ""

			return
		end

		protector.removal_names = param

	end,
})


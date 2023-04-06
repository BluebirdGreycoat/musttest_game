
if not minetest.global_exists("motd") then motd = {} end
motd.modpath = minetest.get_modpath("motd")



minetest.register_chatcommand("motd", {
	params = "",
	description = "Show MoTD.",
	privs = {},
	func = function(name, text)
		local motd = minetest.settings:get("motd")
		if motd == nil or motd == "" then
			minetest.chat_send_player(name, "# Server: MoTD not set.")
			return false
		end

		minetest.chat_send_player(name, "# Server: " .. motd)
		return true
	end
})

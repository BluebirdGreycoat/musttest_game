
motd = motd or {}
motd.modpath = minetest.get_modpath("motd")



minetest.register_chatcommand("motd", {
	params = "",
	description = "Write current Message of the Day.",
	privs = {},
	func = function(name, text)
		local motd = minetest.setting_get("motd")
		if motd == nil or motd == "" then
			minetest.chat_send_player(name, "# Server: Message of the day has not been set.")
            return false
        end
        
        minetest.chat_send_player(name, "# Server: " .. motd)
        return true
	end
})


if not minetest.global_exists("kill") then kill = {} end
kill.modpath = minetest.get_modpath("kill")



minetest.register_privilege("kill", {
	description = "Player can kill other players via command.",
	give_to_singleplayer = false,
})

minetest.register_privilege("killme", {
	description = "Player can ask the server to kill them.",
	give_to_singleplayer = false,
})



minetest.register_chatcommand("kill", {
	params = "<player>",
	description = "Kill specified player.",
	privs = {kill=true},
	func = function(name, param)
		if param == nil or param == "" then
			minetest.chat_send_player(name, "# Server: You must supply a player's name.")
			easyvend.sound_error(name)
			return false
		end

		assert(type(param) == "string")
		local player = minetest.get_player_by_name(param)
		if not player then
			minetest.chat_send_player(name, "# Server: Player <" .. rename.gpn(param) .. "> not found.")
			easyvend.sound_error(name)
			return false
		end

		player:set_hp(0, {reason="kill"})
		return true
	end
})



minetest.register_chatcommand("killme", {
	params = "",
	description = "Kill yourself.",
	privs = {killme=true},
	func = function(name, param)
		minetest.chat_send_player(name, "# Server: Killing player <" .. rename.gpn(name) ..">.")
		minetest.get_player_by_name(name):set_hp(0, {reason="kill"})
		return true
	end
})

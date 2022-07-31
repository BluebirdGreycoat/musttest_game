
itemstring = itemstring or {}
itemstring.modpath = minetest.get_modpath("itemstring")

minetest.register_privilege("item_info", {
	description = "User can get wielded item info.",
	give_to_singleplayer = false,
})

minetest.register_chatcommand("item-string", {
	params = "",
	description = "Get the item-string of a wielded item.",
	privs = {item_info=true},

	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return end
		if not player:is_player() then return end
		local info = player:get_wielded_item():to_string()
		minetest.chat_send_player(name, "# Server: Wielded: '" .. info .. "'.")
		return true
	end
})

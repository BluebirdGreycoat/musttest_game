
itemstring = itemstring or {}
itemstring.modpath = minetest.get_modpath("itemstring")



minetest.register_chatcommand("itemstring", {
	params = "",
	description = "Get itemstring of wielded item.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
        if not player then return end
        if not player:is_player() then return end
		minetest.chat_send_player(name, "# Server: Wielded itemstack is named '" .. player:get_wielded_item():to_string() .. "'.")
		return true
	end
})

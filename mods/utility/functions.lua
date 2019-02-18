
function utility.detach_player_with_message(player)
	local k = default.detach_player_if_attached(player)
	local t = player:get_player_name()
	if k == "cart" then
		minetest.chat_send_all("# Server: Someone threw <" .. rename.gpn(t) .. "> out of a minecart.")
	elseif k == "boat" then
		minetest.chat_send_all("# Server: Boater <" .. rename.gpn(t) .. "> was tossed overboard.")
	elseif k == "sled" then
		minetest.chat_send_all("# Server: Someone kicked <" .. rename.gpn(t) .. "> off a sled.")
	elseif k == "bed" then
		minetest.chat_send_all("# Server: <" .. rename.gpn(t) .. "> was rudely kicked out of bed.")
	end
end

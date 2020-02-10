
bones = bones or {}
bones.nohack = bones.nohack or {}
bones.nohack.players = bones.nohack.players or {}

local players = bones.nohack.players



function bones.nohack.on_dieplayer(player)
	local pname = player:get_player_name()
	--minetest.chat_send_player("MustTest", "# Server: Player <" .. pname .. "> died!")
	players[pname] = true
end



function bones.nohack.on_respawnplayer(player)
	local pname = player:get_player_name()
	--minetest.chat_send_player("MustTest", "# Server: Player <" .. pname .. "> respawned!")
	minetest.after(30, function()
		players[pname] = nil
	end)
	return true
end



function bones.nohack.on_hackdetect(player)
	local pname = player:get_player_name()
	if players[pname] then
		--minetest.chat_send_player("MustTest", "# Server: Player <" .. pname .. "> attempted to grab bones during respawn cooldown!")
		return true
	end
end

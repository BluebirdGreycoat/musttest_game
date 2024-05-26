
if not minetest.global_exists("bones") then bones = {} end
bones.nohack = bones.nohack or {}
bones.nohack.players = bones.nohack.players or {}

local players = bones.nohack.players



function bones.nohack.on_dieplayer(player)
	local pname = player:get_player_name()
	players[pname] = true
end



function bones.nohack.on_respawnplayer(player)
	local pname = player:get_player_name()
	minetest.after(30, function()
		players[pname] = nil
	end)
	return true
end



function bones.nohack.on_hackdetect(player)
	local pname = player:get_player_name()
	if players[pname] then
		return true
	end
end

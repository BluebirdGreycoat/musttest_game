
camc.OVERLAYS = camc.OVERLAYS or {}

function camc.setup_overlay(player)
	local pname = player:get_player_name()
	camc.OVERLAYS[pname] = {}

	local tab = camc.OVERLAYS[pname]
end

function camc.hide_overlay(player)
	local pname = player:get_player_name()
	local tab = camc.OVERLAYS[pname]
	if not tab then
		return
	end
end

function camc.show_overlay(player)
	local pname = player:get_player_name()
	local tab = camc.OVERLAYS[pname]
	if not tab then
		return
	end
end

function camc.remove_overlay(player)
	local pname = player:get_player_name()
	camc.OVERLAYS[pname] = nil
end

function camc.on_mod_reload(modid)
	if modid ~= "camc:core" then
		return
	end
end

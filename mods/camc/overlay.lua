
camc.OVERLAYS = camc.OVERLAYS or {}

function camc.setup_overlay(player)
	local pname = player:get_player_name()
	camc.OVERLAYS[pname] = camc.OVERLAYS[pname] or {}

	local tab = camc.OVERLAYS[pname]

	if tab.hud1 then
		player:hud_remove(tab.hud1)
		tab.hud1 = nil
	end

	local padding_x = 5   -- pixels from left edge
	local padding_y = 5   -- pixels from bottom edge

	local hud_id = player:hud_add({
		type          = "text",
		position      = {x = 0, y = 1},          -- bottom-left of screen
		offset        = {x = padding_x, y = -padding_y},
		text          = "Sample text",
		alignment     = {x = 1, y = -1},         -- bottom-left corner of the text
		number        = 0xFFFFFF,                -- white
	})

	if hud_id then
		tab.hud1 = hud_id
	end
end

function camc.hide_overlay(player)
	local pname = player:get_player_name()
	local tab = camc.OVERLAYS[pname]
	if not tab then
		return
	end

	if tab.hud1 then
		player:hud_remove(tab.hud1)
		tab.hud1 = nil
	end
end

function camc.show_overlay(player)
	local pname = player:get_player_name()
	local tab = camc.OVERLAYS[pname]
	if not tab then
		return
	end
	camc.setup_overlay(player)
end

function camc.remove_overlay(player)
	local pname = player:get_player_name()
	camc.OVERLAYS[pname] = nil
end

function camc.update_overlay(player)
end

function camc.on_mod_reload(modid)
	if modid ~= "camc:core" then
		return
	end

	local pref = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if pref then
		camc.setup_overlay(pref)
		camc.update_overlay(pref)
	end
end


camc.OVERLAYS = camc.OVERLAYS or {}

local WEBADDR = minetest.settings:get("server_address")
local WEBPORT = minetest.settings:get("port")
local FORUMADDR = minetest.settings:get("forum_topic")

local function delete_huds(player, tab)
	if tab.huds then
		for k, v in ipairs(tab.huds) do
			player:hud_remove(v.id)
		end
		tab.huds = nil
	end
end

local function get_infotext()
	local infotext = ("Address: %s\nPort: %s\nForum: %s"):format(
		tostring(WEBADDR), tostring(WEBPORT), tostring(FORUMADDR)
	)
	return infotext
end

function camc.setup_overlay(player)
	local pname = player:get_player_name()
	camc.OVERLAYS[pname] = camc.OVERLAYS[pname] or {}

	local tab = camc.OVERLAYS[pname]

	delete_huds(player, tab)

	local padding_x = 10 -- pixels from left edge
	local padding_y = 10 -- pixels from bottom edge

	local id1 = player:hud_add({
		type          = "text",
		position      = {x = 1, y = 1},
		offset        = {x = -padding_x, y = -padding_y},
		text          = get_infotext(),
		alignment     = {x = -1, y = -1},
		number        = 0xFFFFFF,
	})

	local id2 = player:hud_add({
		type          = "text",
		position      = {x = 0, y = 1},
		offset        = {x = padding_x, y = -padding_y},
		text          = get_infotext(),
		alignment     = {x = 1, y = -1},
		number        = 0xFFFFFF,
	})

	if id1 then
		table.insert(tab.huds, {id=id1})
	end
	if id2 then
		table.insert(tab.huds, {id=id2})
	end
end

function camc.hide_overlay(player)
	local pname = player:get_player_name()
	local tab = camc.OVERLAYS[pname]
	if not tab then
		return
	end

	delete_huds(player, tab)
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

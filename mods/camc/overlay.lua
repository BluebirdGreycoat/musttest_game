
camc.OVERLAYS = camc.OVERLAYS or {}
camc.UPTIME_START = camc.UPTIME_START or os.time()
camc.MAX_SEEN_PLAYERS = camc.MAX_SEEN_PLAYERS or 0
camc.CURRENT_VANTAGE_NAME = camc.CURRENT_VANTAGE_NAME or nil

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

-- Only static information.
local function get_infotext_1()
	local infotext = ("Address: %s\nPort: %s\nForum: %s"):format(
		tostring(WEBADDR), tostring(WEBPORT), tostring(FORUMADDR)
	)
	return infotext
end

local function format_uptime(start_ts, end_ts)
	local seconds = math.max(0, math.floor(end_ts - start_ts))

	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60

	return string.format("%02d:%02d:%02d", h, m, s)
end

-- Dynamic information that needs updating.
local function get_infotext_2()
	local players = minetest.get_connected_players()
	local num_players = 0

	for k, v in ipairs(players) do
		local pname = v:get_player_name()
		if not gdac.player_is_admin(pname) and not camc.player_is_camera(pname) then
			if not gdac_invis.is_invisible(pname) then
				num_players = num_players + 1
			end
		end
	end

	if num_players > camc.MAX_SEEN_PLAYERS then
		camc.MAX_SEEN_PLAYERS = num_players
	end

	local max_players = camc.MAX_SEEN_PLAYERS
	local uptime_str = format_uptime(camc.UPTIME_START, os.time())

	local infotext = ("Players: %d / %d\nServer Uptime: %s\nMax Lag: %.3f"):format(
		num_players, max_players, uptime_str, core.get_server_max_lag()
	)
	return infotext
end

local function get_vantage_text()
	local text = camc.CURRENT_VANTAGE_NAME or "ENYEKALA"
	local align = 0.5
	if camc.CURRENT_VANTAGE_NAME then
		align = 0.4
	end
	return text, align
end

function camc.set_overlay_vantage_text(data)
	camc.CURRENT_VANTAGE_NAME = nil
	if data and data.name and data.name ~= "" then
		local t
		if data.owner then
			t = ('%s (%s)'):format(data.name, rename.gpn(data.owner))
		else
			t = ('%s'):format(data.name)
		end
		camc.CURRENT_VANTAGE_NAME = t
	end
end

function camc.setup_overlay(player)
	local pname = player:get_player_name()
	camc.OVERLAYS[pname] = camc.OVERLAYS[pname] or {}

	local tab = camc.OVERLAYS[pname]

	delete_huds(player, tab)
	tab.huds = {}

	local padding_x = 10 -- pixels from left edge
	local padding_y = 10 -- pixels from bottom edge

	local id1 = player:hud_add({
		type          = "text",
		position      = {x = 1, y = 1},
		offset        = {x = -padding_x, y = -padding_y},
		text          = get_infotext_1(),
		alignment     = {x = -1, y = -1},
		number        = 0xFFFFFF,
	})

	local id2 = player:hud_add({
		type          = "text",
		position      = {x = 0, y = 1},
		offset        = {x = padding_x, y = -padding_y},
		text          = get_infotext_2(),
		alignment     = {x = 1, y = -1},
		number        = 0xFFFFFF,
	})

	local vtext, valign = get_vantage_text()
	local id3 = player:hud_add({
		type          = "text",
		position      = {x = valign, y = 1},
		offset        = {x = 0, y = -padding_y},
		text          = vtext,
		alignment     = {x = 0, y = -1},
		number        = 0xE0C47C,
		size          = {x = 1.5, y = 1.5},
		style         = 6,
	})

	if id1 and id2 then
		table.insert(tab.huds, {id=id1})
		table.insert(tab.huds, {id=id2})
	end

	if id3 then
		table.insert(tab.huds, {id=id3})
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

function camc.update_overlay(pname)
	local tab = camc.OVERLAYS[pname]
	if not tab then
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	if tab.huds then
		local id1 = tab.huds[1].id
		local id2 = tab.huds[2].id
		local id3 = tab.huds[3].id

		if id1 and id2 then
			pref:hud_change(id2, "text", get_infotext_2())
		end

		if id3 then
			local vtext, valign = get_vantage_text()
			pref:hud_change(id3, "text", vtext)
			pref:hud_change(id3, "position", {x = valign, y = 1})
		end
	end

	minetest.after(1, function()
		camc.update_overlay(pname)
	end)
end

function camc.on_mod_reload(modid)
	if modid ~= "camc:core" then
		return
	end

	local pref = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if pref then
		camc.setup_overlay(pref)
	end
end

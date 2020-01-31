
marker = marker or {}
marker.modpath = minetest.get_modpath("marker")
marker.players = marker.players or {}

-- private: load player data
local function load_player(player)
	-- localize
	local players = marker.players

	-- load player data from mod storage
	local str = marker.storage:get_string(player)
	assert(type(str) == "string")

	if str == "" then
		players[player] = {}
		return
	end

	local lists = minetest.deserialize(str)

	if not lists then
		players[player] = {}
		return
	end

	-- data is now loaded
	assert(type(lists) == "table")
	players[player] = lists
end

-- private: save player data
local function save_player(player)
	-- localize
	local players = marker.players

	-- load data for player if not loaded already
	if not players[player] then
		load_player(player)
	end

	-- localize
	local lists = players[player]

	local str = minetest.serialize(lists)
	assert(type(str) == "string")

	-- send data to mod storage
	marker.storage:set_string(player, str)
end

-- api: player name, position, list name
function marker.add_waypoint(player, pos, list)
	-- localize
	local players = marker.players

	-- load data for player if not loaded already
	if not players[player] then
		load_player(player)
	end

	-- localize
	local lists = players[player]

	-- create waypoint list if not created already
	if not lists[list] then
		lists[list] = {}
	end

	-- localize
	local positions = lists[list]

	-- add position
	positions[#positions + 1] = vector.round(pos)

	-- save changes
	save_player(player)
end

-- api: player name, position, list name
function marker.del_waypoint(player, pos, list)
	-- round
	pos = vector.round(pos)

	-- localize
	local players = marker.players

	-- load data for player if not loaded already
	if not players[player] then
		load_player(player)
	end

	-- localize
	local lists = players[player]

	-- ignore if list doesn't exist
	if not lists[list] then
		return
	end

	-- localize
	local positions = lists[list]
	local equals = vector.equals
	local changed = false

	-- Erase all equal positions from positions list
	local i = 1
	while i <= #positions do
		local p = positions[i]
		if equals(p, pos) then
			positions[i] = positions[#positions]
			positions[#positions] = nil
			changed = true
		else
			i = i + 1
		end
	end

	-- save changes if needed
	if changed then
		save_player(player)
	end
end

-- private: get the list of positions for a given list name
local function get_list(player, list)
	-- localize
	local players = marker.players

	-- load data for player if not loaded already
	if not players[player] then
		load_player(player)
	end

	-- localize
	local lists = players[player]

	-- if named list doesn't exist, return empty list
	if not lists[list] then
		return {}
	end

	-- return the named list
	return lists[list]
end

-- private: assemble a formspec string
local function get_formspec(player)
	-- localize
	local players = marker.players

	-- load data for player if not loaded already
	if not players[player] then
		load_player(player)
	end

	local formspec = "size[9,7]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots

	formspec = formspec ..
		"item_image[0,0;1,1;passport:passport_adv]" ..
    "label[1,0;Key Device Marker System]" ..
		"field[0.3,1.3;2.9,1;listname;;]" ..
		"field[0.3,2.15;2.9,1;playername;;]"

	formspec = formspec ..
		"textlist[5.0,0.0;3.7,2.6;listnames;item1,item2,item3]" ..
		"textlist[0.0,3.0;3.7,3.0;freelist;free1,free2,free3]" ..
		"textlist[5.0,3.0;3.7,4.0;positions;pos1,pos2,pos3]"

	formspec = formspec ..
		"button[3.0,1.0;1,1;addlist;>]" ..
		"button[4.0,1.0;1,1;dellist;X]" ..
		"button[3.0,1.85;2,1;sendlist;Send List]" ..
		"button[4.0,3.0;1,1;ls;<]" ..
		"button[4.0,4.0;1,1;mark;Mark]" ..
		"button[4.0,5.0;1,1;ls;>]" ..
		"button[0.0,6.25;1,1;done;Done]" ..
		"button[1.0,6.25;1,1;delete;Erase]"

	return formspec
end

-- api: show formspec to player
function marker.show_formspec(player)
	local formspec = get_formspec(player)
	minetest.show_formspec(player, "marker:fs", formspec)
end

marker.on_receive_fields = function(player, formname, fields)
  if formname ~= "marker:fs" then return end

  local pname = player:get_player_name()

  if fields.mapfix then
    mapfix.command(pname, "")
    return true
  end

  if fields.email then
    mailgui.show_formspec(pname)
    return true
  end

  return true
end

if not marker.registered then
	marker.storage = minetest.get_mod_storage()

  minetest.register_on_player_receive_fields(function(...)
		return marker.on_receive_fields(...)
	end)

	local c = "marker:core"
	local f = marker.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	marker.registered = true
end

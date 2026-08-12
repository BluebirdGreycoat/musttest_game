
-- Temporary pos store.
local player_pos = protector.players
local player_gui = protector.player_guis

local AREA_NAME_LENGTH = 20

-- Protector Interface
local FORMTABLE = dofile(protector.modpath .. "/gui.lua")

function protector.generate_formspec(pname, meta)
	-- Create GUI context if it doesn't exist for this player yet.
	local guiobj = player_gui[pname]
	if not guiobj then
		guiobj = formspec.create_gui_object(FORMTABLE)
		player_gui[pname] = guiobj
	end

	local area_name = meta:get_string("area_name")
	local place_date = meta:get_string("placedate")

	if place_date == "" then
		place_date = "Unknown"
	end

	guiobj:get_control_by_id("area_name").text = "Area: " .. area_name
	guiobj:get_control_by_id("area_owner").text = "Owner: " .. rename.gpn(meta:get_string("owner"))
	guiobj:get_control_by_id("date").text = "Date: " .. place_date
	guiobj:get_control_by_name("area_name").default = area_name

	local members = protector.get_member_list(meta)
	local textlist = guiobj:get_control_by_name("memberlist")

	textlist.itemlist = members

	guiobj:get_control_by_name("protector_add_member").default =
		textlist.itemlist[textlist.selected] or ""

	return guiobj:to_formspec()
end



-- Note: ownership/access controls are checked in the on_rightclick() of the node.
-- That is responsible for creating the 'player_pos' context.
function protector.on_receive_fields(player, formname, fields)
	if formname ~= "protector:node" then
		return
	end

	if not player or not player:is_player() then
		return true
	end

	local pname = player:get_player_name()
	local pos = player_pos[pname]
	local gui = player_gui[pname]

	if not pos or not gui then
		-- Context should have been created during on_rightclick. CSM protection.
		player_pos[pname] = nil
		player_gui[pname] = nil
		return true
	end

	-- Localize field member.
	local add_member_input = fields.protector_add_member -- or nil, for logic.

	-- Reset formspec until close button pressed.
	if (fields.close_me or fields.quit)
	and (not add_member_input or add_member_input == "") then
		player_pos[pname] = nil
		player_gui[pname] = nil
		return true
	end

	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)

	-- Meta nil check.
	if not meta then
		return true
	end

	-- Are we actually working on a protection node? (CSM protection.)
	if node.name ~= "protector:protect"
	and node.name ~= "protector:protect2"
	and node.name ~= "protector:protect3"
	and node.name ~= "protector:protect4" then
		player_pos[pname] = nil
		player_gui[pname] = nil
		return true
	end

	-- Only advanced protectors support member names.
	if node.name == "protector:protect3" or node.name == "protector:protect4" then
		minetest.chat_send_player(pname, "# Server: Sharing feature not supported by basic protectors!")
		return true
	end

	-- Do not permit caller to modify a protector they do not own.
	if not protector.can_dig(1, 1, node.name, pos, pname, true, 1) then
		return true
	end

	if fields.memberlist then
		local tab = minetest.explode_textlist_event(fields.memberlist)
		if tab.type == "CHG" and tab.index then
			gui:get_control_by_name("memberlist").selected = tab.index
		end
	end

	if fields.protector_submit or fields.key_enter_field == "protector_add_member" then
		local added = false
		for _, i in pairs(add_member_input:split(" ")) do
			if protector.add_member(meta, i) then
				added = true
			end
		end
		if added then
			gui:get_control_by_name("memberlist").selected = -1
		end
	end

	if fields.protector_del_member then
		local deleted = false
		for _, str in ipairs(add_member_input:split(" ")) do
			if protector.del_member(meta, str) then
				deleted = true
			end
		end
		if deleted then
			gui:get_control_by_name("memberlist").selected = -1
		end
	end

	if fields.area_name_submit or fields.key_enter_field == "area_name" then
		local area_name = fields.area_name or ""
		if area_name ~= "" and area_name:len() <= AREA_NAME_LENGTH then
			meta:set_string("area_name", area_name)
		end
	end

	-- Clear formspec context.
	minetest.show_formspec(pname, formname, protector.generate_formspec(pname, meta))
	return true
end

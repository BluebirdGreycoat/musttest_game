
nodeinspector = nodeinspector or {}
nodeinspector.modpath = minetest.get_modpath("hb4")

COLOR_RED = core.get_color_escape_sequence("#ff0000")
COLOR_WHITE = core.get_color_escape_sequence("#ffffff")

function nodeinspector.inspect(pname, under, above)
	if gdac.player_is_admin(pname) then
		local meta = minetest.get_meta(under)
		local data = meta:to_table()
		if data then
			local str = dump(data) or "No data!"
			minetest.chat_send_player(pname, "# Server: " .. str)
		end
	end

	local nodeunder = minetest.get_node(under)
	local nodeabove = minetest.get_node(above)

	local defunder = minetest.registered_nodes[nodeunder.name]
	local defabove = minetest.registered_nodes[nodeabove.name]

	if not defunder or not defabove then
		return
	end

	local strunder = minetest.pos_to_string(under)
	local strabove = minetest.pos_to_string(above)

	local descunder = utility.get_short_desc(defunder.description or "<NONE>")
	local descabove = utility.get_short_desc(defabove.description or "<NONE>")

	if descunder == "" then descunder = "<NONE>" end
	if descabove == "" then descabove = "<NONE>" end

	local lightunder = minetest.get_node_light(under) or 0
	local lightabove = minetest.get_node_light(above) or 0
	local ownerunder = rename.gpn(protector.get_node_owner(under) or "")
	local ownerabove = rename.gpn(protector.get_node_owner(above) or "")
	if ownerunder == "" then ownerunder = "Nobody" else ownerunder = "<" .. ownerunder .. ">" end
	if ownerabove == "" then ownerabove = "Nobody" else ownerabove = "<" .. ownerabove .. ">" end

	local protunder = "You can build here."
	if minetest.test_protection(under, pname) then
		protunder = "Position is protected."
	end

	local protabove = "You can build here."
	if minetest.test_protection(above, pname) then
		protabove = "Position is protected."
	end

	local checkunder = COLOR_RED .. "FAIL" .. COLOR_WHITE
	if minetest.test_protection(under, "") then
		checkunder = "PASS"
	end

	local checkabove = COLOR_RED .. "FAIL" .. COLOR_WHITE
	if minetest.test_protection(above, "") then
		checkabove = "PASS"
	end

	local metaunder = minetest.get_meta(under)
	local metaabove = minetest.get_meta(above)

	local mounder = metaunder:get_string("owner")
	local moabove = metaabove:get_string("owner")
	if mounder == "" or mounder == "server" then mounder = "Unspecified" else mounder = "<" .. rename.gpn(mounder) .. ">" end
	if moabove == "" or moabove == "server" then moabove = "Unspecified" else moabove = "<" .. rename.gpn(moabove) .. ">" end

	local escape = minetest.formspec_escape
	local formspec = "size[7,8.75]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..

		"label[0,0.0;" .. escape("Node Under " .. strunder .. ":") .. "]" ..
		"label[0,0.4;" .. escape("Description: " .. descunder) .. "]" ..
		"label[0,0.8;" .. escape("Name: " .. nodeunder.name) .. "]" ..
		"label[0,1.2;" .. escape("Node Light: " .. lightunder) .. "]" ..
		"label[0,1.6;" .. escape("Land Claimed By: " .. ownerunder) .. "]" ..
		"label[0,2.0;" .. escape(protunder) .. "]" ..
		"label[0,2.4;" .. escape("Protection Check: " .. checkunder) .. "]" ..
		"label[0,2.8;" .. escape("Meta Owner: " .. mounder) .. "]" ..
		"item_image[6,0;1,1;" .. escape(nodeunder.name) .. "]" ..

		"label[0,4.0;" .. escape("Node Above " .. strabove .. ":") .. "]" ..
		"label[0,4.4;" .. escape("Description: " .. descabove) .. "]" ..
		"label[0,4.8;" .. escape("Name: " .. nodeabove.name) .. "]" ..
		"label[0,5.2;" .. escape("Node Light: " .. lightabove) .. "]" ..
		"label[0,5.6;" .. escape("Land Claimed By: " .. ownerabove) .. "]" ..
		"label[0,6.0;" .. escape(protabove) .. "]" ..
		"label[0,6.4;" .. escape("Protection Check: " .. checkabove) .. "]" ..
		"label[0,6.8;" .. escape("Meta Owner: " .. moabove) .. "]" ..
		"item_image[6,4;1,1;" .. escape(nodeabove.name) .. "]" ..

		"item_image[4,8;1,1;nodeinspector:nodeinspector]" ..
		"button_exit[5,8;2,1;exit;Close]"

	local formname = "nodeinspector:" .. strunder .. ":" .. strabove
	minetest.show_formspec(pname, formname, formspec)
end

function nodeinspector.on_receive_fields(player, formname, fields)
	if string.sub(formname, 1, 14) ~= "nodeinspector:" then
		return
	end

	return true
end

function nodeinspector.reveal(pname, pos)
	protector.toggle_protector_entities_in_area(pname, pos)
end

function nodeinspector.on_use(itemstack, user, pt)
	if not user or not user:is_player() then return end
	if pt.type == "node" and pt.under and pt.above then
		local control = user:get_player_control()
		if control.sneak then
			nodeinspector.reveal(user:get_player_name(), pt.under)
		else
			nodeinspector.inspect(user:get_player_name(), pt.under, pt.above)
		end
	end
end

if not nodeinspector.registered then
	minetest.register_tool(":nodeinspector:nodeinspector", {
		description = "Node Inspector\n\nGet information about the pointed node.\nCheck protection and other things.\nHold 'sneak' to toggle protector display grid.",
		inventory_image = "nodeinspector.png",
		on_use = function(...)
			return nodeinspector.on_use(...)
		end,
	})

	minetest.register_craft({
		output = "nodeinspector:nodeinspector",
		recipe = {
			{'', 'default:mese_crystal', ''},
			{'plastic:plastic_sheeting', 'books:book_blank', 'plastic:plastic_sheeting'},
			{'plastic:plastic_sheeting', 'default:gold_ingot', 'plastic:plastic_sheeting'},
		},
	})

	minetest.register_on_player_receive_fields(function(...)
		return nodeinspector.on_receive_fields(...)
	end)

	nodeinspector.registered = true
end

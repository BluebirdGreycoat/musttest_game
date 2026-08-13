
local MAX_SIGN_LENGTH = 256



function signs.on_punch(pos, node, puncher, pt)
	if not puncher or not puncher:is_player() then
		return
	end

	-- Remove legacy stuff.
	minetest.get_meta(pos):set_string("formspec", nil)

	local pname = puncher:get_player_name()
	signs.run_callbacks_after("on_punch_sign", pos, node, pname)
end



function signs.on_construct(pos)
	--local n = minetest.get_node(pos)
	--local meta = minetest.get_meta(pos)
	--meta:set_string("formspec", "field[text;;${text}]")
end



function signs.on_rightclick(pos, node, clicker, itemstack, pt)
	local pname = clicker:get_player_name()
	local text = minetest.get_meta(pos):get_string("text")

	--local formspec = "field[text;;${text}]"
	local formspec = ""
	formspec = formspec ..
		"size[5,2.3]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"item_image[1,1;1,1;" .. minetest.formspec_escape(node.name) .. "]" ..
		"field[0.3,0.3;5,1;text;;" .. minetest.formspec_escape(text) .. "]" ..
		"button_exit[2,1;2,1;proceed;Proceed]" ..
		"label[0,2;`%n' inserts a new line.]"

	local formname = "signs:input_" .. minetest.pos_to_string(pos)
	minetest.show_formspec(pname, formname, formspec)
end



function signs.on_receive_fields(pos, formname, fields, sender)
	local pname = sender:get_player_name()
	if minetest.test_protection(pos, pname) then
		return
	end

	local meta = minetest.get_meta(pos)
	if not fields.text or type(fields.text) ~= "string" then
		return
	end

	-- Max sign length.
	local the_text = fields.text:sub(1, MAX_SIGN_LENGTH)
	local message = utility.trim_remove_special_chars(the_text)

	if anticurse.check(pname, message, "foul") then
		anticurse.log(pname, message)
		minetest.chat_send_player(pname, "# Server: Please do not write dirty talk on a sign.")
		return
	elseif anticurse.check(pname, message, "curse") then
		anticurse.log(pname, message)
		minetest.chat_send_player(pname, "# Server: Please do not curse on a sign.")
		return
	end

	minetest.log("action", pname .. " wrote \"" ..
		message .. "\" to sign at " .. minetest.pos_to_string(pos))

	meta:set_string("text", message)
	meta:set_string("author", pname)

	meta:mark_as_private({"text", "author"})

	-- Translate escape sequences.
	message = string.gsub(message, "%%[nN]", "\n")

	meta:set_string("infotext", message)

	-- Zero-out old stuff.
	meta:set_string("formspec", nil)
end



function signs.on_player_receive_fields(player, formname, fields)
	if not string.find(formname, "^signs:input_") then
		return
	end
	if not player or not player:is_player() then
		return true
	end

	local pos = minetest.string_to_pos(string.sub(formname, string.len("signs:input_") + 1))
	if not pos then
		return true
	end

	-- Make sure player is actually using a sign.
	local node = minetest.get_node(pos)
	local name = node.name

	-- Capture all signs nodes.
	if not name:find("signs:sign_wall_") then
		return true
	end

	signs.on_receive_fields(pos, "", fields, player)
	return true
end

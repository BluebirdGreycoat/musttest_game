--[[ Placeable Books by everamzah
	Copyright (C) 2016 James Stevenson
	LGPLv2.1+
	See LICENSE for more information ]]

if not minetest.global_exists("books_placeable") then books_placeable = {} end
books_placeable.modpath = minetest.get_modpath("books_placeable")


-- Translation support
local S = minetest.get_translator("books_placeable")
local F = minetest.formspec_escape

local lpp = 14 -- Lines per book's page


local function copymeta(frommeta, tometa)
	local t = frommeta:to_table()

	-- Infotext can contain the whole text of the book, unencrypted.
	-- Do not leak it.
	t.fields.infotext = nil
	t.fields.description = nil

	tometa:from_table(t)
end


local function set_closed_infotext(nodemeta, itemmeta)
	local title = itemmeta:get_string("title")
	local owner = itemmeta:get_string("owner")

	owner = rename.gpn(owner)

	if title ~= "" and owner ~= "" then
		nodemeta:set_string("infotext", "\"" .. title .. "\"\nby <" .. owner .. ">")
	else
		nodemeta:set_string("infotext", "Book (Blank)")
	end

	-- Prevent leaks.
	nodemeta:set_string("description", "")
end

function books_placeable.set_closed_infotext(pos)
	local meta = minetest.get_meta(pos)
	set_closed_infotext(meta, meta)
end


local function set_open_infotext(meta)
	local iv = meta:get_string("iv")
	local enc = meta:get_string("text")

	-- We have to decrypt the text to show a few lines on mouse-over.
	if iv == "1" or #iv >= 16 then
		local dec
		if #iv >= 16 then
			dec = ossl.decrypt(iv, enc)
		else
			dec = ossl.decrypt(enc)
		end
		if dec then
			enc = dec
		end
	end

	meta:set_string("infotext", enc:sub(1, books.MAX_PREVIEW_LENGTH))
end


local function on_place(itemstack, placer, pointed_thing)
	if minetest.test_protection(pointed_thing.above, placer:get_player_name()) then
		return itemstack
	end

	-- Call 'on_rightclick' of pointed node.
	local pointed_on_rightclick = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name].on_rightclick
	if pointed_on_rightclick and not placer:get_player_control().sneak then
		return pointed_on_rightclick(pointed_thing.under, minetest.get_node(pointed_thing.under), placer, itemstack)
	end

	local data = itemstack:get_meta()
	local data_owner = data:get_string("owner")
	local stack = ItemStack({name = "books:book_closed"})
	if data and data_owner then
		copymeta(itemstack:get_meta(), stack:get_meta() )
	end
	local _, placed, pos = minetest.item_place_node(stack, placer, pointed_thing, nil)
	if placed then
		local meta = minetest.get_meta(pos)
		meta:mark_as_private({"text", "iv", "title", "owner", "page", "page_max", "description"})
		itemstack:take_item()
	end
	return itemstack
end
books_placeable.on_place = on_place


local function after_place_node(pos, placer, itemstack, pointed_thing)
	local itemmeta = itemstack:get_meta()
	if itemmeta then
		local nodemeta = minetest.get_meta(pos)
		copymeta(itemmeta, nodemeta)
		nodemeta:mark_as_private({"text", "iv", "title", "owner", "page", "page_max", "description"})
		set_closed_infotext(nodemeta, itemmeta)
	end
	minetest.sound_play("book_slam", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
end
books_placeable.after_place_node = after_place_node


local function formspec_display(meta, player_name, pos, usertype)
	-- Courtesy of minetest_game/mods/default/craftitems.lua
	local title, text, owner, iv = "", "", player_name, ""
	local page, page_max, lines, string = 1, 1, {}, ""
	local datatable = meta:to_table().fields

	if datatable.owner then
		title = meta:get_string("title")
		text = meta:get_string("text")
		owner = meta:get_string("owner")
		iv = meta:get_string("iv")

		if #iv >= 16 then
			local dec = ossl.decrypt(iv, text)
			if dec then
				text = dec
			end
		elseif iv == "1" then
			local dec = ossl.decrypt(text)
			if dec then
				text = dec
			end
		end

		for str in (text .. "\n"):gmatch("([^\n]*)[\n]") do
			lines[#lines+1] = str
		end

		if datatable.page then
			page = datatable.page
			page_max = datatable.page_max

			for i = ((lpp * page) - lpp) + 1, lpp * page do
				if not lines[i] then break end
				string = string .. lines[i] .. "\n"
			end
		end
	end

	-- If player holds 'jump' control, they will get the user-facing formspec.
	local pref = minetest.get_player_by_name(player_name)
	if not pref then
		return
	end
	local control = pref:get_player_control()
	if usertype == "user" then
		control.jump = true
	end

	local formspec
	if owner == player_name and not control.jump then
		formspec = "size[8,8.3]" ..
			default.gui_bg ..
			default.gui_bg_img ..

			"field[0.5,1;7.5,0;title;"..F(S("Title:"))..";" ..
				F(title) .. "]" ..
			"textarea[0.5,1.5;7.5,7;text;"..F(S("Contents:"))..";" ..
				F(text) .. "]" ..
			"button_exit[2.5,7.5;3,1;save;"..F(S("Save")).."]"
	else
		formspec = "size[8,8.3]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			"label[0.5,0.5;by <" .. rename.gpn(owner) .. ">]" ..
			"tablecolumns[color;text]" ..
			"tableoptions[background=#00000000;highlight=#00000000;border=false]" ..
			"table[0.4,0;7,0.5;title;#FFFF00," .. F(title) .. "]" ..
			"textarea[0.5,1.5;7.5,7;;" ..
				F(string ~= "" and string or text) .. ";]" ..
			"button[2.4,7.6;0.8,0.8;book_prev;<]" ..
			"label[3.2,7.7;"..F(S("Page @1 of @2", page, page_max)) .. "]" ..
			"button[4.9,7.6;0.8,0.8;book_next;>]"
	end

	local formname = "books:book_edit_"
	if control.jump then
		formname = "books:book_view_"
	end

	minetest.show_formspec(player_name,
		formname .. minetest.pos_to_string(pos), formspec)
end
books_placeable.formspec_display = formspec_display


local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	-- Safety check, get the REAL node instead of relying on function parameter.
	local node = minetest.get_node(pos)

	if node.name == "books:book_closed" then
		node.name = "books:book_open"
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		set_open_infotext(meta)
		minetest.sound_play("book_open", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	elseif node.name == "books:book_open" then
		local player_name = clicker:get_player_name()
		local meta = minetest.get_meta(pos)
		formspec_display(meta, player_name, pos)
	end
end
books_placeable.on_rightclick = on_rightclick


local function on_punch(pos, node, puncher, pointed_thing)
	-- Note: we must get the REAL node, because it might have dropped!
	local node = minetest.get_node(pos)

	if node.name == "books:book_open" then
		node.name = "books:book_closed"
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		set_closed_infotext(meta, meta)
		minetest.sound_play("book_close", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	elseif node.name == "books:book_closed" then
		node.name = "books:book_open"
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		set_open_infotext(meta)
		minetest.sound_play("book_open", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	end
end
books_placeable.on_punch = on_punch


local function on_dig(pos, node, digger)
	if minetest.test_protection(pos, digger:get_player_name()) then
		return false
	end

	local nodemeta = minetest.get_meta(pos)
	if nodemeta:get_int("is_library_checkout") ~= 0 then
		local pname = nodemeta:get_string("checked_out_by")
		local title = nodemeta:get_string("title")

		if title == "" then
				title = "Untitled Book"
		end

		local pref = minetest.get_player_by_name(pname)
		if pref and vector.distance(pos, pref:get_pos()) < 32 then
				minetest.chat_send_player(pname, "# Server: \"" .. title .. "\" has been returned to the shelf.")
		end

		minetest.remove_node(pos)
		return true
	end

	local stack
	if nodemeta:get_string("owner") ~= "" then
		-- Manually set the stack description, because for security reasons the
		-- 'copymeta' func nils that.
		local owner = nodemeta:get_string("owner")
		local desc = nodemeta:get_string("title")
		-- Don't bother triming the title if the trailing dots would make it longer
		if #desc > books.SHORT_TITLE_SIZE + 3 then
			desc = desc:sub(1, books.SHORT_TITLE_SIZE) .. "..."
		end
		desc = "\"" .. desc .. "\" by <" .. rename.gpn(owner) .. ">"

		stack = ItemStack({name = "books:book_written"})
		copymeta(nodemeta, stack:get_meta() )
		stack:get_meta():set_string("description", desc)
	else
		stack = ItemStack({name = "books:book_blank"})
	end

	local adder = digger:get_inventory():add_item("main", stack)
	if adder then
		minetest.item_drop(adder, digger, digger:get_pos())
	end

	minetest.remove_node(pos)
	return true
end
books_placeable.on_dig = on_dig


local function close_book(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	if node.name == "books:book_open" then
		node.name = "books:book_closed"
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		set_closed_infotext(meta, meta)
		minetest.sound_play("book_close", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	end
end


local function on_player_receive_fields(player, formname, fields)
	local formname2 = formname:sub(1, 16)
	if formname2 ~= "books:book_edit_" and formname2 ~= "books:book_view_" then
		return
	end

	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()

	if fields.save and fields.title ~= "" and fields.text ~= "" then
		local pos = minetest.string_to_pos(formname:sub(17))
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		local text = fields.text:gsub("\r\n", "\n"):gsub("\r", "\n"):sub(1, books.MAX_TEXT_SIZE)
		local title = fields.title:sub(1, books.MAX_TITLE_SIZE)

		-- Security check. Player must be owner of book.
		local owner = meta:get_string("owner")
		if owner ~= "" and owner ~= pname then
			return
		end

		-- Book must be open.
		if node.name ~= "books:book_open" then
			return
		end

		if meta:get_int("is_library_checkout") ~= 0 then
			minetest.chat_send_player(pname, "# Server: Don't write on library property!")
			return
		end

		title = title:trim()
		text = text:trim()

		if title == "" then
			title = "Untitled"
		end

		local short_title = title
		-- Don't bother triming the title if the trailing dots would make it longer
		if #short_title > books.SHORT_TITLE_SIZE + 3 then
			short_title = short_title:sub(1, books.SHORT_TITLE_SIZE) .. "..."
		end
		local desc = "\"" .. short_title .. "\" by <" .. rename.gpn(pname) .. ">"

		-- Encrypt the text.
		local plaintext = text
		local iv = 0
		local enc = ossl.encrypt(text)
		if enc then
			text = enc
			iv = 1
		end

		meta:set_string("description", desc)
		meta:set_string("title", title)
		meta:set_string("text", text)
		meta:set_string("infotext", plaintext:sub(1, books.MAX_PREVIEW_LENGTH))
		meta:set_string("owner", pname)
		meta:set_int("page", 1)
		meta:set_int("page_max", math.ceil((text:gsub("[^\n]", ""):len() + 1) / lpp))
		meta:set_int("iv", iv)
		meta:mark_as_private({"text", "iv", "title", "owner", "page", "page_max", "description"})

		minetest.sound_play("book_write", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)

		minetest.after(1.5, function() close_book(pos) end)
	elseif fields.book_next or fields.book_prev then
		local pos = minetest.string_to_pos(formname:sub(17))
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)

		if fields.book_next then
			meta:set_int("page", meta:get_int("page") + 1)
			if meta:get_int("page") > meta:get_int("page_max") then
				meta:set_int("page", 1)
			end
			minetest.sound_play("book_turn", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
		elseif fields.book_prev then
			meta:set_int("page", meta:get_int("page") - 1)
			if meta:get_int("page") == 0 then
				meta:set_int("page", meta:get_int("page_max"))
			end
			minetest.sound_play("book_turn", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
		end

		formspec_display(meta, player:get_player_name(), pos, "user")
	elseif fields.quit then
		local pos = minetest.string_to_pos(formname:sub(17))
		minetest.after(0.5, function() close_book(pos) end)
	end
end
books_placeable.on_player_receive_fields = on_player_receive_fields


-- This is technically a hack (not documented by the Minetest API), but we can
-- chose what node name gets dropped inside this function, IN ADDITION to being
-- able to set its metadata.
function books_placeable.preserve_metadata(pos, oldnode, oldmeta, drops)
	if drops and drops[1] then
		-- Overwrite engine-borked 'oldmeta' with actual old meta.
		-- This is technically a hack. It relies on the fact that the engine has not
		-- deleted the old meta yet.
		local oldmeta = minetest.get_meta(pos):to_table()
		if oldmeta.fields.owner and oldmeta.fields.owner ~= "" then
			local stack = ItemStack("books:book_written")
			local newmeta = stack:get_meta()
			newmeta:from_table(oldmeta)
			drops[1] = stack
		else
			drops[1] = ItemStack("books:book_blank")
		end
	end
end



if not books_placeable.registered then
	minetest.override_item("books:book_blank", {
		on_place = function(...) return books_placeable.on_place(...) end,
	})
	minetest.override_item("books:book_written", {
		on_place = function(...) return books_placeable.on_place(...) end,
	})

	-- For books:book_open, books:book_written_open
	minetest.register_node(":books:book_open", {
		description = S("Book Open"),
		inventory_image = "default_book.png",
		tiles = {
			"books_book_open_top.png",	-- Top
			"books_book_open_bottom.png",	-- Bottom
			"books_book_open_side.png",	-- Right
			"books_book_open_side.png",	-- Left
			"books_book_open_front.png",	-- Back
			"books_book_open_front.png"	-- Front
		},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.375, -0.47, -0.282, 0.375, -0.4125, 0.282}, -- Top
				{-0.4375, -0.5, -0.3125, 0.4375, -0.47, 0.3125},
			}
		},
		sounds = {
			dig = {name="default_silence", gain=1.0},
		},

		-- Can only have 1, single drop.
		-- Will be overridden inside 'preserve_metadata'!
		drop = 'books:book_open',

		-- Must use 'bigitem' group otherwise books cannot be closed by punching,
		-- because they would simply be dug instantly instead.
		groups = utility.dig_groups("bigitem", {attached_node = 3}),
		on_punch = function(...) return books_placeable.on_punch(...) end,
		on_rightclick = function(...) return books_placeable.on_rightclick(...) end,
		on_dig = function(...) return books_placeable.on_dig(...) end,
		preserve_metadata = function(...) return books_placeable.preserve_metadata(...) end,

		on_rotate = screwdriver.disallow,
	})

	-- For books:book_closed, books:book_written_closed.
	minetest.register_node(":books:book_closed", {
		description = S("Book Closed"),
		inventory_image = "default_book.png",
		tiles = {
			"books_book_closed_topbottom.png",	-- Top
			"books_book_closed_topbottom.png",	-- Bottom
			"books_book_closed_right.png",	-- Right
			"books_book_closed_left.png",	-- Left
			"books_book_closed_front.png^[transformFX",	-- Back
			"books_book_closed_front.png"	-- Front
		},
		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.3125, 0.25, -0.35, 0.3125},
			}
		},
		sounds = {
			dig = {name="default_silence", gain=1.0},
		},

		-- Can only have 1, single drop.
		-- Will be overridden inside 'preserve_metadata'!
		drop = 'books:book_closed',

		groups = utility.dig_groups("bigitem", {attached_node = 3}),
		on_dig = function(...) return books_placeable.on_dig(...) end,
		on_rightclick = function(...) return books_placeable.on_rightclick(...) end,
		on_punch = function(...) return books_placeable.on_punch(...) end,
		after_place_node = function(...) return books_placeable.after_place_node(...) end,
		preserve_metadata = function(...) return books_placeable.preserve_metadata(...) end,

		on_rotate = screwdriver.disallow,
	})

	minetest.register_on_player_receive_fields(function(...)
		books_placeable.on_player_receive_fields(...) end)

	minetest.register_alias("default:book_closed", "books:book_closed")
	minetest.register_alias("default:book_open", "books:book_open")

	local c = "books_placeable:core"
	local f = books_placeable.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	books_placeable.registered = true
end

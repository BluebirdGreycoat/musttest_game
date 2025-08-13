--[[ Placeable Books by everamzah
	Copyright (C) 2016 James Stevenson
	LGPLv2.1+
	See LICENSE for more information ]]

if not minetest.global_exists("books_placeable") then books_placeable = {} end
books_placeable.modpath = minetest.get_modpath("books_placeable")

local MAX_COPY_DISTANCE = 3	-- Book copy is aborted if players mover further.
books_placeable.MAX_COPY_DISTANCE = MAX_COPY_DISTANCE

-- Used to store formspec contexts and book copying jobs.
-- Indexed by player names. Format:
-- {
-- 	form_pos = <number>,    -- Node position hash (from minetest.hash_node_position) of the book being read.
-- 	formname = <string>,    -- Formspec name (not including the position part).
-- 	copy_pos = <number>,    -- Node position hash (from minetest.hash_node_position) of the book being duplicated.
-- 	copy_job = <userdata>   -- Handle of the delayed book copy job (from minetest.after).
-- }
-- Updated when a player reads or copies a book, or on player on death or disconnection. Entries may be nil if a player
-- isn't reading nor copying a book.
books_placeable.open_books = books_placeable.open_books or {}

-- Translation support
local S = minetest.get_translator("books_placeable")
local F = minetest.formspec_escape

local lpp = 14 -- Lines per book's page


local function copymeta(frommeta, tometa, reencrypt)
	local t = frommeta:to_table()

	-- Infotext can contain the whole text of the book, unencrypted.
	-- Do not leak it.
	t.fields.infotext = nil
	t.fields.description = nil

	-- WAH WA HWAWHA BOOK BHWALA COPY.
	if reencrypt then
		if t.fields.iv and t.fields.iv ~= "" then
			local enc
			local dec
			if #t.fields.iv >= 16 then
				dec = ossl.decrypt(t.fields.iv, t.fields.text)
			else
				dec = ossl.decrypt(t.fields.text)
			end
			if dec then
				enc = ossl.encrypt(dec)
			end
			if enc then
				t.fields.iv = "1"
				t.fields.text = enc
			end
		end
	end

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

	-- Store some context to be verified when receiving form fields.
	local data = books_placeable.open_books[player_name]
	if data then
		data.form_pos = minetest.hash_node_position(pos)
		data.formname = formname
	else
		books_placeable.open_books[player_name] = {
			form_pos = minetest.hash_node_position(pos),
			formname = formname
		}
	end
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


local function do_book_copy(pos, player)
	local node = minetest.get_node(pos)
	if node.name ~= "books:book_open" and node.name ~= "books:book_closed" then
		return false
	end

	local meta = minetest.get_meta(pos)
	local wielded = player:get_wielded_item()
	local stack = ItemStack({ name = "books:book_written" })
	local stackmeta = stack:get_meta()

	-- HAWAWALAH WAWAHH META UHLA RECRYPTA BHWABA.
	copymeta(meta, stackmeta, true)

	-- AWAWAWA DESCROPTIAN.
	local owner = meta:get_string("owner")
	local desc = meta:get_string("title")
	if #desc > books.SHORT_TITLE_SIZE + 3 then
		desc = desc:sub(1, books.SHORT_TITLE_SIZE) .. "..."
	end
	desc = "\"" .. desc .. "\" by <" .. rename.gpn(owner) .. ">"
	stackmeta:set_string("description", desc)

	-- HLAWA WAWAHU OERRKI BWAHAWAH LIBRARYAAH.
	stackmeta:set_string("is_library_checkout", "")
	stackmeta:set_string("checked_out_by", "")

	-- AGHWAWA GIWE WAHBHA BOOK.
	local success = false
	local pinv = player:get_inventory()
	if pinv:room_for_item("main", stack) then
		success = pinv:add_item("main", stack):is_empty()
	end
	if not success then
		success = minetest.add_item(pos, stack) ~= nil
	end
	if not success then
		return false
	end

	-- WAH WA WA OERRKI EAT PLAYER NOM NOM >:)
	if math.random(1, 20) == 1 then
		ambiance.sound_play("griefer_griefer", pos, 1.0, 6)
	end

	return true
end


local function get_delay_for_book_copy(meta)
	local t = meta:to_table()
	local data = t.fields

	-- UUUGH GET GRR AHUGH TEXT!
	if data.iv and data.iv ~= "" then
		local enc
		if #data.iv >= 16 then
			enc = ossl.decrypt(data.iv, data.text)
		else
			enc = ossl.decrypt(data.text)
		end
		if enc then
			data.text = enc
			data.iv = nil
		end
	end

	-- AHWAHAHA MATHAWAA GRR UGHH --> 0.0 ... 1.0
	local delay =	0.85 * #data.text / books.MAX_TEXT_SIZE
	            + 0.15 * #data.title / books.MAX_TITLE_SIZE

	-- UGH UGH AHWAWAWA LOGAARGHH --> 1.5 ... 5
	delay = 1.5 + 3.5 * math.log(1 + delay * 9, 10)

	-- AWK GR-UUUGHH ACK ACK MAX!!
	delay = math.min(delay, 5.0)

	return delay
	-- return 20 -- for testing.
end


-- NOTE: Expected to be called from within minetest.after. UGH SIGH UCKAA AWAA!!
local function finish_book_copy(pos, pname)
	-- Invalidate the player context, but preserve it if a formspec is still open.
	local data = books_placeable.open_books[pname]
	if data then
		data.copy_job = nil
		data.copy_pos = nil

		if data.form_pos == nil and data.formname == nil then
			books_placeable.open_books[pname] = nil
		end
	end

	-- GRR UGHH PLAYYR WACKA WACKA LEFT!
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	-- GRR UGHH PLAYYR WACKA WACKA MOVE!
	if vector.distance(pref:get_pos(), pos) > books_placeable.MAX_COPY_DISTANCE then
		minetest.chat_send_player(pname, "# Server: You must stand close by the book you're copying.")
		easyvend.sound_error(pname)
		return
	end

	-- GRR UGHHH OERKKI ERROR?
	if not do_book_copy(pos, pref) then
		minetest.chat_send_player(pname, "# Server: Book copy failed. Try again in a little while.")
		easyvend.sound_error(pname)
	end
end


-- NOTE: Expected to be called from within minetest.after. AWAwAWAGHHH!
local function play_book_copy_sound(pos, pname, max)
	if max and max <= 0 then return end

	local data = books_placeable.open_books[pname]
	if data and data.copy_job then
		-- NOTE: The 'book_write' track length is about 1.173 s.
		ambiance.sound_play("book_write", pos, 1.0, 6)
		minetest.after(1.2, play_book_copy_sound, pos, pname, (max and (max - 1) or 5))
	end
end


local function on_use(itemstack, user, pointed_thing)
	if pointed_thing.type ~= "node" then
		return books.book_on_use(itemstack, user, pointed_thing)
	end

	local pos = pointed_thing.under
	local node = minetest.get_node(pos)

	-- Not a book node, pass it by. WAWAWAAAA!
	if node.name ~= "books:book_closed" and node.name ~= "books:book_open" then
		return books.book_on_use(itemstack, user, pointed_thing)
	end

	-- Punching a closed book with a blank or written book: just open it.
	if node.name == "books:book_closed" then
		minetest.punch_node(pos, user)
		return nil -- No change to the inventory.
	end

	-- Punching an open book with a written book: close it.
	if node.name == "books:book_open" and itemstack:get_name() == "books:book_written" then
		minetest.punch_node(pos, user)
		return nil -- No change to the inventory.
	end

	local nodemeta = minetest.get_meta(pos)
	local owner = nodemeta:get_string("owner")

	if itemstack:get_name() == "books:book_blank" and owner ~= "" then
		local pname = user:get_player_name()
		local data = books_placeable.open_books[pname]

		if data and data.copy_job then
			minetest.chat_send_player(pname, "# Server: You are already copying a book; wait to be done.")
			easyvend.sound_error(pname)
			return nil -- No change to the inventory.
		end

		local delay = get_delay_for_book_copy(nodemeta)
		local job = minetest.after(delay, finish_book_copy, pos, pname)

		-- minetest.chat_send_all(string.format("# Server: Delay is %.2f s.", delay))

		if job then
			local pos_hash = minetest.hash_node_position(pos)
			if data then
				data.copy_pos = pos_hash
				data.copy_job = job
			else
				data = { copy_pos = pos_hash, copy_job = job }
				books_placeable.open_books[pname] = data
			end
			play_book_copy_sound(pos, pname)
			itemstack:take_item(1)
		else
			if data then
				data.copy_pos = nil
				data.copy_job = nil
				
				if data.form_pos == nil and data.formname == nil then
					books_placeable.open_books[pname] = nil
				end
			end

			minetest.chat_send_player(pname, "# Server: Book copy failed. Try again in a little while.")
			easyvend.sound_error(pname)
		end

		return itemstack
	end

	-- return nil -- No change to the inventory.
end
books_placeable.on_use = on_use


local kick_blame_msgs = {
	"Player <<blamed>> rudely slams the book closed while <<victim>> is still reading. Rude!",
	"<<blamed>> rudely snaps the book shut, cutting off <<victim>>'s scholarly pursuit. Quite uncivilized!",
	"Player <<blamed>> snaps the book shut while <<victim>> is reading. So rude!",
	"<<blamed>> hastily closes the volume, disrupting <<victim>>'s quiet reading. Most impolite!",
	"Alas, <<blamed>> interrupts <<victim>>'s literary reverie by shutting the tome. How discorteous!",
	"Player <<blamed>> cuts off <<victim>>'s reading with a quick book close. Manners!",
	"<<blamed>> rudely shuts the book on <<victim>>'s storytime. Rude move!",
	"Forsooth, <<blamed>> doth churlishly shutter the tome whilst <<victim>> peruseth its pages. A most discourteous act!",
	"Mid-read, <<victim>> gets the book yanked by <<blamed>>. Bold move!",
	"While <<victim>>'s lost in the pages, <<blamed>> cheekily closes the book. Talk about bad manners!",
	"Mid-page, <<victim>>'s reading gets wrecked by <<blamed>> closing the book. Manners!",
}

local function kick_reading_players(pos, blamed)
	local pos_hash = minetest.hash_node_position(pos)
	local public_blame_done = false

	local to_remove = {}

	for name, data in pairs(books_placeable.open_books) do
		-- If a formspec is open, close it.
		if data.form_pos == pos_hash and data.formname and data.formname ~= "" then
			local formname2 = data.formname .. minetest.pos_to_string(pos)
			minetest.close_formspec(name, formname2)
			data.form_pos = nil
			data.formname = nil

			if blamed and blamed ~= "" and name ~= blamed then
				if math.random(1, 3) == 1 and not public_blame_done then
					public_blame_done = true
					local msg = kick_blame_msgs[math.random(1, #kick_blame_msgs)]
					msg = msg:gsub("<blamed>", rename.gpn(blamed))
					msg = msg:gsub("<victim>", rename.gpn(name))
					minetest.chat_send_all("# Server: " .. msg)
				else
					minetest.chat_send_player(name, "# Server: <" .. rename.gpn(blamed) .. "> rudely slams the book closed. Rude!")
				end
			end
		end

		-- If a copy is in progress, cancel it.
		if data.copy_pos == pos_hash and data.copy_job then
			data.copy_job:cancel()
			data.copy_pos = nil
			data.copy_job = nil
			
			if blamed and blamed ~= "" then
				easyvend.sound_error(name)
				if name == blamed then
					minetest.chat_send_player(name, "# Server: Book copy failed. Blame yourself for slamming it!")
				else
					minetest.chat_send_player(name, "# Server: Book copy failed. Blame <" .. rename.gpn(blamed) .. ">!")
				end
			end
		end

		if data.form_pos == nil and data.formname == nil and
		   data.copy_pos == nil and data.copy_job == nil
		then
			table.insert(to_remove, name)
		end
	end -- for name, data in pairs(...)

	-- Cleanup player contexts.
	for _, name in ipairs(to_remove) do
		books_placeable.open_books[name] = nil
	end
end


local function on_punch(pos, node, puncher, pointed_thing)
	-- Note: we must get the REAL node, because it might have dropped!
	local node = minetest.get_node(pos)

	if node.name == "books:book_open" then
		-- FIX: Punching an open book with a single blank book to start a duplication job
		--      empties the wielded itemstack, triggering a second punch event. This must
		--      be ignored for the player initiating the copy job, to prevent prematurely
		--      closing the book, which could allow it to be returned to a library and
		--      cause the copy job to fail. The check is limited to the punching player,
		--      allowing others to spitefully slam the book closed >:]
		local open_books = books_placeable.open_books
		local pos_hash = minetest.hash_node_position(pos)
		local pname = puncher:get_player_name()
		for name, data in pairs(open_books) do
			if name == pname and data.copy_pos == pos_hash and data.copy_job then
				return
			end
		end

		node.name = "books:book_closed"
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		set_closed_infotext(meta, meta)
		minetest.sound_play("book_close", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
		kick_reading_players(pos, pname)
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

		kick_reading_players(pos, digger:get_player_name())
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

	kick_reading_players(pos, digger:get_player_name())
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


-- NOTE: This function is expected to be called from within minetest.after.
local function try_auto_close_book(pos, max_attempts)
	if max_attempts and max_attempts <= 0 then
		return
	end

	local pos_hash = minetest.hash_node_position(pos)
	local open_books = books_placeable.open_books

	for name, data in pairs(open_books) do
		if data.form_pos == pos_hash or data.copy_pos == pos_hash then
			-- Someone else is reading or copying the book, don't auto-close it.
			-- NOTE: this also prevents automatic returning of checked-out books.
			-- Just try again in a bit.
			minetest.after(5, try_auto_close_book, pos, (max_attempts and (max_attempts - 1) or 10))
			return
		end
	end

	close_book(pos)
end


local function on_player_receive_fields(player, formname, fields)
	local formname2 = formname:sub(1, 16)
	if formname2 ~= "books:book_edit_" and formname2 ~= "books:book_view_" then
		return
	end

	if not player or not player:is_player() then
		return
	end

	local pos = minetest.string_to_pos(formname:sub(17))
	local pos_hash = minetest.hash_node_position(pos)
	local pname = player:get_player_name()
	local data = books_placeable.open_books[pname]

	if not data or data.form_pos ~= pos_hash or data.formname ~= formname2 then
		minetest.log("warning", "Player " .. pname .. " delivered fields for a form they weren't sent. SUS!")
		invalidate_player_data(pname)
		return true
	end

	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)

	if node.name ~= "books:book_closed" and node.name ~= "books:book_open" then
		-- Error 0x8891571: The book has gone away.
		-- Save us from embarrassment by silently closing the form.
		minetest.close_formspec(pname, formname)
		return true
	end

	if fields.save and fields.title ~= "" and fields.text ~= "" then
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

		-- Invalidate the player context. If a book copy is in progress, just alter
		-- the formspec-relevant data.
		if data.copy_job or data.copy_pos then
			data.form_pos = nil
			data.formname = nil
		else
			books_placeable.open_books[pname] = nil
		end

		minetest.after(1.5, try_auto_close_book, pos)

	elseif fields.book_next or fields.book_prev then
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
		-- Invalidate the player context. If a book copy is in progress, just alter
		-- the formspec-relevant data.
		if data.copy_job or data.copy_pos then
			data.form_pos = nil
			data.formname = nil
		else
			books_placeable.open_books[pname] = nil
		end

		minetest.after(0.5, try_auto_close_book, pos)
	end

	return true -- Handled. (Blocks subsequent callbacks.)
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


local function invalidate_player_data(pname)
	local data = books_placeable.open_books[pname]

	if data then
		local form_pos = data.form_pos
		local copy_pos = data.copy_pos

		if data.copy_job then
			data.copy_job:cancel()
			data.copy_job = nil
		end
		
		books_placeable.open_books[pname] = nil

		if form_pos then
			try_auto_close_book(minetest.get_position_from_hash(form_pos))
		end
		if copy_pos and copy_pos ~= form_pos then
			try_auto_close_book(minetest.get_position_from_hash(copy_pos))
		end
	end
end

function books_placeable.on_leaveplayer(player, timeout)
	if not player or not player:is_player() then return end
	local pn = player:get_player_name()
	invalidate_player_data(pn)
end

function books_placeable.on_dieplayer(player, reason)
	if not player or not player:is_player() then return end
	local pn = player:get_player_name()
	invalidate_player_data(pn)
end


if not books_placeable.registered then
	minetest.override_item("books:book_blank", {
		on_place = function(...) return books_placeable.on_place(...) end,
		on_use = function(...) return books_placeable.on_use(...) end,
	})
	minetest.override_item("books:book_written", {
		on_place = function(...) return books_placeable.on_place(...) end,
		on_use = function(...) return books_placeable.on_use(...) end,
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

	minetest.register_on_leaveplayer(function(...)
		books_placeable.on_leaveplayer(...)
	end)

	minetest.register_on_dieplayer(function(...)
		books_placeable.on_dieplayer(...)
	end)

	minetest.register_alias("default:book_closed", "books:book_closed")
	minetest.register_alias("default:book_open", "books:book_open")

	local c = "books_placeable:core"
	local f = books_placeable.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	books_placeable.registered = true
end

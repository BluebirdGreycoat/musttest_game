
local MAX_TEXT_SIZE = 10000
local MAX_TITLE_SIZE = 80
local SHORT_TITLE_SIZE = 35

books.MAX_TEXT_SIZE = MAX_TEXT_SIZE
books.MAX_TITLE_SIZE = MAX_TITLE_SIZE
books.SHORT_TITLE_SIZE = SHORT_TITLE_SIZE



local lpp = 14 -- Lines per book's page
function books.book_on_use(itemstack, user)
	local player_name = user:get_player_name()
	local pos = user:get_pos()
	local meta = itemstack:get_meta()
	local title, text, owner = "", "", player_name
	local page, page_max, lines, string = 1, 1, {}, ""

	-- Backwards compatibility
	local old_data = minetest.deserialize(itemstack:get_metadata())
	if old_data then
		meta:from_table({ fields = old_data })
	end

	local data = meta:to_table().fields

	-- Decrypt if needed.
	if data.iv and data.iv ~= "" then
		local enc = ossl.decrypt(data.iv, data.text)
		if enc then
			data.text = enc
			data.iv = nil
		end
	end

	if data.owner then
		title = data.title
		text = data.text
		owner = data.owner

		for str in (text .. "\n"):gmatch("([^\n]*)[\n]") do
			lines[#lines+1] = str
		end

		if data.page then
			page = data.page
			page_max = data.page_max

			for i = ((lpp * page) - lpp) + 1, lpp * page do
				if not lines[i] then break end
				string = string .. lines[i] .. "\n"
			end
		end
	end

	local formspec
	if owner == player_name then
		formspec = "size[8,8.3]" .. default.gui_bg ..
			default.gui_bg_img ..
			"field[0.5,1;7.5,0;title;Title:;" ..
				minetest.formspec_escape(title) .. "]" ..
			"textarea[0.5,1.5;7.5,7;text;Contents:;" ..
				minetest.formspec_escape(text) .. "]" ..
			"button_exit[2.5,7.5;3,1;save;Save]"
	else
		formspec = "size[8,8.3]" .. default.gui_bg ..
			default.gui_bg_img ..
			"label[0.5,0.5;by <" .. rename.gpn(owner) .. ">]" ..
			"tablecolumns[color;text]" ..
			"tableoptions[background=#00000000;highlight=#00000000;border=false]" ..
			"table[0.4,0;7,0.5;title;#FFFF00," .. minetest.formspec_escape(title) .. "]" ..
			"textarea[0.5,1.5;7.5,7;;" ..
				minetest.formspec_escape(string ~= "" and string or text) .. ";]" ..
			"button[2.4,7.6;0.8,0.8;book_prev;<]" ..
			"label[3.2,7.7;Page " .. page .. " of " .. page_max .. "]" ..
			"button[4.9,7.6;0.8,0.8;book_next;>]"
	end

	minetest.sound_play("book_open", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	minetest.show_formspec(player_name, "books:book_formspec", formspec)
	return itemstack
end



books.on_player_receive_fields = function(player, formname, fields)
	if formname ~= "books:book_formspec" then return end
	local inv = player:get_inventory()
	local stack = player:get_wielded_item()
	local pos = player:get_pos()

	if fields.save and fields.title and fields.text
			and fields.title ~= "" and fields.text ~= "" then
		local new_stack, data
		if stack:get_name() ~= "books:book_written" then
			local count = stack:get_count()
			if count == 1 then
				stack:set_name("books:book_written")
			else
				stack:set_count(count - 1)
				new_stack = ItemStack("books:book_written")
			end
		else
			data = stack:get_meta():to_table().fields
		end

		if data and data.owner and data.owner ~= player:get_player_name() then
			return
		end

		if not data then data = {} end

		data.title = fields.title:sub(1, MAX_TITLE_SIZE)
		data.owner = player:get_player_name()
		local short_title = data.title
		-- Don't bother triming the title if the trailing dots would make it longer
		if #short_title > SHORT_TITLE_SIZE + 3 then
			short_title = short_title:sub(1, SHORT_TITLE_SIZE) .. "..."
		end
		data.description = "\"" .. short_title .. "\" By <"..rename.gpn(data.owner) .. ">"
		data.text = fields.text:sub(1, MAX_TEXT_SIZE)
		data.page = 1
		data.page_max = math.ceil((#data.text:gsub("[^\n]", "") + 1) / lpp)

		-- Encrypt the new text.
		data.iv = ossl.geniv()
		local enc = ossl.encrypt(data.iv, data.text)
		if enc then
			data.text = enc
		else
			data.iv = nil
		end

		if new_stack then
			new_stack:get_meta():from_table({ fields = data })
			if inv:room_for_item("main", new_stack) then
				inv:add_item("main", new_stack)
			else
				minetest.add_item(player:get_pos(), new_stack)
			end
		else
			stack:get_meta():from_table({ fields = data })
		end

		minetest.sound_play("book_write", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)

	elseif fields.book_next or fields.book_prev then
		local data = stack:get_meta():to_table().fields
		if not data or not data.page then
			return
		end

		data.page = tonumber(data.page)
		data.page_max = tonumber(data.page_max)

		if fields.book_next then
			data.page = data.page + 1
			if data.page > data.page_max then
				data.page = 1
			end
		else
			data.page = data.page - 1
			if data.page == 0 then
				data.page = data.page_max
			end
		end

		stack:get_meta():from_table({fields = data})
		stack = books.book_on_use(stack, player)

		minetest.sound_play("book_turn", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	elseif fields.quit then
		minetest.sound_play("book_close", {pos = pos, gain = 0.1, max_hear_distance = 16}, true)
	end

	-- Update stack
	player:set_wielded_item(stack)
end



books.on_craft = function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= "books:book_written" then
		return
	end

	local original
	local index
	for i = 1, player:get_inventory():get_size("craft") do
		if old_craft_grid[i]:get_name() == "books:book_written" then
			original = old_craft_grid[i]
			index = i
		end
	end
	if not original then
		return
	end
	local copymeta = original:get_meta():to_table()

	-- Re-encrypt the data with a different IV.
	if copymeta.fields and copymeta.fields.iv and copymeta.fields.iv ~= "" then
		local newiv = ossl.geniv()
		local enc
		local dec = ossl.decrypt(copymeta.fields.iv, copymeta.fields.text)
		if dec then
			enc = ossl.encrypt(newiv, dec)
		end
		if enc then
			copymeta.fields.iv = newiv
			copymeta.fields.text = enc
		end
	end

	-- copy of the book held by player's mouse cursor
	itemstack:get_meta():from_table(copymeta)

	-- put the book with metadata back in the craft grid
	craft_inv:set_stack("craft", index, original)
end


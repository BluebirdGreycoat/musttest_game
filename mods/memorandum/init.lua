
-- File shall be reloadable.
memorandum = memorandum or {}
memorandum.modpath = minetest.get_modpath("memorandum")



local collisionbox_sheet = {
	-1/2,   -- Left.
	-1/2,   -- Bottom.
	-1/2,   -- Front.
	1/2,    -- Right.
	-7/16,  -- Top.
	1/2,    -- Back.
}

local collisionbox_glass = {
	-1/4,   -- Left.
	-1/2,   -- Bottom.
	-1/4,   -- Front.
	1/4,    -- Right.
	4/10,   -- Top.
	1/4,    -- Back.
}

local param2_walldirections = {
		8,     -- South.
		17,    -- West.
		6,     -- North.
		15,    -- East.
}



-- Check if player may interact with memorandum at a location.
memorandum.is_protected = function(pos, name)
	local nn = minetest.get_node(pos).name
	if nn == "memorandum:letter_written" or nn == "memorandum:message" then -- Special nodes. Author may always dig/place/interact.
		local meta = minetest.get_meta(pos)
		local author = meta:get_string("signed") or ""
		if author == name then
			return -- Not protected if player is the author.
		end
	end
	return minetest.test_protection(pos, name)
end



-- Extract information from itemstack meta.
memorandum.extract_metainfo = function(text)
	local newformat = false
	if string.find(text, ":JSON$") then
		newformat = true
	end
    
	if newformat == true then
		text = string.gsub(text, ":JSON$", "")
		local data = minetest.parse_json(text)

		-- Ensure all parameters exist, or chose defaults.
		data = data or {}
		data.message = data.message or ""
		data.author = data.author or ""

		return data
	else
		-- Deserialize according to the old format.
		-- This allows us to support old memorandum items in the world.
		local scnt = string.sub(text, -2, -1)
		local mssg = ""
		local sgnd = ""

		if scnt == "00" then
			mssg = string.sub(text, 1, -3)
			sgnd = ""
		elseif tonumber(scnt) == nil then -- to support previous versions
			mssg = string.sub(text, 37, -1)
			sgnd = ""
		else
			mssg = string.sub(text, 1, -scnt -3)
			sgnd = string.sub(text, -scnt-2, -3)
		end

		return {message=mssg, author=sgnd}
	end
end



-- Serialize info from metadata into a string.
memorandum.insert_metainfo = function(meta)
	local message = meta:get_string("text") or ""
	local author = meta:get_string("signed") or ""
	local serialized = minetest.write_json({message=message, author=author})
	-- Tag string as JSON data. The now-depreciated data format can never have this string at the end.
	-- This means we can use it to determine if data is in the old format or the new format, when loading.
	serialized = serialized .. ":JSON"
	return serialized
end



-- API function. Intended to be used to generate a string that
-- can be used as metadata, when creating a memorandum itemstack.
-- This is called from the Email-GUI mod, for instance.
memorandum.compose_metadata = function(data)
  local message = data.text or ""
  local author = data.signed or ""
  local serialized = minetest.write_json({message=message, author=author})
  serialized = serialized .. ":JSON"
  return serialized
end



-- Player has right-clicked a memorandum node.
memorandum.on_rightclick = function(pos, node, clicker, itemstack, pt)
	local pname = clicker:get_player_name()
	local meta = minetest.get_meta(pos)
	local info = {
		text = meta:get_string("text"),
		signed = meta:get_string("signed"),
		edit = meta:get_int("edit"),
	}
	local formspec = memorandum.get_formspec(info)
	local tag = minetest.pos_to_string(pos)
	if memorandum.check_explosive_runes(pname, pos, info.signed, info.text) then
		-- Prevent repeat explosion.
		minetest.remove_node(pos)
	end
	minetest.show_formspec(pname, "memorandum:main_" .. tag, formspec)
end



memorandum.on_player_receive_fields = function(player, formname, fields)
	if string.sub(formname, 1, 16) ~= "memorandum:main_" then
		return
	end

	local tag = string.sub(formname, 17)
	local pos = minetest.string_to_pos(tag)
	if not pos then
		return true
	end

	-- Delegate fields to the appropriate input function.
	local node = minetest.get_node(pos)
	if node.name == "memorandum:letter_written" then
		memorandum.on_letter_written_input(pos, fields, player)
	elseif node.name == "memorandum:letter_empty" then
		memorandum.on_letter_empty_input(pos, fields, player)
	end

	return true
end



-- Obtain a formspec string. Possible formspecs are "write", "edit", and "view".
memorandum.get_formspec = function(info)
	if info.edit == 2 then
		-- Obtain formspec which allows writing.
		local formspec = "size[10,5]" ..
			default.gui_bg ..
			default.gui_slots ..
			default.gui_bg_img ..
			"label[0,0;Write letter below.]" ..
			"textarea[0.3,0.5;10,3;text;;" .. minetest.formspec_escape(info.text) .. "]" ..
			"field[0.3,4.3;4,1;signed;Sign Letter (Optional);" .. minetest.formspec_escape(info.signed) .. "]" ..
			"item_image[7,4;1,1;default:paper]" ..
			"button_exit[8,4;2,1;done;Done]"
		-- ^^^ Edit formspec field names are used, `text` & `signed`.
		-- The other formspecs *must not* use these fieldnames.

		return formspec
	elseif info.edit == 0 then
		-- Obtain formspec which allows viewing.
		local formspec = "size[10,8]" ..
			default.gui_bg ..
			default.gui_slots ..
			default.gui_bg_img ..
			"label[0,0;On this sheet of paper is written a message:]" ..
			"textarea[0.3,1;10,6;letter;;" .. minetest.formspec_escape(info.text) .. "]" ..
			"item_image[7,7;1,1;memorandum:letter]" ..
			"button_exit[8,7;2,1;exit;Close]" ..
			"label[0,7.3;Letters can be edited with an eraser.]"

		if type(info.signed) == "string" and info.signed ~= "" then
			formspec = formspec .. "label[0,7;Signed by <" .. minetest.formspec_escape(info.signed) .. ">]"
		else
			formspec = formspec .. "label[0,7;Letter is not signed.]"
		end

		return formspec
	elseif info.edit == 1 then
		-- Obtain 'edit' formspec (this formspec does not actually handle edit permissions).
		local formspec = "size[10,5]" ..
			default.gui_bg ..
			default.gui_slots ..
			default.gui_bg_img ..
			"label[0,0;Edit letter below:]" ..
			"textarea[0.3,0.5;10,3;text;;" .. minetest.formspec_escape(info.text) .. "]" ..
			"field[0.3,4.3;4,1;signed;Edit Signature;" .. minetest.formspec_escape(info.signed) .. "]" ..
			"item_image[7,4;1,1;memorandum:letter]" ..
			"button_exit[8,4;2,1;exit;Done]"
		-- ^^^ Edit formspec field names are used, `text` & `signed`.
		-- The other formspecs *must not* use these fieldnames.

		return formspec
	end

	return ""
end



-- This is called when default paper is converted to memorandum (an in-world node).
memorandum.on_paper_initialize = function(itemstack, placer, pointed_thing)
	if not placer then return end
	if not placer:is_player() then return end

	-- Pass-through rightclicks if target node defines it.
	-- This mimics the behavior of `minetest.item_place()`.
	if pointed_thing.type == "node" then
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		if node.name ~= "ignore" then
			local ndef = minetest.registered_nodes[node.name]
			if ndef and ndef.on_rightclick then
				return ndef.on_rightclick(under, node, placer, itemstack, pointed_thing)
			end
		end
	end

	local above = pointed_thing.above

	-- Ensure we are replacing air.
	if minetest.get_node(above).name ~= "air" then return end

	-- Do not place empty paper if protected.
	if memorandum.is_protected(above, placer:get_player_name()) then
		return
	end

	-- Place empty letter in world.
	local under = pointed_thing.under
	local facedir = minetest.dir_to_facedir(placer:get_look_dir())
	if (above.x ~= under.x) or (above.z ~= under.z) then
		minetest.set_node(above, {name="memorandum:letter_empty", param2=param2_walldirections[facedir+1]})
	else
		minetest.set_node(above, {name="memorandum:letter_empty", param2=facedir})
	end

	dirtspread.on_environment(above)
	droplift.notify(above)

	itemstack:take_item()
	return itemstack
end



-- This is called when memorandum is initialized into an in-world node state.
memorandum.on_letter_empty_initialize = function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "A Sheet of Paper")
	meta:set_int("edit", 2) -- 2 means write new letter (previously blank).
	meta:mark_as_private("edit")
end



-- Called when an empty letter receives formspec data.
memorandum.on_letter_empty_input = function(pos, fields, sender)
	if not (fields.text and fields.signed) then return end
	if fields.text == "" then return end -- If no text was received, the letter remains empty.

	-- Do not allow player to edit memorandum if protected.
	if memorandum.is_protected(pos, sender:get_player_name()) then
		minetest.chat_send_player(sender:get_player_name(), "# Server: This memorandum cannot be written.")
		return
	end

	-- Player does not need an eraser to write on blank paper,
	-- so no check to see if player is wielding eraser.

	local facedir = minetest.get_node(pos).param2
	minetest.add_node(pos, {name="memorandum:letter_written", param2=facedir})

	local meta = minetest.get_meta(pos)
	meta:set_string("text", fields.text)
	meta:set_string("signed", fields.signed)
	meta:set_string("owner", sender:get_player_name()) -- Record REAL author.
	meta:set_int("edit", 0)
	meta:set_string("infotext", "A Sheet of Paper (Written)")
	meta:mark_as_private({"text", "signed", "edit", "owner"})
end



-- Called when an already-written letter (existing as a node) receives fields from user.
-- This only happens when the letter is to be edited.
memorandum.on_letter_written_input = function(pos, fields, sender)
	if not sender then return end
	if not sender:is_player() then return end

	-- These fields can only be set in the presence of an enabled editing formspec.
	-- The viewing formspecs do not have these fields.
	if not fields.text then return end
	if not fields.signed then return end

	local sendername = sender:get_player_name()
	local item = sender:get_wielded_item()
	if not item then return end
	if item:get_name() ~= "memorandum:eraser" then
		minetest.chat_send_player(sendername, "# Server: You are not wielding an eraser.")
		return
	end

	-- Do not edit memorandum if protected.
	if memorandum.is_protected(pos, sendername) then
		minetest.chat_send_player(sendername, "# Server: Memorandum is protected.")
		return
	end

	local meta = minetest.get_meta(pos)
	local signer = meta:get_string("signed")

	-- Don't allow letter to be modified if signer is not player and signer isn't blank.
	-- We need this check to prevent a situation in which a second player edits a letter that
	-- was erased by a first player. However, two or more players can still edit a letter that isn't signed by any of them.
	if not (rename.grn(signer) == sendername or signer == "") then
		minetest.chat_send_player(sendername, "# Server: This paper is guarded by its signature.")
		return
	end

	if meta:get_int("edit") ~= 1 then
		minetest.chat_send_player(sendername, "# Server: Letter was not being edited! It cannot be changed now.")
		return
	end

	if fields.text == "" then
		-- If the letter was erased, replace it with an empty letter.
		-- This, if dug, converts back to default paper.
		local facedir = minetest.get_node(pos).param2
		minetest.swap_node(pos, {name="memorandum:letter_empty", param2=facedir})
		meta:set_string("infotext", "A Sheet of Paper")
		meta:set_int("edit", 2) -- Means may be edited again as if fresh paper.
	else
		meta:set_string("infotext", "A Sheet of Paper (Written)")
		meta:set_int("edit", 0)
	end

	meta:set_string("text", fields.text)
	meta:set_string("signed", fields.signed)
	meta:set_string("owner", sendername)
	meta:mark_as_private({"text", "signed", "edit"})

	minetest.chat_send_player(sendername, "# Server: Memorandum successfully edited.")
end



-- Called when an empty letter is dug, in which case it should convert back to default paper.
memorandum.on_letter_empty_dig = function(pos, node, digger)
	if not digger then return end
	if not digger:is_player() then return end

	-- Do not dig empty paper if protected.
	if memorandum.is_protected(pos, digger:get_player_name()) then
		return
	end

	local inv = digger:get_inventory()
	inv:add_item("main", {name="default:paper", count=1, wear=0, metadata=""})
	minetest.remove_node(pos)
end



-- Called when a written letter craftitem needs to show a formspec with the letter's contents.
memorandum.show_message_formspec = function(player, message, author)
	minetest.show_formspec(player, "memorandum:reading", memorandum.get_formspec({signed=author, text=message, edit=0}))
end



-- Called when a written letter is 'used' while held as a craftitem.
-- It should show a formspec to the player displaying the letter's contents.
memorandum.on_letter_item_use = function(itemstack, user, pointed_thing)
	if not user then return end
	if not user:is_player() then return end

	local text = itemstack:get_metadata()
	local data = memorandum.extract_metainfo(text)
	local player = user:get_player_name()

	if memorandum.check_explosive_runes(player, user:get_pos(), data.author, data.message) then
		itemstack:take_item()
	end

	memorandum.show_message_formspec(player, data.message, data.author)
	return itemstack
end



-- Called when a written letter craftitem is to be placed in the world.
memorandum.on_letter_item_place = function(itemstack, placer, pointed_thing)
	if not placer then return end
	if not placer:is_player() then return end

	-- Pass-through rightclicks if target node defines it.
	-- This mimics the behavior of `minetest.item_place()`.
	if pointed_thing.type == "node" then
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		if node.name ~= "ignore" then
			local ndef = minetest.registered_nodes[node.name]
			if ndef and ndef.on_rightclick then
				return ndef.on_rightclick(under, node, placer, itemstack, pointed_thing)
			end
		end
	end

	-- We specifically allow players to place written letters in other player's protected areas.
	-- This allows players to post messages to each other without requiring mailboxes.
	-- Note that no one will be able to dig the letter except the owner of the area, or the player who placed it.

	local above = pointed_thing.above
	local under = pointed_thing.under
	local facedir = minetest.dir_to_facedir(placer:get_look_dir())

	-- Ensure we are replacing air.
	if minetest.get_node(above).name ~= "air" then return end

	if (above.x ~= under.x) or (above.z ~= under.z) then
		minetest.add_node(above, {name="memorandum:letter_written", param2=param2_walldirections[facedir+1]})
	else
		minetest.add_node(above, {name="memorandum:letter_written", param2=facedir})
	end

	local text = itemstack:get_metadata()
	local data = memorandum.extract_metainfo(text)
	local meta = minetest.get_meta(above)
	meta:set_string("infotext", "A Sheet of Paper (Written)")
	meta:set_string("text", data.message)
	meta:set_string("signed", data.author)
	meta:mark_as_private({"text", "signed"})

	itemstack:take_item()
	return itemstack
end



-- Called when a written letter (existing as a node) is being dug.
memorandum.on_letter_written_dig = function(pos, node, digger)
	if not digger then return end
	if not digger:is_player() then return end

	-- Do not remove memorandum if protected.
	if memorandum.is_protected(pos, digger:get_player_name()) then
		return
	end

	local meta = minetest.get_meta(pos)
	local serialized = memorandum.insert_metainfo(meta)

	local item = digger:get_wielded_item()
	local inv = digger:get_inventory()

	-- If dug using a glass bottle, put the letter in the bottle.
	-- Otherwise, the letter becomes a regular craftitem.
	if item:get_name() == "vessels:glass_bottle" then
		inv:remove_item("main", "vessels:glass_bottle")
		inv:add_item("main", {name="memorandum:message", count=1, wear=0, metadata=serialized})
	else
		inv:add_item("main", {name="memorandum:letter", count=1, wear=0, metadata=serialized})
	end

	minetest.remove_node(pos)
end



-- Wear out an eraser on each use.
memorandum.add_eraser_wear = function(itemstack, user, pointed_thing, uses)
	itemstack:add_wear(65535/(uses-1))
	return itemstack
end



-- Called when an eraser is used.
memorandum.on_eraser_use = function(itemstack, user, pointed_thing)
	if not user then return end
	if not user:is_player() then return end
	if not pointed_thing.under then return end

	local pos = pointed_thing.under
	local node = minetest.get_node(pos)
	local player = user:get_player_name()

	-- Do not erase memorandum if protected.
	if memorandum.is_protected(pos, player) then
		minetest.chat_send_player(player, "# Server: Memorandum is guarded against editing or erasure.")
		return
	end

	-- Ensure we are pointing at an erasable letter.
	if node.name ~= "memorandum:letter_written" then return end

	local meta = minetest.get_meta(pos)
	local signer = meta:get_string("signed")

	-- Don't allow letter to be modified if signer is not player and signer isn't blank.
	if not (rename.grn(signer) == player or signer == "") then
		minetest.chat_send_player(player, "# Server: This paper is guarded by its signature.")
		return
	end

	meta:set_int("edit", 1) -- 1 means edit already-written letter.
	meta:mark_as_private("edit")

	itemstack = memorandum.add_eraser_wear(itemstack, user, pointed_thing, 30)
	minetest.chat_send_player(player, "# Server: Memorandum may be edited. Rightclick to edit, press 'Done' to confirm your edits.")
	return itemstack
end



-- Called when message-in-a-bottle is used.
memorandum.on_message_use = function(itemstack, user, pointed_thing)
	if not user then return end
	if not user:is_player() then return end
	if not pointed_thing.under then return end

	local pos = pointed_thing.above
	if minetest.get_node(pos).name ~= "air" then return end

	-- We specifically allow players to place written letters in other player's protected areas.
	-- This allows players to post messages to each other without requiring mailboxes.
	-- Note that no one will be able to dig the letter except the owner of the area, or the player who placed it.

	minetest.add_node(pos, {name="memorandum:letter_written", param2=math.random(0, 3)})

	local text = itemstack:get_metadata()
	local data = memorandum.extract_metainfo(text)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "A Sheet of Paper (Written)")
	meta:set_string("text", data.message)
	meta:set_string("signed", data.author)
	meta:mark_as_private({"text", "signed"})

	itemstack:take_item()
	user:get_inventory():add_item("main", {name="vessels:glass_bottle", count=1, wear=0, metadata=""})
	return itemstack
end



-- Called when message-in-a-bottle is placed.
memorandum.on_message_place = function(itemstack, placer, pointed_thing)
	if not placer then return end
	if not placer:is_player() then return end

	-- Pass-through rightclicks if target node defines it.
	-- This mimics the behavior of `minetest.item_place()`.
	if pointed_thing.type == "node" then
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		if node.name ~= "ignore" then
			local ndef = minetest.registered_nodes[node.name]
			if ndef and ndef.on_rightclick then
				return ndef.on_rightclick(under, node, placer, itemstack, pointed_thing)
			end
		end
	end

	local pos = pointed_thing.above
	if minetest.get_node(pos).name ~= "air" then return end

	-- We specifically allow players to place written letters in other player's protected areas.
	-- This allows players to post messages to each other without requiring mailboxes.
	-- Note that no one will be able to dig the letter except the owner of the area, or the player who placed it.

	minetest.set_node(pos, {name="memorandum:message"})

	local text = itemstack:get_metadata()
	local data = memorandum.extract_metainfo(text)
	local meta = minetest.get_meta(pos)
	meta:set_string("text", data.message)
	meta:set_string("signed", data.author)
	meta:set_string("infotext", "Bottle With Message")
	meta:mark_as_private({"text", "signed"})

	dirtspread.on_environment(pos)
	droplift.notify(pos)

	itemstack:take_item()
	return itemstack
end



-- Called when message-in-a-bottle is being dug.
memorandum.on_message_dig = function(pos, node, digger)
	if not digger then return end
	if not digger:is_player() then return end

	-- Do not allow dig if protected.
	-- The author of the message may always dig.
	if memorandum.is_protected(pos, digger:get_player_name()) then
		return
	end

	local meta = minetest.get_meta(pos)
	local serialized = memorandum.insert_metainfo(meta)

	local inv = digger:get_inventory()
	inv:add_item("main", {name="memorandum:message", count=1, wear=0, metadata=serialized})
	minetest.remove_node(pos)
end



-- Running gag.
function memorandum.check_explosive_runes(pname, pos, author, text)
	-- Validate arguments.
	if type(pname) ~= "string" or type(pos) ~= "table" or type(author) ~= "string" or type(text) ~= "string" then
		return
	end

	-- Explosive runes never explode on the writer.
	if pname == author then
		return
	end

	text = text:lower()
	if text:find("explosive") and text:find("rune") then
		local p = vector.round({x=pos.x, y=pos.y, z=pos.z})
		local d = {
			radius = math.random(1, math.random(1, 4)),
			damage_radius = math.random(5, 15),
			ignore_protection = false,
			disable_drops = true,
			ignore_on_blast = false,
		}
		local t = math.floor(text:len() / 10)
		minetest.after((t / 2.0), function() minetest.sound_play("tnt_ignite", {pos = pos}) end)
		minetest.after(t, function() tnt.boom(p, d) end)

		-- Indicates the memorandum should be removed.
		-- Either from player's inventory, or from the world if placed as a node.
		-- If memorandum would explode, we must always remove it to prevent a repeat.
		return true
	end
end



-- Code which runs only on first load.
if not memorandum.run_once then
	-- Allow paper to be placed in the world, as an empty letter node.
	minetest.override_item("default:paper", {
		on_place = function(...) return memorandum.on_paper_initialize(...) end,
	})
    
	-- An empty letter is the intermediate state between default paper and a written letter.
	-- Note that the empty letter can exist only as a node, if dug it reverts to default paper.
	minetest.register_node("memorandum:letter_empty", {
		drawtype = "nodebox",
		tiles = {
			"memorandum_letter_empty.png",
			"memorandum_letter_empty.png^[transformFY" -- mirror
		},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "fixed",
			fixed = collisionbox_sheet,
		},
		groups = utility.dig_groups("item", {not_in_creative_inventory=1}),
		sounds = default.node_sound_leaves_defaults(),

		on_construct = function(...) return memorandum.on_letter_empty_initialize(...) end,
		on_rightclick = function(...) return memorandum.on_rightclick(...) end,
		on_dig = function(...) return memorandum.on_letter_empty_dig(...) end,
	})

	-- A written letter craftitem. Can be read.
	minetest.register_craftitem("memorandum:letter", {
		description = "Written Letter",
		inventory_image = "default_paper.png^memorandum_letters.png",
		stack_max = 1,
		groups = {not_in_creative_inventory=1},

		on_use = function(...) return memorandum.on_letter_item_use(...) end,
		on_place = function(...) return memorandum.on_letter_item_place(...) end,
	})

	-- A written letter, in-world node version.
	-- The in-world node version can be edited using an eraser, in addition to being read.
	minetest.register_node("memorandum:letter_written", {
		drawtype = "nodebox",
		tiles = {
			"memorandum_letter_empty.png^memorandum_letter_text.png",
			"memorandum_letter_empty.png^[transformFY" -- mirror
		},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "fixed",
			fixed = collisionbox_sheet
		},
		groups = utility.dig_groups("item", {not_in_creative_inventory=1}),
		sounds = default.node_sound_leaves_defaults(),

		on_rightclick = function(...) return memorandum.on_rightclick(...) end,
		on_dig = function(...) return memorandum.on_letter_written_dig(...) end,
	})

	-- An eraser, used to edit letters than have already been written.
	minetest.register_tool("memorandum:eraser", {
		description = "Writing Eraser",
		inventory_image = "memorandum_eraser.png",
		wield_image = "memorandum_eraser.png^[transformR90",
		wield_scale = {x = 0.5, y = 0.5, z = 1},
		groups = {not_repaired_by_anvil = 1},

		on_use = function(...) return memorandum.on_eraser_use(...) end,
	})

	-- Message-in-a-bottle. This is created by digging a written letter node while wielding a glass vessel.
	minetest.register_node("memorandum:message", {
		description = "Message In A Bottle",
		drawtype = "plantlike",
		tiles = {"vessels_glass_bottle.png^memorandum_message.png"},
		inventory_image = "vessels_glass_bottle.png^memorandum_message.png",
		wield_image = "vessels_glass_bottle.png^memorandum_message.png",
		paramtype = "light",
		selection_box = {
			type = "fixed",
			fixed = collisionbox_glass,
		},
		stack_max = 1,
		walkable = false,
		groups = utility.dig_groups("item", {vessel=1, attached_node=1, not_in_creative_inventory=1}),
		movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
		--sounds = default.node_sound_glass_defaults(),

		on_use = function(...) return memorandum.on_message_use(...) end,
		on_place = function(...) return memorandum.on_message_place(...) end,
		on_dig = function(...) return memorandum.on_message_dig(...) end,
	})

	if minetest.get_modpath("farming") ~= nil then
		minetest.register_craft({
			type = "shapeless",
			output = "memorandum:eraser",
			recipe = {"farming:bread"},
		})
	end
	if minetest.get_modpath("candles") ~= nil then
		minetest.register_craft({
			type = "shapeless",
			output = "memorandum:eraser",
			recipe = {"candles:wax"},
		})
	end
	if minetest.get_modpath("bees") ~= nil then
		minetest.register_craft({
			type = "shapeless",
			output = "memorandum:eraser",
			recipe = {"bees:honey_comb"},
		})
	end
	if minetest.get_modpath("technic") ~= nil then
		minetest.register_craft({
			type = "shapeless",
			output = "memorandum:eraser",
			recipe = {"technic:raw_latex"},
		})
	end

	minetest.register_on_player_receive_fields(function(...)
		return memorandum.on_player_receive_fields(...)
	end)

	-- Reloadable.
	local name = "memorandum:core"
	local file = memorandum.modpath .. "/init.lua"
	reload.register_file(name, file, false)

	memorandum.run_once = true
end






-- Player contexts.
safe.players = safe.players or {}

-- Inventory passwords. Needed so inventory contents can be decrypted as long as
-- an inventory is open. Transient usage only. Separate from player contexts
-- because these have a different lifetime.
safe.passwords = safe.passwords or {}



function safe.gen_invname(pos, pname)
	return "safe:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ":" .. pname
end



function safe.is_valid_node(pos)
	local name = minetest.get_node(pos).name

	for k, v in pairs(safe.safe_nodes) do
		if k == name then
			return true
		end
	end
end



-- Mainly used to prevent safe nodes from being trashed.
-- Also prevents safes from being stored recursively, which would be bad.
function safe.is_safe_name(name)
	for k, v in pairs(safe.safe_nodes) do
		if k == name then
			return true
		end
	end
end



function safe.encrypt_inv_location(meta, pos, inv, list, idx)
	local stack = inv:get_stack(list, idx)
	local str = stack:to_string()
	local hash = minetest.hash_node_position(pos)

	assert(safe.passwords[hash])
	local password = safe.passwords[hash]
	assert(type(password) == "string")

	local encoded = ""
	local encrypted = 0

	if stack:get_count() > 0 and str ~= "" then
		local enc = safe.encrypt(password, str)
		if enc then
			encoded = enc
			encrypted = 1
		end
	end

	meta:set_string("item" .. idx, encoded)
	meta:set_int("item" .. idx .. "iv", encrypted)
	meta:mark_as_private({"item" .. idx, "item" .. idx .. "iv"})
end



function safe.get_inventory_callbacks(ndef, pname)
	return {
		-- Pile of security and safety checks.
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local pn = player:get_player_name()
			if pn ~= pname then
				return 0
			end
			local ctx = safe.players[pn]
			if not ctx then
				return 0
			end
			if ctx.locked then
				return 0
			end
			local pos = ctx.pos
			if not safe.is_valid_node(pos) then
				return 0
			end
			local hash = minetest.hash_node_position(pos)
			if not safe.passwords[hash] then
				return 0
			end
			if vector.distance(pos, player:get_pos()) > safe.INTERACTION_DISTANCE then
				return 0
			end
			if from_list ~= "main" or to_list ~= "main" then
				return 0
			end
			return count
		end,



		allow_put = function(inv, listname, index, stack, player)
			local pn = player:get_player_name()
			if pn ~= pname then
				return 0
			end
			local ctx = safe.players[pn]
			if not ctx then
				return 0
			end
			if ctx.locked then
				return 0
			end
			local pos = ctx.pos
			if not safe.is_valid_node(pos) then
				return 0
			end
			local hash = minetest.hash_node_position(pos)
			if not safe.passwords[hash] then
				return 0
			end
			if vector.distance(pos, player:get_pos()) > safe.INTERACTION_DISTANCE then
				return 0
			end
			if listname ~= "main" then
				return 0
			end
			-- Recursive storage protection.
			if safe.is_safe_name(stack:get_name()) then
				return 0
			end
			if not ndef._safe_allow_item(stack:get_name()) then
				return 0
			end
			return stack:get_count()
		end,



		allow_take = function(inv, listname, index, stack, player)
			local pn = player:get_player_name()
			if pn ~= pname then
				return 0
			end
			local ctx = safe.players[pn]
			if not ctx then
				return 0
			end
			if ctx.locked then
				return 0
			end
			local pos = ctx.pos
			if not safe.is_valid_node(pos) then
				return 0
			end
			local hash = minetest.hash_node_position(pos)
			if not safe.passwords[hash] then
				return 0
			end
			if vector.distance(pos, player:get_pos()) > safe.INTERACTION_DISTANCE then
				return 0
			end
			if listname ~= "main" then
				return 0
			end
			return stack:get_count()
		end,



		-- I encrypt inv locations peicemeal in order to provide robustness against
		-- a server crash. For the same reason, I also do this as soon as possible,
		-- whenever something changes, instead of waiting for the user to close the
		-- formspec.
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local pn = player:get_player_name()
			local ctx = safe.players[pn]
			local pos = ctx.pos
			local meta = minetest.get_meta(pos)
			safe.encrypt_inv_location(meta, pos, inv, to_list, to_index)
			safe.encrypt_inv_location(meta, pos, inv, from_list, from_index)
		end,



		on_put = function(inv, listname, index, stack, player)
			local pn = player:get_player_name()
			local ctx = safe.players[pn]
			local pos = ctx.pos
			local meta = minetest.get_meta(pos)
			safe.encrypt_inv_location(meta, pos, inv, listname, index)
		end,



		on_take = function(inv, listname, index, stack, player)
			local pn = player:get_player_name()
			local ctx = safe.players[pn]
			local pos = ctx.pos
			local meta = minetest.get_meta(pos)
			safe.encrypt_inv_location(meta, pos, inv, listname, index)
		end,
	}
end



-- Why do I use a detached inventory here? It's because regular node inventories
-- are sent to all nearby players. Not secure! I need to make sure the inventory
-- is only sent to the player who is actually supposed to be accessing the safe.
function safe.load_detached_inventory(pos, pname)
	local invname = safe.gen_invname(pos, pname)
	if not minetest.get_inventory({type="detached", name=invname}) then
		local co = safe.MESSAGE_COLOR
		minetest.chat_send_player(pname, co .. "# Server: Accessing secure inventory ...")

		local ndef = minetest.registered_nodes[minetest.get_node(pos).name]
		local cb = safe.get_inventory_callbacks(ndef, pname)
		local inv = minetest.create_detached_inventory(invname, cb, pname)
		inv:set_size("main", ndef._safe_inventory_size)

		local hash = minetest.hash_node_position(pos)
		assert(safe.passwords[hash])
		local password = safe.passwords[hash]
		assert(type(password) == "string")

		-- Populate the detached inventory.
		local meta = minetest.get_meta(pos)
		for k = 1, ndef._safe_inventory_size do
			local s = meta:get_string("item" .. k)
			local e = meta:get_int("item" .. k .. "iv")
			if s ~= "" then
				-- Decrypt if encrypted.
				if e == 1 then
					s = safe.decrypt(password, s)
				end

				if s and s ~= "" then
					local stack = ItemStack(s)
					inv:set_stack("main", k, stack)
				else
					-- Warn the user, for what it's worth (i.e., not much).
					local c = safe.MESSAGE_COLOR
					minetest.chat_send_player(pname, c ..
						"# Server: Error: could not decrypt stack at index " .. k ..
						". Possible corruption?")
				end
			end
		end
	end
end



function safe.change_inventory_password(pos, oldpass, newpass)
	local t = {}
	local meta = minetest.get_meta(pos)
	local ndef = minetest.registered_nodes[minetest.get_node(pos).name]
	local hash = minetest.hash_node_position(pos)

	-- Safety check. We CANNOT have a password resident in memory.
	assert(not safe.passwords[hash])

	-- Load inventory with old password.
	for k = 1, ndef._safe_inventory_size do
		local s = meta:get_string("item" .. k)
		local e = meta:get_int("item" .. k .. "iv")

		if s ~= "" and e == 1 then
			local ns = safe.decrypt(oldpass, s)
			if ns then
				s = ns
			else
				-- Failure to decrypt means we have to clear this slot.
				s = ""
				e = 0
			end
		end

		t[#t + 1] = {data=s, enc=e}
	end

	-- Encrypt stuff.
	for k, v in ipairs(t) do
		-- Skip trying to encrypt empty slots.
		if v.data ~= "" then
			local s = safe.encrypt(newpass, v.data)
			if s then
				v.data = s
				v.enc = 1
			else
				v.enc = 0
			end
		else
			v.enc = 0
		end
	end

	-- Write inventory with new password.
	for k, v in ipairs(t) do
		meta:set_string("item" .. k, v.data)
		meta:set_int("item" .. k .. "iv", v.enc)
		meta:mark_as_private({"item" .. k, "item" .. k .. "iv"})
	end
end



function safe.get_formspec(pos, pname)
  local defgui = default.gui_bg .. default.gui_bg_img .. default.gui_slots

  local formspec
  local meta = minetest.get_meta(pos)
  local owner = meta:get_string("owner")
  local locked = false

  if meta:get_int("locked") == 1 then
		locked = true
	end

	-- This can happen if the server shut down while safes were open.
	local hash = minetest.hash_node_position(pos)
	if not safe.passwords[hash] then
		safe.lock_safe(pos, pname)
		locked = true
	end

  if locked then
		-- Locked formspec.
		local ndef = minetest.registered_nodes[minetest.get_node(pos).name]
		local cn = ndef._safe_common_name

		if pname == owner then
			formspec = "size[3.4,5.1]" .. defgui .. "real_coordinates[true]" ..
				"label[1.1,1.1;Enter Password]" ..
				"pwdfield[1.1,1.4;2.5,0.5;pin_entry;]" ..
				"button_exit[1.1,2.0;2.5,0.5t;unlock_safe;Unlock " .. cn .. "]" ..
				"label[1.1,3.1;Change Password]" ..
				"label[0.4,3.65;Old]" ..
				"label[0.4,4.25;New]" ..
				"label[0.4,4.85;New]" ..
				"pwdfield[1.1,3.4;2.5,0.5;old_password;]" ..
				"pwdfield[1.1,4.0;2.5,0.5;new_password;]" ..
				"pwdfield[1.1,4.6;2.5,0.5;confirm_password;]" ..
				"button_exit[1.1,5.2;2.5,0.5;change_pwd;Change]"
		else
			formspec = "size[3.4,2.0]" .. defgui .. "real_coordinates[true]" ..
				"label[1.1,1.1;Enter Password]" ..
				"pwdfield[1.1,1.4;2.5,0.5;pin_entry;]" ..
				"button_exit[1.1,2.0;2.0,0.7;unlock_safe;Unlock " .. cn .. "]"
		end
  else
		-- Name of detached inventory.
		local invname = safe.gen_invname(pos, pname)
		safe.load_detached_inventory(pos, pname)

		local ndef = minetest.registered_nodes[minetest.get_node(pos).name]
		local cn = ndef._safe_common_name

		local w = ndef._safe_inventory_w
		local h = ndef._safe_inventory_h
		local pad = 0.25

		local restrict = "false"
		if meta:get_int("restrict_password") == 1 then
			restrict = "true"
		end

		-- The formspec math causes the formspec to change size vertically depending
		-- on the number of inventory rows in the safe. Formspec size doesn't follow
		-- new (real) coordinates.

		-- Unlocked formspec.
		formspec = "size[8," .. (h+6.1) .. "]" .. defgui .. "real_coordinates[true]" ..
			"button_exit[7.12," .. (h+0.5+(pad*h)) .. ";3.0,0.7;lock_safe;Lock " .. cn .. "]" ..
			"label[0.35," .. (h+0.6+(pad*h)) .. ";" .. minetest.formspec_escape("Secure Storage: owned by <" .. rename.gpn(owner) .. ">") .. "]" ..
			"list[detached:" .. invname .. ";main;0.35,0.5;" .. w .. "," .. h .. ";]" ..
			"list[current_player;main;0.35," .. (h+2.1+(pad*h)) .. ";8,1;]" ..
			"list[current_player;main;0.35," .. (h+3.5+(pad*h)) .. ";8,3;8]" ..
			"listring[detached:" .. invname .. ";main]" ..
			"listring[current_player;main]" ..
			default.get_hotbar_bg(0.35, (h+2.1+(pad*h)), true)

		-- Add some options for the owner.
		if pname == owner then
			formspec = formspec .. "checkbox[0.35," .. (h+1.0+(pad*h)) .. ";restrict_password;Restrict Password;" .. restrict .. "]"
		end
	end

	return formspec, locked
end



function safe.on_construct(pos)
end



function safe.on_destruct(pos)
	local hash = minetest.hash_node_position(pos)
	safe.passwords[hash] = nil

	-- If someone had this safe open, destroy their context.
	local delete_me = {}
	for pname, context in pairs(safe.players) do
		if vector.equals(context.pos, pos) then
			delete_me[pname] = context
		end
	end
	for pname, context in pairs(delete_me) do
		safe.players[pname] = nil
		minetest.close_formspec(pname, "safe:main")
		minetest.remove_detached_inventory(safe.gen_invname(context.pos, pname))
	end
end



function safe.on_blast(pos)
	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	if ndef._safe_is_blastable then
		local drops = {}
		drops[1] = ItemStack(ndef._safe_close_node)
		local metatable = minetest.get_meta(pos):to_table()
		safe.preserve_metadata(pos, node, metatable.fields, drops)
		minetest.remove_node(pos)
		return drops
	end
end



function safe.on_rightclick(pos, node, user, itemstack, pt)
	local pname = user:get_player_name()

	if not ossl.have_openssl then
		minetest.chat_send_player(pname, "# Server: Encrypted storage is not available because OpenSSL is missing.")
		return
	end

	-- No-go if player too far.
	if vector.distance(pos, user:get_pos()) > safe.INTERACTION_DISTANCE then
		return
	end

	-- No-go if the user already has a safe open.
	if safe.players[pname] then
		return
	end

	-- Well, duh. Need to check this too.
	if not safe.is_valid_node(pos) then
		return
	end
	local ndef = minetest.registered_nodes[minetest.get_node(pos).name]

	local meta = minetest.get_meta(pos)
	if meta:get_int("disable_time") >= os.time() then
		ambiance.sound_play("safe_abort", pos, 1.0, 20)
		return
	end

	-- The canary must exist and cannot be an empty string.
	if meta:get_string("canary") == "" then
		ambiance.sound_play("safe_abort", pos, 1.0, 20)
		return
	end

	-- The implementation of safes requires that only one person can use at a time.
	for k, v in pairs(safe.players) do
		if vector.equals(v.pos, pos) then
			local c = safe.MESSAGE_COLOR
			local cn = ndef._safe_common_name:lower()
			minetest.chat_send_player(pname, c .. "# Server: Someone else is using this " .. cn .. ".")
			return
		end
	end

	local form, locked = safe.get_formspec(pos, pname)
	safe.players[pname] = {pos = pos, locked = locked}
	minetest.show_formspec(pname, "safe:main", form)

	if not locked then
		ambiance.sound_play("safe_open", pos, 1.0, 20)
	end
end



function safe.encrypt(password, data)
	local s = ossl.encrypt({password=password, data=data})
	if s then
		s = ossl.encrypt(s)
	end
	return s
end



function safe.decrypt(password, data)
	local s = ossl.decrypt(data)
	if s then
		s = ossl.decrypt({password=password, data=s})
	end
	return s
end



function safe.after_place_node(pos, user, itemstack, pt)
	local pname = user:get_player_name()
	local meta = minetest.get_meta(pos)
	local ndef = minetest.registered_nodes[minetest.get_node(pos).name]

	-- Note: since the server is responsible for BOTH encryption and decryption,
	-- there is no way (that I know of) to design the system such that the server
	-- operator cannot know the access password. Thus, preventing admins from
	-- getting into your safes is NOT the goal of this code. This only protects
	-- you from other regular players and map hackers.
	--
	-- That being said, if we assume the server operator is a white hat, it still
	-- makes sense NOT to store the password in the map data, and to use the user's
	-- password to encrypt the data, so that even if anyone manages to obtain a
	-- copy of the map DB and the server's master key, they still won't be able to
	-- decrypt the safe contents without a brute force attack.
	--
	-- But keep in mind that as long as Minetest's network protocol is plaintext,
	-- this is all moot if you're being MITM'ed. And you're always being MITM'ed!
	--
	-- Historical note: MITM stands for Man-In-The-Middle. Certain members of
	-- society are trying to make it stand for Monster-In-The-Middle. Because use
	-- of the word "man" offends them, or ... something something SJW something.

	local oldmeta = itemstack:get_meta()
	if oldmeta:get_string("canary") ~= "" and oldmeta:get_string("owner") ~= "" then
		meta:from_table(oldmeta:to_table())
		meta:set_int("locked", 1)
		meta:mark_as_private({"owner", "canary", "locked", "disable_time"})

		for k = 1, ndef._safe_inventory_size do
			meta:mark_as_private({"item" .. k, "item" .. k .. "iv"})
		end

		-- Safe must be locked by default.
		local n = minetest.get_node(pos)
		n.name = ndef._safe_close_node
		minetest.swap_node(pos, n)

		safe.update_infotext(pos)
		return
	end

	-- New safe setup.
	meta:set_string("owner", pname)
	meta:set_string("canary", safe.encrypt("default", "encrypted") or "")
	meta:set_int("locked", 1)
	meta:mark_as_private({"owner", "canary", "locked"})

	local c = safe.MESSAGE_COLOR
	local cn = ndef._safe_common_name
	minetest.chat_send_player(pname, c .. "# Server: " .. cn .. "'s default password is: \"default\".")
	minetest.chat_send_player(pname, c .. "# Server: You need to set a new password.")

	-- Safe is locked after construction, by default.
	local n = minetest.get_node(pos)
	n.name = ndef._safe_close_node
	minetest.swap_node(pos, n)

	safe.update_infotext(pos)
end



function safe.on_punch(pos, node, user, pt)
	local meta = minetest.get_meta(pos)
	if meta:get_int("locked") == 0 then
		-- Can't lock a safe that is currently in use.
		for k, v in pairs(safe.players) do
			if vector.equals(v.pos, pos) then
				return
			end
		end

		safe.lock_safe(pos, user:get_player_name())
	end
end



function safe.can_dig(pos, user)
	local meta = minetest.get_meta(pos)
	local ndef = minetest.registered_nodes[minetest.get_node(pos).name]

	-- Note: I allow to dig a safe that's locked, because punching it always
	-- engages the lock.

	-- Check safe not currently disabled.
	if meta:get_int("disable_time") >= os.time() then
		return false
	end

	if not ndef._safe_allow_dig then
		-- Can't dig unless inventory is empty.
		for k = 1, ndef._safe_inventory_size do
			local s = meta:get_string("item" .. k)
			if s ~= "" then
				return false
			end
		end
	end

	-- Can't dig if someone is currently using it.
	for k, v in pairs(safe.players) do
		if vector.equals(v.pos, pos) then
			return false
		end
	end

	return true
end



function safe.update_infotext(pos)
	local meta = minetest.get_meta(pos)
	local locked = (meta:get_int("locked") == 1)
	local ndef = minetest.registered_nodes[minetest.get_node(pos).name]
	local cn = ndef._safe_common_name

	if locked then
		meta:set_string("infotext", "Locked " .. cn)
	else
		meta:set_string("infotext", "Open " .. cn)
	end
end



function safe.unlock_safe(pos, password)
	local meta = minetest.get_meta(pos)
	local hash = minetest.hash_node_position(pos)
	safe.passwords[hash] = nil

	if meta:get_int("locked") == 1 then
		meta:set_int("locked", 0)
		meta:mark_as_private("locked")
		safe.update_infotext(pos)

		-- Will be needed for encryption/decryption while the safe is unlocked.
		-- This is sensitive data. Transient only. Do not store in DB.
		safe.passwords[hash] = password

		local n = minetest.get_node(pos)
		local ndef = minetest.registered_nodes[n.name]
		n.name = ndef._safe_open_node
		minetest.swap_node(pos, n)

		ambiance.sound_play("safe_unlock", pos, 1.0, 20)
	end
end



function safe.lock_safe(pos, pname)
	local meta = minetest.get_meta(pos)
	local hash = minetest.hash_node_position(pos)
	safe.passwords[hash] = nil

	if meta:get_int("locked") == 0 then
		meta:set_int("locked", 1)
		meta:mark_as_private("locked")
		minetest.remove_detached_inventory(safe.gen_invname(pos, pname))
		safe.update_infotext(pos)

		local n = minetest.get_node(pos)
		local ndef = minetest.registered_nodes[n.name]
		n.name = ndef._safe_close_node
		minetest.swap_node(pos, n)

		ambiance.sound_play("safe_lock", pos, 1.0, 20)
	end
end



function safe.on_player_receive_fields(player, formname, fields)
	if formname ~= "safe:main" then
		return
	end

	local pname = player:get_player_name()
	local context = safe.players[pname]

	if not context then
		return true
	end

	local pos = context.pos
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	-- Interaction distance check.
	if vector.distance(pos, player:get_pos()) > safe.INTERACTION_DISTANCE then
		safe.players[pname] = nil
		return true
	end

	if not safe.is_valid_node(pos) then
		safe.players[pname] = nil
		return true
	end
	local ndef = minetest.registered_nodes[minetest.get_node(pos).name]

	-- Check safe not currently disabled.
	if meta:get_int("disable_time") >= os.time() then
		safe.players[pname] = nil
		ambiance.sound_play("safe_abort", pos, 1.0, 20)
		return true
	end

	if fields.lock_safe and not context.locked then
		safe.lock_safe(pos, pname)
		safe.players[pname] = nil

		ambiance.sound_play("safe_close", pos, 1.0, 20)
		return true
	end

	-- Player enters password to access the safe.
	if (fields.unlock_safe or fields.key_enter_field == "pin_entry") and context.locked then
		local pin = (type(fields.pin_entry) == "string" and fields.pin_entry) or ""
		local canary = safe.decrypt(pin, meta:get_string("canary"))

		-- If we could decrypt the canary correctly, we have the right password.
		-- But note! We also check if the password is restricted. If that doesn't
		-- pass, we tell the user exactly the same as if they got the password wrong.
		local may_access = (meta:get_int("restrict_password") == 0 or pname == owner)

		if canary and canary == "encrypted" and may_access then
			context.locked = false
			safe.unlock_safe(pos, pin)
			minetest.show_formspec(pname, "safe:main", safe.get_formspec(pos, pname))
			ambiance.sound_play("safe_open", pos, 1.0, 20)
		else
			safe.players[pname] = nil
			meta:set_int("disable_time", os.time() + 5)
			meta:mark_as_private("disable_time")
			local c = safe.MESSAGE_COLOR
			local cn = ndef._safe_common_name
			minetest.chat_send_player(pname, c .. "# Server: Wrong password. " .. cn .. " temporarily disabled.")
			ambiance.sound_play("safe_error", pos, 1.0, 20)
		end

		return true
	end

	if context.locked then
		if fields.key_enter_field == "old_password" then
			minetest.show_formspec(pname, "safe:main", safe.get_formspec(pos, pname))
			return true
		end

		if fields.key_enter_field == "new_password" then
			minetest.show_formspec(pname, "safe:main", safe.get_formspec(pos, pname))
			return true
		end

		if fields.key_enter_field == "confirm_password" then
			minetest.show_formspec(pname, "safe:main", safe.get_formspec(pos, pname))
			return true
		end
	end

	-- Only the owner can change the password restriction, and only while the safe is UNLOCKED.
	if fields.restrict_password and pname == owner and not context.locked then
		if fields.restrict_password == 'true' then
			meta:set_int("restrict_password", 1)
			meta:mark_as_private("restrict_password")
			local c = safe.MESSAGE_COLOR
			local cn = ndef._safe_common_name:lower()
			minetest.chat_send_player(pname, c .. "# Server: Only the owner may use the password to this " .. cn .. ".")
		elseif fields.restrict_password == 'false' then
			meta:set_int("restrict_password", 0)
			meta:mark_as_private("restrict_password")
			local c = safe.MESSAGE_COLOR
			local cn = ndef._safe_common_name:lower()
			minetest.chat_send_player(pname, c .. "# Server: Anyone with the password may access this " .. cn .. ".")
		end
		minetest.show_formspec(pname, "safe:main", safe.get_formspec(pos, pname))
		return true
	end

	-- Only the owner can change the password, and only while the safe is locked.
	-- Changing the password means we have to re-encrypt the whole inventory.
	if fields.change_pwd and pname == owner and context.locked then
		local color = safe.MESSAGE_COLOR
		local pin = (type(fields.old_password) == "string" and fields.old_password) or ""
		local canary = safe.decrypt(pin, meta:get_string("canary"))

		-- If we could decrypt the canary correctly, we have the right password.
		if canary and canary == "encrypted" then
			local newpass = (type(fields.new_password) == "string" and fields.new_password) or ""
			local cnfpass = (type(fields.confirm_password) == "string" and fields.confirm_password) or ""

			if #newpass <= 16 then
				if newpass == cnfpass then
					safe.change_inventory_password(pos, pin, newpass)
					meta:set_string("canary", safe.encrypt(newpass, "encrypted") or "")
					meta:mark_as_private("canary")
					safe.players[pname] = nil
					minetest.chat_send_player(pname, color .. "# Server: Password updated.")
					return true
				else
					safe.players[pname] = nil
					minetest.chat_send_player(pname, color .. "# Server: New passwords do not match!")
					ambiance.sound_play("safe_error", pos, 1.0, 20)
					return true
				end
			else
				safe.players[pname] = nil
				minetest.chat_send_player(pname, color .. "# Server: Password cannot be more than 16 letters.")
				ambiance.sound_play("safe_error", pos, 1.0, 20)
				return true
			end
		else
			safe.players[pname] = nil
			meta:set_int("disable_time", os.time() + 5)
			meta:mark_as_private("disable_time")
			minetest.chat_send_player(pname, color .. "# Server: Incorrect password.")
			ambiance.sound_play("safe_error", pos, 1.0, 20)
		end

		return true
	end

	if fields.quit then
		safe.players[pname] = nil
		minetest.remove_detached_inventory(safe.gen_invname(pos, pname))

		if not context.locked then
			ambiance.sound_play("safe_close", pos, 1.0, 20)
		end
		return true
	end

	minetest.show_formspec(pname, "safe:main", safe.get_formspec(pos, pname))
	return true
end



function safe.on_leaveplayer(pref)
	local pname = pref:get_player_name()
	local context = safe.players[pname]

	-- Lock safe if player was actively using it when they left.
	-- This doesn't trigger if player closed the safe formspec BEFORE they leave.
	if context then
		safe.lock_safe(context.pos, pname)

		-- Be sure it gets removed, if the lock_safe() didn't do it.
		minetest.remove_detached_inventory(safe.gen_invname(context.pos, pname))
	end

	safe.players[pname] = nil
end



function safe.preserve_metadata(pos, oldnode, oldmeta, drops)
	if drops and drops[1] then
		local ndef = minetest.registered_nodes[minetest.get_node(pos).name]
		if ndef._safe_is_known_node then
			local stack = drops[1]
			local meta = stack:get_meta()

			-- Remove keys.
			oldmeta.description = nil
			oldmeta.infotext = nil

			-- Check if the briefcase actually contains anything.
			local have_documents = false
			for k = 1, ndef._safe_inventory_size do
				if oldmeta["item" .. k] and oldmeta["item" .. k] ~= "" then
					have_documents = true
					break
				end
			end

			if have_documents then
				oldmeta.description = "Briefcase With Documents"
			end

			meta:from_table({fields=oldmeta})
			stack:set_name(ndef._safe_close_node)
			stack:set_count(1)
		end
	end
end

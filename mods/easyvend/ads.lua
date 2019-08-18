
ads = ads or {}
ads.modpath = minetest.get_modpath("easyvend")
ads.worldpath = minetest.get_worldpath()
ads.data = ads.data or {}
ads.players = ads.players or {}
ads.datapath = ads.worldpath .. "/advertisements.dat"
ads.dirty = true
ads.bodylen = 1024
ads.titlelen = 64
ads.viewrange = 5000 -- Distance at which ads are visible.
ads.marketrange = 10 -- Distance at which shops are visible (distance from ad source).
ads.days = 30
ads.ad_cost = 1525



function ads.generate_submission_formspec()
	local formspec =
		"size[10,8]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[0,0;Submit a public advertisement for your shop to enable remote trading.]" ..
		"label[0,0.4;Having your shop listed in the public market directory also increases its visibility.]" ..
		"label[0,1.0;Write your shop’s tagline here. It is limited to " .. ads.titlelen .. " characters. Example: ‘Buy Wood Here!’]" ..
		"item_image[9,0;1,1;currency:minegeld_100]" ..
		"field[0.3,1.7;10,1;title;;]"

	formspec = formspec ..
		"label[0,2.5;Enter a description of your shop. This might include details on items sold, and pricing.]" ..
		"label[0,2.9;You will also want to include instructions on how to find your shop.]" ..
		"label[0,3.3;You should make sure the text is " .. ads.bodylen .. " characters or less.]" ..
		"textarea[0.3,3.8;10,3.0;text;;]"

	formspec = formspec ..
		"label[0,6.4;Advertisement records are always removed exactly " .. math.floor(ads.days) .. " days after submission.]" ..
		"label[0,6.8;Note that you should submit your advertisement from the location of your shop.]" ..
		"button[5,7.3;2,1;cancel;Cancel]" ..
		"button[7,7.3;3,1;submit;Submit (Cost: " .. ads.ad_cost .. " MG)]" ..
		"field_close_on_enter[title;false]" ..
		"item_image[0,7.3;1,1;currency:minegeld_100]"
	return formspec
end



function ads.show_submission_formspec(pos, pname, booth)
	local formspec = ads.generate_submission_formspec()
	local b = "|"
	if booth then
		b = "|booth"
	end
	local key = "ads:submission_" .. minetest.pos_to_string(vector.round(pos)) .. b
	minetest.show_formspec(pname, key, formspec)
end



function ads.show_inventory_formspec(pos, pname, booth)
	pos = vector.round(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z

	-- Obtain hooks into the trash mod's trash slot inventory.
	local ltrash, mtrash = trash.get_listname()
	local itrash = trash.get_iconname()

	local formspec =
		"size[16,11]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[nodemeta:" .. spos .. ";storage;0,0;16,5;]" ..
		"list[nodemeta:" .. spos .. ";storage;9,5;7,6;80]" ..
		"list[current_player;main;0,6.6;8,1;]" ..
		"list[current_player;main;0,8;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";storage]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 6.6) ..

		-- Vending icon.
		"item_image[5,5.3;1,1;easyvend:vendor_on]" ..

		-- Trash icon.
		"list[" .. ltrash .. ";" .. mtrash .. ";7,5.3;1,1;]" ..
		"image[7,5.3;1,1;" .. itrash .. "]"

	-- Buttons.
	formspec = formspec ..
		"button[0,5.3;2,1;backinv;Back]"

	local p2 = depositor.get_drop_location(pname)
	if p2 and vector.equals(pos, p2) then
		formspec = formspec ..
			"button[2,5.3;3,1;unsetpoint;Revoke Delivery Point]"
	else
		formspec = formspec ..
			"button[2,5.3;3,1;setpoint;Mark Delivery Point]"
	end

	local b = "|"
	if booth then
		b = "|booth"
	end
	local key = "ads:inventory_" .. minetest.pos_to_string(vector.round(pos)) .. b
	minetest.show_formspec(pname, key, formspec)
end



function ads.on_receive_submission_fields(player, formname, fields)
	if string.sub(formname, 1, 15) ~= "ads:submission_" then
		return
	end
	local pos = minetest.string_to_pos(string.sub(formname, 16, string.find(formname, "|")-1))
	if not pos then
		--minetest.chat_send_all("Invalid!")
		return true
	end
	local pname = player:get_player_name()

	if fields.submit then
		local inv = player:get_inventory()
		--local gotgold = inv:contains_item("main", ItemStack("currency:minegeld_100 10"))
		local gotgold = currency.has_cash_amount(inv, "main", ads.ad_cost)

		if not gotgold then
			minetest.chat_send_player(pname, "# Server: You must be able to pay " .. ads.ad_cost .. " minegeld to register an advertisement for your shop!")
			easyvend.sound_error(pname)
			goto error
		end

		if not passport.player_registered(pname) then
			minetest.chat_send_player(pname, "# Server: You must be a Citizen of the Colony before you can purchase a shop advertisement!")
			easyvend.sound_error(pname)
			goto error
		end

		if not fields.title or fields.title == "" or string.len(fields.title) > ads.titlelen then
			minetest.chat_send_player(pname, "# Server: You must write a name for your shop (not more than " .. ads.titlelen .. " characters).")
			easyvend.sound_error(pname)
			goto error
		end

		if not fields.text or fields.text == "" or string.len(fields.text) > ads.bodylen then
			minetest.chat_send_player(pname, "# Server: You must write the body of your advertisement (not more than " .. ads.bodylen .. " characters).")
			easyvend.sound_error(pname)
			goto error
		end

    if anticurse.check(pname, fields.text, "foul") then
			minetest.chat_send_player(pname, "# Server: Don't include foul language, please!")
			easyvend.sound_error(pname)
      anticurse.log(pname, fields.text)
			goto error
    elseif anticurse.check(pname, fields.text, "curse") then
			minetest.chat_send_player(pname, "# Server: Don't include foul language, please!")
			easyvend.sound_error(pname)
      anticurse.log(pname, fields.text)
			goto error
    end

    if anticurse.check(pname, fields.title, "foul") then
			minetest.chat_send_player(pname, "# Server: Don't include foul language, please!")
			easyvend.sound_error(pname)
      anticurse.log(pname, fields.title)
			goto error
    elseif anticurse.check(pname, fields.title, "curse") then
			minetest.chat_send_player(pname, "# Server: Don't include foul language, please!")
			easyvend.sound_error(pname)
      anticurse.log(pname, fields.title)
			goto error
    end

		--minetest.close_formspec(pname, formname)
		ambiance.sound_play("easyvend_activate", player:get_pos(), 0.5, 10)

		--inv:remove_item("main", ItemStack("currency:minegeld_100 10"))
		currency.remove_cash(inv, "main", ads.ad_cost)
		ads.add_entry({
			shop = fields.title or "No Title Set",
			pos = pos, -- Records the position at which the advertisement was submitted.
			owner = pname,
			custom = fields.text or "No Text Submitted",
			expires = os.time() + (60*60*24*math.floor(ads.days)),
			date = os.time(),
		})

		local booth = false
		if string.find(formname, "|booth") then
			booth = true
		end

		ads.show_formspec(pos, pname, booth)
		do return true end

		::error::
	end

	if fields.cancel or fields.quit then
		if string.find(formname, "|booth") then
			ads.show_formspec(pos, pname, true)
		else
			minetest.close_formspec(pname, formname)
		end
	end

	return true
end



function ads.get_valid_ads(pos)
	pos = vector.round(pos)
	local temp = {}
	local curtime = os.time()
	for i = 1, #(ads.data), 1 do
		local ad = ads.data[i]
		local str = ""
		local stack = ItemStack(ad.item)
		local def = minetest.registered_items[stack:get_name()]

		-- Skip ads with missing data.
		if not ad.shop or not ad.date then
			goto continue
		end

		-- Don't show ads for unknown items or items without descriptions.
		if not def or not def.description then
			goto continue
		end

		-- Don't show ads for far shops.
		-- That is, don't show ads that were submitted far from the current location.
		if vector.distance(pos, ad.pos) > ads.viewrange then
			goto continue
		end

		-- Ignore ads submitted in a different realm.
		if not rc.same_realm(pos, ad.pos) then
			goto continue
		end

		-- Don't show expired ads.
		if ad.expires < curtime then
			goto continue
		end

		temp[#temp+1] = table.copy(ad)
		::continue::
	end
	return temp
end



function ads.get_valid_shops(ad_pos, owner)
	local db = {}
	for k, v in ipairs(depositor.shops) do
		if v.active and
			v.owner == owner and
			vector.distance(ad_pos, v.pos) < ads.marketrange and
			rc.same_realm(ad_pos, v.pos)
		then
			if (v.type == 1 or v.type == 2) and
				v.item ~= "none" and
				v.item ~= "" and
				v.item ~= "ignore"
			then
				table.insert(db, {owner=v.owner, item=v.item, number=v.number, cost=v.cost, currency=v.currency, type=v.type, pos={x=v.pos.x, y=v.pos.y, z=v.pos.z}})
			end
		end
	end
	return db
end



function ads.generate_formspec(pos, pname, booth)
	-- Set up player's view of the data.
	if not ads.players[pname] then
		ads.players[pname] = {}
	end
	local data = ads.players[pname]
	data.ads = ads.get_valid_ads(pos) or {}
	data.shops = data.shops or {}
	data.selected = data.selected or 0
	data.shopselect = data.shopselect or 0

	if data.selected ~= 0 and data.selected > #data.ads then
		data.selected = #data.ads
	end
	if data.shopselect ~= 0 and data.shopselect > #data.shops then
		data.shopselect = #data.shops
	end

	-- Count of how many ads player owns in this list.
	local ownadcount = 0

	local formspec =
		"size[15.2,8]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[0,0;View nearby shops & trading opportunities!]"

	if booth then
		formspec = formspec ..
			"label[0,0.4;You can view listings for shops closer than " .. ads.viewrange .. " meters from this booth.]"
	else
		formspec = formspec ..
			"label[0,0.4;You are viewing the listings for shops within " .. ads.viewrange .. " meters of your position.]"
	end

	formspec = formspec ..
		"textlist[0,0.9;5,5.8;adlist;"

	for i = 1, #(data.ads), 1 do
		local ad = data.ads[i]
		local str = ""

		if ad.owner == pname then
			ownadcount = ownadcount + 1
		end

		-- Display shop title in list.
		str = str .. ad.shop

		str = minetest.formspec_escape(str)
		formspec = formspec .. str

		-- Append comma.
		if i < #(data.ads) then
			formspec = formspec .. ","
		end

		::continue::
	end

	local strad = "entries"
	if ownadcount == 1 then
		strad = "entry"
	end
	formspec = formspec .. ";" .. data.selected .. ";false]" ..
		"label[0,6.8;You bought " .. ownadcount .. " " .. strad .. " in this list.]"

	local addesc = "See your shop advertisement here!"

	local shoplist = ""
	if data.selected and data.selected >= 1 and data.selected <= #(data.ads) then
		if data.ads[data.selected] then
			local ad = data.ads[data.selected]
			local esc = minetest.formspec_escape
			formspec = formspec ..
				"label[5.35,5.0;" .. esc("<" .. rename.gpn(ad.owner) .. "> paid for this listing.") .. "]" ..
				"label[5.35,5.4;" .. esc("Submitted on " .. os.date("!%Y/%m/%d", ad.date) .. ".") .. "]" ..
				"label[5.35,5.8;" .. esc("Expires after " .. os.date("!%Y/%m/%d", ad.expires) .. ".") .. "]" ..
				"label[5.35,6.2;" .. esc("From " .. rc.pos_to_namestr(ad.pos) .. ".") .. "]" ..
				"label[5.35,6.6;" .. esc("Distance " .. math.floor(vector.distance(ad.pos, pos)) .. " meters.") .. "]"
			if ad.custom then
				addesc = ad.shop .. "\n\n" .. ad.custom
			end

			-- List nearby shops belonging to the selected ad.
			local shops = ads.get_valid_shops(ad.pos, ad.owner)
			ads.players[pname].shops = shops
			for k, v in ipairs(shops) do
				local str = ""

				if v.type == 1 then
					str = str .. "Selling"
				elseif v.type == 2 then
					str = str .. "Buying"
				else
					str = str .. "Unknown"
				end

				str = str .. ": "

				local def = minetest.registered_items[v.item]
				if def then
					str = str .. v.number .. "x " .. utility.get_short_desc(def.description)
					str = str .. " For " .. currency.get_stack_value(v.currency, v.cost) .. " Minegeld"

					str = minetest.formspec_escape(str)
					shoplist = shoplist .. str

					-- Append comma.
					if k < #shops then
						shoplist = shoplist .. ","
					end
				end

			end -- end for
		end
	end

	formspec = formspec .. "textlist[10,0.9;5,5.8;shoplist;" .. shoplist
	formspec = formspec .. ";" .. (data.shopselect or 0) .. ";false]"

	addesc = minetest.formspec_escape(addesc)
	formspec = formspec ..
		"textarea[5.6,0.87;4.7,4.6;warning;;" .. addesc .. "]"

	if booth then
		formspec = formspec ..
			"button[0,7.3;4,1;newadd;List Your Shop]" ..
			"item_image[4,7.3;1,1;easyvend:vendor_on]"

		-- Show inventory/purchase button only if player has permissions on this booth.
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") == pname or minetest.check_player_privs(pname, "protection_bypass") then
			formspec = formspec ..
				"button[11.2,7.3;2,1;storage;Inventory]"

			local shops = ads.players[pname].shops
			local sel = (data.shopselect or 0)
			if shops and sel ~= 0 and shops[sel] then
				local text = ""
				local idef = minetest.registered_items[shops[sel].item]
				local curt = shops[sel].currency
				local cost = shops[sel].cost or 0

				if idef and shops[sel].owner ~= pname then
					if shops[sel].type == 1 then
						text = "Purchase (" .. shops[sel].number .. "x " .. utility.get_short_desc(idef.description) .. " For " .. currency.get_stack_value(curt, cost) .. " Minegeld)"
					elseif shops[sel].type == 2 then
						text = "Deposit (" .. shops[sel].number .. "x " .. utility.get_short_desc(idef.description) .. " For " .. currency.get_stack_value(curt, cost) .. " Minegeld)"
					end

					if text ~= "" then
						formspec = formspec ..
							"button[5,7.3;6.2,1;dotrade;" .. minetest.formspec_escape(text) .. "]"
					end
				end
			end
		end
	end

	formspec = formspec ..
		"button[13.2,7.3;2,1;done;Done]"
	return formspec
end



function ads.on_receive_fields(player, formname, fields)
	if string.sub(formname, 1, 9) ~= "ads:main_" then
		return
	end
	local pos = minetest.string_to_pos(string.sub(formname, 10, string.find(formname, "|")-1))
	if not pos then
		--minetest.chat_send_all("Invalid!")
		return true
	end
	local pname = player:get_player_name()
	if not ads.players[pname] then
		return true
	end

	if fields.done or fields.quit then
		minetest.close_formspec(pname, formname)
		return true
	end

	local event = minetest.explode_textlist_event(fields["adlist"])
	if event.type == "CHG" then
		local index = event.index
		local max = #(ads.players[pname].ads)
		if index > max then index = max end

		-- Reset selected shop whenever selected ad changes.
		if index ~= ads.players[pname].selected then
			ads.players[pname].shopselect = 0
		end

		ads.players[pname].selected = index
		--minetest.chat_send_all("" .. index)
	end

	local event = minetest.explode_textlist_event(fields["shoplist"])
	if event.type == "CHG" then
		if ads.players[pname].shops then
			local index = event.index
			local max = #(ads.players[pname].shops)
			if index > max then index = max end
			ads.players[pname].shopselect = index
			--minetest.chat_send_all("" .. index)
		end
	end

	local booth = false
	if string.find(formname, "|booth") then
		booth = true

		if fields.newadd then
			ads.show_submission_formspec(pos, pname, booth)
			return true
		end

		if fields.storage or fields.dotrade then
			local meta = minetest.get_meta(pos)
			if meta:get_string("owner") == pname or minetest.check_player_privs(pname, "protection_bypass") then

				if fields.storage then
					ads.show_inventory_formspec(pos, pname, booth)
				elseif fields.dotrade then
					local sel = ads.players[pname].shopselect or 0
					local shops = ads.players[pname].shops
					if shops and sel ~= 0 and shops[sel] then
						local item = shops[sel].item
						local cost = shops[sel].cost
						local type = shops[sel].type
						local number = shops[sel].number
						local currency = shops[sel].currency
						local owner = shops[sel].owner or ""
						local putsite = depositor.get_drop_location(pname)
						local dropsite = depositor.get_drop_location(owner)
						local vpos = shops[sel].pos
						if putsite then
							if dropsite then
								local msg = depositor.execute_trade(vpos, pname, owner, putsite, dropsite, item, number, cost, currency, type)
								if msg then
									minetest.chat_send_player(pname, "# Server: " .. msg)
								end
							else
								minetest.chat_send_player(pname, "# Server: Cannot execute trade. <" .. rename.gpn(owner) .. "> has not registered an address for remote trading.")
								easyvend.sound_error(pname)
							end
						else
							minetest.chat_send_player(pname, "# Server: Cannot execute trade. You have not registered an address for remote trading.")
							easyvend.sound_error(pname)
						end
					end
				end

			end
			return true
		end
	end

	ads.show_formspec(pos, pname, booth)
	return true
end



function ads.show_formspec(pos, pname, booth)
	local formspec = ads.generate_formspec(pos, pname, booth)
	local b = "|"
	if booth then
		b = "|booth"
	end
	local key = "ads:main_" .. minetest.pos_to_string(vector.round(pos)) .. b
	minetest.show_formspec(pname, key, formspec)
end



function ads.add_entry(data)
	ads.data[#(ads.data)+1] = {
		shop = data.shop,				-- Brief Name of Shop
		pos = data.pos,					-- {x,y,z}
		owner = data.owner, 		-- playername
		custom = data.custom,		-- Custom text. Here are directions to my shop.
		expires = data.expires,	-- timestamp of expiration (integer)
		date = data.date,				-- timestamp of submission (integer)
	}
	ads.dirty = true
	ads.players = {}
end



function ads.remove_expired()
	-- Remove expired ads.
	local temp = {}
	local time = os.time()
	for k, v in ipairs(ads.data) do
		-- Ad is removed it expiration time is older than current time.
		if v.expires > time then
			temp[#temp+1] = v
		else
			ads.dirty = true
			ads.players = {}
		end
	end
	ads.data = temp
end



function ads.load_data()
	ads.data = {}
	local file = io.open(ads.datapath, "r")
  if file then
    local data = file:read("*all")
    local db = minetest.deserialize(data)
    file:close()
    if type(db) == "table" then
      ads.data = db
			ads.dirty = false
			ads.players = {}
    end
  end
	-- Remove expired ads after loading.
	ads.remove_expired()
end



function ads.save_data()
	-- Remove expired ads before saving.
	ads.remove_expired()
	if ads.dirty then
		local str = minetest.serialize(ads.data)
		if type(str) ~= "string" then return end -- Failsafe.
		local file = io.open(ads.datapath, "w")
		if file then
			file:write(str)
			file:close()
		end
		ads.dirty = false
	end
end



function ads._on_rename_check(pos)
	local meta = minetest.get_meta(pos)
	local pname = meta:get_string("owner")
	meta:set_string("infotext", "Market Trade Booth\nOwned by <" .. rename.gpn(pname) .. ">!")
end



function ads.after_place_node(pos, placer)
	local pname = placer:get_player_name()
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", pname)
	meta:set_string("infotext", "Market Trade Booth\nOwned by <" .. rename.gpn(pname) .. ">!")

	local inv = meta:get_inventory()
	inv:set_size("storage", (5*16) + (7*6))

	depositor.update_info(pos, pname, "none", 0, 0, "none", "info")
end



local function has_inventory_privilege(meta, player)
  if minetest.check_player_privs(player, "protection_bypass") then
    return true
  end

	if player:get_player_name() == meta:get_string("owner") then
		return true
	end

	return false
end



function ads.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)

	if from_list ~= to_list then
		return 0
	end

	if not has_inventory_privilege(meta, player) then
		return 0
	end

	return count
end



function ads.allow_metadata_inventory_put(pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)

	if listname ~= "storage" then
		return 0
	end

	if not has_inventory_privilege(meta, player) then
		return 0
	end

	return stack:get_count()
end



function ads.allow_metadata_inventory_take(pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)

	if listname ~= "storage" then
		return 0
	end

	if not has_inventory_privilege(meta, player) then
		return 0
	end

	return stack:get_count()
end



function ads.on_receive_inventory_fields(player, formname, fields)
	if string.sub(formname, 1, 14) ~= "ads:inventory_" then
		return
	end
	local pos = minetest.string_to_pos(string.sub(formname, 15, string.find(formname, "|")-1))
	if not pos then
		return true
	end

	local pname = player:get_player_name()
	if not ads.players[pname] then
		return true
	end

	if fields.done or fields.quit then
		minetest.close_formspec(pname, formname)
		return true
	end

	local booth = false
	if string.find(formname, "|booth") then
		booth = true
	end

	if booth and fields.backinv then
		ads.show_formspec(pos, pname, booth)
		return true
	end

	if booth and fields.setpoint then
		local node = minetest.get_node(pos)
		if node.name == "market:booth" then
			local meta = minetest.get_meta(pos)
			-- Owner or admin may use.
			if meta:get_string("owner") == pname or minetest.check_player_privs(player, "protection_bypass") then
				depositor.set_drop_location(pos, pname)
				local p2 = depositor.get_drop_location(pname)
				if p2 then
					minetest.chat_send_player(pname, "# Server: Goods will be delivered to drop-point at " .. rc.pos_to_namestr(p2) .. "! Payments are also retrieved at this location.")
					ads.show_inventory_formspec(pos, pname, booth)
				else
					minetest.chat_send_player(pname, "# Server: Error, could not set delivery drop-point.")
					easyvend.sound_error(pname)
				end
			else
				minetest.chat_send_player(pname, "# Server: Cannot set delivery drop-point, you do not own this booth.")
				easyvend.sound_error(pname)
			end
		else
			minetest.chat_send_player(pname, "# Server: Error (0xDEADBEEF).")
			easyvend.sound_error(pname)
		end
		return true
	end

	if booth and fields.unsetpoint then
		local p2 = depositor.get_drop_location(pname)
		if p2 then
			minetest.chat_send_player(pname, "# Server: Delivery point at " .. rc.pos_to_namestr(p2) .. " revoked by explicit request.")
		end
		depositor.unset_drop_location(pname)
		ads.show_inventory_formspec(pos, pname, booth)
		return true
	end

	return true
end



function ads.can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("storage")
end



function ads.on_blast(pos)
	local def = minetest.reg_ns_nodes[minetest.get_node(pos).name]
	local drops = {}
	default.get_inventory_drops(pos, "storage", drops)
	drops[#drops+1] = "market:booth"
	minetest.remove_node(pos)
	return drops
end



if not ads.run_once then
	ads.load_data()
	minetest.register_on_shutdown(function() ads.save_data() end)
	minetest.register_on_mapsave(function() ads.save_data() end)

	minetest.register_on_player_receive_fields(function(...)
		return ads.on_receive_fields(...)
	end)
	minetest.register_on_player_receive_fields(function(...)
		return ads.on_receive_submission_fields(...)
	end)
	minetest.register_on_player_receive_fields(function(...)
		return ads.on_receive_inventory_fields(...)
	end)

	local c = "ads:core"
	local f = ads.modpath .. "/ads.lua"
	reload.register_file(c, f, false)

	--[[
	ads.add_entry({
		shop = "Rabit’s Coal Pharmacy",
		pos = {x=0,y=0,z=0},
		owner = "Rabit",
		custom = "You can find my shop on Fifth Av.",
		expires = os.time() + (60*60*24*7),
		date = os.time(),
	})
	ads.add_entry({
		shop = "Fox’s Mineral Industry",
		pos = {x=0,y=0,z=0},
		owner = "Fox",
		custom = "I am at the North Square. Purple building!",
		expires = os.time() + (60*60*24*7),
		date = os.time(),
	})
	--]]

	minetest.register_node(":market:booth", {
		description = "Trade Booth\n\nA kiosk for remote-delivery trading.",
		tiles = {
			"easyvend_vendor_side.png",
			"easyvend_vendor_side.png",
			"easyvend_ad_booth.png",
			"easyvend_ad_booth.png",
			"easyvend_ad_booth.png",
			"easyvend_ad_booth.png",
		},
		paramtype2 = "facedir",
		groups = utility.dig_groups("furniture", {flammable = 2}),
		sounds = default.node_sound_wood_defaults(),

		after_place_node = function(pos, placer, itemstack, pt)
			ads.after_place_node(pos, placer)
		end,

		on_punch = function(pos, node, puncher, pt)
			depositor.check_machine(pos)
		end,

		on_construct = function(pos)
			depositor.on_construct(pos)
		end,

		on_destruct = function(pos)
			depositor.on_destruct(pos)
		end,

		on_rightclick = function(pos, node, clicker, itemstack, pt)
			ads.show_formspec(vector.round(pos), clicker:get_player_name(), true)
			return itemstack
		end,

		_on_rename_check = function(...)
			ads._on_rename_check(...)
		end,

		allow_metadata_inventory_move = function(...)
			return ads.allow_metadata_inventory_move(...)
		end,

		allow_metadata_inventory_put = function(...)
			return ads.allow_metadata_inventory_put(...)
		end,

		allow_metadata_inventory_take = function(...)
			return ads.allow_metadata_inventory_take(...)
		end,

		can_dig = function(...)
			return ads.can_dig(...)
		end,

		on_blast = function(...)
			return ads.on_blast(...)
		end,
	})

	minetest.register_craft({
		output = "market:booth",
		recipe = {
			{'', 'default:sign_wall_wood', ''},
			{'', 'easyvend:vendor', ''},
			{'', 'techcrafts:control_logic_unit', ''},
		},
	})

	ads.run_once = true
end

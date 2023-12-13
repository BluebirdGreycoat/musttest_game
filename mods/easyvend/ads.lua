
if not minetest.global_exists("ads") then ads = {} end
ads.modpath = minetest.get_modpath("easyvend")
ads.worldpath = minetest.get_worldpath()
ads.data = ads.data or {}
ads.players = ads.players or {}
ads.datapath = ads.worldpath .. "/advertisements.dat"
ads.dirty = true
ads.bodylen = 1024
ads.titlelen = 64
ads.viewrange = 8000 -- Distance at which ads are visible.
ads.marketrange = 15 -- Distance at which shops are visible (distance from ad source).
ads.ad_cost = 5
ads.tax = 0

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_floor = math.floor

local open_storage = {
	{1, 4},
	{17, 20},
	{33, 36},
	{49, 52},
	{65, 68},
}

function ads.is_open_index(index)
	for k, v in ipairs(open_storage) do
		if index >= v[1] and index <= v[2] then
			return true
		end
	end
end



function ads.generate_submission_formspec(data)
	local esc = minetest.formspec_escape

	local title_text = ""
	local body_text = ""
	local edit_mode_str = ""

	local submit_name = "submit"
	local submit_text = "Submit (Cost: " .. ads.ad_cost .. " MG)"

	if data then
		title_text = data.title_text
		body_text = data.body_text

		submit_name = "confirmedit"
		submit_text = "Confirm Edits"

		edit_mode_str = " [EDIT MODE]"
	end

	local formspec =
		"size[10,8]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[0,0;" .. esc("Submit a public advertisement for your shop to enable remote trading." .. edit_mode_str) .. "]" ..
		"label[0,0.4;" .. esc("Having your shop listed in the public market directory also increases its visibility.") .. "]" ..
		"label[0,1.0;" .. esc("Write your shop’s tagline here. It is limited to " .. ads.titlelen .. " characters. Example: ‘Buy Wood Here!’") .. "]" ..
		"item_image[9,0;1,1;currency:minegeld_100]" ..
		"field[0.3,1.7;10,1;title;;" .. esc(title_text) .. "]"

	formspec = formspec ..
		"label[0,2.5;" .. esc("Enter a description of your shop. This might include details on items sold, and pricing.") .. "]" ..
		"label[0,2.9;" .. esc("You may also want to include instructions on how to find your shop.") .. "]" ..
		"label[0,3.3;" .. esc("You should make sure the text is " .. ads.bodylen .. " characters or less.") .. "]" ..
		"textarea[0.3,3.8;10,3.0;text;;" .. esc(body_text) .. "]"

	formspec = formspec ..
		"label[0,6.4;" .. esc("Note that you SHOULD submit your advertisement from the location of your shop.") .. "]" ..
		"label[0,6.8;" .. esc("If you submit elsewhere, vending/depositing machines will not be available for remote trading.") .. "]" ..
		"button[5,7.3;2,1;cancel;" .. esc("Cancel") .. "]" ..
		"button[7,7.3;3,1;" .. submit_name .. ";" .. esc(submit_text) .. "]" ..
		"field_close_on_enter[title;false]" ..
		"item_image[0,7.3;1,1;currency:minegeld_100]"

	return formspec
end



function ads.show_submission_formspec(pos, pname, booth, data)
	local formspec = ads.generate_submission_formspec(data)
	local b = "|"
	if booth then
		b = "|booth"
	end
	local key = "ads:submission_" .. minetest.pos_to_string(vector_round(pos)) .. b
	minetest.show_formspec(pname, key, formspec)
end



function ads.show_inventory_formspec(pos, pname, booth)
	pos = vector_round(pos)
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

	-- Slot overlay.
	for x = 4, 15 do
		for y = 0, 4 do
			formspec = formspec .. "image[" .. x .. "," .. y .. ";1,1;books_slot.png]"
		end
	end
	for x = 9, 15 do
		for y = 5, 10 do
			formspec = formspec .. "image[" .. x .. "," .. y .. ";1,1;books_slot.png]"
		end
	end

	-- Buttons.
	formspec = formspec ..
		"button[0,5.3;2,1;backinv;Back]"

	local add_setpoint_tip = function(formspec, name)
		local text = "Both you and your potential customers must have a trading booth\n" ..
			"registered as their remote delivery address in order for remote trading to work.\n" ..
			"This is also required if you are a buyer looking to purchase items remotely.\n" ..
			"\n"

		local dp = depositor.get_drop_location(pname)
		if dp then
			text = text .. "Your currently registered delivery address is " .. rc.pos_to_namestr(dp) .. ".\n"
			if vector.equals(dp, pos) then
				text = text .. "This is located at this market booth here."
			else
				text = text .. "This is located elsewhere than the current market booth."
			end
		else
			text = text .. "You currently have no remote delivery address set!"
		end

		formspec = formspec ..
			"tooltip[" .. name .. ";" .. minetest.formspec_escape(text) .. "]"
		return formspec
	end

	local p2 = depositor.get_drop_location(pname)
	if p2 and vector.equals(pos, p2) then
		formspec = formspec ..
			"button[2,5.3;3,1;unsetpoint;Revoke Delivery Point]"
		formspec = add_setpoint_tip(formspec, "unsetpoint")
	else
		formspec = formspec ..
			"button[2,5.3;3,1;setpoint;Mark Delivery Point]"
		formspec = add_setpoint_tip(formspec, "setpoint")
	end

	local b = "|"
	if booth then
		b = "|booth"
	end
	local key = "ads:inventory_" .. minetest.pos_to_string(vector_round(pos)) .. b
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

	-- Determine if we were called from a market booth.
	local booth = false
	if string.find(formname, "|booth") then
		booth = true
	end

	if not booth then
		minetest.chat_send_player(pname, "# Server: This action can only be completed at a market kiosk.")
		easyvend.sound_error(pname)
		return true
	end

	-- Ensure player data exists.
	if not ads.players[pname] then
		minetest.chat_send_player(pname, "# Server: Error: userdata not initialized.")
		easyvend.sound_error(pname)
		return true
	end

	-- Check booth owner.
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)

	if node.name == "market:booth" and (meta:get_string("owner") == pname or minetest.check_player_privs(pname, "server")) then
		-- Everything good.
	else
		minetest.chat_send_player(pname, "# Server: You don't have permission to do that.")
		easyvend.sound_error(pname)
		return true
	end

	if fields.submit or fields.confirmedit then
		local inv

		if fields.submit then
			inv = player:get_inventory()
			local gotgold = currency.has_cash_amount(inv, "main", ads.ad_cost)

			if not gotgold then
				minetest.chat_send_player(pname, "# Server: You must be able to pay " .. ads.ad_cost .. " minegeld to register a public notice!")
				easyvend.sound_error(pname)
				goto error
			end
		elseif fields.confirmedit then
			local str = ads.players[pname].editname
			if not str or str == "" then
				minetest.chat_send_player(pname, "# Server: The name of the advertisement to be edited was not specified.")
				easyvend.sound_error(pname)
				goto error
			end
		end

		if not passport.player_registered(pname) then
			minetest.chat_send_player(pname, "# Server: You must be a Citizen of the Colony before you can purchase or edit a public notice!")
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

		-- Make sure a shop with this title doesn't already exist.
		if fields.submit then
			for k, v in ipairs(ads.data) do
				if v.shop == fields.title then
					minetest.chat_send_player(pname, "# Server: A public notice with that title already exists! Your notice title must be unique.")
					easyvend.sound_error(pname)
					goto error
				end
			end
		elseif fields.confirmedit then
			local original_name = ads.players[pname].editname or ""
			for k, v in ipairs(ads.data) do
				if v.shop ~= original_name then
					if v.shop == fields.title then
						minetest.chat_send_player(pname, "# Server: A public notice with that title already exists! Your notice title must be unique.")
						easyvend.sound_error(pname)
						goto error
					end
				end
			end
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

		ambiance.sound_play("easyvend_activate", player:get_pos(), 0.5, 10)

		if fields.submit then
			currency.remove_cash(inv, "main", ads.ad_cost)

			local real_owner = pname

			-- This allows admins to create records owned by other players,
			-- based on who owns the land.
			if gdac.player_is_admin(pname) then
				local land_owner = protector.get_node_owner(pos) or ""
				if land_owner ~= "" then
					real_owner = land_owner
				end
			end

			ads.add_entry({
				shop = fields.title or "No Title Set",
				pos = pos, -- Records the position at which the advertisement was submitted.
				owner = real_owner,
				custom = fields.text or "No Text Submitted",
				date = os.time(),
			})
		elseif fields.confirmedit then
			for k, v in ipairs(ads.data) do
				if v.shop == ads.players[pname].editname then
					if v.owner == pname or minetest.check_player_privs(pname, "server") then
						v.shop = fields.title or "No Title Set"
						v.custom = fields.text or "No Text Submitted"
						ads.dirty = true
						ads.players = {} -- Force refetching data for all players.
						break
					else
						minetest.chat_send_player("# Server: Public notice was submitted by someone else! You do not have permission to edit it.")
						easyvend.sound_error(pname)
						goto error
					end
				end
			end
		end

		if fields.submit then
			minetest.chat_send_player(pname, "# Server: Notice submitted.")
		elseif fields.confirmedit then
			minetest.chat_send_player(pname, "# Server: Notice updated.")
		end

		ads.show_formspec(pos, pname, booth)
		do return true end

		::error::
	end

	if fields.cancel or fields.quit then
		if booth then
			ads.show_formspec(pos, pname, true)
		else
			minetest.close_formspec(pname, formname)
		end
	end

	return true
end



local function in_market_range(mark, vend)
	local r = ads.marketrange
	if vend.x >= (mark.x - r) and vend.x <= (mark.x + r)
			and vend.y >= (mark.y - r) and vend.y <= (mark.y + r)
			and vend.z >= (mark.z - r) and vend.z <= (mark.z + r) then
		return true
	end
	return false
end



local function match_search(search, itemstr)
	if not search or search == "" then
		return true
	end

	local idef = minetest.registered_items[itemstr]
	if not idef then
		return false
	end

	local shortdesc = utility.get_short_desc(idef.description)
	shortdesc = shortdesc:lower()

	local tokens = search:split(" ")
	if not tokens or #tokens == 0 then
		return false
	end

	local count = 0

	for i = 1, #tokens do
		local tok = tokens[i]

		if tok ~= "" then
			tok = tok:lower()
			if itemstr:find(tok, 1, true) or shortdesc:find(tok, 1, true) then
				count = count + 1
			end
		end
	end

	-- All search tokens found for this item.
	if count == #tokens then
		return true
	end

	return false
end



function ads.get_valid_shops(ad_pos, owner, srchtxt)
	local db = {}
	for k, v in ipairs(depositor.shops) do
		if v.active and v.owner == owner and in_market_range(ad_pos, v.pos) and
			rc.same_realm(ad_pos, v.pos)
		then
			if (v.type == 1 or v.type == 2) and
				v.item ~= "none" and
				v.item ~= "" and
				v.item ~= "ignore"
			then
				if match_search(srchtxt, v.item) then
					table.insert(db, {
						owner = v.owner,
						item = v.item,
						number = v.number,
						cost = v.cost,
						currency = v.currency,
						type = v.type,
						pos = {x=v.pos.x, y=v.pos.y, z=v.pos.z},
					})
				end
			end
		end
	end
	return db
end



function ads.get_valid_ads(pos, srchtxt)
	pos = vector_round(pos)
	local temp = {}
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
		if vector_distance(pos, ad.pos) > ads.viewrange then
			goto continue
		end

		-- Ignore ads submitted in a different realm.
		if not rc.same_realm(pos, ad.pos) then
			goto continue
		end

		-- Skip adds without matching shops, if we're doing an item search.
		if srchtxt and srchtxt ~= "" then
			local shops = ads.get_valid_shops(ad.pos, ad.owner, srchtxt)
			if #shops == 0 then
				goto continue
			end
		end

		temp[#temp+1] = table.copy(ad)
		::continue::
	end
	return temp
end



-- Constructs the main formspec, for viewing ads and shop listings.
function ads.generate_formspec(pos, pname, booth)
	-- Set up player's view of the data.
	if not ads.players[pname] then
		ads.players[pname] = {}
	end
	local data = ads.players[pname]
	data.shops = data.shops or {}
	data.selected = data.selected or 0
	data.shopselect = data.shopselect or 0

	-- Caching the AD search is needed because depending on parameters/environment,
	-- this algorith is potentially expensive.
	if not data.ads or
			(data.srchtxt or "") ~= (data.cache_srchtxt or "") or
			(data.cache_time or 0) < os.time() then
		data.ads = ads.get_valid_ads(pos, data.srchtxt) or {}
		data.cache_srchtxt = data.srchtxt
		data.cache_time = os.time() + 60*5
	end

	if data.selected ~= 0 and data.selected > #data.ads then
		data.selected = #data.ads
	end
	if data.shopselect ~= 0 and data.shopselect > #data.shops then
		data.shopselect = #data.shops
	end

	local meta = minetest.get_meta(pos)
	local booth_owner = meta:get_string("owner")

	-- Count of how many ads player owns in this list.
	local ownadcount = 0

	local fs_size_x = 15.2
	local fs_size_y = 8.2

	-- If the formspec is viewed from an OWNED market booth, we need an extra row for more buttons.
	if booth and (booth_owner == pname or minetest.check_player_privs(pname, "server")) then
		fs_size_y = 9.1
	end

	local tax_notice = ""
	if ads.tax > 0 then
		tax_notice = " NOTICE: A " .. ads.tax .. "% tax is applied to all remote transactions."
	end

	local esc = minetest.formspec_escape
	local formspec =
		"size[" .. fs_size_x .. "," .. fs_size_y .. "]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[0,0;" .. minetest.formspec_escape("View nearby shops & trading opportunities!" .. tax_notice) .. "]"

	if booth then
		formspec = formspec ..
			"label[0,0.4;" .. minetest.formspec_escape("You are viewing public notices that were posted within " .. ads.viewrange .. " meters of this kiosk.") .. "]"
	else
		formspec = formspec ..
			"label[0,0.4;" .. minetest.formspec_escape("You are viewing public notices within " .. ads.viewrange .. " meters of your position.") .. "]"
	end

	formspec = formspec ..
		"item_image[14.2,0;1,1;easyvend:depositor_on]" ..
		"textlist[0,1;5,5.8;adlist;"

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
		"label[0,7;You bought " .. ownadcount .. " " .. strad .. " in this list.]"

	local addesc = "See your public notice here!"

	local shoplist = ""
	if data.selected and data.selected >= 1 and data.selected <= #(data.ads) then
		if data.ads[data.selected] then
			local ad = data.ads[data.selected]

			local owner_text = "<" .. rename.gpn(ad.owner) .. "> owns this listing."
			if gdac.player_is_admin(ad.owner) then
				owner_text = "Record of Public Notice."
			end

			formspec = formspec ..
				"label[5.35,5.0;" .. esc(owner_text) .. "]" ..
				"label[5.35,5.3;" .. esc("Submitted on " .. os.date("!%Y/%m/%d", ad.date) .. ".") .. "]" ..
				"label[5.35,5.6;" .. esc("From " .. rc.pos_to_namestr(ad.pos) .. ".") .. "]" ..
				"label[5.35,5.9;" .. esc("Distance " .. math_floor(vector_distance(ad.pos, pos)) .. " meters.") .. "]"
			if ad.custom then
				addesc = ad.shop .. "\n\n" .. ad.custom
			end

			-- List nearby shops belonging to the selected ad.
			local shops = ads.get_valid_shops(ad.pos, ad.owner, data.srchtxt)
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
				local cost = currency.get_stack_value(v.currency, v.cost)
				cost = currency.calculate_tax(cost, v.type, ads.tax)

				local def = minetest.registered_items[v.item]
				if def then
					str = str .. v.number .. "x " .. utility.get_short_desc(def.description)
					str = str .. " For " .. cost .. " Minegeld"

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

	formspec = formspec .. "textlist[10,1;5,5.8;shoplist;" .. shoplist
	formspec = formspec .. ";" .. (data.shopselect or 0) .. ";false]"

	addesc = minetest.formspec_escape(addesc)
	formspec = formspec ..
		"textarea[5.6,0.97;4.7,4.6;warning;;" .. addesc .. "]"

	formspec = formspec ..
		"field[5.6,6.81;2.7,1;srchtxt;;" .. esc(data.srchtxt or "") .. "]" ..
		"button[8.0,6.5;1,1;dosearch;" .. esc("?") .. "]" ..
		"button[9.0,6.5;1,1;clearsearch;X]" ..
		"field_close_on_enter[srchtxt;false]"

	if booth then
		-- Show inventory/purchase button only if player has permissions on this booth.
		if booth_owner == pname or minetest.check_player_privs(pname, "server") then
			-- List-shop button w/ vendor image.
			formspec = formspec ..
				"button[0,7.5;4,1;newadd;List Your Shop]" ..
				"tooltip[newadd;" .. minetest.formspec_escape(
					"Listing your shop makes it visible to other market kiosks within 5 kilometers of this one.\n" ..
						"This also allows citizens to trade using your vending/depositing machines remotely.\n" ..
						"\n" ..
						"Make sure you create the advertisement from the actual location of your shop!\n" ..
						"The market kiosk only links with vending/depositing machines within 15 meters.") .. "]" ..
				"item_image[4,7.5;1,1;easyvend:vendor_on]"

			formspec = formspec ..
				"button[11.2,7.5;2,1;storage;Inventory]" ..
				"tooltip[storage;" .. minetest.formspec_escape(
					"The inventory is used when trading remotely, while it is registered as your delivery address.\n" ..
					"You can trade remotely from any market kiosk that you own. But only one kiosk can be your delivery point.\n" ..
					"\n" ..
					"When purchasing an item remotely, your market kiosk's inventory must have currency to pay the cost.\n" ..
					"The purchased item will be sent to your market kiosk and cash will be removed from the same location.\n" ..
					"\n" ..
					"If you are depositing an item, your market kiosk must have the item in its inventory ready for transport.\n" ..
					"Cash for the deposit will be sent to the same location.") .. "]"

			local shops = ads.players[pname].shops
			local sel = (data.shopselect or 0)
			if shops and sel ~= 0 and shops[sel] then
				local text = ""
				local idef = minetest.registered_items[shops[sel].item]
				local curt = shops[sel].currency
				local cost = shops[sel].cost or 0

				local realcost = currency.get_stack_value(curt, cost)
				realcost = currency.calculate_tax(realcost, shops[sel].type, ads.tax)

				if idef and shops[sel].owner ~= pname then
					if shops[sel].type == 1 then
						text = "Purchase (" .. shops[sel].number .. "x " .. utility.get_short_desc(idef.description) .. " For " .. realcost .. " MG)"
					elseif shops[sel].type == 2 then
						text = "Deposit (" .. shops[sel].number .. "x " .. utility.get_short_desc(idef.description) .. " For " .. realcost .. " MG)"
					end

					if text ~= "" then
						formspec = formspec ..
							"button[5,7.5;6.2,1;dotrade;" .. minetest.formspec_escape(text) .. "]" ..
							"tooltip[dotrade;" .. minetest.formspec_escape(
								"This will try to execute a purchase or a deposit, depending on the type of shop selected.\n" ..
									"The transaction will be aborted if anything goes wrong.") .. "]"

						formspec = formspec ..
							"button[9,8.4;2.2,1;domark;" .. minetest.formspec_escape("Mark Location") .. "]"
					end
				end
			end

			-- Edit/remove add buttons.
			formspec = formspec ..
				"button[0,8.4;2,1;editrecord;" .. minetest.formspec_escape("Edit Record") .. "]" ..
				"button[2,8.4;4,1;deleterecord;" .. minetest.formspec_escape("Delete Record (With Refund)") .. "]"
		end
	end

	if booth and (booth_owner == pname or minetest.check_player_privs(pname, "server")) then
		-- All good.
	else
		if booth then
			formspec = formspec .. "label[0,7.5;" .. esc("You cannot use this market kiosk for remote trading, because you do not own it.") .. "]"
		else
			formspec = formspec .. "label[0,7.5;" .. esc("You cannot use this interface for remote trading, because it is detached.") .. "]"
		end
	end

	formspec = formspec ..
		"button[13.2,7.5;2,1;done;Done]"
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

	if fields.quit then
		return true
	end

	if fields.done then
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
	end

	if fields.key_enter_field == "srchtxt" or fields.dosearch or fields.clearsearch then
		local srchtxt = fields.srchtxt or ""

		if fields.dosearch or fields.key_enter_field == "srchtxt" then
			if srchtxt ~= "" then
				ads.players[pname].srchtxt = srchtxt
			else
				ads.players[pname].srchtxt = nil
			end
		elseif fields.clearsearch then
			ads.players[pname].srchtxt = nil
		end
	end

	if fields.storage or fields.dotrade or fields.domark or fields.editrecord or fields.deleterecord or fields.newadd then
		if booth then
			local meta = minetest.get_meta(pos)
			if meta:get_string("owner") == pname or minetest.check_player_privs(pname, "server") then

				if fields.storage then
					ads.show_inventory_formspec(pos, pname, booth)
					return true
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

						local valid_trade = true
						if not rc.same_realm(pos, vpos) then
							valid_trade = false
						end
						if vector.distance(pos, vpos) > (ads.viewrange + ads.marketrange) then
							valid_trade = false
						end

						if valid_trade then
							if putsite then
								if dropsite then
									local msg = depositor.execute_trade(vpos, pname, owner, putsite, dropsite, item, number, cost, ads.tax, currency, type)
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
						else
							minetest.chat_send_player(pname, "# Server: 0xBAADF00D")
						end
					end
				elseif fields.domark then
					local sel = ads.players[pname].shopselect or 0
					local shops = ads.players[pname].shops
					if shops and sel ~= 0 and shops[sel] then
						local vpos = shops[sel].pos
						local lname = pname .. "'s Vend Locs"
						if marker.list_size(pname, lname) < marker.max_waypoints then
							marker.add_waypoint(pname, vpos, lname)
							marker.update_single_hud(pname)
							minetest.chat_send_player(pname, "# Server: Location added to marker list.")
						end
					end
					return true
				elseif fields.editrecord then
					local sel = ads.players[pname].selected or 0
					if sel ~= 0 then
						local data = ads.players[pname].ads or {}
						if sel >= 1 and sel <= #data then
							if data[sel].owner == pname or minetest.check_player_privs(pname, "server") then
								ads.players[pname].shopselect = 0
								ads.players[pname].editname = data[sel].shop -- Record name of the advertisement the player will be editing.
								local edit_info = {
									title_text = data[sel].shop,
									body_text = data[sel].custom,
								}
								ads.show_submission_formspec(pos, pname, booth, edit_info)
								return true
							else
								-- Player doesn't have privs to edit this record.
								minetest.chat_send_player(pname, "# Server: The selected notice does not belong to you.")
								easyvend.sound_error(pname)
							end
						else
							-- Selection index out of range.
							minetest.chat_send_player(pname, "# Server: You must select one of your own public notices, first.")
							easyvend.sound_error(pname)
						end
					else
						-- Nothing selected.
						minetest.chat_send_player(pname, "# Server: You must select one of your own public notices, first.")
						easyvend.sound_error(pname)
					end
				elseif fields.deleterecord then
					local sel = ads.players[pname].selected or 0
					if sel ~= 0 then
						local data = ads.players[pname].ads or {}
						if sel >= 1 and sel <= #data then
							local owner = data[sel].owner
							local title = data[sel].shop
							if owner == pname or minetest.check_player_privs(pname, "server") then
								local player_inv = player:get_inventory()
								if currency.room_for_cash(player_inv, "main", ads.ad_cost) then
									ads.players[pname].shopselect = 0 -- Unselect any vendor/depositor listing.
									ads.players[pname].selected = 0 -- Reset ad selection to nil to prevent double-deletions.
									--minetest.chat_send_player(pname, "# Server: Would delete advertisement titled: \"" .. title .. "\"!")

									-- Search for record by owner/title and delete it.
									local found = false
									local ad_real_owner = ""
									for k, v in ipairs(ads.data) do
										if v.shop == title and v.owner == owner then
											ad_real_owner = v.owner
											table.remove(ads.data, k)
											found = true
											ads.dirty = true
											break
										end
									end

									if found then
										minetest.chat_send_player(pname, "# Server: Advertisement titled: \"" .. title .. "\", owned by <" .. rename.gpn(ad_real_owner) .. "> was removed.")
										currency.add_cash(player_inv, "main", ads.ad_cost)
									else
										minetest.chat_send_player(pname, "# Server: Could not locate record for deletion!")
										easyvend.sound_error(pname)
									end
								else
									-- Player doesn't have room in their inventory for the cash.
									minetest.chat_send_player(pname, "# Server: You must have room in your inventory to receive the cash refund of " .. ads.ad_cost .. " mg.")
									easyvend.sound_error(pname)
								end
							else
								-- Player doesn't have privs to delete this record.
								minetest.chat_send_player(pname, "# Server: The selected public notice does not belong to you.")
								easyvend.sound_error(pname)
							end
						else
							-- Selection index out of range.
							minetest.chat_send_player(pname, "# Server: You must select one of your own public notices, first.")
							easyvend.sound_error(pname)
						end
					else
						-- Nothing selected.
						minetest.chat_send_player(pname, "# Server: You must select one of your own public notices, first.")
						easyvend.sound_error(pname)
					end
				elseif fields.newadd then
					ads.show_submission_formspec(pos, pname, booth)
					return true
				end

			else
				-- Player sent button click on a market booth they don't own.
				minetest.chat_send_player(pname, "# Server: You do not have permission to do that.")
				easyvend.sound_error(pname)
			end
		else
			-- Player sent fields requiring a market booth, but this is a "detached" formspec.
			minetest.chat_send_player(pname, "# Server: This action can only be completed at a market kiosk.")
			easyvend.sound_error(pname)
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
	local key = "ads:main_" .. minetest.pos_to_string(vector_round(pos)) .. b
	minetest.show_formspec(pname, key, formspec)
end



function ads.add_entry(data)
	ads.data[#(ads.data)+1] = {
		shop = data.shop,				-- Brief Name of Shop
		pos = data.pos,					-- {x,y,z}
		owner = data.owner, 		-- playername
		custom = data.custom,		-- Custom text. Here are directions to my shop.
		date = data.date,				-- timestamp of submission (integer)
	}
	ads.dirty = true
	ads.players = {}
end



function ads.load_data()
	ads.data = {}
	local file = io.open(ads.datapath, "r")
  if file then
    local data = file:read("*all")
    local db = minetest.deserialize(data)
    file:close()
    if type(db) == "table" then
			table.shuffle(db)
      ads.data = db
			ads.dirty = false
			ads.players = {}
    end
  end
end



function ads.save_data()
	if ads.dirty then
		local str = minetest.serialize(ads.data)
		if type(str) ~= "string" then return end -- Failsafe.
		local file = io.open(ads.datapath, "w")
		if file then
			file:write(str)
			file:close()
		end
	end
	ads.dirty = false
end



function ads._on_update_infotext(pos)
	local meta = minetest.get_meta(pos)
	local pname = meta:get_string("owner")
	meta:set_string("infotext", "Market Trade Booth\nOwned by <" .. rename.gpn(pname) .. ">!")
end



function ads.after_place_node(pos, placer)
	local pname = placer:get_player_name()

	-- If placed by admin, use landowner as real owner.
	if gdac.player_is_admin(pname) then
		local landowner = protector.get_node_owner(pos) or ""
		if landowner ~= "" then
			pname = landowner
		end
	end

	local meta = minetest.get_meta(pos)
	meta:set_string("owner", pname)
	meta:set_string("infotext", "Market Trade Booth\nOwned by <" .. rename.gpn(pname) .. ">!")

	local inv = meta:get_inventory()
	inv:set_size("storage", (5*16) + (7*6))

	depositor.update_info(pos, pname, "none", 0, 0, "none", "info")
end



local function has_inventory_privilege(meta, player)
  if minetest.check_player_privs(player, "server") then
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

	-- Disallow storing items in the overflow pile.
	if ads.is_open_index(from_index) and not ads.is_open_index(to_index) then
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

	-- Disallow storing items in the overflow pile.
	if not ads.is_open_index(index) then
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
			if meta:get_string("owner") == pname or minetest.check_player_privs(player, "server") then
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
				minetest.chat_send_player(pname, "# Server: Cannot set delivery drop-point, you do not own this kiosk.")
				easyvend.sound_error(pname)
			end
		else
			minetest.chat_send_player(pname, "# Server: Error: 0xDEADBEEF 5392 (please report).")
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

	minetest.register_node(":market:booth", {
		description = "Networked Trade Kiosk\n\nA market kiosk enables remote trading.\nWill link with nearby vending/depositing machines.\nCan also display public notices.",
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
			ads.show_formspec(vector_round(pos), clicker:get_player_name(), true)
			return itemstack
		end,

		_on_update_infotext = function(...)
			ads._on_update_infotext(...)
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
			{'chests:chest_public_closed', 'easyvend:vendor', 'chests:chest_public_closed'},
			{'', 'fine_wire:copper', ''},
		},
	})

	ads.run_once = true
end

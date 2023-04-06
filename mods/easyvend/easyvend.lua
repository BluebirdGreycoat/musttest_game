
if not minetest.global_exists("easyvend") then easyvend = {} end
easyvend.modpath = minetest.get_modpath("easyvend")

-- Localize for performance.
local math_floor = math.floor

local traversable_node_types = easyvend.traversable_node_types
local registered_chests = easyvend.registered_chests



local currency_types = {}
local initial_currency = 1

for k, v in ipairs(currency.note_names) do
	table.insert(currency_types, v)
end

-- Maximum price that can be configured on a vendor or depositor.
local maxcost = 1000000
local slots_max = 30



-- Allow for other mods to register custom chests
easyvend.register_chest = function(node_name, inv_list, meta_owner)
	easyvend.registered_chests[node_name] = { inv_list = inv_list, meta_owner = meta_owner }
	easyvend.traversable_node_types[node_name] = true
end

-- Partly a wrapper around contains_item, but does special treatment if the item
-- is a tool. Basically checks whether the items exist in the supplied inventory
-- list. If check_wear is true, only counts items without wear.
easyvend.check_and_get_items = function(inventory, listname, itemtable, check_wear)
	local itemstring = itemtable.name
	local minimum = itemtable.count
	if check_wear == nil then check_wear = false end
	local get_items = {}
	-- Tool workaround
	if minetest.registered_tools[itemstring] ~= nil then
		local count = 0
		for i=1,inventory:get_size(listname) do
			local stack = inventory:get_stack(listname, i)
			if stack:get_name() == itemstring then
				if not check_wear or stack:get_wear() == 0 then
					count = count + 1
					table.insert(get_items, {id=i, item=stack})
					if count >= minimum then
						return true, get_items
					end
				end
			end
		end
		return false
	else
		-- Normal Minetest check
		return inventory:contains_item(listname, ItemStack(itemtable))
	end
end



easyvend.free_slots = function(inv, listname)
	local size = inv:get_size(listname)
	local free = 0
	for i=1,size do
		local stack = inv:get_stack(listname, i)
		if stack:is_empty() then
			free = free + 1
		end
	end
	return free
end



easyvend.buysell = function(nodename)
	local buysell = nil
	if ( nodename == "easyvend:depositor" or nodename == "easyvend:depositor_on" ) then
		buysell = "buy"
	elseif ( nodename == "easyvend:vendor" or nodename == "easyvend:vendor_on" ) then
		buysell = "sell"
	end
	return buysell
end

easyvend.is_active = function(nodename)
	if ( nodename == "easyvend:depositor_on" or nodename == "easyvend:vendor_on" ) then
		return true
	elseif ( nodename == "easyvend:depositor" or nodename == "easyvend:vendor" ) then
		return false
	else
		return nil
	end
end

easyvend.set_formspec = function(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)

	local description = utility.get_short_desc(minetest.reg_ns_nodes[node.name].description);
	local number = meta:get_int("number")
	local cost = meta:get_int("cost")
	local itemname = meta:get_string("itemname")
	local bg = ""
	local configmode = meta:get_int("configmode") == 1
	if minetest.get_modpath("default") then
		bg = default.formspec.get_form_colors() .. default.formspec.get_form_image() .. default.formspec.get_slot_colors()
	end

	local numbertext, costtext, buysellbuttontext
	local itemcounttooltip = "Item count"
	local buysell = easyvend.buysell(node.name)
	if buysell == "sell" then
		numbertext = "Offered Item"
		costtext = "Price"
		buysellbuttontext = "Buy"
	elseif buysell == "buy" then
		numbertext = "Requested Item"
		costtext = "Payment"
		buysellbuttontext = "Sell"
	else
		return
	end
	local status = meta:get_string("status")
	if status == "" then status = "Unknown." end
	local message = meta:get_string("message")
	if message == "" then message = "No message." end
	local status_image
	if node.name == "easyvend:vendor_on" or node.name == "easyvend:depositor_on" then
		status_image = "easyvend_status_on.png"
	else
		status_image = "easyvend_status_off.png"
	end

	-- TODO: Expose number of items in stock

	local formspec = "size[8,7.3;]"
		.. bg
	.."label[3,-0.2;" .. minetest.formspec_escape(description) .. "]"

	.."image[7.5,0.2;0.5,1;" .. status_image .. "]"
	.."textarea[2.8,0.2;5.1,2;;Status: " .. minetest.formspec_escape(status) .. ";]"
	.."textarea[2.8,1.3;5.6,2;;Message: " .. minetest.formspec_escape(message) .. ";]"

		.."label[0,-0.15;"..numbertext.."]"
		.."label[0,1.2;"..costtext.."]"
		.."list[current_player;main;0,3.5;8,4;]"
    
    local machine_currency = meta:get_string("machine_currency")

	if configmode then
		local wear = "false"
		if meta:get_int("wear") == 1 then wear = "true" end
		formspec = formspec
				.."item_image_button[0,1.65;1,1;" .. machine_currency .. ";easyvend_currency_image;]"
				.."list[context;item;0,0.35;1,1;]"
				.."listring[current_player;main]"
				.."listring[context;item]"
		.."field[1.3,0.65;1.5,1;number;;" .. number .. "]"
		.."tooltip[number;"..itemcounttooltip.."]"
		.."field[1.3,1.95;1.5,1;cost;;" .. cost .. "]"
		.."tooltip[cost;"..itemcounttooltip.."]"
		.."button[6,2.8;2,0.5;save;Confirm]"
		.."tooltip[save;Confirm configuration and activate machine (only for owner)]"
		local weartext, weartooltip
		if buysell == "buy" then
			weartext = "Buy worn tools"
			weartooltip = "If disabled, only tools in perfect condition will be bought from sellers (only settable by owner)"
		else
			weartext = "Sell worn tools"
			weartooltip = "If disabled, only tools in perfect condition will be sold (only settable by owner)"
		end
		if minetest.registered_tools[itemname] ~= nil then
			formspec = formspec .."checkbox[2,2.4;wear;"..minetest.formspec_escape(weartext)..";"..wear.."]"
			.."tooltip[wear;"..minetest.formspec_escape(weartooltip).."]"
		end
	else
		formspec = formspec
				.."item_image_button[0,1.65;1,1;" .. machine_currency .. ";easyvend_currency_image;]"
				.."item_image_button[0,0.35;1,1;"..itemname..";item_image;]"
		.."label[1,1.85;×" .. cost .. "]"
		.."label[1,0.55;×" .. number .. "]"
		.."button[6,2.8;2,0.5;config;Configure]"
		if buysell == "sell" then
			formspec = formspec .. "tooltip[config;Configure offered items and price (only for owner)]"
		else
			formspec = formspec .. "tooltip[config;Configure requested items and payment (only for owner)]"
		end
		formspec = formspec .."button[0,2.8;2,0.5;buysell;"..buysellbuttontext.."]"
		if minetest.registered_tools[itemname] ~= nil then
			local weartext
			if meta:get_int("wear") == 0 then
				if buysell == "buy" then
					weartext = "Only intact tools are bought."
				else
					weartext = "Only intact tools are sold."
				end
			else
				if buysell == "sell" then
					weartext = "Warning: Might sell worn tools."
				else
					weartext = "Worn tools are bought, too."
				end
			end
			if weartext ~= nil then
				formspec = formspec .."textarea[2.3,2.6;3,1;;"..minetest.formspec_escape(weartext)..";]"
			end
		end
	end

	meta:set_string("formspec", formspec)
end

easyvend.machine_disable = function(pos, node, playername)
	if node.name == "easyvend:vendor_on" then
				easyvend.sound_disable(pos)
		minetest.swap_node(pos, {name="easyvend:vendor", param2 = node.param2})
		return true
	elseif node.name == "easyvend:depositor_on" then
				easyvend.sound_disable(pos)
		minetest.swap_node(pos, {name="easyvend:depositor", param2 = node.param2})
		return true
	else
		if playername ~= nil then
			easyvend.sound_error(playername)
		end
		return false
	end
end

easyvend.machine_enable = function(pos, node)
		if node.name == "easyvend:vendor" then
				easyvend.sound_setup(pos)
		minetest.swap_node(pos, {name="easyvend:vendor_on", param2 = node.param2})
		return true
	elseif node.name == "easyvend:depositor" then
				easyvend.sound_setup(pos)
		minetest.swap_node(pos, {name="easyvend:depositor_on", param2 = node.param2})
		return true
	else
		return false
	end
end

easyvend.upgrade_currency = function(pos, meta, old_currency, old_cost)
	if old_currency == "default:gold_ingot" then
		-- Upgrade gold to currency at 1 to 25. This is a fixed exchange rate.
		meta:set_string("machine_currency", "currency:minegeld_5")
		meta:set_int("cost", math_floor((old_cost * 25) / 5))
		return ("currency:minegeld_5"), math_floor((old_cost * 25) / 5)
	end
	return old_currency, old_cost
end

easyvend.machine_check = function(pos, node)
	local active = true
	local status = "Ready."

	local meta = minetest.get_meta(pos)

	local machine_owner = meta:get_string("owner")
	local itemname = meta:get_string("itemname")
	local number = meta:get_int("number")

	local check_wear = meta:get_int("wear") == 0
	local inv = meta:get_inventory()
	local itemstack = inv:get_stack("item", 1)
	local buysell = easyvend.buysell(node.name)
    
	local machine_currency = meta:get_string("machine_currency")
	local cost = meta:get_int("cost")

	-- If the machine uses a depreciated currency, this will upgrade it using a fixed exchange rate.
	machine_currency, cost = easyvend.upgrade_currency(pos, meta, machine_currency, cost)

	local chest_pos_remove, chest_error_remove, chest_pos_add, chest_error_add
	if buysell == "sell" then
		-- Vending machine.
		chest_pos_remove, chest_error_remove = easyvend.find_connected_chest(machine_owner, pos, itemname, check_wear, number, true)
		chest_pos_add, chest_error_add = easyvend.find_connected_chest(machine_owner, pos, machine_currency, check_wear, cost, false)
	else
		-- Depositing machine.
		chest_pos_remove, chest_error_remove = easyvend.find_connected_chest(machine_owner, pos, machine_currency, check_wear, cost, true)
		chest_pos_add, chest_error_add = easyvend.find_connected_chest(machine_owner, pos, itemname, check_wear, number, false)
	end

	if chest_pos_remove and chest_pos_add then
		local rchest, rchestdef, rchest_meta, rchest_inv
		rchest = minetest.get_node(chest_pos_remove)
		rchestdef = registered_chests[rchest.name]
		rchest_meta = minetest.get_meta(chest_pos_remove)
		rchest_inv = rchest_meta:get_inventory()

		local checkstack, checkitem
		if buysell == "buy" then
			checkitem = machine_currency
		else
			checkitem = itemname
		end
		local stock = 0
		-- Count stock
		-- FIXME: Ignore tools with bad wear level
		for i=1,rchest_inv:get_size(rchestdef.inv_list) do
			checkstack = rchest_inv:get_stack(rchestdef.inv_list, i)
			if checkstack:get_name() == checkitem then
				stock = stock + checkstack:get_count()
			end
		end
		meta:set_int("stock", stock)

		if not itemstack:is_empty() then
			local number_stack_max = itemstack:get_stack_max()
			local maxnumber = number_stack_max * slots_max
			if not(number >= 1 and number <= maxnumber and cost >= 1 and cost <= maxcost) then
				active = false
				if buysell == "sell" then
					status = "Invalid item count or price."
				else
					status = "Invalid item count or payment."
				end
			end
		else
			active = false
			status = "Awaiting configuration by owner."
		end
	else
		active = false
		meta:set_int("stock", 0)
		if chest_error_remove == "no_chest" and chest_error_add == "no_chest" then
			status = "No storage; machine needs to be connected with a locked chest."
		elseif chest_error_remove == "not_owned" or chest_error_add == "not_owned" then
			status = "Storage can’t be accessed because it is owned by a different person!"
		elseif chest_error_remove == "no_stock" then
			if buysell == "sell" then
				status = "The vending machine has insufficient materials!"
			else
				status = "The depositing machine is out of money!"
			end
		elseif chest_error_add == "no_space" then
			status = "No room in the machine’s storage!"
		else
			status = "Unknown error!"
		end
	end
	if meta:get_int("configmode") == 1 then
		active = false
		status = "Awaiting configuration by owner."
	end

	if currency.is_currency(itemname) then
		status = "Cannot treat currency as a directly saleable item!"
		active = false
	end

	-- If the currency type is depreciated, then this warning overrides all others.
	if not currency.is_currency(machine_currency) then
		status = "Machine uses a depreciated currency standard!"
		active = false
	end

	meta:set_string("status", status)
	itemname=itemstack:get_name()
	meta:set_string("itemname", itemname)

	-- Inform remote market system of any changes.
	depositor.update_info(pos, machine_owner, itemname, number, cost, machine_currency, buysell, active)

	local change
	if node.name == "easyvend:vendor" or node.name == "easyvend:depositor" then
		if active then change = easyvend.machine_enable(pos, node) end
	elseif node.name == "easyvend:vendor_on" or node.name == "easyvend:depositor_on" then
		if not active then change = easyvend.machine_disable(pos, node) end
	end

	local current_node = minetest.get_node(pos)
	meta:set_string("infotext", easyvend.make_infotext(pos, current_node.name, machine_owner, cost, number, itemname))
	easyvend.set_formspec(pos)
	return change
end

easyvend.on_receive_fields_config = function(pos, formname, fields, sender)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local inv_self = meta:get_inventory()
	local itemstack = inv_self:get_stack("item",1)
	local buysell = easyvend.buysell(node.name)
 
	if fields.config then
		meta:set_int("configmode", 1)
		local was_active = easyvend.is_active(node.name)
		if was_active then
			meta:set_string("message", "Configuration mode activated; machine disabled.")
		else
			meta:set_string("message", "Configuration mode activated.")
		end
		easyvend.machine_check(pos, node)
		return
	end

	if not fields.save then
		return
	end

	local number = fields.number
	local cost = fields.cost

	number = tonumber(number)
	cost = tonumber(cost)

	local itemname=""
	local number_stack_max = 0
	if itemstack and not itemstack:is_empty() then
		itemname = itemstack:get_name()
		number_stack_max = itemstack:get_stack_max()
	end

	local oldnumber = meta:get_int("number")
	local oldcost = meta:get_int("cost")
	local maxnumber = number_stack_max * slots_max
	
	if ( itemstack == nil or itemstack:is_empty() ) then
		meta:set_string("status", "Awaiting configuration by owner.")
		meta:set_string("message", "No item specified.")
		easyvend.sound_error(sender:get_player_name())
		easyvend.set_formspec(pos)
		return
	elseif ( number == nil or number < 1 or number > maxnumber ) then
		if maxnumber > 1 then
			meta:set_string("message", string.format("Invalid item count; must be between 1 and %d!", maxnumber))
		else
			meta:set_string("message", "Invalid item count; must be exactly 1!")
		end
		meta:set_int("number", oldnumber)
		easyvend.sound_error(sender:get_player_name())
		easyvend.set_formspec(pos)
		return
	elseif ( cost == nil or cost < 1 or cost > maxcost ) then
		if maxcost > 1 then
			meta:set_string("message", string.format("Invalid cost; must be between 1 and %d!", maxcost))
		else
			meta:set_string("message", "Invalid cost; must be exactly 1!")
		end
		meta:set_int("cost", oldcost)
		easyvend.sound_error(sender:get_player_name())
		easyvend.set_formspec(pos)
		return
	end
	meta:set_int("number", number)
	meta:set_int("cost", cost)
	meta:set_string("itemname", itemname)
	meta:set_int("configmode", 0)
	meta:set_string("message", "Configuration successful.")

	local change = easyvend.machine_check(pos, node)

	if not change then
		if (node.name == "easyvend:vendor_on" or node.name == "easyvend:depositor_on") then
			easyvend.sound_setup(pos)
		else
			easyvend.sound_disable(pos)
		end
	end
end

easyvend.make_infotext = function(pos, nodename, owner, cost, number, itemstring)
	local dname = rename.gpn(owner)
	local d = ""
	if itemstring == nil or itemstring == "" or number == 0 or cost == 0 then
		if easyvend.buysell(nodename) == "sell" then
			d = string.format("Inactive Vending Machine (Owned by <%s>!)", dname)
		else
			d = string.format("Inactive Depositing Machine (Owned by <%s>!)", dname)
		end
		return d
	end
	local iname = minetest.registered_items[itemstring].description
	if iname == nil then iname = itemstring end
	iname = utility.get_short_desc(iname)
	local printitem, printcost
	if number == 1 then
		printitem = iname
	else
		printitem = string.format("%d×%s", number, iname)
	end
    
	local meta = minetest.get_meta(pos)
	local machine_currency = meta:get_string("machine_currency")

	if currency.is_currency(machine_currency) then
		printcost = currency.get_stack_value(machine_currency, cost) .. " Minegeld"
	else
		printcost = "Depreciated Currency!"
	end

	if nodename == "easyvend:vendor_on" then
		d = string.format("Vending Machine (Owned by <%s>!)\nSelling: %s\nPrice: %s", dname, printitem, printcost)
	elseif nodename == "easyvend:vendor" then
		d = string.format("Inactive Vending Machine (Owned by <%s>!)\nSelling: %s\nPrice: %s", dname, printitem, printcost)
	elseif nodename == "easyvend:depositor_on" then
		d = string.format("Depositing Machine (Owned by <%s>!)\nBuying: %s\nPayment: %s", dname, printitem, printcost)
	elseif nodename == "easyvend:depositor" then
		d = string.format("Inactive Depositing Machine (Owned by <%s>!)\nBuying: %s\nPayment: %s", dname, printitem, printcost)
	end
	return d
end

easyvend.execute_trade = function(pos, sender, player_inv, pin, vendor_inv, iin, remote_tax)
	local sendername = sender:get_player_name()
	local meta = minetest.get_meta(pos)

	local node = minetest.get_node(pos)
	local number = meta:get_int("number")
	local cost = meta:get_int("cost")
	local itemname=meta:get_string("itemname")
	local item=meta:get_inventory():get_stack("item", 1)
	local check_wear = meta:get_int("wear") == 0 and minetest.registered_tools[itemname] ~= nil

	local buysell = easyvend.buysell(node.name)

	local number_stack_max = item:get_stack_max()
	local maxnumber = number_stack_max * slots_max

	if ( number == nil or number < 1 or number > maxnumber ) or
	( cost == nil or cost < 1 or cost > maxcost ) or
	( itemname == nil or itemname=="") then
		meta:set_string("status", "Invalid item count or price!")
		easyvend.machine_disable(pos, node, sendername)
		easyvend.set_formspec(pos)
		return
	end

	local machine_currency = meta:get_string("machine_currency")
	local machine_owner = meta:get_string("owner")

	-- Check currency.
	if not currency.is_currency(machine_currency) then
		easyvend.sound_error(sendername)
		minetest.chat_send_player(sendername, "# Server: Shop at " .. rc.pos_to_namestr(pos) .. " uses a depreciated currency, attempting to upgrade!")
		minetest.chat_send_player(sendername, "# Server: If this happens, try to use the shop again and it may work if nothing else is wrong.")
		easyvend.machine_check(pos, node)
		--meta:set_string("status", "Machine uses a depreciated currency standard!")
		--easyvend.machine_disable(pos, node, sendername)
		--easyvend.set_formspec(pos)
		return
	end

	-- Cannot sell or buy currency directly.
	if currency.is_currency(itemname) then
		meta:set_string("status", "Cannot treat currency as a directly saleable item!")
		easyvend.machine_disable(pos, node, sendername)
		easyvend.set_formspec(pos)
		return
	end

	local chest_pos_remove, chest_error_remove, chest_pos_add, chest_error_add
	if buysell == "sell" then
		-- Vending.
		chest_pos_remove, chest_error_remove = easyvend.find_connected_chest(machine_owner, pos, itemname, check_wear, number, true)
		chest_pos_add, chest_error_add = easyvend.find_connected_chest(machine_owner, pos, machine_currency, check_wear, cost, false)
	else
		-- Depositing.
		chest_pos_remove, chest_error_remove = easyvend.find_connected_chest(machine_owner, pos, machine_currency, check_wear, cost, true)
		chest_pos_add, chest_error_add = easyvend.find_connected_chest(machine_owner, pos, itemname, check_wear, number, false)
	end

	if chest_pos_remove ~= nil and chest_pos_add ~= nil and sender and sender:is_player() then
		local rchest = minetest.get_node(chest_pos_remove)
		local rchestdef = registered_chests[rchest.name]
		local rchest_meta = minetest.get_meta(chest_pos_remove)
		local rchest_inv = rchest_meta:get_inventory()
		local achest = minetest.get_node(chest_pos_add)
		local achestdef = registered_chests[achest.name]
		local achest_meta = minetest.get_meta(chest_pos_add)
		local achest_inv = achest_meta:get_inventory()

		-- If passing a target inventory, redirect operations to it.
		-- This also indicates whether this is a remote trade executed via market.
		local vchest_inv = achest_inv
		local vchest_name = achestdef.inv_list
		if vendor_inv and iin then
			vchest_inv = vendor_inv
			vchest_name = iin
		end

		local stack = {name=itemname, count=number, wear=0, metadata=""}
		local price = currency.get_stack_value(machine_currency, cost)
		local chest_has, player_has, chest_free, player_free, chest_out, player_out
		local msg = ""

		if buysell == "sell" then
			-- Vending.
			local pricewithtax = price
			if vendor_inv then
				pricewithtax = currency.calculate_tax(price, 1, remote_tax)
			end

			chest_has, chest_out = easyvend.check_and_get_items(rchest_inv, rchestdef.inv_list, stack, check_wear)
			player_has = currency.has_cash_amount(player_inv, pin, pricewithtax)
			chest_free = currency.room_for_cash(vchest_inv, vchest_name, price)
			player_free = player_inv:room_for_item(pin, stack)
			if chest_has and player_has and chest_free and player_free then
				if number <= number_stack_max then
					easyvend.machine_enable(pos, node)

					-- Transfer items before transfering cash (this is because cash transfers can use up an unexpected number of free slots).
					if check_wear then
						rchest_inv:set_stack(rchestdef.inv_list, chest_out[1].id, "")
						player_inv:add_item(pin, chest_out[1].item)
					else
						stack = rchest_inv:remove_item(rchestdef.inv_list, stack)
						player_inv:add_item(pin, stack)
					end

					-- Transfer cash.
					currency.remove_cash(player_inv, pin, pricewithtax)
					currency.add_cash(vchest_inv, vchest_name, price)

					-- Deliver tax to the colonial government.
					currency.record_tax_income(pricewithtax - price)

					meta:set_string("message", "Item bought.")
					easyvend.sound_vend(pos)
					easyvend.machine_check(pos, node)

					local remote_str = ""
					if vendor_inv then
						remote_str = " remotely"
					end

					minetest.log("action", sendername .. remote_str .. " bought " .. number .. " " ..
						itemname .. " for " .. price .. " minegeld from vending machine owned by " ..
						machine_owner .. " at " .. minetest.pos_to_string(pos) .. ", tax was " .. (pricewithtax - price))
				else
					-- Large item counts (multiple stacks)
					local numberstacks = math.modf(number / number_stack_max)
					local numberremainder = math.fmod(number, number_stack_max)
					local numberfree = numberstacks
					if numberremainder > 0 then numberfree = numberfree + 1 end
					if not player_free and easyvend.free_slots(player_inv, pin) < numberfree then
						if numberfree > 1 then
							msg = string.format("No room in your inventory (%d empty slots required)!", numberfree)
						else
							msg = "No room in your inventory!"
						end
						meta:set_string("message", msg)
					elseif not chest_free and not currency.room_for_cash(vchest_inv, vchest_name, price) then
						meta:set_string("status", "No room in the machine’s storage!")
						easyvend.machine_disable(pos, node, sendername)
					else
						-- Remember items for transfer
						local cheststacks = {}
						easyvend.machine_enable(pos, node)

						-- Transfer items before transfering cash (this is because cash transfers can use up an unexpected number of free slots).
						if check_wear then
							for o=1, #chest_out do
								rchest_inv:set_stack(rchestdef.inv_list, chest_out[o].id, "")
							end
						else
							for i=1, numberstacks do
								stack.count = number_stack_max
								table.insert(cheststacks, rchest_inv:remove_item(rchestdef.inv_list, stack))
							end
						end

						if numberremainder > 0 then
							stack.count = numberremainder
							table.insert(cheststacks, rchest_inv:remove_item(rchestdef.inv_list, stack))
						end

						if check_wear then
							for o=1, #chest_out do
								player_inv:add_item(pin, chest_out[o].item)
							end
						else
							for i=1, #cheststacks do
								player_inv:add_item(pin, cheststacks[i])
							end
						end

						-- Transfer money.
						currency.remove_cash(player_inv, pin, pricewithtax)
						currency.add_cash(vchest_inv, vchest_name, price)

						-- Deliver tax to the colonial government.
						currency.record_tax_income(pricewithtax - price)

						meta:set_string("message", "Item bought.")
						easyvend.sound_vend(pos)
						easyvend.machine_check(pos, node)

						local remote_str = ""
						if vendor_inv then
							remote_str = " remotely"
						end

						minetest.log("action", sendername .. remote_str .. " bought " .. number .. " " ..
							itemname .. " for " .. price .. " minegeld from vending machine owned by " ..
							machine_owner .. " at " .. minetest.pos_to_string(pos) .. ", tax was " .. (pricewithtax - price))
					end
				end
			elseif chest_has and player_has then
				if not player_free then
					msg = "No room in your inventory!"
					meta:set_string("message", msg)
					easyvend.sound_error(sendername)
				elseif not chest_free then
					msg = "No room in the machine’s storage!"
					meta:set_string("status", msg)
					easyvend.machine_disable(pos, node, sendername)
				end
			else
				if not chest_has then
					msg = "The vending machine has insufficient materials!"
					meta:set_string("status", msg)
					easyvend.machine_disable(pos, node, sendername)
				elseif not player_has then
					msg = "You can’t afford this item!"
					meta:set_string("message", msg)
					easyvend.sound_error(sendername)
				end
			end
		else
			-- Depositing.
			local pricewithtax = price
			if vendor_inv then
				pricewithtax = currency.calculate_tax(price, 2, remote_tax)
			end

			chest_has = currency.has_cash_amount(rchest_inv, rchestdef.inv_list, price)
			player_has, player_out = easyvend.check_and_get_items(player_inv, pin, stack, check_wear)
			chest_free = vchest_inv:room_for_item(vchest_name, stack)
			player_free = currency.room_for_cash(player_inv, pin, pricewithtax)
			if chest_has and player_has and chest_free and player_free then
				if number <= number_stack_max then
					easyvend.machine_enable(pos, node)

					-- Transfer items before transfering cash (this is because cash transfers can use up an unexpected number of free slots).
					if check_wear then
						player_inv:set_stack(pin, player_out[1].id, "")
						vchest_inv:add_item(vchest_name, player_out[1].item)
					else
						stack = player_inv:remove_item(pin, stack)
						vchest_inv:add_item(vchest_name, stack)
					end

					-- Transfer money.
					currency.remove_cash(rchest_inv, rchestdef.inv_list, price)
					currency.add_cash(player_inv, pin, pricewithtax)

					-- Deliver tax to the colonial government.
					currency.record_tax_income(price - pricewithtax)

					meta:set_string("status", "Ready.")
					meta:set_string("message", "Item sold.")
					easyvend.sound_deposit(pos)
					easyvend.machine_check(pos, node)

					local remote_str = ""
					if vendor_inv then
						remote_str = " remotely"
					end

					minetest.log("action", sendername .. remote_str .. " sold " .. number .. " " ..
						itemname .. " for " .. price .. " minegeld to depositing machine owned by " ..
						machine_owner .. " at " .. minetest.pos_to_string(pos) .. ", tax was " .. (price - pricewithtax))
				else
					-- Large item counts (multiple stacks)
					local numberstacks = math.modf(number / number_stack_max)
					local numberremainder = math.fmod(number, number_stack_max)
					local numberfree = numberstacks
					if numberremainder > 0 then numberfree = numberfree + 1 end
					if not player_free and not currency.room_for_cash(player_inv, pin, pricewithtax) then
						msg = "Not enough room in your inventory for payment!"
						meta:set_string("message", msg)
						easyvend.sound_error(sendername)
					elseif not chest_free and easyvend.free_slots(vchest_inv, vchest_name) < numberfree then
						meta:set_string("status", "No room in the machine’s storage!")
						easyvend.machine_disable(pos, node, sendername)
					else
						easyvend.machine_enable(pos, node)
						-- Remember removed items for transfer
						local playerstacks = {}

						-- Transfer items before transfering cash (this is because cash transfers can use up an unexpected number of free slots).
						if check_wear then
							for o=1, #player_out do
								player_inv:set_stack(pin, player_out[o].id, "")
							end
						else
							for i=1, numberstacks do
								stack.count = number_stack_max
								table.insert(playerstacks, player_inv:remove_item(pin, stack))
							end
						end

						if numberremainder > 0 then
							stack.count = numberremainder
							table.insert(playerstacks, player_inv:remove_item(pin, stack))
						end

						if check_wear then
							for o=1, #player_out do
								vchest_inv:add_item(vchest_name, player_out[o].item)
							end
						else
							for i=1, #playerstacks do
								vchest_inv:add_item(vchest_name, playerstacks[i])
							end
						end

						-- Transfer money.
						currency.remove_cash(rchest_inv, rchestdef.inv_list, price)
						currency.add_cash(player_inv, pin, pricewithtax)

						-- Deliver tax to the colonial government.
						currency.record_tax_income(price - pricewithtax)

						meta:set_string("message", "Item sold.")
						easyvend.sound_deposit(pos)
						easyvend.machine_check(pos, node)

						local remote_str = ""
						if vendor_inv then
							remote_str = " remotely"
						end

						minetest.log("action", sendername .. remote_str .. " sold " .. number .. " " ..
							itemname .. " for " .. price .. " minegeld to depositing machine owned by " ..
							machine_owner .. " at " .. minetest.pos_to_string(pos) .. ", tax was " .. (price - pricewithtax))
					end
				end
			elseif chest_has and player_has then
				if not player_free then
					msg = "No room in your inventory!"
					meta:set_string("message", msg)
					easyvend.sound_error(sendername)
				elseif not chest_free then
					msg = "No room in the machine’s storage!"
					meta:set_string("status", msg)
					easyvend.machine_disable(pos, node, sendername)
				end
			else
				if not player_has then
					msg = "You have insufficient materials!"
					meta:set_string("message", msg)
					easyvend.sound_error(sendername)
				elseif not chest_has then
					msg = "The depositing machine is out of money!"
					meta:set_string("status", msg)
					easyvend.machine_disable(pos, node, sendername)
				end
			end
		end
	else
		local status
		meta:set_int("stock", 0)
		if chest_error_remove == "no_chest" and chest_error_add == "no_chest" then
			status = "No storage; machine needs to be connected with a locked chest."
		elseif chest_error_remove  == "not_owned" or chest_error_add == "not_owned" then
			status = "Storage can’t be accessed because it is owned by a different person!"
		elseif chest_error_remove  == "no_stock" then
			if buysell == "sell" then
				status = "The vending machine has insufficient materials!"
			else
				status = "The depositing machine is out of money!"
			end
		elseif chest_error_add  == "no_space" then
			status = "No room in the machine’s storage!"
		else
			status = "Unknown error!"
		end
		meta:set_string("status", status)
		easyvend.sound_error(sendername)
	end

	easyvend.set_formspec(pos)
end

-- Executed when player uses formspec on actual vending machine.
easyvend.on_receive_fields_buysell = function(pos, formname, fields, sender)
	if not fields.buysell then
		return
	end

	return easyvend.execute_trade(pos, sender, sender:get_inventory(), "main", nil, nil, nil)
end

easyvend.after_place_node = function(pos, placer)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local player_name = placer:get_player_name()
	local dname = rename.gpn(player_name)
	inv:set_size("item", 1)
	inv:set_size("gold", 1)

	local machine_currency = currency_types[initial_currency]
	meta:set_string("machine_currency", machine_currency)
	meta:set_int("machine_currency_idx", initial_currency)
	inv:set_stack( "gold", 1, machine_currency )

	local d = ""
	if node.name == "easyvend:vendor" then
		d = string.format("Inactive Vending Machine (Owned by <%s>!)", dname)
		meta:set_int("wear", 1)
	elseif node.name == "easyvend:depositor" then
		d = string.format("Inactive Depositing Machine (Owned by <%s>!)", dname)
		meta:set_int("wear", 0)
	end
	meta:set_string("infotext", d)
	meta:set_string("status", "Awaiting configuration by owner.")
	meta:set_string("message", "Welcome! Please prepare the machine.")
	meta:set_int("number", 1)
	meta:set_int("cost", 1)
	meta:set_int("stock", -1)
	meta:set_int("configmode", 1)
	meta:set_string("itemname", "")

	meta:set_string("owner", player_name or "")
	meta:set_string("rename", dname)

	easyvend.set_formspec(pos)
end

easyvend.can_dig = function(pos, player)
	local meta = minetest.get_meta(pos)
	local name = player:get_player_name()
	local owner = meta:get_string("owner")
	-- Owner can always dig shop
	if owner == name then
		return true
	end
	local chest_pos = easyvend.find_connected_chest(owner, pos)
	local chest, meta_chest
	if chest_pos then
		chest = minetest.get_node(chest_pos)
		meta_chest = minetest.get_meta(chest_pos)
	else
		return true --if no chest, enyone can dig this shop
	end
	if registered_chests[chest.name] then
		 if player and player:is_player() then
			local owner_chest = meta_chest:get_string(registered_chests[chest.name].meta_owner)
			if name == owner_chest then
				return true --chest owner can also dig shop
			end
		 end
		 return false
	else
		return true --if no chest, enyone can dig this shop
	end
end

easyvend.on_receive_fields = function(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = meta:get_string("owner")
	local sendername = sender:get_player_name(sender)
    
	if fields.easyvend_currency_image then
		if meta:get_int("configmode") == 1 and sendername == owner then
			-- Toggle through possible banknote denominations.
			local idx = meta:get_int("machine_currency_idx") or initial_currency
			idx = idx + 1
			if idx > #currency_types then idx = 1 end
			meta:set_string("machine_currency", currency_types[idx])
			meta:set_int("machine_currency_idx", idx)

			easyvend.set_formspec(pos)
		end
	end

	if fields.config or fields.save or fields.usermode then
		if sender:get_player_name() == owner then
			easyvend.on_receive_fields_config(pos, formname, fields, sender)
		else
			meta:set_string("message", "Only the owner may change the configuration.")
			easyvend.sound_error(sendername)
			easyvend.set_formspec(pos)
			return
		end
	elseif fields.wear ~= nil then
		if sender:get_player_name() == owner then
			if fields.wear == "true" then
				if easyvend.buysell(node.name) == "buy" then
					meta:set_string("message", "Used tools are now accepted.")
				else
					meta:set_string("message", "Used tools are now for sale.")
				end
				meta:set_int("wear", 1)
			elseif fields.wear == "false" then
				if easyvend.buysell(node.name) == "buy" then
					meta:set_string("message", "Used tools are now rejected.")
				else
					meta:set_string("message", "Used tools won’t be sold anymore.")
				end
				meta:set_int("wear", 0)
			end
			easyvend.set_formspec(pos)
			return
		else
			meta:set_string("message", "Only the owner may change the configuration.")
			easyvend.sound_error(sendername)
			easyvend.set_formspec(pos)
			return
		end
	elseif fields.buysell then
		easyvend.on_receive_fields_buysell(pos, formname, fields, sender)
	end
end

easyvend.sound_error = function(playername) 
	minetest.sound_play("easyvend_error", {to_player = playername, gain = 0.25}, true)
end

easyvend.sound_setup = function(pos)
	minetest.sound_play("easyvend_activate", {pos = pos, gain = 0.5, max_hear_distance = 12}, true)
end

easyvend.sound_disable = function(pos)
	minetest.sound_play("easyvend_disable", {pos = pos, gain = 0.9, max_hear_distance = 12}, true)
end

easyvend.sound_vend = function(pos)
	minetest.sound_play("easyvend_vend", {pos = pos, gain = 0.4, max_hear_distance = 5}, true)
end

easyvend.sound_deposit = function(pos)
	minetest.sound_play("easyvend_deposit", {pos = pos, gain = 0.4, max_hear_distance = 5}, true)
end

--[[ Tower building ]]

easyvend.is_traversable = function(pos)
	local node = minetest.get_node_or_nil(pos)
	if (node == nil) then
		return false
	end
	return traversable_node_types[node.name] == true
end

easyvend.neighboring_nodes = function(pos)
	local check = {
		{x=pos.x, y=pos.y-1, z=pos.z},
		{x=pos.x, y=pos.y+1, z=pos.z},
	}
	local trav = {}
	for i=1,#check do
		if easyvend.is_traversable(check[i]) then
			table.insert(trav, check[i])
		end
	end
	return trav
end

easyvend.find_connected_chest = function(owner, pos, nodename, check_wear, amount, removing)
	local nodes = easyvend.neighboring_nodes(pos)
    
	if (#nodes < 1 or  #nodes > 2) then
		return nil, "no_chest"
	end
    
	-- Find the stack direction
	local first = nil
	local second = nil
	for i=1,#nodes do
		if ( first == nil ) then
			first = nodes[i]
		else
			second = nodes[i]
		end
	end

	local chest_pos, chest_internal

	if (first ~= nil and second ~= nil) then
		local dy = (first.y - second.y)/2
		chest_pos, chest_internal = easyvend.find_chest(owner, pos, dy, nodename, check_wear, amount, removing)
		if ( chest_pos == nil ) then
			chest_pos, chest_internal = easyvend.find_chest(owner, pos, -dy, nodename, check_wear, amount, removing, chest_internal)
		end
	else
		local dy = first.y - pos.y
		chest_pos, chest_internal = easyvend.find_chest(owner, pos, dy, nodename, check_wear, amount, removing)
	end

	if chest_internal.chests == 0 then
		return nil, "no_chest"
	elseif chest_internal.chests == chest_internal.other_chests then
		return nil, "not_owned"
	elseif removing and chest_internal.stock < 1 then
		return nil, "no_stock"
	elseif not removing and chest_internal.space < 1 then
		return nil, "no_space"
	elseif chest_pos ~= nil then
		return chest_pos
	else
		return nil, "unknown"
	end
end

easyvend.find_chest = function(owner, pos, dy, itemname, check_wear, amount, removing, internal)
	pos = {x=pos.x, y=pos.y + dy, z=pos.z}

	if internal == nil then
		internal = {}
		internal.chests = 0
		internal.other_chests = 0
		internal.stock = 0
		internal.space = 0
	end

	local node = minetest.get_node_or_nil(pos)
	if ( node == nil ) then
		return nil, internal
	end
	local chestdef = registered_chests[node.name]
	if (chestdef ~= nil) then
		internal.chests = internal.chests + 1
		local meta = minetest.get_meta(pos)
		if (owner ~= meta:get_string(chestdef.meta_owner)) then
			internal.other_chests = internal.other_chests + 1
			return nil, internal
		end
		local inv = meta:get_inventory()
		if (inv ~= nil) then
			if (itemname ~= nil and amount ~= nil and removing ~= nil and check_wear ~= nil) then
				local chest_has, chest_free
				-- We're going to query the chest to answer two questions:
				-- Does the chest contain the item in the amount requested?
				-- Does the chest contain free slots suitable to store the amount requested?

				if currency.is_currency(itemname) then
					-- Item is a fungible currency, use currency-related functions.
					local value = currency.get_stack_value(itemname, amount)
					chest_free = currency.room_for_cash(inv, chestdef.inv_list, value)
					chest_has = currency.has_cash_amount(inv, chestdef.inv_list, value)

					-- If the chest doesn't have enough space to ADD currency,
					-- we can't safely remove currency, either (due to denomination splitting).
					if not chest_free then
						chest_has = false
					end
				else
					-- Do regular itemstack-style check. Note: as of the current Minetest version,
					-- the raw inv:room_for_item() check works with stacks over the stackmax limit.
					-- The old version of this check also checked for number of free slots,
					-- but that shouldn't be necessary.
					local stack = {name=itemname, count=amount, wear=0, metadata=""}

					chest_has = easyvend.check_and_get_items(inv, chestdef.inv_list, stack, check_wear)
					chest_free = inv:room_for_item(chestdef.inv_list, stack)
				end

				if chest_has then
					internal.stock = internal.stock + 1
				end
				if chest_free then
					internal.space = internal.space + 1
				end

				if (removing and internal.stock == 0) or (not removing and internal.space == 0) then
					return easyvend.find_chest(owner, pos, dy, itemname, check_wear, amount, removing, internal)
				else
					return pos, internal
				end
			end
		end
	elseif (node.name ~= "easyvend:vendor" and node.name~="easyvend:depositor" and node.name~="easyvend:vendor_on" and node.name~="easyvend:depositor_on") then
		return nil, internal
	end

	return easyvend.find_chest(owner, pos, dy, itemname, check_wear, amount, removing, internal)
end

-- Pseudo-inventory handling
easyvend.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
	if listname=="item" then
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner")
		local name = player:get_player_name()
		if name == owner then
			local inv = meta:get_inventory()
			if stack==nil then
				inv:set_stack( "item", 1, nil )
			else
				local sn = stack:get_name()

				-- Do not permit currency denominations to be placed in this slot.
				if currency.is_currency(sn) then
					return 0
				end

				inv:set_stack("item", 1, sn)
				meta:set_string("itemname", sn)
				easyvend.set_formspec(pos)
			end
		end
	end
	return 0
end

easyvend.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
	return 0
end

easyvend.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	return 0
end

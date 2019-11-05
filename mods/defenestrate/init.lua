
defenestrate = defenestrate or {}
defenestrate.modpath = minetest.get_modpath("defenestrate")
defenestrate.timeout = 3

--[===[
-- Returns nil, or item, number.
function defenestrate.get_random_item_in_play()
	local vendor = depositor.get_random_vending_or_depositing_machine()
	if not vendor or not vendor.active then
		-- Ignore inactive shops.
		return
	end

	-- Item must actually exist.
	if not minetest.registered_items[vendor.item] then
		return
	end

	-- Ignore certain items.
	if vendor.item == "air" or vendor.item:find("ignore") then
		return
	end

	-- Must be a valid number of items being sold.
	-- Can't be less than 1, and avoid larger than 64 because we're only doing small transactions.
	if vendor.number < 1 or vendor.number > 64 then
		return
	end

	return vendor
end

function defenestrate.do_stuff()
	-- Get the name and number of a random item being sold on the market.
	local random_shop = defenestrate.get_random_item_in_play()
	if not random_shop then
		minetest.log("autotrade: Did not find a random item being sold on the market.")
		return
	end

	local item, number = random_shop.item, random_shop.number

	-- Get the data for a random depositor buying NOT MORE THAN this amount of the item. Highest bid first.
	local deposit = depositor.get_random_depositor_buying_item(item, number)

	-- Get the data for a random vendor selling NOT LESS THAN this amount of the item. Lowest price first.
	local vendor = depositor.get_random_vendor_selling_item(item, number)

	if not deposit then
		minetest.log("autotrade: Did not find a depositor to sell " .. number .. " " .. item .. ".")
		return
	end
	if not vendor then
		minetest.log("autotrade: Did not find a vendor from which to buy " .. number .. " " .. item .. ".")
		return
	end

	if vector.distance(vendor.pos, deposit.pos) > ads.viewrange then
		minetest.log("autotrade: Randomly selected vending and depositing machines exceed maximum trading range.")
		return
	end

	local sell_cost = currency.get_stack_value(deposit.currency, deposit.cost)
	local buy_cost = currency.get_stack_value(vendor.currency, vendor.cost)

	-- Get location of the market booth belonging to the owner of this vending machine.
	local deposit_drop_pos = depositor.get_drop_location(deposit.owner)
	local vendor_drop_pos = depositor.get_drop_location(vendor.owner)
	if not deposit_drop_pos then
		-- Ignore vending machines that aren't set up to support remote trading.
		minetest.log("autotrade: Randomly chosen depositor (to sell " .. number .. " " .. item .. ") doesn't have a registered market booth.")
		return
	end
	if not vendor_drop_pos then
		-- Ignore vending machines that aren't set up to support remote trading.
		minetest.log("autotrade: Randomly chosen vendor (from which to buy " .. number .. " " .. item .. ") doesn't have a registered market booth.")
		return
	end

	-- Ensure depositor's drop location is valid.
	utility.ensure_map_loaded(vector.add(deposit_drop_pos, {x=-7, y=-7, z=-7}), vector.add(deposit_drop_pos, {x=7, y=7, z=7}))
	utility.ensure_map_loaded(vector.add(vendor_drop_pos, {x=-7, y=-7, z=-7}), vector.add(vendor_drop_pos, {x=7, y=7, z=7}))
	if minetest.get_node(deposit_drop_pos).name ~= "market:booth" then
		minetest.log("autotrade: Could not validate depositor's market booth.")
		return
	end
	if minetest.get_node(vendor_drop_pos).name ~= "market:booth" then
		minetest.log("autotrade: Could not validate vendor's market booth.")
		return
	end

	-- Ignore vending machine if the data doesn't match what's recorded.
	local deposit_machine_pos = table.copy(deposit.pos)
	local deposit_machine_meta = minetest.get_meta(deposit_machine_pos)
	if deposit_machine_meta:get_string("owner") ~= deposit.owner or
		deposit_machine_meta:get_string("itemname") ~= deposit.item or
		deposit_machine_meta:get_string("machine_currency") ~= deposit.currency or
		deposit_machine_meta:get_int("number") ~= deposit.number or
		deposit_machine_meta:get_int("cost") ~= deposit.cost
	then
		minetest.log("autotrade: Actual depositor machine data is not in sync with registered depositor info.")
		return
	end
	local vendor_machine_pos = table.copy(vendor.pos)
	local vendor_machine_meta = minetest.get_meta(vendor_machine_pos)
	if vendor_machine_meta:get_string("owner") ~= vendor.owner or
		vendor_machine_meta:get_string("itemname") ~= vendor.item or
		vendor_machine_meta:get_string("machine_currency") ~= vendor.currency or
		vendor_machine_meta:get_int("number") ~= vendor.number or
		vendor_machine_meta:get_int("cost") ~= vendor.cost
	then
		minetest.log("autotrade: Actual vendor machine data is not in sync with registered vendor info.")
		return
	end

	-- Create an itemstack. This is the item we're gonna try to sell someone.
	local itemstack = ItemStack(item .. " " .. number)

	-- Create a fake player object.
	local fakeplayer = {}
	function fakeplayer.is_player(self)
		return true
	end
	function fakeplayer.get_player_name(self)
		return "server"
	end

	local deposit_drop_meta = minetest.get_meta(deposit_drop_pos)
	local deposit_drop_inv = deposit_drop_meta:get_inventory()
	if not deposit_drop_inv then
		minetest.log("autotrade: Could not obtain inventory for depositor's market booth.")
		return
	end
	local vendor_drop_meta = minetest.get_meta(vendor_drop_pos)
	local vendor_drop_inv = vendor_drop_meta:get_inventory()
	if not vendor_drop_inv then
		minetest.log("autotrade: Could not obtain inventory for vendor's market booth.")
		return
	end

	-- Construct an inventory containing the item we're going to sell someone.
	local user_inv = minetest.create_detached_inventory("defenestrate:inv", {}, "server")
	user_inv:set_size("storage", 5)
	user_inv:set_stack("storage", 1, itemstack)

	minetest.log("autotrade: Attempting to sell " .. itemstack:get_count() .. " " ..
		itemstack:get_name() .. " to depositor at " .. minetest.pos_to_string(deposit_machine_pos) ..
		" for " .. sell_cost .. " minegeld.")

	minetest.log("autotrade: Attempting to buy " .. itemstack:get_count() .. " " ..
		itemstack:get_name() .. " from vendor at " .. minetest.pos_to_string(vendor_machine_pos) ..
		" for " .. buy_cost .. " minegeld.")

	-- The trade function requires map access!
	-- Sell item, get money.
	utility.ensure_map_loaded(vector.add(deposit_machine_pos, {x=-7, y=-7, z=-7}), vector.add(deposit_machine_pos, {x=7, y=7, z=7}))
	easyvend.execute_trade(deposit_machine_pos, fakeplayer, user_inv, "storage", deposit_drop_inv, "storage", ads.tax)

	-- The detached inventory should now contain less (or none) of the item to be sold, and it should contain some minegeld.
	-- Now we can go look for someone who sells something for less or equal to this amount, and buy it.

	-- The trade function requires map access!
	-- Use money obtained in previous transaction to buy item.
	utility.ensure_map_loaded(vector.add(vendor_machine_pos, {x=-7, y=-7, z=-7}), vector.add(vendor_machine_pos, {x=7, y=7, z=7}))
	easyvend.execute_trade(vendor_machine_pos, fakeplayer, user_inv, "storage", vendor_drop_inv, "storage", ads.tax)

	-- Finally, cleanup.
	minetest.remove_detached_inventory("defenestrate:inv")
end

function defenestrate.execute()
	defenestrate.do_stuff()

	-- Repeat.
	minetest.after(defenestrate.timeout, function()
		defenestrate.execute()
	end)
end

--]===]

if not defenestrate.registered then
	local c = "autotrade:core"
	local f = defenestrate.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	--minetest.after(defenestrate.timeout, function()
	--	defenestrate.execute()
	--end)

	defenestrate.registered = true
end

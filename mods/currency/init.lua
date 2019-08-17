
currency = currency or {}
currency.modpath = minetest.get_modpath("currency")
currency.stackmax = 10

-- Test functions.
-- function currency.room(pname, amount)
-- function currency.add(pname, amount)
-- function currency.remove(pname, amount)
-- function currency.tell(pname)



local currency_names = {
	"currency:minegeld",
	"currency:minegeld_5",
	"currency:minegeld_10",
	"currency:minegeld_50",
	"currency:minegeld_100",
}

local currency_values = {1, 5, 10, 50, 100}

local currency_values_by_name = {
	["currency:minegeld"] = 1,
	["currency:minegeld_5"] = 5,
	["currency:minegeld_10"] = 10,
	["currency:minegeld_50"] = 50,
	["currency:minegeld_100"] = 100,
}



function currency.is_currency(name)
	for k, v in ipairs(currency_names) do
		if v == name then
			return true
		end
	end

	return false
end



-- Tell whether the inventory has enough room for the given amount of cash.
-- Try largest denominations first.
function currency.room_for_cash(inv, name, amount)
	if amount < 0 then
		return true
	end

	local size = inv:get_size(name)
	local stackmax = currency.stackmax
	local total = 0

	-- We check each slot individually.
	for i=1, size, 1 do
		local stack = inv:get_stack(name, i)

		if stack:is_empty() then
			-- An emtpy stack can fit the maximum amount of the largest denomination.
			total = total + (stackmax * currency_values[5])
		else
			-- If the stack is not empty, check if it's a currency type.
			-- If not a currency type, then we cannot use this inventory slot.
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				local freespace = stack:get_free_space()

				-- This slot can fit this much extra value.
				total = total + (freespace * currency_values_by_name[sn])
			end
		end

		-- Check if total space is the amount needed.
		-- Exit inventory checking as early as possible.
		if total >= amount then
			return true
		end
	end

	-- Inventory does not have space for cash.
	return false
end

-- Test func.
function currency.room(pname, amount)
	local player = minetest.get_player_by_name(pname)
	local inv = player:get_inventory()
	local room = currency.room_for_cash(inv, "main", amount)
	if room then
		minetest.chat_send_player("MustTest", "# Server: <" .. rename.gpn(pname) .. "> has room for " .. amount .. " minegeld!")
	else
		minetest.chat_send_player("MustTest", "# Server: <" .. rename.gpn(pname) .. "> does NOT have room for " .. amount .. " minegeld!")
	end
end



-- Try to add the given amount of cash to the inventory.
-- It is not an error if the inventory does not have enough space.
function currency.add_cash(inv, name, amount)
	if amount < 0 then
		return
	end

	local size = inv:get_size(name)
	local stackmax = currency.stackmax
	local remainder = amount
	local largest_denom = 5

	-- We check each slot individually.
	for i=1, size, 1 do
		local stack = inv:get_stack(name, i)

		if stack:is_empty() and largest_denom > 0 then
			-- Calculate how many of our (current) largest denomination we need to get close to the remaining value.
			local count
			::try_again::
			count = math.modf(remainder / currency_values[largest_denom])

			-- If none of the (current) largest denomination fit, we need to switch to smaller notes.
			-- Since the smallest note has a value of 1, then `largest_denom` should never go to 0.
			if count <= 0 then
				largest_denom = largest_denom - 1
				if largest_denom <= 0 then
					return -- Should never happen anyway.
				end
				goto try_again
			else
				-- Fill this slot with our (current) largest denomination and subtract the value from the remaining value.
				local can_add = math.min(count, stackmax)
				inv:set_stack(name, i, ItemStack(currency_names[largest_denom] .. " " .. can_add))
				remainder = remainder - (currency_values[largest_denom] * can_add)
			end
		else
			-- If the stack is not empty, check if it's a currency type.
			-- If not a currency type, then we cannot use this inventory slot.
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				local freespace = stack:get_free_space()

				-- Calculate how many notes of the slot's denomination we need to try and stuff into this slot to get close to the remaining value.
				local count = math.modf(remainder / currency_values_by_name[sn])

				if count > 0 then
					-- Calculate the number of notes we can/should add to this slot.
					-- Add them, and subtract the applied value from the remaining value.
					local can_add = math.min(count, freespace)
					stack:set_count(stack:get_count() + can_add)
					inv:set_stack(name, i, stack)
					remainder = remainder - (currency_values_by_name[sn] * can_add)
				end
			end
		end

		-- If all value was added, we can quit early.
		if remainder <= 0 then
			return
		end
	end
end

-- Test func.
function currency.add(pname, amount)
	local player = minetest.get_player_by_name(pname)
	local inv = player:get_inventory()
	currency.add_cash(inv, "main", amount)
end



-- Try to remove a given amount of cash from the inventory.
-- It is not an error if the inventory has less than the given amount.
function currency.remove_cash(inv, name, amount)
	if amount < 0 then
		return
	end

	local available = {}
	local remainder = amount
	local do_stack_split = false
	local size

	::try_again::

	-- Will store data relating to all available cash stacks in the inventory.
	-- Stores stack name, count, and inventory slot index.
	available = {}

	-- Iterate the inventory and find all cash stacks.
	size = inv:get_size(name)
	for i=1, size, 1 do
		local stack = inv:get_stack(name, i)
		if not stack:is_empty() then
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				table.insert(available, {name=sn, count=stack:get_count(), index=i})
			end
		end
	end

	if do_stack_split then
		-- Sort table so that SMALLEST denominations come first.
		table.sort(available,
			function(a, b)
				if currency_values_by_name[a.name] < currency_values_by_name[b.name] then
					return true
				end
			end)
	else
		-- Sort table so that largest denominations come first.
		table.sort(available,
			function(a, b)
				if currency_values_by_name[a.name] > currency_values_by_name[b.name] then
					return true
				end
			end)
	end

	-- For each cash stack, remove bits from the inventory until the whole amount
	-- of cash to remove has been accounted for. Note: this requires the cash
	-- stacks to be sorted largest first!
	for k, v in ipairs(available) do
		local value = currency_values_by_name[v.name]
		local count = math.modf(remainder / value)

		if count > 0 then
			local can_del = math.min(count, v.count)
			local stack = ItemStack(v.name .. " " .. (v.count - can_del))
			inv:set_stack(name, v.index, stack)
			remainder = remainder - (can_del * value)
		else
			-- The current cash stack is of a denomination much larger than the remaining cash we need to remove.
			-- If this is our second iteration through the cash stacks, then we'll have to split the stack into a smaller denomination.
			if do_stack_split then
				-- Remove 1 banknote from the stack, this should cover the whole of the remaining amount + some overcost.
				local stack = ItemStack(v.name .. " " .. (v.count - 1))
				inv:set_stack(name, v.index, stack)
				remainder = remainder - value

				-- Add back the overcost.
				if remainder < 0 then
					local add_back = math.abs(remainder)
					if add_back > 0 then -- Should never be less than 1, but just in case.
						-- If this doesn't fit, oh well, the player has lost some cash.
						-- They shouldn't be letting their inventory become clogged!
						currency.add_cash(inv, name, add_back) -- Might fail to add the whole amount.
						remainder = remainder + add_back

						-- We should only have to split a large denomination ONCE. We can exit here.
						return
					end
				end
			end
		end

		if remainder <= 0 then
			break
		end
	end

	-- If we didn't remove as much cash as we should have, try again, this time splitting the larger denominations.
	if not do_stack_split then
		if remainder > 0 then
			do_stack_split = true
			goto try_again
		end
	end
end

-- Test func.
function currency.remove(pname, amount)
	local player = minetest.get_player_by_name(pname)
	local inv = player:get_inventory()
	currency.remove_cash(inv, "main", amount)
end



-- Tell whether the inventory has at least a given amount of cash.
function currency.has_cash_amount(inv, name, amount)
	return (currency.get_cash(inv, name) >= amount)
end



-- Get the amount of cash in the inventory.
function currency.get_cash_value(inv, name)
	local amount = 0
	local size = inv:get_size(name)
	for i=1, size, 1 do
		local stack = inv:get_stack(name, i)
		if not stack:is_empty() then
			local n = stack:get_name()
			for k, v in ipairs(currency_names) do
				if n == v then
					amount = amount + (currency_values_by_name[n] * stack:get_count())
					break
				end
			end
		end
	end
	return amount
end

-- Test func.
function currency.tell(pname)
	local player = minetest.get_player_by_name(pname)
	local inv = player:get_inventory()
	local amount = currency.get_cash_value(inv, "main")
	minetest.chat_send_player("MustTest", "# Server: <" .. rename.gpn(pname) .. "> has " .. amount .. " minegeld!")
end



if not currency.registered then
	dofile(currency.modpath .. "/craftitems.lua")
	dofile(currency.modpath .. "/crafting.lua")

	local c = "currency:core"
	local f = currency.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	currency.registered = true
end

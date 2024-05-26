
if not minetest.global_exists("currency") then currency = {} end
currency.modpath = minetest.get_modpath("currency")
currency.stackmax = 256
currency.data = currency.data or {}
currency.dirty = true
currency.filename = minetest.get_worldpath() .. "/currency.txt"

-- Localize for performance.
local math_floor = math.floor
local math_min = math.min
local math_max = math.max

-- Test functions. These are also part of the public API, and work with the player's main inventory ("main").
--
-- function currency.room(pname, amount)
-- function currency.add(pname, amount)
-- function currency.remove(pname, amount)
-- function currency.tell(pname)
-- function currency.has(pname, amount)
--
-- Base API functions for managing fungible currency as itemstacks.
--
-- function currency.is_currency(name)
-- function currency.get_stack_value(name, count)
-- function currency.room_for_cash(inv, name, amount)
-- function currency.add_cash(inv, name, amount)
-- function currency.remove_cash(inv, name, amount)
-- function currency.has_cash_amount(inv, name, amount)
-- function currency.get_cash_value(inv, name)
-- function currency.needed_empty_slots(amount)
-- function currency.safe_to_remove_cash(inv, name, amount)



local currency_names = {
	"currency:minegeld",
	"currency:minegeld_2",
	"currency:minegeld_5",
	"currency:minegeld_10",
	"currency:minegeld_20",
	"currency:minegeld_50",
	"currency:minegeld_100",
}

local currency_values = {1, 2, 5, 10, 20, 50, 100}

local currency_values_by_name = {
	["currency:minegeld"] = 1,
	["currency:minegeld_2"] = 2,
	["currency:minegeld_5"] = 5,
	["currency:minegeld_10"] = 10,
	["currency:minegeld_20"] = 20,
	["currency:minegeld_50"] = 50,
	["currency:minegeld_100"] = 100,
}

local currency_count = 7 -- Number of denominations.

-- Export as public API (indexed arrays).
currency.note_names = currency_names
currency.note_values = currency_values


-- Obtain the total value given a denomination and a count of the number of banknotes.
function currency.get_stack_value(name, count)
	if count <= 0 then
		return 0
	end
	local val = currency_values_by_name[name]
	if not val then
		return 0
	end
	return val * count
end



function currency.is_currency(name)
	for k, v in ipairs(currency_names) do
		if v == name then
			return true
		end
	end

	return false
end



-- This computes the number of inventory slots that would be needed to store the
-- given amount of cash as itemstacks, assuming the cash is not combined with any
-- cash stacks already in the inventory. This can be used when it is necessary to
-- absolutely guarantee that an inventory has enough space.
function currency.needed_empty_slots(amount)
	local wanted_slots = 0
	local stackmax = currency.stackmax
	local remainder = amount

	local idx = currency_count
	while idx > 0 do
		local denom = currency_values[idx]
		local count = math.modf(remainder / denom)
		while count > 0 do
			local can_add = math_min(count, stackmax)
			remainder = remainder - (can_add * denom)
			wanted_slots = wanted_slots + 1
			count = count - can_add
		end
		idx = idx - 1
	end

	return wanted_slots
end



-- Tell whether the inventory has enough room for the given amount of cash.
-- Try largest denominations first.
-- Note: function assumes that cash stacks are combined whenever possible when adding the cash.
-- However, the order in which cash may be combined with preexisting stacks is not specified.
-- This means that you may need a few empty slots to be available, depending on how the remainder is split up.
-- If no empty slots are found in such a case, this function will return false, even if there would be another possible way to combine the stacks.
-- The solution is to keep your inventory from becoming clogged, so you always have a few empty slots.
function currency.room_for_cash(inv, name, amount)
	if amount < 0 then
		return true
	end

	local size = inv:get_size(name)
	local stackmax = currency.stackmax
	local remainder = amount

	local available = {}

	-- First, iterate the inventory and find all existing cash stacks.
	-- We must sort them so that largest denominations come first.
	for i=1, size, 1 do
		local stack = inv:get_stack(name, i)
		if not stack:is_empty() then
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				table.insert(available, {name=sn, index=i});
			end
		else
			table.insert(available, {name="", index=i})
		end
	end

	-- Sort! Largest denomination first, empty slots last.
	table.sort(available,
		function(a, b)
			-- If the slot is empty (has a blank name) then its value is 0.
			local v1 = currency_values_by_name[a.name] or 0
			local v2 = currency_values_by_name[b.name] or 0
			if v1 > v2 then
				return true
			end
		end)

	-- We check each slot individually.
	for i=1, #available, 1 do
		local stack = inv:get_stack(name, available[i].index)

		if stack:is_empty() then
			local denom
			local count = 0

			-- Find the denomination value just smaller than the remaining cash we need to fit.
			local idx = currency_count
			while count < 1 and idx > 0 do
				denom = currency_values[idx]
				count = math.modf(remainder / denom)
				idx = idx - 1
			end

			if count > 0 then
				local can_add = math_min(count, stackmax)
				remainder = remainder - (denom * can_add)
			end
		else
			-- If the stack is not empty, check if it's a currency type.
			-- If not a currency type, then we cannot use this inventory slot.
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				local freespace = stack:get_free_space()
				if freespace > 0 then
					local denom = currency_values_by_name[sn]
					local count = math.modf(remainder / denom)

					-- We must ignore the slot if its denomination value is larger than the
					-- remainding value we need to check space for; this is because we can't
					-- put any of that remaining value in this slot. If, on the other hand,
					-- the slot's denomination value was smaller than the remaining value,
					-- then we could put part of the remaining value in the slot and continue
					-- checking other slots for space to hold the rest.
					if count > 0 then
						local can_add = math_min(count, freespace)
						remainder = remainder - (denom * can_add)
					end
				end
			end
		end

		-- Check if we managed to fit everything.
		-- Exit inventory checking as early as possible.
		if remainder <= 0 then
			return true
		end
	end

	-- Inventory does not have space for cash.
	return false
end

-- Test func.
function currency.room(pname, amount)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return false
	end
	local inv = player:get_inventory()
	if not inv then
		return false
	end
	local room = currency.room_for_cash(inv, "main", amount)
	return room
end



-- Try to add the given amount of cash to the inventory.
-- It is not an error if the inventory does not have enough space.
-- Note: it is critical to combine stacks first, before taking up free slots.
-- All cash is guaranteed to be added only if you have first checked if all the cash can fit with `currency.room_for_cash`.
function currency.add_cash(inv, name, amount)
	if amount < 0 then
		return
	end

	local size = inv:get_size(name)
	local stackmax = currency.stackmax
	local remainder = amount
	local largest_denom = currency_count

	local available = {}

	-- First, iterate the inventory and find all existing cash stacks.
	-- We must sort them so that largest denominations come first.
	for i=1, size, 1 do
		local stack = inv:get_stack(name, i)
		if not stack:is_empty() then
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				table.insert(available, {name=sn, index=i});
			end
		else
			table.insert(available, {name="", index=i})
		end
	end

	-- Sort! Largest denomination first, empty slots last.
	table.sort(available,
		function(a, b)
			-- If the slot is empty (has a blank name) then its value is 0.
			local v1 = currency_values_by_name[a.name] or 0
			local v2 = currency_values_by_name[b.name] or 0
			if v1 > v2 then
				return true
			end
		end)

	-- Now that the slots have been ordered, we can go through them and add the cash as needed.

	-- We check each slot individually.
	for i=1, #available, 1 do
		local stack = inv:get_stack(name, available[i].index)

		if stack:is_empty() then
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
				local can_add = math_min(count, stackmax)
				inv:set_stack(name, available[i].index, ItemStack(currency_names[largest_denom] .. " " .. can_add))
				remainder = remainder - (currency_values[largest_denom] * can_add)
			end
		else
			-- If the stack is not empty, check if it's a currency type.
			-- If not a currency type, then we cannot use this inventory slot.
			local sn = stack:get_name()
			if currency.is_currency(sn) then
				local freespace = stack:get_free_space()
				if freespace > 0 then
					-- Calculate how many notes of the slot's denomination we need to try and stuff into this slot to get close to the remaining value.
					local count = math.modf(remainder / currency_values_by_name[sn])

					-- We must ignore the slot if the denomination value is larger than the remaining cash we need to add.
					if count > 0 then
						-- Calculate the number of notes we can/should add to this slot.
						-- Add them, and subtract the applied value from the remaining value.
						local can_add = math_min(count, freespace)
						stack:set_count(stack:get_count() + can_add)
						inv:set_stack(name, available[i].index, stack)
						remainder = remainder - (currency_values_by_name[sn] * can_add)
					end
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
	if not player or not player:is_player() then
		return
	end
	local inv = player:get_inventory()
	if not inv then
		return
	end
	currency.add_cash(inv, "main", amount)
end



-- In general, it is always safe to remove a given amount of cash from an inventory,
-- if the SAME amount can be added to it. This is because, while removing cash can
-- cause stacks to be split, those split stacks together will never be more than
-- the total value to be removed, and therefore they can always be safely added
-- if there was room to add the whole value in the first place.
function currency.safe_to_remove_cash(inv, name, amount)
	if currency.room_for_cash(inv, name, amount) then
		return true
	end
	return false
end



-- Try to remove a given amount of cash from the inventory.
-- It is not an error if the inventory has less than the wanted amount.
-- Warning: in some cases it is necessary to split large bills into smaller ones
-- in order to remove the requested amount of value! If the inventory does not
-- have enough space to fit the smaller bills once the large bill has been split,
-- then value will be LOST.
function currency.remove_cash(inv, name, amount)
	if amount < 0 then
		return
	end

	local available = {}
	local remainder = amount
	local do_stack_split = false
	local size

	-- On the first iteration through the inventory, we try to fulfill the removing of cash
	-- using just the banknotes in the inventory. If we cannot remove the requested amount
	-- of cash using this method, then we iterate the inventory again, this time in order to
	-- find and split banknotes as needed.
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
		-- This is done in order to prevent the proliferation of small bills in a given inventory,
		-- if cash is removed often. Basically, by sorting smallest first, we ensure that
		-- smaller bills are consumed first when removing cash.
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
			local can_del = math_min(count, v.count)
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
	if not player or not player:is_player() then
		return
	end
	local inv = player:get_inventory()
	if not inv then
		return
	end
	currency.remove_cash(inv, "main", amount)
end



-- Tell whether the inventory has at least a given amount of cash.
function currency.has_cash_amount(inv, name, amount)
	return (currency.get_cash_value(inv, name) >= amount)
end

function currency.has(pname, amount)
	return (currency.tell(pname) >= amount)
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
	if not player or not player:is_player() then
		return 0
	end
	local inv = player:get_inventory()
	if not inv then
		return 0
	end
	local amount = currency.get_cash_value(inv, "main")
	return amount
end



-- Helper function to calculate tax based on whether transaction is a purchase or a deposit.
function currency.calculate_tax(amount, type, tax)
	local calc_part = function(w, p) local x = (w * p) return x / 100 end

	if type == 1 then
		-- Purchasing.
		local wtax = amount + calc_part(amount, tax)
		return math_floor(wtax)
	elseif type == 2 then
		-- Depositing.
		local wtax = amount - calc_part(amount, tax)
		wtax = math_max(wtax, 1)
		return math_floor(wtax)
	end

	-- Fallback (should never happen).
	return math_floor(amount)
end



-- Shall be called whenever stuff is purchased (vending/depositing) and tax is added/deducted.
-- The tax value is stored so we keep track of how much currency from taxes we have.
function currency.record_tax_income(amount)
	if amount <= 0 then
		return
	end

	if not currency.data.taxes_stored then
		currency.data.taxes_stored = 0
	end

	currency.data.taxes_stored = currency.data.taxes_stored + amount
	currency.dirty = true
end



function currency.load()
	currency.data = {}
	local file, err = io.open(currency.filename, "r")
	if err then
		if not err:find("No such file") then
			minetest.log("error", "Failed to open " .. currency.filename .. " for reading: " .. err)
		end
	else
		local datastring = file:read("*all")
		if datastring and datastring ~= "" then
			local data = minetest.deserialize(datastring)
			if data and type(data) == "table" then
				currency.data = data
			end
		end
		file:close()
	end
	currency.dirty = false
end



function currency.save()
	if currency.dirty then
		-- Save data.
		local file, err = io.open(currency.filename, "w")
		if err then
			minetest.log("error", "Failed to open " .. currency.filename .. " for writing: " .. err)
		else
			local datastring = minetest.serialize(currency.data)
			if datastring then
				file:write(datastring)
			end
			file:close()
		end
	end
	currency.dirty = false
end



if not currency.registered then
	dofile(currency.modpath .. "/craftitems.lua")
	dofile(currency.modpath .. "/crafting.lua")

	currency.load()

	local c = "currency:core"
	local f = currency.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	currency.registered = true
end

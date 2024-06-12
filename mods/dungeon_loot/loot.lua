
-- Localize for performance.
local math_random = math.random

local function get_max_loot(loot_list, depth)
	local loot_type = loot_list[1].name
	local loot_min_depth = loot_list[1].min_depth
	for i,v in ipairs(loot_list) do
		if v.min_depth < depth then
			loot_type = v.name
			loot_min_depth = v.min_depth
		else
			break
		end
	end
	return loot_type, loot_min_depth
end

local function get_basic_loot(loot_list, depth)
	local loot_type = ""
	local loot_amount = 0
	local total_chance = 0
	for i,v in ipairs(loot_list) do
		if v.chance_and_amount then
			total_chance = total_chance + v.chance_and_amount
		elseif v.chance then
			total_chance = total_chance + v.chance
		else
			error("No chance_and_amount or chance found in basic_list table.")
			return nil, 0
		end
	end
	local leftover = math_random(1,total_chance)
	local type_amount = 0
	for i,v in ipairs(loot_list) do
		if v.chance_and_amount then
			leftover = leftover - v.chance_and_amount
		elseif v.chance then
			leftover = leftover - v.chance
		end
		if leftover < 1 then
			loot_type = v.name
			if v.chance_and_amount then
				type_amount = v.chance_and_amount
			else
				type_amount = v.amount
			end
			break
		end
	end
	if loot_type == "" then 	-- Paranoia
		error("Unable to choose a loot_type from basic_list table.")
		return nil, 0
	end
	loot_amount = math_random(1,math.ceil(type_amount/2))
	if depth > dungeon_loot.depth_first_basic_increase then
		loot_amount = math_random(1,type_amount)
	end
	if depth > dungeon_loot.depth_second_basic_increase then
		loot_amount = math_random(1,type_amount*2)
	end
	return loot_type, loot_amount
end

local function get_item_and_amount(list_item, actual_depth)
	if list_item.chance < math_random() then
		return nil, 0
	end

	-- This must point to a table.
	local list_key = list_item.name .. "_list"
	local list_name = dungeon_loot[list_key]

	-- Suspicious trickery.
	--[[
	list_name_string = "dungeon_loot." .. list_item.name .. "_list"
-- 	list_name = _G[list_name_string]
	lsf = loadstring("list_name = " .. list_name_string)
	lsf()
	--]]
	-- ^ What the H. - MustTest.

	if list_name == nil then
		error("Unable to connect \"" .. list_key .. "\" to actual table")
		return nil, 0
	end

	local amount = 0
	local loot_type = ""
	local loot_depth = 0
	local max_depth = 1

	if actual_depth < 0 then
		max_depth = math.ceil(math.abs(actual_depth))
	end

	if list_item.type == "depth_cutoff" then
		local rnd_depth = math_random(1,max_depth)
 		loot_type, loot_depth = get_max_loot(list_name, rnd_depth)
		if list_item.max_amount == 1 then 	-- For tools & weapons
			amount = 1
		else
			-- Stop large amounts of the first item
			if loot_depth < 1 then
				loot_depth = 5
			end
			local leftover = rnd_depth
			while leftover > 0 do
				amount = amount + 1
				leftover = leftover - math_random(1,loot_depth)
				leftover = leftover - math.ceil(loot_depth/2)
			end
		end
	elseif list_item.type == "basic_list" then
		loot_type, amount = get_basic_loot(list_name, max_depth)
	else
		error("Got unknown loot table type " .. list_item.type)
		loot_type = nil
	end
	-- Hey, if you leave out the max_amount, you deserve what you get
	if list_item.max_amount and amount > list_item.max_amount then
		amount = list_item.max_amount
	end
	return loot_type, amount
end

function dungeon_loot.fill_chest(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	for i, v in ipairs(dungeon_loot.loot_types) do
		local item, num = get_item_and_amount(v,pos.y)
		if item then
			if minetest.registered_items[item] then -- Ensure not unknown item.
				local stack = ItemStack({name = item, count = num, wear = 0, metadata = ""})
				inv:set_stack("main", i, stack)
			end
		end
	end
end

-- Place chest in dungeons

function dungeon_loot.place_loot_chest(tab)
	if tab == nil or #tab < 1 then
		return
	end

	-- Random number of chests.
	local count = math_random(1, 3)

	for k = 1, count do
		local pos = tab[math_random(1, #tab)]

		local minp = vector.offset(pos, -5, -5, -5)
		local maxp = vector.offset(pos, 5, 5, 5)
		local targets = minetest.find_nodes_in_area_under_air(minp, maxp, dungeon_loot.DUNGEON_NODES)

		if targets and #targets > 0 then
			local target = targets[math_random(1, #targets)]
			local param2 = math_random(0, 3)
			local above = vector.offset(target, 0, 1, 0)
			if minetest.get_node(above).name == "air" then
				local cnodes = dungeon_loot.CHEST_NODES
				local chest_node = cnodes[math_random(1, #cnodes)]
				minetest.set_node(above, {name = chest_node, param2 = param2})
				dungeon_loot.fill_chest(above)
			end
		end
	end
end

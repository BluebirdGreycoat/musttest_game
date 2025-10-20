
-- Quickly check for protection in an area.
function fortress.is_protected(minp, maxp)
	-- Step size, to avoid checking every single node.
	-- This assumes protections cannot be smaller than this size.
	local ss = 5
	local check = minetest.test_protection

	for x=minp.x, maxp.x, ss do
		for y=minp.y, maxp.y, ss do
			for z=minp.z, maxp.z, ss do
				if check({x=x, y=y, z=z}, "") then
					-- Protections are present.
					return true
				end
			end
		end
	end

	-- Nothing in the area is protected.
	return false
end

function fortress.add_loot_items(pos, loot)
	local meta = minetest.get_meta(pos)
	if not meta then return end
	local inv = meta:get_inventory()
	if not inv then return end
	local list = inv:get_list("main")
	if not list then return end

	local lootdef = fortress.loot[loot]
	if not lootdef then return end

	local chosen_items = {}
	local chosen_positions = {}

	-- Size of chest inventory.
	local inv_size = inv:get_size("main")
	for i = 1, inv_size do
		chosen_positions[i] = i
	end
	table.shuffle(chosen_positions)

	for k, v in ipairs(lootdef.item_list) do
		local min = v.min or 1
		local max = v.max or 1
		local chance = v.chance or 100

		if math.random(1, 100) <= chance then
			-- Only if named item actually exists.
			if minetest.registered_items[v.item] then
				local itemstr = (v.item .. " " .. math.random(min, max))
				chosen_items[#chosen_items+1] = itemstr
			end
		end
	end

	-- Randomize the order of items, and we will chose the first few up to
	-- 'max_items' allowed.
	table.shuffle(chosen_items)

	for k, v in ipairs(chosen_items) do
		-- Don't add more items than would actually fit, if for some reason the
		-- number of chosen items is larger than the inventory size.
		if k <= inv_size then
			list[chosen_positions[k]] = v

			-- Stop once max-items is reached.
			if k >= lootdef.max_items then
				break
			end
		end
	end

	inv:set_list("main", list)
end


local MINTIME = 60*1
local MAXTIME = 60*15
local SPAWNCHEST_POS = {x=-9222, y=4569, z=5859}

local ITEMS = {
	{item="default:sword_mese", chance=1, tool=true},
	{item="default:sword_steel", chance=5, tool=true},
	{item="default:pick_wood", chance=40, tool=true},
	{item="default:pick_stone", chance=20, tool=true},
	{item="torches:torch_floor", chance=20, min=1, max=5},
	{item="default:flint", chance=8, min=1, max=2},
	{item="default:steel_ingot", chance=6, min=1, max=2},
	{item="default:copper_ingot", chance=4, min=1, max=2},
	{item="mobs:meat_mutton", chance=10, min=1, max=10},
	{item="tinderbox:tinderbox", chance=10, min=1, max=1},
	{item="default:compass", chance=10, min=1, max=1},
	{item="clock:calendar", chance=10, min=1, max=1},
	{item="default:sapling", chance=3, min=1, max=1},
	{item="default:papyrus", chance=3, min=1, max=5},
	{item="farming:wheat", chance=15, min=1, max=5},

	-- Armor.
	{item="3d_armor:helmet_wood", chance=3, min=1, max=1, tool=true},
	{item="3d_armor:leggings_wood", chance=3, min=1, max=1, tool=true},
	{item="3d_armor:boots_wood", chance=3, min=1, max=1, tool=true},
	{item="3d_armor:chestplate_wood", chance=1, min=1, max=1, tool=true},
	{item="shields:shield_wood", chance=3, min=1, max=1, tool=true},
}

function serveressentials.add_loot_to_spawnchest()
	local meta = minetest.get_meta(SPAWNCHEST_POS)
	if not meta then return end

	local inv = meta:get_inventory()
	if not inv then return end

	-- Never adjust inventory while the chest is open.
	local node = minetest.get_node_or_nil(SPAWNCHEST_POS)
	if node then
		if node.name:find("_open") then
			return
		end
	end

	for _, entry in ipairs(ITEMS) do
		if math.random(1, 100) <= entry.chance then
			local stack = ItemStack(entry.item)
			stack:set_count(math.random(entry.min or 1, entry.max or 1))

			-- Randomly damage tools.
			if entry.tool and math.random(1, 10) > 3 then
				stack:set_wear(math.random(10, 60000))
			end

			inv:add_item("main", stack)
		end
	end

	local list = inv:get_list("main")
	local numslots = 0
	for _, item in ipairs(list) do
		if item:get_count() > 0 then
			numslots = numslots + 1
		end
	end
	if numslots > ((#list / 3) * 2) then
		-- Delete some random items.
		for i = 1, 5, 1 do
			local index = math.random(1, #list)
			list[index] = ItemStack("")
		end
		-- Randomly swap the locations of others.
		for i = 1, 5, 1 do
			local index1 = math.random(1, #list)
			local index2 = math.random(1, #list)
			local stack = list[index1]
			list[index1] = list[index2]
			list[index2] = stack
		end
		inv:set_list("main", list)
	end

	-- Call self on a loop.
	minetest.after(math.random(MINTIME, MAXTIME), function()
		serveressentials.add_loot_to_spawnchest()
	end)
end

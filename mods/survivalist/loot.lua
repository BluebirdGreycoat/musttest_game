
-- Localize for performance.
local math_floor = math.floor
local math_random = math.random



local critical_loot = {
	-- The main problem with the `surface` challenge is keeping it from being too easy.
	-- This is especially due to travel being very swift, and too much food can go a long way.
	["surface"] = {
		{item="default:stick", min=5, max=20},
		{item="farming:bread", min=5, max=20},
		{item="default:steel_ingot", min=5, max=20},
		{item="default:diamond", min=3, max=9},
		{item="bones:bones_type2", min=9, max=27},
		{item="torches:torch_floor", min=10, max=30},
		{item="bucket:bucket_water", min=1, max=4},
		{item="default:dirt", min=6, max=12},
	},

	-- The challenge of `cave` mode is building a farm to make food and keep going.
	-- Finding sources of iron and coal are critical. Farm supplies have to be provided
	-- right away because otherwise the gamemode would probably be impossible.
	["cave"] = {
		{item="default:stick", min=10, max=30},
		{item="farming:bread", min=10, max=50},
		{item="basictrees:tree_apple", min=10, max=50},
		{item="pumpkin:bread", min=10, max=30},
		{item="default:steel_ingot", min=30, max=64},
		{item="default:coal_lump", min=30, max=64},
		{item="bones:bones_type2", min=10, max=40},
		{item="default:dirt", min=6, max=12},
		{item="torches:torch_floor", min=10, max=30},
		{item="bucket:bucket_water", min=4, max=12},
		{item="default:grass_dummy", min=5, max=20},
		{item="moreblocks:super_glow_glass", min=6, max=20},
		{item="rackstone:dauthsand", min=3, max=6},
		{item="firetree:sapling", min=2, max=3},
		{item="griefer:grieferstone", min=2, max=4},
		{item="titanium:crystal", min=3, max=16},
	},

	-- Like `cave` mode, in this gamemode building a farm and finding sources of iron and coal are critical.
	["nether"] = {
		{item="default:stick", min=10, max=30},
		{item="farming:bread", min=10, max=50},
		{item="basictrees:tree_apple", min=10, max=50},
		{item="default:steel_ingot", min=30, max=64},
		{item="default:coal_lump", min=30, max=64},
		{item="gems:ruby_gem", min=3, max=13},
		{item="torches:kalite_torch_floor", min=10, max=25},
		{item="moreblocks:super_glow_glass", min=6, max=20},
		{item="rackstone:dauthsand", min=3, max=12},
		{item="firetree:sapling", min=2, max=3},
		{item="default:flint", min=3, max=5},
		{item="bluegrass:seed", min=3, max=16},
		{item="griefer:grieferstone", min=2, max=4},
		{item="titanium:crystal", min=3, max=16},

		{item="default:cobble", min=1, max=64},
		{item="default:cobble", min=1, max=64},
		{item="default:cobble", min=1, max=64},

		-- Nether challenge must have bed, because otherwise it is too
		-- difficult/impossible to craft one.
		{item="beds:fancy_bed_bottom", min=3, max=5},
	},
}



local bonus_loot = {
	{item="farming:seed_wheat", min=2, max=6, chance=40},
	{item="farming:seed_cotton", min=2, max=6, chance=40},
	{item="potatoes:seed", min=2, max=6, chance=40},
	{item="default:junglegrass", min=2, max=6, chance=40},
	{item="default:cactus", min=2, max=6, chance=40},
	{item="bandages:bandage_3", min=5, max=30, chance=40},
	{item="carbon_steel:ingot", min=5, max=30, chance=40},
	{item="default:mese_crystal", min=5, max=30, chance=40},
}



function survivalist.fill_loot_chest(inv, gamemode)
	if not inv then
		return
	end

  local loot = {}
  local critical = critical_loot[gamemode]
  if not critical then
		return
	end
  loot = table.copy(critical)
  table.shuffle(loot)

  local positions = {}
  local listsize = inv:get_size("main")
  for i = 1, listsize, 1 do
		positions[#positions + 1] = i
  end
  table.shuffle(positions)

  -- Add loot.
	for k, v in ipairs(loot) do
		local min = math_floor(v.min)
		local max = math.ceil(v.max)

		if max >= min then
			local count = math_floor(math_random(min, max))
			if count > 0 and #positions > 0 then
				local idx = positions[#positions]
				positions[#positions] = nil
				inv:set_stack("main", idx, ItemStack(v.item .. " " .. count))
			end
		end
	end

	local bonus = table.copy(bonus_loot)
	table.shuffle(bonus)

	-- Add bonus loot.
	for k, v in ipairs(bonus) do
		local min = math_floor(v.min)
		local max = math.ceil(v.max)

		if max >= min then
			local count = math_floor(math_random(min, max))
			local chance = math_random(0, 100)
			if count > 0 and #positions > 0 and chance < v.chance then
				local idx = positions[#positions]
				positions[#positions] = nil
				inv:set_stack("main", idx, ItemStack(v.item .. " " .. count))
			end
		end
	end
end

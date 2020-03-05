
function survivalist.fill_loot_chest(inv, gamemode)
	if not inv then
		return
	end
  local loot = {}

  if gamemode == "surface" then
    -- The main problem with the `surface` challenge is keeping it from being too easy.
    -- This is especially due to travel being very swift, and too much food can go a long way.
    loot = {
      {item="default:stick", min=1, max=20},
      {item="farming:bread", min=1, max=10},
      {item="basictrees:tree_apple", min=1, max=20},
      {item="pumpkin:bread", min=1, max=10},
      {item="default:steel_ingot", min=3, max=15},
      {item="default:diamond", min=1, max=8},
      {item="bones:bones_type2", min=1, max=25},
      {item="torches:torch_floor", min=10, max=30},
    }
  elseif gamemode == "cave" then
    -- The challenge of `cave` mode is building a farm to make food and keep going.
    -- Finding sources of iron and coal are critical. Farm supplies have to be provided
    -- right away because otherwise the gamemode would probably be impossible.
    loot = {
      {item="default:stick", min=10, max=30},
      {item="farming:bread", min=10, max=20},
      {item="basictrees:tree_apple", min=10, max=20},
      {item="pumpkin:bread", min=10, max=20},
      {item="default:steel_ingot", min=30, max=64},
      {item="bones:bones_type2", min=10, max=40},
      {item="default:dirt", min=3, max=6},
      {item="torches:torch_floor", min=10, max=30},
      {item="bucket:bucket_water", min=1, max=4},
      {item="default:grass_dummy", min=1, max=10},
      {item="moreblocks:super_glow_glass", min=6, max=10},
      {item="rackstone:dauthsand", min=3, max=6},
      {item="firetree:sapling", min=1, max=2},
      {item="griefer:grieferstone", min=1, max=4},
      {item="titanium:crystal", min=3, max=8},
    }
  elseif gamemode == "nether" then
    -- Like `cave` mode, in this gamemode building a farm and finding sources of iron and coal are critical.
    loot = {
      {item="default:stick", min=1, max=30},
      {item="farming:bread", min=10, max=30},
      {item="basictrees:tree_apple", min=10, max=20},
      {item="default:steel_ingot", min=30, max=64},
      {item="default:coal_lump", min=30, max=64},
      {item="gems:ruby_gem", min=3, max=13},
      {item="torches:kalite_torch_floor", min=10, max=25},
      {item="moreblocks:super_glow_glass", min=3, max=10},
      {item="rackstone:dauthsand", min=3, max=6},
      {item="firetree:sapling", min=1, max=2},
      {item="default:flint", min=5, max=16},
      {item="bluegrass:seed", min=3, max=16},
      {item="griefer:grieferstone", min=1, max=4},
      {item="titanium:crystal", min=1, max=8},
      {item="default:cobble", min=1, max=64},
      {item="beds:fancy_bed_bottom", min=1, max=3},
    }
  end

	local loot_tries = #loot * 3
	for i=1, loot_tries, 1 do
		-- Randomize the order in which loot is applied.
		local v = loot[math.random(1, #loot)]

		-- Divide min/max by 3 (logic is applied 3 times). This splits stacks up.
    local min = math.floor(v.min / 3.0)
    local max = math.ceil(v.max / 3.0)
		if max > min then
			local count = math.floor(math.random(min, max))
			if count > 0 then
				inv:set_stack("main", math.random(1, 12*4), ItemStack(v.item .. " " .. count))
			end
		end
  end
end

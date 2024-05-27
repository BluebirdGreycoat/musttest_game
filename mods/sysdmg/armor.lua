
-- These groups get merged with the items's default groups table, so group
-- names must be prefixed with "armor_".
--
-- Note: 'armor_heal' is actually "armor block chance" (1 .. 100). If block
-- chance passes, then damage is completely blocked (becomes 0). The block
-- chance is limited to a maximum of 90.
--
-- Note: 'armor_use' is the amount of wear added to armor whenever it gets
-- damaged. Armor is destroyed once wear reaches max. Lower value is better.
local BLOCK_MULT = 0.3
sysdmg.default_groups = {
  ["shields:shield_wood"] =          {armor_heal= 5*BLOCK_MULT, armor_use=2000},
  ["shields:shield_enhanced_wood"] = {armor_heal=10*BLOCK_MULT, armor_use=1000},
  ["3d_armor:helmet_wood"]         = {armor_heal= 0*BLOCK_MULT, armor_use=1000},
  ["3d_armor:chestplate_wood"]     = {armor_heal= 5*BLOCK_MULT, armor_use=1500},
  ["3d_armor:leggings_wood"]       = {armor_heal= 0*BLOCK_MULT, armor_use=1500},
  ["3d_armor:boots_wood"]          = {armor_heal= 0*BLOCK_MULT, armor_use=2000},

  ["shields:shield_steel"]         = {armor_heal=10*BLOCK_MULT, armor_use=500},
  ["3d_armor:helmet_steel"]        = {armor_heal= 0*BLOCK_MULT, armor_use=500},
  ["3d_armor:chestplate_steel"]    = {armor_heal=10*BLOCK_MULT, armor_use=500},
  ["3d_armor:leggings_steel"]      = {armor_heal= 0*BLOCK_MULT, armor_use=500},
  ["3d_armor:boots_steel"]         = {armor_heal= 0*BLOCK_MULT, armor_use=500},

  ["shields:shield_carbon"]        = {armor_heal=20*BLOCK_MULT, armor_use=200},
  ["3d_armor:helmet_carbon"]       = {armor_heal= 0*BLOCK_MULT, armor_use=200},
  ["3d_armor:chestplate_carbon"]   = {armor_heal=10*BLOCK_MULT, armor_use=200},
  ["3d_armor:leggings_carbon"]     = {armor_heal= 0*BLOCK_MULT, armor_use=200},
  ["3d_armor:boots_carbon"]        = {armor_heal= 0*BLOCK_MULT, armor_use=200},

  ["shields:shield_bronze"]        = {armor_heal=10*BLOCK_MULT, armor_use=250},
  ["3d_armor:helmet_bronze"]       = {armor_heal= 6*BLOCK_MULT, armor_use=250},
  ["3d_armor:chestplate_bronze"]   = {armor_heal=15*BLOCK_MULT, armor_use=1000},
  ["3d_armor:leggings_bronze"]     = {armor_heal= 6*BLOCK_MULT, armor_use=250},
  ["3d_armor:boots_bronze"]        = {armor_heal= 6*BLOCK_MULT, armor_use=250},

  ["shields:shield_diamond"]       = {armor_heal=15*BLOCK_MULT, armor_use=100},
  ["3d_armor:helmet_diamond"]      = {armor_heal=20*BLOCK_MULT, armor_use=100},
  ["3d_armor:chestplate_diamond"]  = {armor_heal=10*BLOCK_MULT, armor_use=100},
  ["3d_armor:leggings_diamond"]    = {armor_heal= 0*BLOCK_MULT, armor_use=100},
  ["3d_armor:boots_diamond"]       = {armor_heal= 0*BLOCK_MULT, armor_use=100},

  ["shields:shield_gold"]          = {armor_heal=10*BLOCK_MULT, armor_use=250},
  ["3d_armor:helmet_gold"]         = {armor_heal= 6*BLOCK_MULT, armor_use=250},
  ["3d_armor:chestplate_gold"]     = {armor_heal=15*BLOCK_MULT, armor_use=1000},
  ["3d_armor:leggings_gold"]       = {armor_heal= 6*BLOCK_MULT, armor_use=250},
  ["3d_armor:boots_gold"]          = {armor_heal= 6*BLOCK_MULT, armor_use=250},

  ["shields:shield_mithril"]       = {armor_heal= 8*BLOCK_MULT, armor_use=50},
  ["3d_armor:helmet_mithril"]      = {armor_heal= 5*BLOCK_MULT, armor_use=50},
  ["3d_armor:chestplate_mithril"]  = {armor_heal=10*BLOCK_MULT, armor_use=250},
  ["3d_armor:leggings_mithril"]    = {armor_heal= 5*BLOCK_MULT, armor_use=50},
  ["3d_armor:boots_mithril"]       = {armor_heal= 5*BLOCK_MULT, armor_use=50},

  ["3d_armor:helmet_cotton"]       = {armor_heal= 25*BLOCK_MULT, armor_use=700},
  ["3d_armor:chestplate_cotton"]   = {armor_heal= 35*BLOCK_MULT, armor_use=800},
  ["3d_armor:leggings_cotton"]     = {armor_heal= 15*BLOCK_MULT, armor_use=1000},
  ["3d_armor:boots_cotton"]        = {armor_heal= 15*BLOCK_MULT, armor_use=1300},

  ["3d_armor:helmet_leather"]      = {armor_heal= 20*BLOCK_MULT, armor_use=500},
  ["3d_armor:chestplate_leather"]  = {armor_heal= 25*BLOCK_MULT, armor_use=1000},
  ["3d_armor:leggings_leather"]    = {armor_heal= 10*BLOCK_MULT, armor_use=1100},
  ["3d_armor:boots_leather"]       = {armor_heal= 10*BLOCK_MULT, armor_use=1200},
}



-- Wear multipliers for when armor gets damaged by something.
sysdmg.wear_groups = {
  ["shields:shield_wood"]          = {fall=0.5, crumbly=0.1, lava=4.0, heat=2.0, ground=0.0, boom=3.0},
  ["shields:shield_enhanced_wood"] = {fall=0.5, crumbly=0.1, lava=4.0, heat=2.0, ground=0.0, boom=3.0},
  ["3d_armor:helmet_wood"]         = {fall=0.5, crumbly=0.1, lava=4.0, crush=3.0, heat=2.0, ground=0.0},
  ["3d_armor:chestplate_wood"]     = {fall=0.5, crumbly=0.1, lava=4.0, heat=2.0, ground=0.0, boom=4.0},
  ["3d_armor:leggings_wood"]       = {fall=1.25,crumbly=0.1, lava=4.0,  heat=2.0},
  ["3d_armor:boots_wood"]          = {fall=1.5, crumbly=0.1, lava=4.0, heat=2.0, ground=2.0},

  ["shields:shield_steel"]         = {fall=0.5, fleshy=0.5, lava=2.0, crumbly=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_steel"]        = {fall=0.5, fleshy=0.5, lava=2.0, crumbly=1.25, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_steel"]    = {fall=0.5, fleshy=0.5, lava=2.0, crumbly=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_steel"]      = {fall=1.25,fleshy=0.5, lava=2.0, crumbly=1.25, },
  ["3d_armor:boots_steel"]         = {fall=1.5, fleshy=0.5, lava=2.0, crumbly=1.25, ground=2.0},

  ["shields:shield_carbon"]        = {fall=0.5, snappy=0.6, fleshy=0.4, lava=1.5, crumbly=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_carbon"]       = {fall=0.5, snappy=0.6, fleshy=0.4, lava=1.5, crumbly=1.25, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_carbon"]   = {fall=0.5, snappy=0.6, fleshy=0.4, lava=1.5, crumbly=1.25, ground=0.0, boom=4.0},
  ["3d_armor:leggings_carbon"]     = {fall=1.25,snappy=0.6, fleshy=0.4, lava=1.5, crumbly=1.25, },
  ["3d_armor:boots_carbon"]        = {fall=1.5, snappy=0.6, fleshy=0.4, lava=1.5, crumbly=1.25, ground=2.0},

  ["shields:shield_bronze"]        = {fall=0.5, crush=1.25, ground=0.0, boom=0.5},
  ["3d_armor:helmet_bronze"]       = {fall=0.5, crush=3.0, ground=0.0,  boom=0.5},
  ["3d_armor:chestplate_bronze"]   = {fall=0.5, crush=1.5, ground=0.0,  boom=0.5},
  ["3d_armor:leggings_bronze"]     = {fall=1.25, crush=1.25,            boom=0.5},
  ["3d_armor:boots_bronze"]        = {fall=1.5, ground=2.0, crush=1.25, boom=0.5},

  ["shields:shield_diamond"]       = {fall=0.5, cracky=2.0, ground=0.0, boom=3.0},
  ["3d_armor:helmet_diamond"]      = {fall=0.5, cracky=2.0, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_diamond"]  = {fall=0.5, cracky=2.0, ground=0.0, boom=4.0},
  ["3d_armor:leggings_diamond"]    = {fall=1.25,cracky=2.0,  },
  ["3d_armor:boots_diamond"]       = {fall=1.5, cracky=2.0, ground=2.0},

  ["shields:shield_gold"]          = {fall=0.5, lava=0.3, heat=0.1, ground=0.0, boom=3.0},
  ["3d_armor:helmet_gold"]         = {fall=0.5, lava=0.3, heat=0.1, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_gold"]     = {fall=0.5, lava=0.3, heat=0.1, ground=0.0, boom=4.0},
  ["3d_armor:leggings_gold"]       = {fall=1.25,lava=0.3, heat=0.1,  },
  ["3d_armor:boots_gold"]          = {fall=1.5, lava=0.3, heat=0.1, ground=2.0},

  ["shields:shield_mithril"]       = {fall=0.5, fleshy=0.5, snappy=0.1, ground=0.0, boom=3.0},
  ["3d_armor:helmet_mithril"]      = {fall=0.5, fleshy=0.5, snappy=0.1, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_mithril"]  = {fall=0.5, fleshy=0.5, snappy=0.1, ground=0.0, boom=4.0},
  ["3d_armor:leggings_mithril"]    = {fall=0.8, fleshy=0.5, snappy=0.1, },
  ["3d_armor:boots_mithril"]       = {fall=0.9, fleshy=0.5, snappy=0.1, ground=2.0},

  ["3d_armor:helmet_cotton"]       = {fall=0.5, crumbly=0.1, lava=4.0, crush=3.0, heat=2.0, ground=0.0},
  ["3d_armor:chestplate_cotton"]   = {fall=0.5, crumbly=0.1, lava=4.0, heat=2.0, ground=0.0, boom=4.0},
  ["3d_armor:leggings_cotton"]     = {fall=1.25,crumbly=0.1, lava=4.0,  heat=2.0},
  ["3d_armor:boots_cotton"]        = {fall=1.5, crumbly=0.1, lava=4.0, heat=2.0, ground=2.0},

  ["3d_armor:helmet_leather"]      = {fall=0.5, crumbly=0.1, lava=4.0, crush=3.0, heat=2.0, ground=0.0},
  ["3d_armor:chestplate_leather"]  = {fall=0.5, crumbly=0.1, lava=4.0, heat=2.0, ground=0.0, boom=4.0},
  ["3d_armor:leggings_leather"]    = {fall=1.25,crumbly=0.1, lava=4.0,  heat=2.0},
  ["3d_armor:boots_leather"]       = {fall=1.5, crumbly=0.1, lava=4.0, heat=2.0, ground=2.0},
}



-- Resitance group values range from 0 .. 100.
-- Higher values give more resistance.
-- Note that the total resistance for a particular group cannot exceed 90.
sysdmg.resist_groups = {
  ["shields:shield_wood"]          = {fleshy=5,  crumbly=10, },
  ["shields:shield_enhanced_wood"] = {fleshy=8,  crumbly=20, },
  ["3d_armor:helmet_wood"]         = {fleshy=5,  crumbly=15, },
  ["3d_armor:chestplate_wood"]     = {fleshy=10, crumbly=25, },
  ["3d_armor:leggings_wood"]       = {fleshy=5,  crumbly=10, },
  ["3d_armor:boots_wood"]          = {fleshy=5,  crumbly=15, },

  ["shields:shield_steel"]         = {fleshy=10, cracky=15, snappy=10, crumbly=5},
  ["3d_armor:helmet_steel"]        = {fleshy=10, cracky=15, snappy=10, crumbly=5},
  ["3d_armor:chestplate_steel"]    = {fleshy=15, cracky=10, snappy=15, crumbly=5},
  ["3d_armor:leggings_steel"]      = {fleshy=15, cracky=10, snappy=15, crumbly=5},
  ["3d_armor:boots_steel"]         = {fleshy=10, cracky=10, snappy=10, crumbly=5},

  ["shields:shield_carbon"]        = {fleshy=12, cracky=20, snappy=10, arrow=18},
  ["3d_armor:helmet_carbon"]       = {fleshy=12, cracky=10, snappy=15, arrow=15},
  ["3d_armor:chestplate_carbon"]   = {fleshy=17, cracky=20, fireball=20, snappy=15, arrow=20},
  ["3d_armor:leggings_carbon"]     = {fleshy=17, cracky=10, snappy=15, arrow=15},
  ["3d_armor:boots_carbon"]        = {fleshy=12, cracky=10, snappy=10, arrow=12},

  ["shields:shield_bronze"]        = {fleshy=10, fireball=50, boom=20, heat=6},
  ["3d_armor:helmet_bronze"]       = {fleshy=10, crumbly=12,  boom=12, heat=6},
  ["3d_armor:chestplate_bronze"]   = {fleshy=15, crumbly=20,  boom=20, heat=16},
  ["3d_armor:leggings_bronze"]     = {fleshy=15, crumbly=12,  boom=10, heat=6},
  ["3d_armor:boots_bronze"]        = {fleshy=10, crumbly=8,   boom=10, heat=6},

  ["shields:shield_diamond"]       = {fleshy=15, choppy=20, crush=15, arrow=15},
  ["3d_armor:helmet_diamond"]      = {fleshy=15, choppy=10, crush=20, arrow=20},
  ["3d_armor:chestplate_diamond"]  = {fleshy=20, choppy=15, crush=20, arrow=20},
  ["3d_armor:leggings_diamond"]    = {fleshy=20, choppy=10, crush=15, arrow=6},
  ["3d_armor:boots_diamond"]       = {fleshy=15, choppy=10, crush=15, arrow=6},

  ["shields:shield_gold"]          = {fleshy=10, heat=8, lava=5},
  ["3d_armor:helmet_gold"]         = {fleshy=10, heat=8, lava=10},
  ["3d_armor:chestplate_gold"]     = {fleshy=15, heat=8, lava=15},
  ["3d_armor:leggings_gold"]       = {fleshy=15, heat=8, lava=15},
  ["3d_armor:boots_gold"]          = {fleshy=10, heat=8, lava=20},

  ["shields:shield_mithril"]       = {boom=10, cracky=15, fleshy=15, fireball=50},
  ["3d_armor:helmet_mithril"]      = {boom=5, cracky=8, fleshy=20, arrow=60},
  ["3d_armor:chestplate_mithril"]  = {boom=10, cracky=15, fleshy=25, fireball=25},
  ["3d_armor:leggings_mithril"]    = {boom=5, cracky=8, fleshy=25},
  ["3d_armor:boots_mithril"]       = {boom=5, cracky=8, fleshy=20},

  ["3d_armor:helmet_cotton"]       = {fleshy=5,  crumbly=15, },
  ["3d_armor:chestplate_cotton"]   = {fleshy=10, crumbly=25, },
  ["3d_armor:leggings_cotton"]     = {fleshy=5,  crumbly=10, },
  ["3d_armor:boots_cotton"]        = {fleshy=5,  crumbly=15, },

  ["3d_armor:helmet_leather"]      = {fleshy=5,  crumbly=15, },
  ["3d_armor:chestplate_leather"]  = {fleshy=10, crumbly=25, },
  ["3d_armor:leggings_leather"]    = {fleshy=5,  crumbly=10, },
  ["3d_armor:boots_leather"]       = {fleshy=5,  crumbly=15, },
}

-- Make calculating the "hard meta" rather difficult.
do
  local pr = PcgRandom(os.time())
  for armor, groups in pairs(sysdmg.resist_groups) do
    for damage, amount in pairs(groups) do
      amount = math.max(1, (amount + pr:next(-1, 1)))
      groups[damage] = amount
    end
  end
end



-- Shall return an armor resist-groups table.
-- To be called at load-time only; shall NOT return nil.
function sysdmg.get_armor_resist_for(name2)
  local name = name2
  if name:sub(1, 1) == ":" then
    name = name:sub(2)
  end

  if sysdmg.resist_groups[name] then
    return table.copy(sysdmg.resist_groups[name])
  end
  return {}
end

-- Shall return an armor wear-groups table.
-- To be called at load-time only; shall NOT return nil.
function sysdmg.get_armor_wear_for(name2)
  local name = name2
  if name:sub(1, 1) == ":" then
    name = name:sub(2)
  end

  if sysdmg.wear_groups[name] then
    return table.copy(sysdmg.wear_groups[name])
  end
  return {}
end

-- Shall return armor's default groups table.
-- To be called at load-time only; shall NOT return nil.
function sysdmg.get_armor_groups_for(name2, groups)
  local name = name2
  if name:sub(1, 1) == ":" then
    name = name:sub(2)
  end

  if sysdmg.default_groups[name] then
    local g = table.copy(sysdmg.default_groups[name])
    if groups then
      for k, v in pairs(groups) do
        g[k] = v
      end
    end
    return g
  end
  return groups or {}
end

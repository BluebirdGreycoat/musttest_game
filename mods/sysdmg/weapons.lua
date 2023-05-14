
-- These groups get merged with the items's default groups table, so group
-- names must be prefixed with "armor_".
--
-- Note: 'armor_heal' is actually "armor block chance". If block chance passes,
-- then damage is completely blocked (becomes 0).
--
-- Note: 'armor_use' is the amount of wear added to armor whenever it gets
-- damaged. Armor is destroyed once wear reaches max.
sysdmg.default_groups = {
  ["shields:shield_wood"] =          {armor_heal=0, armor_use=2000},
  ["shields:shield_enhanced_wood"] = {armor_heal=0, armor_use=1000},
  ["3d_armor:helmet_wood"]         = {armor_heal=0, armor_use=2000},
  ["3d_armor:chestplate_wood"]     = {armor_heal=0, armor_use=2000},
  ["3d_armor:leggings_wood"]       = {armor_heal=0, armor_use=2000},
  ["3d_armor:boots_wood"]          = {armor_heal=0, armor_use=2000},

  ["shields:shield_steel"]         = {armor_heal=0, armor_use=500},
  ["3d_armor:helmet_steel"]        = {armor_heal=0, armor_use=500},
  ["3d_armor:chestplate_steel"]    = {armor_heal=0, armor_use=500},
  ["3d_armor:leggings_steel"]      = {armor_heal=0, armor_use=500},
  ["3d_armor:boots_steel"]         = {armor_heal=0, armor_use=500},

  ["shields:shield_carbon"]        = {armor_heal=0, armor_use=200},
  ["3d_armor:helmet_carbon"]       = {armor_heal=0, armor_use=200},
  ["3d_armor:chestplate_carbon"]   = {armor_heal=0, armor_use=200},
  ["3d_armor:leggings_carbon"]     = {armor_heal=0, armor_use=200},
  ["3d_armor:boots_carbon"]        = {armor_heal=0, armor_use=200},

  ["shields:shield_bronze"]        = {armor_heal=6, armor_use=250},
  ["3d_armor:helmet_bronze"]       = {armor_heal=6, armor_use=250},
  ["3d_armor:chestplate_bronze"]   = {armor_heal=6, armor_use=250},
  ["3d_armor:leggings_bronze"]     = {armor_heal=6, armor_use=250},
  ["3d_armor:boots_bronze"]        = {armor_heal=6, armor_use=250},

  ["shields:shield_diamond"]       = {armor_heal=12, armor_use=100},
  ["3d_armor:helmet_diamond"]      = {armor_heal=12, armor_use=100},
  ["3d_armor:chestplate_diamond"]  = {armor_heal=12, armor_use=100},
  ["3d_armor:leggings_diamond"]    = {armor_heal=12, armor_use=100},
  ["3d_armor:boots_diamond"]       = {armor_heal=12, armor_use=100},

  ["shields:shield_gold"]          = {armor_heal=6, armor_use=250},
  ["3d_armor:helmet_gold"]         = {armor_heal=6, armor_use=250},
  ["3d_armor:chestplate_gold"]     = {armor_heal=6, armor_use=250},
  ["3d_armor:leggings_gold"]       = {armor_heal=6, armor_use=250},
  ["3d_armor:boots_gold"]          = {armor_heal=6, armor_use=250},

  ["shields:shield_mithril"]       = {armor_heal=12, armor_use=50},
  ["3d_armor:helmet_mithril"]      = {armor_heal=12, armor_use=50},
  ["3d_armor:chestplate_mithril"]  = {armor_heal=12, armor_use=50},
  ["3d_armor:leggings_mithril"]    = {armor_heal=12, armor_use=50},
  ["3d_armor:boots_mithril"]       = {armor_heal=12, armor_use=50},
}



sysdmg.wear_groups = {
  ["shields:shield_wood"]          = {fall=0.5, punch=1.25, heat=3.0, ground=0.0, boom=3.0},
  ["shields:shield_enhanced_wood"] = {fall=0.5, punch=1.25, heat=3.0, ground=0.0, boom=3.0},
  ["3d_armor:helmet_wood"]         = {fall=0.5, crush=3.0, heat=3.0, ground=0.0},
  ["3d_armor:chestplate_wood"]     = {fall=0.5, punch=1.5, heat=3.0, ground=0.0, boom=4.0},
  ["3d_armor:leggings_wood"]       = {fall=1.25, heat=3.0},
  ["3d_armor:boots_wood"]          = {fall=1.5, heat=3.0, ground=2.0},

  ["shields:shield_steel"]         = {fall=0.5, punch=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_steel"]        = {fall=0.5, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_steel"]    = {fall=0.5, punch=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_steel"]      = {fall=1.25},
  ["3d_armor:boots_steel"]         = {fall=1.5, ground=2.0},

  ["shields:shield_carbon"]        = {fall=0.5, punch=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_carbon"]       = {fall=0.5, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_carbon"]   = {fall=0.5, punch=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_carbon"]     = {fall=1.25},
  ["3d_armor:boots_carbon"]        = {fall=1.5, ground=2.0},

  ["shields:shield_bronze"]        = {fall=0.5, punch=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_bronze"]       = {fall=0.5, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_bronze"]   = {fall=0.5, punch=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_bronze"]     = {fall=1.25},
  ["3d_armor:boots_bronze"]        = {fall=1.5, ground=2.0},

  ["shields:shield_diamond"]       = {fall=0.5, punch=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_diamond"]      = {fall=0.5, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_diamond"]  = {fall=0.5, punch=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_diamond"]    = {fall=1.25},
  ["3d_armor:boots_diamond"]       = {fall=1.5, ground=2.0},

  ["shields:shield_gold"]          = {fall=0.5, punch=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_gold"]         = {fall=0.5, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_gold"]     = {fall=0.5, punch=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_gold"]       = {fall=1.25},
  ["3d_armor:boots_gold"]          = {fall=1.5, ground=2.0},

  ["shields:shield_mithril"]       = {fall=0.5, punch=1.25, ground=0.0, boom=3.0},
  ["3d_armor:helmet_mithril"]      = {fall=0.5, crush=3.0, ground=0.0},
  ["3d_armor:chestplate_mithril"]  = {fall=0.5, punch=1.5, ground=0.0, boom=4.0},
  ["3d_armor:leggings_mithril"]    = {fall=0.8},
  ["3d_armor:boots_mithril"]       = {fall=0.9, ground=2.0},
}



sysdmg.resist_groups = {
  ["shields:shield_wood"]          = {fleshy=5, cracky=5, heat=10},
  ["shields:shield_enhanced_wood"] = {fleshy=8, cracky=25, heat=20},
  ["3d_armor:helmet_wood"]         = {fleshy=5, cracky=10, heat=15},
  ["3d_armor:chestplate_wood"]     = {fleshy=10, cracky=15, heat=25},
  ["3d_armor:leggings_wood"]       = {fleshy=5, cracky=10, heat=10},
  ["3d_armor:boots_wood"]          = {fleshy=5, cracky=5, heat=15},

  ["shields:shield_steel"]         = {fleshy=10, crush=10, arrow=15, boom=8},
  ["3d_armor:helmet_steel"]        = {fleshy=10, crush=10, arrow=15, boom=5},
  ["3d_armor:chestplate_steel"]    = {fleshy=15, crush=15, arrow=20, boom=10},
  ["3d_armor:leggings_steel"]      = {fleshy=15, crush=15, arrow=15, boom=5},
  ["3d_armor:boots_steel"]         = {fleshy=10, crush=10, arrow=10, boom=5},

  ["shields:shield_carbon"]        = {fleshy=12, arrow=18, boom=10},
  ["3d_armor:helmet_carbon"]       = {fleshy=12, crush=12, arrow=15, boom=8},
  ["3d_armor:chestplate_carbon"]   = {fleshy=17, crush=17, arrow=20, boom=15},
  ["3d_armor:leggings_carbon"]     = {fleshy=17, crush=10, arrow=15, boom=10},
  ["3d_armor:boots_carbon"]        = {fleshy=12, crush=8, arrow=12, boom=5},

  ["shields:shield_bronze"]        = {fleshy=10, fireball=50, boom=20},
  ["3d_armor:helmet_bronze"]       = {fleshy=10, crumbly=12},
  ["3d_armor:chestplate_bronze"]   = {fleshy=15, crumbly=20},
  ["3d_armor:leggings_bronze"]     = {fleshy=15, crumbly=12},
  ["3d_armor:boots_bronze"]        = {fleshy=10, crumbly=8},

  ["shields:shield_diamond"]       = {fleshy=15, arrow=20},
  ["3d_armor:helmet_diamond"]      = {fleshy=15},
  ["3d_armor:chestplate_diamond"]  = {fleshy=20},
  ["3d_armor:leggings_diamond"]    = {fleshy=20},
  ["3d_armor:boots_diamond"]       = {fleshy=15},

  ["shields:shield_gold"]          = {fleshy=10, crumbly=25},
  ["3d_armor:helmet_gold"]         = {fleshy=10},
  ["3d_armor:chestplate_gold"]     = {fleshy=15},
  ["3d_armor:leggings_gold"]       = {fleshy=15},
  ["3d_armor:boots_gold"]          = {fleshy=10},

  ["shields:shield_mithril"]       = {fleshy=15},
  ["3d_armor:helmet_mithril"]      = {fleshy=20},
  ["3d_armor:chestplate_mithril"]  = {fleshy=25},
  ["3d_armor:leggings_mithril"]    = {fleshy=25},
  ["3d_armor:boots_mithril"]       = {fleshy=20},
}



-- Shall return an armor resist-groups table.
-- To be called at load-time only; shall NOT return nil.
function sysdmg.get_armor_resist_for(name)
  if sysdmg.resist_groups[name] then
    return table.copy(sysdmg.resist_groups[name])
  end
  return {}
end

-- Shall return an armor wear-groups table.
-- To be called at load-time only; shall NOT return nil.
function sysdmg.get_armor_wear_for(name)
  if sysdmg.wear_groups[name] then
    return table.copy(sysdmg.wear_groups[name])
  end
  return {}
end

-- Shall return armor's default groups table.
-- To be called at load-time only; shall NOT return nil.
function sysdmg.get_armor_groups_for(name, groups)
  if sysdmg.default_groups[name] then
    local g = table.copy(sysdmg.default_groups[name])
    if groups then
      for k, v in pairs(groups) do
        g[k] = v
      end
    end
    return g
  end
  return groups
end

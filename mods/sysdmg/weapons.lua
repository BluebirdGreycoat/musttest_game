
-- Globally reduce all weapon damage to provide longer reaction time in PvP.
-- Normal damage scaling would be 500.
local SCALE = 250
local KNB = 100

-- Damage groups for all weapons.
-- Warning: Minetest will round all values to nearest integer; DO NOT expect
-- float values to work! (Note that scaling is performed after this table.)
--
-- Note: knockback represents meters per second, times 100.
-- For reference, the HAND does 'knockback=100'.
-- Hammers do 3*KNB (300).
sysdmg.damage_groups = {
  ["anvil:hammer"]            = {fleshy=0.2, knockback=3},
  ["xdecor:hammer"]           = {fleshy=0.2, knockback=3},
  ["shears:shears"]           = {fleshy=2.0},

  ["default:pick_wood"]       = {fleshy=1.2, knockback=1.1},
  ["default:pick_stone"]      = {crush=0.2, fleshy=0.2, knockback=2.5},
  ["default:pick_steel"]      = {fleshy=5.2, knockback= 2},
  ["default:pick_bronze"]     = {fleshy=5.2, knockback= 2},
  ["default:pick_bronze2"]    = {fleshy=5.2, knockback= 2},
  ["default:pick_mese"]       = {fleshy=0.4, knockback= 2},
  ["default:pick_diamond"]    = {fleshy=5.2, knockback= 1.5},
  ["moreores:pick_silver"]    = {freeze=0.2, fleshy=0.2, knockback= 1.5},
  ["moreores:pick_mithril"]   = {fleshy=5.2, knockback= 1.5},
  ["titanium:pick"]           = {fleshy=5.2, knockback= 2.5},
  ["gems:pick_ruby"]          = {fleshy=5.2, knockback= 2.6},
  ["gems:rf_pick_ruby"]       = {fleshy=5.1, knockback= 2.6},
  ["gems:pick_amethyst"]      = {fleshy=5.2, knockback= 2.9},
  ["gems:rf_pick_amethyst"]   = {fleshy=5.1, knockback= 2.7},
  ["gems:pick_sapphire"]      = {fleshy=5.2, knockback= 2.8},
  ["gems:rf_pick_sapphire"]   = {fleshy=5.1, knockback= 2.7},
  ["gems:pick_emerald"]       = {fleshy=5.2, knockback= 2.8},
  ["gems:rf_pick_emerald"]    = {fleshy=5.1, knockback= 2.7},

  ["default:shovel_stone"]    = {fleshy=0.1, crush=0.4, knockback=3.1},
  ["default:shovel_steel"]    = {fleshy=0.1, crush=0.2, knockback= 3},
  ["default:shovel_bronze"]   = {fleshy=0.1, crush=0.2, knockback= 3},
  ["default:shovel_bronze2"]  = {fleshy=0.1, crush=0.2, knockback= 3},
  ["default:shovel_mese"]     = {fleshy=0.1, crush=0.2, knockback= 3},
  ["default:shovel_diamond"]  = {fleshy=0.1, crush=0.2, knockback= 2.7},
  ["moreores:shovel_silver"]  = {freeze=0.2, fleshy=0.1, crush=0.2, knockback= 2.7},
  ["moreores:shovel_mithril"] = {fleshy=0.1, crush=0.2, knockback= 2.7},
  ["titanium:shovel"]         = {fleshy=0.1, crush=0.2, knockback= 3.1},
  ["gems:shovel_ruby"]        = {fleshy=0.1, crush=0.2, knockback=2.5},
  ["gems:rf_shovel_ruby"]     = {fleshy=0.05, crush=0.2, knockback= 2.5},
  ["gems:shovel_amethyst"]    = {fleshy=0.1, crush=0.2, knockback=3.1},
  ["gems:rf_shovel_amethyst"] = {fleshy=0.05, crush=0.2, knockback= 3.1},
  ["gems:shovel_sapphire"]    = {fleshy=0.1, crush=0.2, knockback=3.1},
  ["gems:rf_shovel_sapphire"] = {fleshy=0.05, crush=0.2, knockback=2.9},
  ["gems:shovel_emerald"]     = {fleshy=0.1, crush=0.2, knockback=2.7},
  ["gems:rf_shovel_emerald"]  = {fleshy=0.05, crush=0.2, knockback=2.6},

  ["default:axe_stone"]       = {fleshy=1.0, crush=0.2, knockback=3.5},
  ["default:axe_steel"]       = {fleshy=5.0, knockback=3},
  ["default:axe_bronze"]      = {fleshy=4.0, knockback=3},
  ["default:axe_bronze2"]     = {fleshy=4.0, knockback=3},
  ["default:axe_mese"]        = {fleshy=0.2, knockback=2.9},
  ["default:axe_diamond"]     = {fleshy=7.0, knockback=2.9},
  ["moreores:axe_silver"]     = {shock=2.0, fleshy=0.2, freeze=0.2, knockback=2.9},
  ["moreores:axe_mithril"]    = {fleshy=9.0, knockback=2.9},
  ["titanium:axe"]            = {fleshy=5.0, knockback=3.8},
  ["gems:axe_ruby"]           = {fleshy=6.1, knockback=3.0},
  ["gems:rf_axe_ruby"]        = {fleshy=6.0, knockback=2.9},
  ["gems:axe_amethyst"]       = {fleshy=6.1, knockback=3.1},
  ["gems:rf_axe_amethyst"]    = {fleshy=6.0, knockback=2.9},
  ["gems:axe_sapphire"]       = {fleshy=7.1, knockback=3.0},
  ["gems:rf_axe_sapphire"]    = {fleshy=7.0, knockback=2.7},
  ["gems:axe_emerald"]        = {fleshy=7.1, knockback=3.0},
  ["gems:rf_axe_emerald"]     = {fleshy=7.0, knockback=2.7},

  ["default:sword_stone"]     = {crush = 6.2, fleshy=0.2, knockback=3.5},
  ["default:sword_steel"]     = {fleshy= 6.0, knockback=1.5},
  ["default:sword_bronze"]    = {fleshy= 10.0, knockback=1.5},
  ["default:sword_bronze2"]   = {fleshy= 10.0, knockback=1.5},
  ["default:sword_mese"]      = {fleshy= 8.7,  knockback=1.3},
  ["default:sword_diamond"]   = {fleshy= 8.0, knockback=1.3},
  ["moreores:sword_silver"]   = {freeze= 8.2, knockback=1.3},
  ["moreores:sword_mithril"]  = {fleshy= 10.0, knockback=1.3},
  ["titanium:sword"]          = {fleshy= 8.0, knockback=3.5},
  ["gems:sword_ruby"]         = {fleshy= 8.1, knockback=1.7},
  ["gems:rf_sword_ruby"]      = {fleshy= 8.0, knockback=1.6},
  ["gems:sword_amethyst"]     = {fleshy= 9.1, knockback=3.5},
  ["gems:rf_sword_amethyst"]  = {fleshy= 9.0, knockback=3.1},
  ["gems:sword_sapphire"]     = {fleshy= 7.1, knockback=1.7},
  ["gems:rf_sword_sapphire"]  = {fleshy= 7.0, knockback=1.6},
  ["gems:sword_emerald"]      = {poison= 7.1, knockback=1.7},
  ["gems:rf_sword_emerald"]   = {poison= 7.0, knockback=1.6},

  ["stoneworld:oerkki_scepter"] = {heat=4, knockback=1.8},
  ["stoneworld:oerkki_soa"]     = {heat=4, knockback=1.8},
  ["wizard:banish_staff"]       = {knockback=1.8},
  ["wizard:tracking_staff"]     = {knockback=1.8},
  ["wizard:gagging_staff"]      = {knockback=1.8},
  ["wizard:summon_staff"]       = {knockback=1.8},
}

-- Apply scaling
do
  for weapon, groups in pairs(sysdmg.damage_groups) do
    for damage, amount in pairs(groups) do
      -- Skip special types.
      if damage == "knockback" then
        groups[damage] = amount * KNB
      else
        groups[damage] = amount * SCALE
      end
    end
  end
end

-- Make calculating the "hard meta" rather difficult.
do
  local pr = PcgRandom(os.time())
  for weapon, groups in pairs(sysdmg.damage_groups) do
    for damage, amount in pairs(groups) do
      -- Skip special types.
      if damage ~= "knockback" then
        amount = math.max(1, (amount + pr:next(-50, 50)))
        groups[damage] = amount
      end
    end
  end
end



-- Shall return a damage-groups table.
-- To be called at load-time only; shall return nil as needed.
function sysdmg.get_damage_groups_for(name2, groups)
  local name = name2
  if name:sub(1, 1) == ":" then
    name = name:sub(2)
  end

  --minetest.log('getting damage groups for: ' .. name)

  if sysdmg.damage_groups[name] then
    local g = table.copy(sysdmg.damage_groups[name])
    if groups then
      for k, v in pairs(groups) do
        g[k] = v
      end
    end
    return g
  end

  -- May return nil if 'groups' is nil.
  return groups
end

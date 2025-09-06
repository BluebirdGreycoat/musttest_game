
-- Globally reduce all weapon damage to provide longer reaction time in PvP.
-- Normal damage scaling would be 500.
local SCALE = 250
local KNB = 100

-- Damage groups for all weapons.
-- Warning: Minetest will round all values to nearest integer; DO NOT expect
-- float values to work!
--
-- Note: knockback represents meters per second, times 100.
-- For reference, the HAND does 'knockback=100'.
-- Hammers do 3*KNB (300).
sysdmg.damage_groups = {
  ["anvil:hammer"]            = {cracky=6.0*SCALE, fleshy=0.2*SCALE, knockback=3*KNB},
  ["xdecor:hammer"]           = {cracky=6.0*SCALE, fleshy=0.2*SCALE, knockback=3*KNB},
  ["shears:shears"]           = {fleshy=2.0*SCALE},

  ["default:pick_wood"]       = {snappy= 1.0*SCALE, fleshy=1.2*SCALE, knockback=1.1*KNB},
  ["default:pick_stone"]      = {snappy= 1.0*SCALE, crush=0.2*SCALE, fleshy=0.2*SCALE, knockback=2.5*KNB},
  ["default:pick_steel"]      = {snappy=8.0*SCALE, fleshy=5.2*SCALE, knockback= 2*KNB},
  ["default:pick_bronze"]     = {snappy=8.0*SCALE, fleshy=5.2*SCALE, knockback= 2*KNB},
  ["default:pick_bronze2"]    = {snappy=8.0*SCALE, fleshy=5.2*SCALE, knockback= 2*KNB},
  ["default:pick_mese"]       = {crumbly=16.0*SCALE, fleshy=0.4*SCALE, knockback= 2*KNB},
  ["default:pick_diamond"]    = {snappy=12.0*SCALE, fleshy=5.2*SCALE, knockback= 1.5*KNB},
  ["moreores:pick_silver"]    = {snappy=12.0*SCALE, crumbly=0.2*SCALE, fleshy=0.2*SCALE, knockback= 1.5*KNB},
  ["moreores:pick_mithril"]   = {snappy=16.0*SCALE, fleshy=5.2*SCALE, knockback= 1.5*KNB},
  ["titanium:pick"]           = {snappy=10.0*SCALE, fleshy=5.2*SCALE, knockback= 2.5*KNB},
  ["gems:pick_ruby"]          = {snappy=12.1*SCALE, fleshy=5.2*SCALE, knockback= 2.6*KNB},
  ["gems:rf_pick_ruby"]       = {snappy=12.0*SCALE, fleshy=5.1*SCALE, knockback= 2.6*KNB},
  ["gems:pick_amethyst"]      = {snappy=11.1*SCALE, fleshy=5.2*SCALE, knockback= 2.9*KNB},
  ["gems:rf_pick_amethyst"]   = {snappy=11.0*SCALE, fleshy=5.1*SCALE, knockback= 2.7*KNB},
  ["gems:pick_sapphire"]      = {snappy=12.1*SCALE, fleshy=5.2*SCALE, knockback= 2.8*KNB},
  ["gems:rf_pick_sapphire"]   = {snappy=12.0*SCALE, fleshy=5.1*SCALE, knockback= 2.7*KNB},
  ["gems:pick_emerald"]       = {snappy=11.1*SCALE, fleshy=5.2*SCALE, knockback= 2.8*KNB},
  ["gems:rf_pick_emerald"]    = {snappy=11.0*SCALE, fleshy=5.1*SCALE, knockback= 2.7*KNB},

  ["default:shovel_stone"]    = {cracky=1.0*SCALE, fleshy=0.1*SCALE, crush=0.4*SCALE, knockback=3.1*KNB},
  ["default:shovel_steel"]    = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 3*KNB},
  ["default:shovel_bronze"]   = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 3*KNB},
  ["default:shovel_bronze2"]  = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 3*KNB},
  ["default:shovel_mese"]     = {cracky=2.5*SCALE, crumbly=2.5*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 3*KNB},
  ["default:shovel_diamond"]  = {cracky=6.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 2.7*KNB},
  ["moreores:shovel_silver"]  = {cracky=2.0*SCALE, crumbly=0.2*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 2.7*KNB},
  ["moreores:shovel_mithril"] = {cracky=8.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 2.7*KNB},
  ["titanium:shovel"]         = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 3.1*KNB},
  ["gems:shovel_ruby"]        = {cracky=5.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=2.5*KNB},
  ["gems:rf_shovel_ruby"]     = {cracky=5.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback= 2.5*KNB},
  ["gems:shovel_amethyst"]    = {cracky=6.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=3.1*KNB},
  ["gems:rf_shovel_amethyst"] = {cracky=6.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback= 3.1*KNB},
  ["gems:shovel_sapphire"]    = {cracky=5.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=3.1*KNB},
  ["gems:rf_shovel_sapphire"] = {cracky=5.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback=2.9*KNB},
  ["gems:shovel_emerald"]     = {cracky=6.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=2.7*KNB},
  ["gems:rf_shovel_emerald"]  = {cracky=6.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback=2.6*KNB},

  ["default:axe_stone"]       = {choppy=1.0*SCALE, crush=0.2*SCALE, snappy=0.2*SCALE, knockback=3.5*KNB},
  ["default:axe_steel"]       = {choppy=5.0*SCALE, snappy=0.2*SCALE, knockback=3*KNB},
  ["default:axe_bronze"]      = {choppy=4.0*SCALE, snappy=0.2*SCALE, knockback=3*KNB},
  ["default:axe_bronze2"]     = {choppy=4.0*SCALE, snappy=0.2*SCALE, knockback=3*KNB},
  ["default:axe_mese"]        = {crumbly=6.0*SCALE, choppy=0.2*SCALE, snappy=0.2*SCALE, knockback=2.9*KNB},
  ["default:axe_diamond"]     = {choppy=7.0*SCALE, snappy=0.2*SCALE, knockback=2.9*KNB},
  ["moreores:axe_silver"]     = {electrocute=2.0*SCALE, choppy=0.2*SCALE, crumbly=0.2*SCALE, snappy=0.2*SCALE, knockback=2.9*KNB},
  ["moreores:axe_mithril"]    = {choppy=9.0*SCALE, snappy=0.2*SCALE, knockback=2.9*KNB},
  ["titanium:axe"]            = {choppy=5.0*SCALE, snappy=0.2*SCALE, knockback=3.8*KNB},
  ["gems:axe_ruby"]           = {choppy=6.1*SCALE, snappy=0.2*SCALE, knockback=3.0*KNB},
  ["gems:rf_axe_ruby"]        = {choppy=6.0*SCALE, snappy=0.1*SCALE, knockback=2.9*KNB},
  ["gems:axe_amethyst"]       = {choppy=6.1*SCALE, snappy=0.2*SCALE, knockback=3.1*KNB},
  ["gems:rf_axe_amethyst"]    = {choppy=6.0*SCALE, snappy=0.1*SCALE, knockback=2.9*KNB},
  ["gems:axe_sapphire"]       = {choppy=7.1*SCALE, snappy=0.2*SCALE, knockback=3.0*KNB},
  ["gems:rf_axe_sapphire"]    = {choppy=7.0*SCALE, snappy=0.1*SCALE, knockback=2.7*KNB},
  ["gems:axe_emerald"]        = {choppy=7.1*SCALE, snappy=0.2*SCALE, knockback=3.0*KNB},
  ["gems:rf_axe_emerald"]     = {choppy=7.0*SCALE, snappy=0.1*SCALE, knockback=2.7*KNB},

  ["default:sword_stone"]     = {cracky= 4.0*SCALE, crush=0.2*SCALE, fleshy=0.2*SCALE, knockback=3.5*KNB},
  ["default:sword_steel"]     = {fleshy= 6.0*SCALE, snappy=0.2*SCALE, knockback=1.5*KNB},
  ["default:sword_bronze"]    = {fleshy=10.0*SCALE, snappy=0.2*SCALE, knockback=1.5*KNB},
  ["default:sword_bronze2"]   = {fleshy=10.0*SCALE, snappy=0.2*SCALE, knockback=1.5*KNB},
  ["default:sword_mese"]      = {crumbly= 8.0*SCALE, fleshy=0.2*SCALE, snappy=0.2*SCALE, knockback=1.3*KNB},
  ["default:sword_diamond"]   = {fleshy= 8.0*SCALE, snappy=0.2*SCALE, knockback=1.3*KNB},
  ["moreores:sword_silver"]   = {electrocute=6.0*SCALE, fleshy=0.2*SCALE, crumbly=0.2*SCALE, snappy=0.2*SCALE, knockback=1.3*KNB},
  ["moreores:sword_mithril"]  = {fleshy=10.0*SCALE, snappy=0.2*SCALE, knockback=1.3*KNB},
  ["titanium:sword"]          = {fleshy= 8.0*SCALE, snappy=0.2*SCALE, knockback=3.5*KNB},
  ["gems:sword_ruby"]         = {fleshy= 8.1*SCALE, snappy=0.3*SCALE, knockback=1.7*KNB},
  ["gems:rf_sword_ruby"]      = {fleshy= 8.0*SCALE, snappy=0.1*SCALE, knockback=1.6*KNB},
  ["gems:sword_amethyst"]     = {fleshy= 9.1*SCALE, snappy=0.3*SCALE, knockback=3.5*KNB},
  ["gems:rf_sword_amethyst"]  = {fleshy= 9.0*SCALE, snappy=0.1*SCALE, knockback=3.1*KNB},
  ["gems:sword_sapphire"]     = {fleshy= 7.1*SCALE, snappy=0.3*SCALE, knockback=1.7*KNB},
  ["gems:rf_sword_sapphire"]  = {fleshy= 7.0*SCALE, snappy=0.1*SCALE, knockback=1.6*KNB},
  ["gems:sword_emerald"]      = {fleshy= 7.1*SCALE, snappy=0.3*SCALE, knockback=1.7*KNB},
  ["gems:rf_sword_emerald"]   = {fleshy= 7.0*SCALE, snappy=0.1*SCALE, knockback=1.6*KNB},

  ["stoneworld:oerkki_scepter"] = {heat=4*SCALE, knockback=4, lava=1*SCALE, knockback=1.8*KNB},
  ["stoneworld:oerkki_soa"]     = {heat=4*SCALE, knockback=4, lava=1*SCALE, knockback=1.8*KNB},
  ["wizard:banish_staff"]       = {knockback=4, knockback=1.8*KNB},
  ["wizard:tracking_staff"]     = {knockback=4, knockback=1.8*KNB},
  ["wizard:gagging_staff"]      = {knockback=4, knockback=1.8*KNB},
  ["wizard:summon_staff"]       = {knockback=4, knockback=1.8*KNB},
}

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

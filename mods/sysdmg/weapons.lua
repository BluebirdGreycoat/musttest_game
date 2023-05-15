
-- Globally reduce all weapon damage to provide longer reaction time in PvP.
-- Normal damage scaling would be 500.
local SCALE = 250

-- Damage groups for all weapons.
sysdmg.damage_groups = {
  ["anvil:hammer"]            = {cracky=6.0*SCALE, fleshy=0.2*SCALE},
  ["xdecor:hammer"]           = {cracky=6.0*SCALE, fleshy=0.2*SCALE},
  ["shears:shears"]           = {fleshy=2.0*SCALE},

  ["default:pick_wood"]       = {snappy= 1.0*SCALE, fleshy=1.2*SCALE, },
  ["default:pick_stone"]      = {snappy= 1.0*SCALE, crush=0.2*SCALE, fleshy=0.2*SCALE, knockback= 8},
  ["default:pick_steel"]      = {snappy=8.0*SCALE, fleshy=5.2*SCALE, knockback= 3},
  ["default:pick_bronze"]     = {snappy=8.0*SCALE, fleshy=5.2*SCALE, knockback= 3},
  ["default:pick_bronze2"]    = {snappy=8.0*SCALE, fleshy=5.2*SCALE, knockback= 3},
  ["default:pick_mese"]       = {crumbly=16.0*SCALE, fleshy=0.4*SCALE, knockback= 3},
  ["default:pick_diamond"]    = {snappy=12.0*SCALE, fleshy=5.2*SCALE, knockback= 3},
  ["moreores:pick_silver"]    = {snappy=12.0*SCALE, crumbly=0.2*SCALE, fleshy=0.2*SCALE, knockback= 3},
  ["moreores:pick_mithril"]   = {snappy=16.0*SCALE, fleshy=5.2*SCALE, knockback= 3},
  ["titanium:pick"]           = {snappy=10.0*SCALE, fleshy=5.2*SCALE, knockback= 6},
  ["gems:pick_ruby"]          = {snappy=12.1*SCALE, fleshy=5.2*SCALE, knockback= 6},
  ["gems:rf_pick_ruby"]       = {snappy=12.0*SCALE, fleshy=5.1*SCALE, knockback= 5},
  ["gems:pick_amethyst"]      = {snappy=11.1*SCALE, fleshy=5.2*SCALE, knockback= 6},
  ["gems:rf_pick_amethyst"]   = {snappy=11.0*SCALE, fleshy=5.1*SCALE, knockback= 5},
  ["gems:pick_sapphire"]      = {snappy=12.1*SCALE, fleshy=5.2*SCALE, knockback= 6},
  ["gems:rf_pick_sapphire"]   = {snappy=12.0*SCALE, fleshy=5.1*SCALE, knockback= 5},
  ["gems:pick_emerald"]       = {snappy=11.1*SCALE, fleshy=5.2*SCALE, knockback= 6},
  ["gems:rf_pick_emerald"]    = {snappy=11.0*SCALE, fleshy=5.1*SCALE, knockback= 5},

  ["default:shovel_stone"]    = {cracky=1.0*SCALE, fleshy=0.1*SCALE, crush=0.4*SCALE, knockback=16},
  ["default:shovel_steel"]    = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["default:shovel_bronze"]   = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["default:shovel_bronze2"]  = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["default:shovel_mese"]     = {cracky=2.5*SCALE, crumbly=2.5*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["default:shovel_diamond"]  = {cracky=6.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["moreores:shovel_silver"]  = {cracky=2.0*SCALE, crumbly=0.2*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["moreores:shovel_mithril"] = {cracky=8.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["titanium:shovel"]         = {cracky=2.0*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback= 6},
  ["gems:shovel_ruby"]        = {cracky=5.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=10},
  ["gems:rf_shovel_ruby"]     = {cracky=5.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback= 7},
  ["gems:shovel_amethyst"]    = {cracky=6.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=10},
  ["gems:rf_shovel_amethyst"] = {cracky=6.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback= 7},
  ["gems:shovel_sapphire"]    = {cracky=5.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=10},
  ["gems:rf_shovel_sapphire"] = {cracky=5.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback= 7},
  ["gems:shovel_emerald"]     = {cracky=6.1*SCALE, fleshy=0.1*SCALE, crush=0.2*SCALE, knockback=10},
  ["gems:rf_shovel_emerald"]  = {cracky=6.0*SCALE, fleshy=0.05*SCALE, crush=0.2*SCALE, knockback= 7},

  ["default:axe_stone"]       = {choppy=1.0*SCALE, crush=0.2*SCALE, snappy=0.2*SCALE, knockback=4},
  ["default:axe_steel"]       = {choppy=5.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:axe_bronze"]      = {choppy=4.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:axe_bronze2"]     = {choppy=4.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:axe_mese"]        = {crumbly=6.0*SCALE, choppy=0.2*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:axe_diamond"]     = {choppy=7.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["moreores:axe_silver"]     = {electrocute=2.0*SCALE, choppy=0.2*SCALE, crumbly=0.2*SCALE, snappy=0.2*SCALE, knockback=1},
  ["moreores:axe_mithril"]    = {choppy=9.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["titanium:axe"]            = {choppy=5.0*SCALE, snappy=0.2*SCALE, knockback=4},
  ["gems:axe_ruby"]           = {choppy=6.1*SCALE, snappy=0.2*SCALE, knockback=1},
  ["gems:rf_axe_ruby"]        = {choppy=6.0*SCALE, snappy=0.1*SCALE, knockback=0.5},
  ["gems:axe_amethyst"]       = {choppy=6.1*SCALE, snappy=0.2*SCALE, knockback=1},
  ["gems:rf_axe_amethyst"]    = {choppy=6.0*SCALE, snappy=0.1*SCALE, knockback=0.5},
  ["gems:axe_sapphire"]       = {choppy=7.1*SCALE, snappy=0.2*SCALE, knockback=1},
  ["gems:rf_axe_sapphire"]    = {choppy=7.0*SCALE, snappy=0.1*SCALE, knockback=0.5},
  ["gems:axe_emerald"]        = {choppy=7.1*SCALE, snappy=0.2*SCALE, knockback=1},
  ["gems:rf_axe_emerald"]     = {choppy=7.0*SCALE, snappy=0.1*SCALE, knockback=0.5},

  ["default:sword_stone"]     = {cracky= 4.0*SCALE, crush=0.2*SCALE, fleshy=0.2*SCALE, knockback=6},
  ["default:sword_steel"]     = {fleshy= 6.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:sword_bronze"]    = {fleshy=10.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:sword_bronze2"]   = {fleshy=10.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:sword_mese"]      = {crumbly= 8.0*SCALE, fleshy=0.2*SCALE, snappy=0.2*SCALE, knockback=1},
  ["default:sword_diamond"]   = {fleshy= 8.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["moreores:sword_silver"]   = {electrocute=6.0*SCALE, fleshy=0.2*SCALE, crumbly=0.2*SCALE, snappy=0.2*SCALE, knockback=1},
  ["moreores:sword_mithril"]  = {fleshy=10.0*SCALE, snappy=0.2*SCALE, knockback=1},
  ["titanium:sword"]          = {fleshy= 8.0*SCALE, snappy=0.2*SCALE, knockback=6},
  ["gems:sword_ruby"]         = {fleshy= 8.1*SCALE, snappy=0.3*SCALE, knockback=1},
  ["gems:rf_sword_ruby"]      = {fleshy= 8.0*SCALE, snappy=0.1*SCALE, knockback=0.5},
  ["gems:sword_amethyst"]     = {fleshy= 9.1*SCALE, snappy=0.3*SCALE, knockback=1},
  ["gems:rf_sword_amethyst"]  = {fleshy= 9.0*SCALE, snappy=0.1*SCALE, knockback=0.5},
  ["gems:sword_sapphire"]     = {fleshy= 7.1*SCALE, snappy=0.3*SCALE, knockback=1},
  ["gems:rf_sword_sapphire"]  = {fleshy= 7.0*SCALE, snappy=0.1*SCALE, knockback=0.5},
  ["gems:sword_emerald"]      = {fleshy= 7.1*SCALE, snappy=0.3*SCALE, knockback=1},
  ["gems:rf_sword_emerald"]   = {fleshy= 7.0*SCALE, snappy=0.1*SCALE, knockback=0.5},

  ["stoneworld:oerkki_scepter"] = {heat=4*SCALE, knockback=4, lava=1*SCALE},
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


local SCALE = 500

sysdmg.damage_groups = {
  ["anvil:hammer"]            = {fleshy=6*SCALE, cracky=10*SCALE},
  ["xdecor:hammer"]           = {fleshy=6*SCALE, cracky=10*SCALE},
  ["shears:shears"]           = {},

  ["default:pick_wood"]       = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:pick_stone"]      = {fleshy=1*SCALE, cracky=12*SCALE, crumbly=1*SCALE, knockback=16},
  ["default:pick_steel"]      = {fleshy=13*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["default:pick_bronze"]     = {fleshy=13*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["default:pick_bronze2"]    = {fleshy=13*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["default:pick_mese"]       = {fleshy=16*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["default:pick_diamond"]    = {fleshy=17*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["moreores:pick_silver"]    = {fleshy=12*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["moreores:pick_mithril"]   = {fleshy=19*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["titanium:pick"]           = {fleshy=15*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=6},
  ["gems:pick_ruby"]          = {fleshy=17*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:rf_pick_ruby"]       = {fleshy=17*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:pick_amethyst"]      = {fleshy=16*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:rf_pick_amethyst"]   = {fleshy=16*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:pick_sapphire"]      = {fleshy=17*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:rf_pick_sapphire"]   = {fleshy=17*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:pick_emerald"]       = {fleshy=16*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},
  ["gems:rf_pick_emerald"]    = {fleshy=16*SCALE, cracky=1*SCALE, crumbly=1*SCALE, knockback=10},

  ["default:shovel_stone"]    = {fleshy=1*SCALE, cracky=5*SCALE, crumbly=1*SCALE},
  ["default:shovel_steel"]    = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=6*SCALE},
  ["default:shovel_bronze"]   = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:shovel_bronze2"]  = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:shovel_mese"]     = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:shovel_diamond"]  = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["moreores:shovel_silver"]  = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["moreores:shovel_mithril"] = {fleshy=8*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["titanium:shovel"]         = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=6*SCALE},
  ["gems:shovel_ruby"]        = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_shovel_ruby"]     = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:shovel_amethyst"]    = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_shovel_amethyst"] = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:shovel_sapphire"]    = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_shovel_sapphire"] = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:shovel_emerald"]     = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_shovel_emerald"]  = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},

  ["default:axe_stone"]       = {fleshy=1*SCALE, cracky=5*SCALE, crumbly=1*SCALE},
  ["default:axe_steel"]       = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:axe_bronze"]      = {fleshy=4*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:axe_bronze2"]     = {fleshy=4*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:axe_mese"]        = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:axe_diamond"]     = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["moreores:axe_silver"]     = {fleshy=2*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["moreores:axe_mithril"]    = {fleshy=9*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["titanium:axe"]            = {fleshy=5*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:axe_ruby"]           = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_axe_ruby"]        = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:axe_amethyst"]       = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_axe_amethyst"]    = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:axe_sapphire"]       = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_axe_sapphire"]    = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:axe_emerald"]        = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_axe_emerald"]     = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},

  ["default:sword_stone"]     = {fleshy=4*SCALE, cracky=6*SCALE, crumbly=1*SCALE},
  ["default:sword_steel"]     = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:sword_bronze"]    = {fleshy=10*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:sword_bronze2"]   = {fleshy=10*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:sword_mese"]      = {fleshy=8*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["default:sword_diamond"]   = {fleshy=8*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["moreores:sword_silver"]   = {fleshy=6*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["moreores:sword_mithril"]  = {fleshy=10*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["titanium:sword"]          = {fleshy=8*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:sword_ruby"]         = {fleshy=8*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_sword_ruby"]      = {fleshy=8*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:sword_amethyst"]     = {fleshy=9*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_sword_amethyst"]  = {fleshy=9*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:sword_sapphire"]     = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_sword_sapphire"]  = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:sword_emerald"]      = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
  ["gems:rf_sword_emerald"]   = {fleshy=7*SCALE, cracky=1*SCALE, crumbly=1*SCALE},
}



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

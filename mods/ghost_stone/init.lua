
if not minetest.global_exists("ghost_stone") then ghost_stone = {} end
ghost_stone.modpath = minetest.get_modpath("ghost_stone")



if not ghost_stone.run_once then
  minetest.register_node("ghost_stone:cobble", {
    description = "Ghost Stone",
    drawtype = "glasslike",
    paramtype = "light",
    
    -- Don't confuse with cobble while in inventory. Avoids accidental trashing.
    inventory_image = "ghost_stone.png",
    wield_image = "ghost_stone.png",
    
    tiles = {"default_cobble.png"}, -- Hard to see/looks like cobble.
    is_ground_content = false,
    groups = utility.dig_groups("cobble"),
    sounds = rackstone.rackstone_sounds(),
    walkable = false, -- Player can hide inside/walk through/fall through.
    post_effect_color = {a = 100, r = 255, g = 0, b = 40},
    drowning = 8,
  })
    
  minetest.register_craft({
    output = "ghost_stone:cobble 8",
    recipe = {
      {"default:cobble", "default:cobble", "default:cobble"},
      {"default:cobble", "rackstone:evilrack", "default:cobble"},
      {"default:cobble", "default:cobble", "default:cobble"},
    },
  })
  
  local c = "ghost_stone:core"
  local f = ghost_stone.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  ghost_stone.run_once = true
end

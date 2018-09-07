--------------------------------------------------------------------------------
-- Gem Cutter Mod for Must Test Survival
-- Author: GoldFireUn
-- License of Source Code: MIT
-- License of Media: CC BY-SA 3.0
--------------------------------------------------------------------------------

gem_cutter = gem_cutter or {}
gem_cutter.modpath = minetest.get_modpath("gem_cutter")



gem_cutter.get_formspec_defaults = 
function()
  local str =
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  return str
end

gem_cutter.formspec_active = 
function(fuel_percent, item_percent)
  local formspec =
    "size[8,8.5]" ..
    gem_cutter.get_formspec_defaults() ..
    
    "label[3.5,0;Fuel & Input]" ..
    "list[context;src;3.5,0.5;1,1;]" ..
    "list[context;fuel;3.5,2.5;1,1;]" ..
    "image[3.5,1.5;1,1;machine_progress_bg.png^[lowpart:" ..
    (100-fuel_percent) .. ":machine_progress_fg.png]" ..
    
    "image[4.5,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:" ..
    (item_percent) .. ":gui_furnace_arrow_fg.png^[transformR270]" ..
    "label[5.5,0.46;Destination]" ..
    "list[context;dst;5.5,0.96;2,2;]" ..
    
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    
    "label[0.75,0;Configuration]" ..
    "list[context;cfg;0.75,0.5;2,1;]" ..
    "label[0.75,2;Upgrades]" ..
    "list[context;upg;0.75,2.5;2,1;]" ..
    
    "listring[context;dst]"..
    "listring[current_player;main]"..
    "listring[context;src]"..
    "listring[current_player;main]"..
    "listring[context;fuel]"..
    "listring[current_player;main]"..
    default.get_hotbar_bg(0, 4.25)
  return formspec
end

gem_cutter.formspec_inactive = 
function()
  return gem_cutter.formspec_active(100, 0)
end

gem_cutter.on_punch = 
function(pos, node, puncher, pointed_thing)
  machines.initialize_typedata(pos, "gem_cutter:inactive", "mv")
  gem_cutter.trigger_update(pos)
end

gem_cutter.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



gem_cutter.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("dst") and
    inv:is_empty("src") and
    inv:is_empty("cfg") and
    inv:is_empty("upg")
end



gem_cutter.allow_metadata_inventory_put =  
function(pos, listname, index, stack, player)
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    "mesefuel", "fuel", "src", "dst", "cfg", "upg")
end



gem_cutter.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return gem_cutter.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



gem_cutter.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  return stack:get_count()
end



local MACHINE_DATA = {
  name = "Gem Cutter",
  method = "cutting",
  demand = 200,
  swap = {
    inactive = "gem_cutter:inactive",
    active = "gem_cutter:active",
  },
  form = {
    inactive = gem_cutter.formspec_inactive,
    active = gem_cutter.formspec_active,
  },
  fuel = "mesefuel",
  processable = "Cuttable",
}

gem_cutter.on_timer = 
function(pos, elapsed)
  machines.log_update(pos, "Gem Cutter")
  return machines.on_machine_timer(pos, elapsed, MACHINE_DATA)
end



gem_cutter.on_construct = 
function(pos)
end

gem_cutter.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  machines.initialize_typedata(pos, "gem_cutter:inactive", "mv")
  machines.after_place_machine(pos, placer, "Gem Cutter", 1, gem_cutter.formspec_inactive)
end



gem_cutter.on_metadata_inventory_move = 
function(pos)
  gem_cutter.trigger_update(pos)
end



gem_cutter.on_metadata_inventory_put = 
function(pos)
  gem_cutter.trigger_update(pos)
end



gem_cutter.on_metadata_inventory_take = 
function(pos)
  gem_cutter.trigger_update(pos)
end



gem_cutter.on_blast = 
function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  default.get_inventory_drops(pos, "upg", drops)
  drops[#drops+1] = "gem_cutter:inactive"
  minetest.remove_node(pos)
  return drops
end



if not gem_cutter.run_once then
  for k, v in ipairs({
    {name="inactive", light=0, tile="gem_cutter_lv_front.png"},
    {name="active", light=8, tile="gem_cutter_lv_front_active.png"},
  }) do
    minetest.register_node("gem_cutter:" .. v.name, {
      description = "Gem Cutter",
      tiles = {
        "gem_cutter_lv_top.png", "gem_cutter_lv_bottom.png",
        "gem_cutter_lv_side.png", "gem_cutter_lv_side.png",
        "gem_cutter_lv_side.png", v.tile,
      },

      paramtype2 = "facedir",
      groups = {
        level=1, cracky=3,
        immovable = 1,
        tier_mv = 1,
      },
      
      light_source = v.light,
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "gemcut2:lv_inactive",

      can_dig = function(...)       
        return gem_cutter.can_dig(...) end,
      on_timer = function(...)      
        return gem_cutter.on_timer(...) end,
      on_construct = function(...)  
        return gem_cutter.on_construct(...) end,
      on_blast = function(...)      
        return gem_cutter.on_blast(...) end,
      on_punch = function(...)
        return gem_cutter.on_punch(...) end,
      after_place_node = function(...)
        return gem_cutter.after_place_node(...) end,
      on_metadata_inventory_move = function(...)
        return gem_cutter.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return gem_cutter.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return gem_cutter.on_metadata_inventory_take(...) end,
      allow_metadata_inventory_put = function(...)
        return gem_cutter.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return gem_cutter.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return gem_cutter.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end

  minetest.register_alias("gems:gem_fabricator", "gem_cutter:inactive")
  minetest.register_alias("gems:gem_fabricator_active", "gem_cutter:active")



  minetest.register_craft({
    output = 'gemcut2:lv_inactive',
    recipe = {
      {'default:desert_stonebrick', 'gem_cutter:blade', 'default:desert_stonebrick'},
      {'default:desert_stonebrick', 'techcrafts:machine_casing', 'default:desert_stonebrick'},
      {'techcrafts:control_logic_unit', 'techcrafts:electric_motor', 'battery:battery'},
    }
  })



  minetest.register_craftitem("gem_cutter:blade", {
    description = "Diamond Grinding Wheel",
    inventory_image = "gem_cutter_cutting_wheel.png",
  })
  minetest.register_alias("gems:diamond_cutting_wheel", "gem_cutter:blade")

  minetest.register_craft({
    output = 'gem_cutter:blade',
    recipe = {
      {'dusts:coal', 'dusts:diamond', 'dusts:coal'},
      {'dusts:diamond', 'carbon_steel:ingot', 'dusts:diamond'},
      {'dusts:coal', 'dusts:diamond', 'dusts:coal'},
    }
  })

  --minetest.register_craft({
  --  type = "cutter",
  --  blade = 'gem_cutter:blade',
  --  durability = 120,
  --})
  
  local c = "gem_cutter:core"
  local f = gem_cutter.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(gem_cutter.modpath .. "/v2.lua")
  gem_cutter.run_once = true
end

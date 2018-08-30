
grinder.get_formspec_defaults = function()
  local str =
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  return str
end



grinder.formspec_active = function(fuel_percent, item_percent)
  local formspec =
    "size[8,8.5]" ..
    grinder.get_formspec_defaults() ..
    
    "label[3.5,0;Fuel & Input]" ..
    "list[context;src;3.5,0.5;1,1;]" ..
    "list[context;fuel;3.5,2.5;1,1;]" ..
    "image[3.5,1.5;1,1;gems_progress_bg.png^[lowpart:" ..
    (100-fuel_percent) .. ":gems_progress_fg.png]" ..
    
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
    
    "listring[context;dst]" ..
    "listring[current_player;main]" ..
    "listring[context;src]" ..
    "listring[current_player;main]" ..
    "listring[context;fuel]"..
    "listring[current_player;main]"..
    default.get_hotbar_bg(0, 4.25)
  return formspec
end



grinder.formspec_inactive = function()
  return grinder.formspec_active(100, 0)
end

grinder.on_punch = 
function(pos, node, puncher, pointed_thing)
  machines.initialize_typedata(pos, "grinder:inactive", "mv")
  grinder.trigger_update(pos)
end

grinder.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



grinder.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("dst") and
    inv:is_empty("src") and
    inv:is_empty("cfg") and
    inv:is_empty("upg")
end



grinder.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    "mesefuel", "fuel", "src", "dst", "cfg", "upg")
end



grinder.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return grinder.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



grinder.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  return stack:get_count()
end



local MACHINE_DATA = {
  name = "Grinder",
  method = "grinding",
  demand = 200,
  swap = {
    inactive = "grinder:inactive",
    active = "grinder:active",
  },
  form = {
    inactive = grinder.formspec_inactive,
    active = grinder.formspec_active,
  },
  fuel = "mesefuel",
  processable = "Grindable",
}

grinder.on_timer = function(pos, elapsed)
  machines.log_update(pos, "Grinder")
  return machines.on_machine_timer(pos, elapsed, MACHINE_DATA)
end



grinder.on_construct = 
function(pos)
end

grinder.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  machines.initialize_typedata(pos, "grinder:inactive", "mv")
  machines.after_place_machine(pos, placer, "Grinder", 1, grinder.formspec_inactive)
end



grinder.on_metadata_inventory_move = 
function(pos)
  grinder.trigger_update(pos)
end



grinder.on_metadata_inventory_put = 
function(pos)
  grinder.trigger_update(pos)
end



grinder.on_metadata_inventory_take = 
function(pos)
  grinder.trigger_update(pos)
end



grinder.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  default.get_inventory_drops(pos, "upg", drops)
  drops[#drops+1] = "grinder:inactive"
  minetest.remove_node(pos)
  return drops
end

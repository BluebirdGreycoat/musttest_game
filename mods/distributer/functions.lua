
-- Localize for performance.
local math_floor = math.floor

distributer.update_formspec =
function(pos, chg, max, cnt)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  local status_string = "Network EU Status: Total Arrays: " .. cnt ..
    ", Total Charge: " .. chg .. "/" .. max
  
  local formspec =
    "size[8,8.5]" ..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors() ..
    
    "label[0,0;" .. minetest.formspec_escape(status_string) .. "]" ..
    
    "label[0,0.5;Configuration Slots]" ..
    "list[context;config;0,1;8,2;]" ..
    
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    
    "listring[context;config]" ..
    "listring[current_player;main]" ..
    default.get_hotbar_bg(0, 4.25)
  meta:set_string("formspec", formspec)
end

-- Typedata is used when traversing the network, without touching the node.
-- It must contain as much data as needed to get the node even if unloaded.
-- This must be done after node construction.
-- This should also be done when punched, to allow old nodes to be upgraded.
distributer.initialize_typedata =
function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("technic_machine", "yes")
  meta:set_string("technic_type", "utility")
  meta:set_string("technic_tier", "lv|mv|hv")
  meta:set_string("technic_name", "distributer:distributer")
end

distributer.on_punch = 
function(pos, node, puncher, pointed_thing)
  distributer.initialize_typedata(pos)
  distributer.trigger_update(pos)
end

distributer.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty("config")
end

distributer.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  
  local NCONFIG = "cfg:dev"
  if listname == "config" and stack:get_name() == NCONFIG then
    return stack:get_count()
  end
  
  return 0
end

distributer.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  
  return count
end

distributer.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  
  return stack:get_count()
end



distributer.update_infotext =
function(pos, chg, max, cnt)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  local infotext = "Network EU Observer\n" ..
    "Total Arrays: " .. cnt .. "\n" ..
    "Stored EUs: " .. chg .. "/" .. max .. "\n"
  
  if max > 0 then
    local percent = math_floor(chg / max * 100)
    infotext = infotext .. "Total Charge: " .. percent .. "%"
  else
    infotext = infotext .. "Total Charge: 0%"
  end
  
  meta:set_string("infotext", infotext)
end



distributer.on_timer = 
function(pos, elapsed)
  machines.log_update(pos, "Observer")
  
  local table_in = {
    purpose = "controler_update",
  }
  local table_out = {}
  local traversal = {}
  
  -- Do not process self.
  local hash = minetest.hash_node_position(pos)
  traversal[hash] = 0
      
  -- TODO: why do we unconditionally update all controlers?
  -- This may cause a huge update cascade, usually for no reason, since energy
  -- may not have changed. Also, we should only update generators when energy
  -- is drained. Consumers should only be auto-updated with energy increases.
  -- Currenty, we're just updating everybody whenever the distributer updates.
      
  -- Update controlers on all adjacent networks of any tier.
  local hubs = machines.get_adjacent_network_hubs(pos)
  if hubs then
    for k, v in ipairs(hubs) do
      local node = minetest.get_node(v)
      local def = minetest.reg_ns_nodes[node.name]
      if def and def.on_machine_execute then
        def.on_machine_execute(v, table_in, table_out, traversal)
      end
    end
  end
  
  local chg, max, cnt = distributer.get_energy_status(pos)
  distributer.update_infotext(pos, chg, max, cnt)
  distributer.update_formspec(pos, chg, max, cnt)
end

distributer.on_blast = 
function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "config", drops)
  drops[#drops+1] = "distributer:distributer"
  minetest.remove_node(pos)
  return drops
end

distributer.on_construct = 
function(pos)
  distributer.initialize_typedata(pos)

  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size("config", 8*2)
  
  distributer.update_infotext(pos, 0, 0, 0)
  distributer.update_formspec(pos, 0, 0, 0)
end

distributer.after_place_node =
function(pos, placer, itemstack, pointed_thing)
end



distributer.on_metadata_inventory_move = 
function(pos)
  distributer.trigger_update(pos)
end

distributer.on_metadata_inventory_put =
function(pos)
  distributer.trigger_update(pos)
end

distributer.on_metadata_inventory_take =
function(pos)
  distributer.trigger_update(pos)
end



distributer.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



-- Read the combined energy storage and max possible storage for all batteries.
-- Do not trigger an update. This function shall not be called externally.
distributer.get_energy_status =
function(pos)
  local table_in = {
    purpose = "get_eu_status",
  }
  local table_out = {}
  local traversal = {}
  
  -- Do not process self.
  local hash = minetest.hash_node_position(pos)
  traversal[hash] = 0
      
  -- Get data from all batteries on network. Any tier is allowed.
  local hubs = machines.get_adjacent_network_hubs(pos)
  if hubs then
    for k, v in ipairs(hubs) do
      local node = minetest.get_node(v)
      local def = minetest.reg_ns_nodes[node.name]
      if def and def.on_machine_execute then
        def.on_machine_execute(v, table_in, table_out, traversal)
      end
    end
  end
  
  return (table_out.eu_chg or 0),
    (table_out.eu_max or 0),
    (table_out.num_batteries or 0)
end



distributer.on_machine_execute =
function(pos, table_in, table_out, traversal)
  -- No recursion check, because distributers do not take part in chains.
  -- This also allows them to function at the very end of a switching chain.

  -- Do not process this node more than once.
  local hash = minetest.hash_node_position(pos)
  if traversal[hash] then return end
  traversal[hash] = 0
  
  local purpose = table_in.purpose
  if purpose == "refresh_eu_status" then
    distributer.trigger_update(pos)
  end
end



if not distributer.functions_loaded then
  local c = "distributer:core"
  local f = distributer.modpath .. "/functions.lua"
  reload.register_file(c, f, false)
  distributer.functions_loaded = true
end

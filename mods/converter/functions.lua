
converter.update_formspec =
function(pos)
  local meta = minetest.get_meta(pos)
  
  local formspec = 
    "size[8,9.5]" ..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors()
    
  formspec = formspec ..
    "label[0,0.5;Supply Converter Configuration]" ..
    "list[context;cfg;0,1;8,1]" ..
    
    "list[current_player;main;0,5.25;8,1;]" ..
    "list[current_player;main;0,6.5;8,3;8]" ..
    default.get_hotbar_bg(0, 5.25)
  
  meta:set_string("formspec", formspec)
end

converter.update_infotext =
function(pos)
  local meta = minetest.get_meta(pos)
  local infotext = "Supply Converter"
  meta:set_string("infotext", infotext)
end

converter.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end

-- Typedata is used when traversing the network, without touching the node.
-- It must contain as much data as needed to get the node even if unloaded.
-- This must be done after node construction.
-- This should also be done when punched, to allow old nodes to be upgraded.
converter.initialize_typedata =
function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("technic_machine", "yes")
  meta:set_string("technic_type", "utility")
  meta:set_string("technic_tier", "lv|mv|hv")
  meta:set_string("technic_name", "converter:converter")
end

converter.on_punch = 
function(pos, node, puncher, pointed_thing)
  converter.initialize_typedata(pos)
  converter.trigger_update(pos)
end

converter.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty("cfg")
end

converter.on_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  converter.trigger_update(pos)
end

converter.on_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  converter.trigger_update(pos)
end

converter.on_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  converter.trigger_update(pos)
end

converter.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then 
    return 0 
  end
  
  if listname == "cfg" and stack:get_name() == "cfg:dev" then
    return stack:get_count()
  end
  return 0
end

converter.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then return 0 end
  return 0
end

converter.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then return 0 end
  return stack:get_count()
end

converter.on_construct = 
function(pos)
end

-- Handle & process incomming power-network events.
-- Important: converters behave similarly to switching stations.
converter.on_machine_execute = 
function(pos, table_in, table_out, traversal)
  -- Prevent infinite recursion.
  -- This check must come *before* we mark the switch as processed, because
  -- it may be possible to reach the switch (with lesser recursion) through
  -- another path on the network.
  local recursion = (table_out.recursion or 0)
  if recursion > 8 then return end
  
  -- Mark node as proccessed, do not process this node more than once.
  -- If this node has less recorded recursion depth than current message,
  -- then we don't traverse this switching station. If this switching station
  -- doesn't have a depth recorded, then we record the depth of the message,
  -- and traverse this station.
  local hash = minetest.hash_node_position(pos)
  if traversal[hash] and traversal[hash] <= recursion then return end
  traversal[hash] = recursion
  
  -- Get surrounding network hubs. All tiers allowed.
  --local hubs = machines.get_adjacent_network_hubs(pos)
  local hubs = networks.get_adjacent_hubs(pos)
  
  -- Pass message to all surrounding hubs.
  for k, v in ipairs(hubs) do
    -- Recursion must be +2 in order to give the supply converter the same
    -- recursion-cost to traverse as a switching station.
    table_out.recursion = recursion + 2
    v.on_machine_execute(v.pos, table_in, table_out, traversal)
  end
end

converter.on_destruct =
function(pos)
end

converter.on_blast = 
function(pos, intensity)
  local drops = {}
  default.get_inventory_drops(pos, "cfg", drops)
  drops[#drops+1] = "converter:converter"
  minetest.remove_node(pos)
  return drops
end

converter.on_timer = 
function(pos, elapsed)
  machines.log_update(pos, "Supply Converter")
  
  converter.update_formspec(pos)
  converter.update_infotext(pos)
end

converter.after_place_node = 
function(pos, placer, itemstack, pointed_thing)
  converter.initialize_typedata(pos)

  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  inv:set_size("cfg", 8)
  
  converter.update_formspec(pos)
  converter.update_infotext(pos)
end



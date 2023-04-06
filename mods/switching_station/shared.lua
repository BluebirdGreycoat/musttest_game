
if not minetest.global_exists("switching_station_hv") then switching_station_hv = {} end
if not minetest.global_exists("switching_station_mv") then switching_station_mv = {} end
if not minetest.global_exists("switching_station_lv") then switching_station_lv = {} end

-- Create copies of these functions by tier.
for k, v in ipairs({
  {tier="hv", up="HV"},
  {tier="mv", up="MV"},
  {tier="lv", up="LV"},
}) do
  -- Which function table are we operating on?
  local functable = _G["switching_station_" .. v.tier]
  
  functable.update_formspec =
  function(pos)
    local meta = minetest.get_meta(pos)
    
    local formspec = 
      "size[8,9.5]" ..
      default.formspec.get_form_colors() ..
      default.formspec.get_form_image() ..
      default.formspec.get_slot_colors()
      
    formspec = formspec ..
      "label[0,0.5;" .. v.up .. " Cable Box Configuration]" ..
      "list[context;cfg;0,1;8,1]" ..
      
      "list[current_player;main;0,5.25;8,1;]" ..
      "list[current_player;main;0,6.5;8,3;8]" ..
      default.get_hotbar_bg(0, 5.25)
    
    meta:set_string("formspec", formspec)
  end

  functable.update_infotext =
  function(pos)
    local meta = minetest.get_meta(pos)
    local infotext = v.up .. " Cable Box\nRouting: ["
    
    for k, v in ipairs({
      {n="n", c="N"},
      {n="s", c="S"},
      {n="e", c="E"},
      {n="w", c="W"},
      {n="u", c="U"},
      {n="d", c="D"},
    }) do
      local p = minetest.string_to_pos(meta:get_string(v.n))
      if p then
        infotext = infotext .. v.c
      end
    end
    
    infotext = infotext .. "]"
    meta:set_string("infotext", infotext)
  end

  functable.trigger_update =
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
  functable.initialize_typedata =
  function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("technic_machine", "yes")
    meta:set_string("technic_type", "switch")
    meta:set_string("technic_tier", v.tier)
    meta:set_string("technic_name", "switching_station:" .. v.tier)
  end

  functable.on_punch = 
  function(pos, node, puncher, pointed_thing)
    functable.initialize_typedata(pos)
    functable.trigger_update(pos)
  end

  functable.can_dig = 
  function(pos, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    return inv:is_empty("cfg")
  end

  functable.on_metadata_inventory_move = 
  function(pos, from_list, from_index, to_list, to_index, count, player)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_put = 
  function(pos, listname, index, stack, player)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_take = 
  function(pos, listname, index, stack, player)
    functable.trigger_update(pos)
  end

  functable.allow_metadata_inventory_put = 
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

  functable.allow_metadata_inventory_move = 
  function(pos, from_list, from_index, to_list, to_index, count, player)
    local pname = player:get_player_name()
    if minetest.test_protection(pos, pname) then return 0 end
    return 0
  end

  functable.allow_metadata_inventory_take = 
  function(pos, listname, index, stack, player)
    local pname = player:get_player_name()
    if minetest.test_protection(pos, pname) then return 0 end
    return stack:get_count()
  end

  functable.on_construct = 
  function(pos)
  end

  -- Handle & process incomming power-network events.
  functable.on_machine_execute = 
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
    
    local meta = minetest.get_meta(pos)
    --meta:set_string("infotext", "Recursion Depth: " .. recursion)
    
    -- Distribute event to all adjacent machines of the same tier as the station.
    --local adjacent_machines = functable.get_adjacent_machines(pos)
    local adjacent_machines = networks.get_adjacent_machines(pos, v.tier)
    for j, g in ipairs(adjacent_machines) do
      table_out.recursion = recursion
      g.on_machine_execute(g.pos, table_in, table_out, traversal)
    end
    
    local station_name = "switching_station:" .. v.tier
    local ndef = minetest.reg_ns_nodes[station_name]
    if not ndef or not ndef.on_machine_execute then return end 
    
    -- Find all connected switching stations. Distribute events down the chain.
    for j, g in ipairs({
      {n="n"},
      {n="s"},
      {n="e"},
      {n="w"},
      {n="u"},
      {n="d"},
    }) do
      local p = minetest.string_to_pos(meta:get_string(g.n))
      if p then
        --local node = minetest.get_node(p)
        local target_meta = minetest.get_meta(p)
        --if node.name == station_name then
        if target_meta:get_string("technic_machine") == "yes" and
           target_meta:get_string("technic_type") == "switch" and
           target_meta:get_string("technic_tier") == v.tier then
          if target_meta:get_string("technic_name") == station_name then
            table_out.recursion = recursion + 1
            ndef.on_machine_execute(p, table_in, table_out, traversal)
          end
        end
      end
    end
  end

  functable.on_destruct =
  function(pos)
    networks.invalidate_hubs(pos, v.tier)
  end

  functable.on_blast = 
  function(pos, intensity)
    networks.invalidate_hubs(pos, v.tier)
    local drops = {}
    drops[#drops+1] = "switching_station:" .. v.tier
    minetest.remove_node(pos)
    return drops
  end

  functable.on_timer = 
  function(pos, elapsed)
    machines.log_update(pos, "Switching Station")
    
    networks.refresh_hubs(pos, v.tier)
    functable.update_formspec(pos)
    functable.update_infotext(pos)
  end

  functable.after_place_node = 
  function(pos, placer, itemstack, pointed_thing)
    functable.initialize_typedata(pos)
    
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    
    inv:set_size("cfg", 8)
    
    networks.invalidate_hubs(pos, v.tier)
    networks.refresh_hubs(pos, v.tier)
    functable.update_formspec(pos)
    functable.update_infotext(pos)
  end
end



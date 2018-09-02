
-- Function tables, per tier.
battery_lv = battery_lv or {}
battery_mv = battery_mv or {}
battery_hv = battery_hv or {}



for k, v in ipairs({
  {tier="lv", up="LV", name="Low-Voltage"},
  {tier="mv", up="MV", name="Medium-Voltage"},
  {tier="hv", up="HV", name="High-Voltage"},
}) do
  -- Which function table are we operating on?
  local functable = _G["battery_" .. v.tier]
  
  -- Typedata is used when traversing the network, without touching the node.
  -- It must contain as much data as needed to get the node even if unloaded.
  -- This must be done after node construction.
  -- This should also be done when punched, to allow old nodes to be upgraded.
  functable.initialize_typedata =
  function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("technic_machine", "yes")
    meta:set_string("technic_type", "battery")
    meta:set_string("technic_tier", v.tier)
    -- This will technically be the wrong name, most of the time, but we should
    -- only ever use it to look up the node definition in order to get functions.
    -- And the functions for arrays 0 through 12 should be all the same.
    meta:set_string("technic_name", "battery:array0_" .. v.tier)
  end

  functable.compose_infotext =
  function(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local chg = meta:get_int("energy")
    local max = meta:get_int("max")
    local size = inv:get_size("batteries")
    local cnt = functable.get_battery_count(inv)
    
    local infotext = v.up .. " Battery Array\n" ..
      "Internal Battery Units: " .. cnt .. "/" .. size .. "\n" ..
      "Energy: " .. chg .. "/" .. max .. " EUs\n"
    
    if max > 0 then
      local percent = math.floor(chg / max * 100)
      infotext = infotext .. "Charge: " .. percent .. "%"
    else
      infotext = infotext .. "Charge: 0%"
    end
    
    meta:set_string("infotext", infotext)
  end

  functable.compose_formspec =
  function(pos)
    local meta = minetest.get_meta(pos)
    local chg, max = functable.get_energy_status(meta)
    
    local charge_desc = v.name .. " Charge Status: " ..
      chg .. "/" .. max .. " EUs"
    
    local formspec =
      "size[8,8.5]" ..
      default.formspec.get_form_colors() ..
      default.formspec.get_form_image() ..
      default.formspec.get_slot_colors() ..
      
      "label[0,0;" .. minetest.formspec_escape(charge_desc) .. "]" ..
      
      "label[0,0.5;NRAIB (Non-Redundant Array of Independant Batteries)]" ..
      "list[context;batteries;0,1;6,2;]" ..
      
      "label[7,0.5;Config]" ..
      "list[context;cfg;7,1;1,2;]" ..
      
      "list[current_player;main;0,4.25;8,1;]" ..
      "list[current_player;main;0,5.5;8,3;8]" ..
      default.get_hotbar_bg(0, 4.25)
    meta:set_string("formspec", formspec)
  end

  functable.update_charge_visual =
  function(pos)
    local meta = minetest.get_meta(pos)
    local chg, max = functable.get_energy_status(meta)
    
    local name = "battery:array0_" .. v.tier
    
    if max > 0 then -- Avoid divide-by-zero.
      local percent = math.floor((chg / max) * 100)
      local sz = math.ceil(100 / 12)
      for i = 0, 12, 1 do
        if percent <= sz*i then
          name = "battery:array" .. i .. "_" .. v.tier
          break
        end
      end
    end
    
    machines.swap_node(pos, name)
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
    return inv:is_empty("batteries") and
      inv:is_empty("cfg")
  end

  functable.allow_metadata_inventory_put = 
  function(pos, listname, index, stack, player)
    local NCONF = "cfg:dev"
    local NBATT = "battery:battery"

    local pname = player:get_player_name()
    if minetest.test_protection(pos, pname) then
      return 0
    end
    
    if listname == "cfg" and stack:get_name() == NCONF then
      return stack:get_count()
    elseif listname == "batteries" and stack:get_name() == NBATT then
      return stack:get_count()
    end
    
    return 0
  end

  functable.allow_metadata_inventory_move = 
  function(pos, from_list, from_index, to_list, to_index, count, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = inv:get_stack(from_list, from_index)
    return functable.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
  end

  functable.allow_metadata_inventory_take = 
  function(pos, listname, index, stack, player)
    local pname = player:get_player_name()
    if minetest.test_protection(pos, pname) then
      return 0
    end
    
    return stack:get_count()
  end

  functable.get_battery_count =
  function(inv)
    local batteries = inv:get_list("batteries")
    
    local count = 0
    for k, v in ipairs(batteries) do
      if v:get_name() == "battery:battery" then
        -- Only 1 battery allowed per stack.
        count = count + 1
      end
    end
    return count
  end

  functable.update_maximum_charge =
  function(meta)
    local count = functable.get_battery_count(meta:get_inventory())
    
    local max
    if v.tier == "lv" then
      max = count * 10000
    elseif v.tier == "mv" then
      max = count * 50000
    elseif v.tier == "hv" then
      max = count * 120000
    end
    
    local chg = meta:get_int("energy")
    
    -- Ensure charge isn't over max. This can happen if user removed a battery.
    if chg > max then
      meta:set_int("energy", max)
    end
    meta:set_int("max", max)
  end



  functable.on_timer = 
  function(pos, elapsed)
    machines.log_update(pos, "Battery Array")
    local meta = minetest.get_meta(pos)
    
    local current_amount = meta:get_int("energy")
    local old_eu_amount = meta:get_int("old_eu")
    
    -- Todo: here, we can respond to changes in EU amount since last update.
    
    meta:set_int("old_eu", current_amount)
    
    -- Needed in case the operator removes or adds a battery.
    -- Also, EUs can be added/drained from batteries without going through a distributer.
    functable.update_maximum_charge(meta)
    functable.update_listeners(pos)
    
    functable.update_charge_visual(pos)
    functable.compose_infotext(pos)
    functable.compose_formspec(pos)
  end

  functable.update_listeners =
  function(pos)
    local table_in = {
      purpose = "refresh_eu_status",
    }
    local table_out = {}
    local traversal = {}
    
    -- Do not process self.
    local hash = minetest.hash_node_position(pos)
    traversal[hash] = 0
              
    -- Update any listening EU observers on the same network tier.
    local hubs = machines.get_adjacent_network_hubs(pos, {v.tier})
    if hubs then
      for k, v in ipairs(hubs) do
        local node = minetest.get_node(v)
        local def = minetest.reg_ns_nodes[node.name]
        if def and def.on_machine_execute then
          def.on_machine_execute(v, table_in, table_out, traversal)
        end
      end
    end
  end

  functable.on_blast = 
  function(pos)
    local drops = {}
    default.get_inventory_drops(pos, "batteries", drops)
    default.get_inventory_drops(pos, "cfg", drops)
    drops[#drops+1] = "battery:array0_" .. v.tier
    minetest.remove_node(pos)
    return drops
  end

  functable.on_construct = 
  function(pos)
    functable.initialize_typedata(pos)
  
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    
    inv:set_size("batteries", 6*2)
    inv:set_size("cfg", 2)
    
    functable.update_maximum_charge(meta)
    functable.compose_infotext(pos)
    functable.compose_formspec(pos)
  end

  functable.after_place_node =
  function(pos, placer, itemstack, pointed_thing)
  end

  functable.on_metadata_inventory_move = 
  function(pos)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_put =
  function(pos)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_take =
  function(pos)
    functable.trigger_update(pos)
  end



  functable.trigger_update =
  function(pos)
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
      timer:start(1.0)
    end
  end



  -- Read the current & max charge of the battery, but do not trigger any update.
  -- Function shall be used internally ONLY.
  functable.get_energy_status =
  function(meta)
    local chg = meta:get_int("energy")
    local max = meta:get_int("max")
    return chg, max
  end



  functable.on_machine_execute =
  function(pos, table_in, table_out, traversal)
    -- We do not check for recursion depth for battery array boxes because
    -- these cannot be chains, so there is no problem with network size.

    -- Do not process this node more than once.
    local hash = minetest.hash_node_position(pos)
    if traversal[hash] then return end
    traversal[hash] = 0
    
    local meta = minetest.get_meta(pos)
    
    local purpose = table_in.purpose
    if purpose == "get_eu_status" then
      local chg, max = functable.get_energy_status(meta)
      table_out.eu_chg = (table_out.eu_chg or 0) + chg
      table_out.eu_max = (table_out.eu_max or 0) + max
      table_out.num_batteries = (table_out.num_batteries or 0) + 1
    elseif purpose == "store_eu" then
      if table_out.amount_eu <= 0 then return end
      
      local chg = meta:get_int("energy")
      local max = meta:get_int("max")
    
      -- Don't trigger an update cascade unless something changed.
      if chg < max then
        local amount = (table_out.amount_eu or 0)
        
        -- Clamp the amount the battery receives to its max capacity.
        -- This allows us to correctly calculate the remaining charge,
        -- after putting as much as possible in the battery.
        if amount + chg > max then
          amount = max - chg
        end
        
        if amount >= 1 then
          local chg = chg + amount
          if chg > max then
            chg = max
          end
          meta:set_int("energy", chg)
          functable.trigger_update(pos)
        end
        
        -- Calculate remaining charge.
        table_out.amount_eu = (table_out.amount_eu or 0) - amount
      end
    elseif purpose == "retrieve_eu" then
      if (table_out.wanted_eu or 0) <= 0 then return end
      
      local wanted_eu = (table_out.wanted_eu or 0)
      local current_eu = meta:get_int("energy")
      local eu_retrieved = 0
      
      -- Do *not* drain battery if we don't have enough EU. Just return 0.
      if current_eu >= wanted_eu then
        eu_retrieved = wanted_eu
        current_eu = current_eu - wanted_eu
        
        table_out.gotten_eu = (table_out.gotten_eu or 0) + eu_retrieved
        table_out.wanted_eu = (table_out.wanted_eu or 0) - eu_retrieved
        
        meta:set_int("energy", current_eu)
      end
      
      -- Don't trigger an update cascade unless something changed.
      if eu_retrieved > 0 then -- Energy was drained; need update.
        functable.trigger_update(pos)
      end
    end
  end



  if not battery.functions_loaded then
    local c = "battery:core"
    local f = battery.modpath .. "/functions.lua"
    reload.register_file(c, f, false)
    battery.functions_loaded = true
  end
end

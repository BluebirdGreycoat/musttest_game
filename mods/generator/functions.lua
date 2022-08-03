
-- Localize for performance.
local math_floor = math.floor

-- Typedata is used when traversing the network, without touching the node.
-- It must contain as much data as needed to get the node even if unloaded.
-- This must be done after node construction.
-- This should also be done when punched, to allow old nodes to be upgraded.
generator.initialize_typedata =
function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("technic_machine", "yes")
  meta:set_string("technic_type", "generator")
  meta:set_string("technic_tier", "lv|mv")
  -- The active nodetype should have all same properties and functions.
  meta:set_string("technic_name", "generator:inactive")
end

generator.on_punch = 
function(pos, node, puncher, pointed_thing)
  generator.initialize_typedata(pos)
  generator.trigger_update(pos)
end

generator.compose_formspec =
function(fuel_percent)
  local formspec =
    "size[8,8.5]" ..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors() ..
    "label[3.5,0;Fuel Supply]" ..
    "list[context;fuel;3.5,2;1,1;]" ..

		utility.progress_image(3.5, 1, "default_furnace_fire_bg.png", "default_furnace_fire_fg.png", fuel_percent) ..

    "label[1.5,0;Upgrades]" ..
    "list[context;upgrades;1.5,1;1,2]" ..
    "label[5.5,0;Configuration]" ..
    "list[context;config;5.5,1;1,2]" ..
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    "listring[context;fuel]" ..
    "listring[current_player;main]" ..
    default.get_hotbar_bg(0, 4.25)
  return formspec
end

generator.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("upgrades") and
    inv:is_empty("config")
end

generator.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  -- Listname `dst` is unused.
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    {"fuel", "mesefuel"}, "fuel", "src", nil, "config", "upgrades")
end

generator.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  
  if from_list == to_list then
    return count
  end
  return 0
end

generator.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  
  return stack:get_count()
end

generator.on_timer = 
function(pos, elapsed)
  machines.log_update(pos, "Generator")
  
  local result = false
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local fuellist = inv:get_list("fuel")
  local time = meta:get_float("time")
  local maxtime = meta:get_float("maxtime")
  local fuel_state = ""
  local percent = 0
  local eups = meta:get_int("eups") -- EUs per/sec.
  local eu_buffered = meta:get_int("eu_buffered")
  local buffer_max = 10000

  -- Manage fuel and EU-producing stuff.
  if time > 0 then
    -- Keep burning current fuel item.
    time = time - 1
    meta:set_float("time", time)
    percent = math_floor(time / maxtime * 100)
    fuel_state = percent .. "%"
    eu_buffered = eu_buffered + eups
    
    -- Restart timer.
    result = true
  else
    if eu_buffered >= buffer_max then
      -- Batteries full, shutdown generator.
      -- We can only get here if the buffer wasn't purged during the last
      -- iteration. That means the network can't absorb any more power.
      fuel_state = "Standby-Mode"
      eups = 0
      machines.swap_node(pos, "generator:inactive")
      minetest.get_node_timer(pos):stop()
    else
      -- Burntime has run out (and batteries not full), get new fuel item.
      if fuellist[1]:get_count() > 0  then
        local fuel, afterfuel
        
        -- Try to get fuel.
        fuel, afterfuel = minetest.get_craft_result({
          method="fuel", width=1, items=fuellist,
        })
        eups = 200
        
        -- If not regular fuel, try to get mesefuel.
        if fuel.time == 0 then
          fuel, afterfuel = minetest.get_craft_result({
            method="mesefuel", width=1, items=fuellist,
          })
          eups = 600
        end
        
        if fuel.time > 0 then
          -- We got a valid fuel item, consume it.
          inv:set_stack("fuel", 1, afterfuel.items[1])
          
          meta:set_float("time", fuel.time)
          meta:set_float("maxtime", fuel.time)
          machines.swap_node(pos, "generator:active")
          percent = 100
          fuel_state = "100%"
          result = true -- Restart timer.
        else
          fuel_state = "Not Fuel"
          eups = 0
          machines.swap_node(pos, "generator:inactive")
          minetest.get_node_timer(pos):stop()
        end
      else
        -- No more fuel, shutdown generator.
        fuel_state = "Empty"
        eups = 0
        machines.swap_node(pos, "generator:inactive")
        minetest.get_node_timer(pos):stop()
      end
    end
  end
  
  -- Deliver charge onto the network.
  -- We allow the buffer to be temporarily greater than its max for this.
  if eu_buffered >= buffer_max then
    eu_buffered = generator.deliver_charge(pos, eu_buffered)
  end
  
  -- Clamp buffer level to capacity.
  if eu_buffered > buffer_max then
    eu_buffered = buffer_max
  end
  
  local machine_state = "Standby"
  if result then machine_state = "Active" end
  local infotext = "Power Generator (" .. machine_state .. ")\n" ..
    "EUs per/sec: " .. eups .. "\nFuel Burn: " .. fuel_state .. "\n" ..
    "Buffered: " .. eu_buffered .. " EUs"
  
  meta:set_int("eups", eups)
  meta:set_int("eu_buffered", eu_buffered)
  meta:set_string("infotext", infotext)
  meta:set_string("formspec", generator.compose_formspec(percent))
  return result
end

-- Deliver EUs to batteries on the network. Return EUs left over.
generator.deliver_charge =
function(pos, charge)
  -- The generator can charge MV batteries as well as LV batteries.
  local hubs = machines.get_adjacent_network_hubs(pos, {"lv", "mv"})
  if hubs then
    for k, v in ipairs(hubs) do
      if charge > 0 then
        -- Gets back the energy left over.
        charge = machines.deliver_charge_to_network(pos, v, charge)
      end
    end
  end
  return charge
end

generator.on_blast = 
function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "upgrades", drops)
  default.get_inventory_drops(pos, "config", drops)
  drops[#drops+1] = "generator:inactive"
  minetest.remove_node(pos)
  return drops
end

generator.on_construct = 
function(pos)
  generator.initialize_typedata(pos)

  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  meta:set_string("infotext", "Power Generator (Standby)")
  meta:set_string("formspec", generator.compose_formspec(0))
  inv:set_size("fuel", 1)
  inv:set_size("upgrades", 2)
  inv:set_size("config", 2)
end

generator.after_place_node =
function(pos, placer, itemstack, pointed_thing)
end

generator.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end

generator.on_metadata_inventory_move = 
function(pos)
  generator.trigger_update(pos)
end

generator.on_metadata_inventory_put =
function(pos)
  generator.trigger_update(pos)
end

generator.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  generator.trigger_update(pos)
end



if not generator.functions_loaded then
  local c = "generator:core"
  local f = generator.modpath .. "/functions.lua"
  reload.register_file(c, f, false)
  generator.functions_loaded = true
end

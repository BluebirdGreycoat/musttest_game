
geothermal_generator = geothermal_generator or {}
geothermal_generator.modpath = minetest.get_modpath("geothermal_generator")



geothermal_generator.update_formspec =
function(pos)
  local meta = minetest.get_meta(pos)
  local formspec =
    "size[8,8.5]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    
    "label[1.5,0.5;Upgrades]" ..
    "list[context;upg;1.5,1;1,2]" ..
    "label[5.5,0.5;Configuration]" ..
    "list[context;cfg;5.5,1;1,2]" ..
    
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    default.get_hotbar_bg(0, 4.25)
  meta:set_string("formspec", formspec)
end

geothermal_generator.update_infotext =
function(pos)
  local meta = minetest.get_meta(pos)
  
  local active = "Standby"
  if meta:get_int("active") == 1 then
    active = "Active" 
  end
  
  local eups = meta:get_int("eups")
  local energy = meta:get_int("energy")
  
  local infotext = "Geothermal Generator (" .. active .. ")\n" ..
    "EUs per/sec: " .. eups .. "\n" ..
    "Buffered: " .. energy .. " EUs"
  
  meta:set_string("infotext", infotext)
end

geothermal_generator.trigger_update =
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
geothermal_generator.initialize_typedata =
function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("technic_machine", "yes")
  meta:set_string("technic_type", "generator")
  meta:set_string("technic_tier", "lv")
  -- The active nodetype should have all same properties and functions.
  meta:set_string("technic_name", "geothermal_generator:inactive")
end

geothermal_generator.on_punch = 
function(pos, node, puncher, pointed_thing)
  geothermal_generator.initialize_typedata(pos)
  geothermal_generator.trigger_update(pos)
end

geothermal_generator.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty("upg") and inv:is_empty("cfg")
end

geothermal_generator.can_run =
function(pos, meta)
  local timer = meta:get_int("chktmr")
  local active = meta:get_int("active")
  if timer <= 0 then
    -- Check all 4 sides of the geothermal generator.
    local targets = {
      {x=pos.x+1, y=pos.y, z=pos.z},
      {x=pos.x-1, y=pos.y, z=pos.z},
      {x=pos.x, y=pos.y, z=pos.z+1},
      {x=pos.x, y=pos.y, z=pos.z-1},
      
      {x=pos.x+1, y=pos.y, z=pos.z+1},
      {x=pos.x+1, y=pos.y, z=pos.z-1},
      {x=pos.x-1, y=pos.y, z=pos.z+1},
      {x=pos.x-1, y=pos.y, z=pos.z-1},
      
      {x=pos.x+1, y=pos.y-1, z=pos.z},
      {x=pos.x-1, y=pos.y-1, z=pos.z},
      {x=pos.x, y=pos.y-1, z=pos.z+1},
      {x=pos.x, y=pos.y-1, z=pos.z-1},
      
      {x=pos.x+1, y=pos.y-1, z=pos.z+1},
      {x=pos.x+1, y=pos.y-1, z=pos.z-1},
      {x=pos.x-1, y=pos.y-1, z=pos.z+1},
      {x=pos.x-1, y=pos.y-1, z=pos.z-1},
    }
    
    local count_water = 0
    local count_lava = 0
    
    for k, v in ipairs(targets) do
      local node = minetest.get_node(v)
      if minetest.get_item_group(node.name, "water") > 0 then
        count_water = count_water + 1
      elseif minetest.get_item_group(node.name, "lava") > 0 then
        count_lava = count_lava + 1
      end
    end
    
    if count_water > 0 and count_lava > 0 then
      -- Randomize time to next nodecheck.
      meta:set_int("chktmr", math.random(3, 15))
      
      meta:set_int("active", 1)
      meta:set_int("eups", (count_water + count_lava) * 10)
      
      machines.swap_node(pos, "geothermal_generator:active")
      return true
    else
      -- Don't set timer if generator is offline.
      -- The next check needs to happen the next time the machine is punched.
      meta:set_int("chktmr", 0)
      
      meta:set_int("active", 0)
      meta:set_int("eups", 0)
      
      machines.swap_node(pos, "geothermal_generator:inactive")
      return false
    end
  end
  -- Decrement check timer.
  timer = timer - 1
  meta:set_int("chktmr", timer)
  -- No check performed; just return whatever the result of the last check was.
  return (active == 1)
end

geothermal_generator.on_timer = 
function(pos, elapsed)
  machines.log_update(pos, "Geothermal Generator")
  local meta = minetest.get_meta(pos)
  local result = geothermal_generator.can_run(pos, meta)
  
  local bufmax = meta:get_int("bmax")
  local energy = meta:get_int("energy")
  if energy >= bufmax then
    -- Unload energy onto the network.
    -- Geothermal is a low-voltage EU producer.
    local hubs = machines.get_adjacent_network_hubs(pos, {"lv"})
    if hubs then
      for k, v in ipairs(hubs) do
        if energy > 0 then
          -- Gets back the energy left over.
          energy = machines.deliver_charge_to_network(pos, v, energy)
        end
      end
    end
  end
  
  -- If energy couldn't be offloaded, then shutdown the generator.
  if energy >= bufmax then
    meta:set_int("eups", 0)
    meta:set_int("active", 0)
    meta:set_int("chktmr", 0)
    machines.swap_node(pos, "geothermal_generator:inactive")
    result = false
  end
    
  -- Produce energy.
  local eups = meta:get_int("eups")
  energy = energy + eups
  if energy > bufmax then
    energy = bufmax
  end
  meta:set_int("energy", energy)
  
  -- Update GUI stuff.
  geothermal_generator.update_formspec(pos)
  geothermal_generator.update_infotext(pos)
  return result
end

geothermal_generator.on_construct = 
function(pos)
end

geothermal_generator.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  geothermal_generator.initialize_typedata(pos)

  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  meta:set_int("bmax", 10000)
  inv:set_size("upg", 2)
  inv:set_size("cfg", 2)
  
  geothermal_generator.update_formspec(pos)
  geothermal_generator.update_infotext(pos)
end

geothermal_generator.on_blast = 
function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "upg", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  drops[#drops+1] = "geothermal_generator:inactive"
  minetest.remove_node(pos)
  return drops
end

geothermal_generator.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then return 0 end
  
  if listname == "cfg" and stack:get_name() == "cfg:dev" then
    return stack:get_count()
  elseif listname == "upg" and stack:get_name() == "battery:battery" then
    return stack:get_count()
  end
  
  return 0
end

geothermal_generator.allow_metadata_inventory_move = 
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

geothermal_generator.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  
  return stack:get_count()
end

geothermal_generator.on_metadata_inventory_move = 
function(pos)
  geothermal_generator.trigger_update(pos)
end

geothermal_generator.on_metadata_inventory_put =
function(pos)
  geothermal_generator.trigger_update(pos)
end

geothermal_generator.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  geothermal_generator.trigger_update(pos)
end



if not geothermal_generator.run_once then
  for k, v in ipairs({
    {name="inactive", tile="geothermal_generator_top.png"},
    {name="active", tile="geothermal_generator_top_active.png"},
  }) do
    minetest.register_node("geothermal_generator:" .. v.name, {
      description = "LV Geothermal Generator",
      tiles = {
        v.tile, v.tile,
        "geothermal_generator_side.png", "geothermal_generator_side.png",
        "geothermal_generator_side.png", "geothermal_generator_side.png"
      },
      
      groups = {
        level=1, cracky=3,
        immovable = 1,
        tier_lv = 1,
      },
      
      paramtype2 = "facedir",
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "geo2:lv_inactive",
      
      allow_metadata_inventory_put = function(...)
        return geothermal_generator.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return geothermal_generator.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return geothermal_generator.allow_metadata_inventory_take(...) end,
      on_metadata_inventory_move = function(...)
        return geothermal_generator.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return geothermal_generator.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return geothermal_generator.on_metadata_inventory_take(...) end,
      on_punch = function(...)
        return geothermal_generator.on_punch(...) end,
      can_dig = function(...)
        return geothermal_generator.can_dig(...) end,
      on_timer = function(...)
        return geothermal_generator.on_timer(...) end,
      on_construct = function(...)
        return geothermal_generator.on_construct(...) end,
      on_blast = function(...)
        return geothermal_generator.on_blast(...) end,
      after_place_node = function(...)
        return geothermal_generator.after_place_node(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end
  
  minetest.register_alias("geothermal_generator:geothermal_generator", "geothermal_generator:inactive")

  minetest.register_craft({
    output = 'geo2:lv_inactive',
    recipe = {
      {'morerocks:granite', 'default:diamond', 'morerocks:granite'},
      {'fine_wire:copper', 'techcrafts:machine_casing', 'fine_wire:copper'},
      {'morerocks:granite', 'cb2:hv', 'morerocks:granite'},
    }
  })

  local c = "geothermal_generator:core"
  local f = geothermal_generator.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(geothermal_generator.modpath .. "/geo2.lua")
	dofile(geothermal_generator.modpath .. "/wat2.lua")
  geothermal_generator.run_once = true
end


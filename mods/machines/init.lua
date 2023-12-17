
-- This is a mod where functions shared by most machines (tools) are located.
-- This avoides excessive code duplication. Machine tools include centrifuge,
-- electric furnace, extractor, grinder, and others. These machines behave
-- generally in similar ways.
if not minetest.global_exists("machines") then machines = {} end
machines.modpath = minetest.get_modpath("machines")

local NEED_LOG = true
local SINGLEPLAYER = minetest.is_singleplayer()

-- Localize for performance.
local math_floor = math.floor



-- API function, for logging machine updates. Needed during debugging.
machines.log_update =
function(pos, name)
  if SINGLEPLAYER == true and NEED_LOG == true then
    minetest.chat_send_all("# Server: " .. name .. " updates @ " .. rc.pos_to_namestr(pos) .. ".")
  end
end



-- Typedata is used when traversing the network, without touching the node.
-- It must contain as much data as needed to get the node even if unloaded.
-- This must be done after node construction.
-- This should also be done when punched, to allow old nodes to be upgraded.
machines.initialize_typedata =
function(pos, name, tier)
  local meta = minetest.get_meta(pos)
  meta:set_string("technic_machine", "yes")
  meta:set_string("technic_type", "tool")
  meta:set_string("technic_tier", tier)
  meta:set_string("technic_name", name)
end



machines.get_energy =
function(from, to, wanted_charge)
  local meta = minetest.get_meta(from)
  local node = minetest.get_node(to)
  local def = minetest.reg_ns_nodes[node.name]
  
  -- Make sure energy can actually be extracted from the node.
  if def and def.on_machine_execute then
    local table_in = {
      purpose = "retrieve_eu",
    }
    local table_out = {
      wanted_eu = wanted_charge,
    }
    local traversal = {}
    
    -- Do not process self.
    local hash = minetest.hash_node_position(from)
    traversal[hash] = 0
          
    def.on_machine_execute(to, table_in, table_out, traversal)
    return (table_out.gotten_eu or 0)
  end
  
  return 0
end



-- API function. Try to get cooktime for a machine by draining power off the network.
machines.get_cooktime =
function(pos, name_cfg, name_ugp, wanted_time, eu_demand)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
    
  -- By default, machine wants this many EUs per/sec.
  local eups = eu_demand
  local upglist = inv:get_list(name_ugp) -- Name configurable.
  
  -- Old machines might not have the upgrade inventory.
  if upglist then
    for k, v in ipairs(upglist) do
      if v:get_name() == "battery:battery" and v:get_count() == 1 then
        -- Each battery upgrade reduces energy needed by 1/3 of previous.
        eups = math_floor((eups / 3) * 2)
      end
    end
  end
  local wanted_eu = wanted_time * eups
  local tried_once = false
  ::try_again::
  
  -- If enough energy is buffered we can grab it & run.
  local eu_buffered = meta:get_int("eu_buffered")
  if wanted_eu <= eu_buffered then
    eu_buffered = eu_buffered - wanted_eu
    meta:set_int("eu_buffered", eu_buffered)
    return wanted_time
  end
  
  if tried_once == false then
    -- Otherwise, we have to refill the buffer.
    -- Get location of network access.
    local netpos = machines.get_adjacent_network_hubs(pos, {"mv"})
    
    -- Energy source(s) found.
    for k, v in ipairs(netpos) do
      -- Should be enough for at least 1 of even the longest cooking item.
      -- If not, how could we fix this? Maybe just reduce the cooktime for the
      -- offending item ....
      local charge = machines.get_energy(pos, v, 10000)
      
      eu_buffered = eu_buffered + charge
      meta:set_int("eu_buffered", eu_buffered)
      
      tried_once = true
      goto try_again
    end
  end
  
  -- No energy obtained. (Machine should fallback to fuel, if any.)
  return 0
end



-- API function. Most machines share this function in common.
machines.allow_metadata_inventory_put =
function(pos, listname, index, stack, player, fueltype, fuelname, srcname, dstname, cfgname, upgname)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then return 0 end
  
  if listname == fuelname then
    if type(fueltype) == "string" then
      local cresult = minetest.get_craft_result({
        method = fueltype,
        width = 1,
        items = {stack},
      })
      if cresult.time ~= 0 then -- Valid fuel.
        return stack:get_count()
      end
    elseif type(fueltype) == "table" then
      for k, v in ipairs(fueltype) do
        local cresult = minetest.get_craft_result({
          method = v,
          width = 1,
          items = {stack},
        })
        if cresult.time ~= 0 then -- Valid fuel.
          return stack:get_count()
        end
      end
    end
  elseif listname == srcname then
    return stack:get_count()
  elseif dstname and listname == dstname then
    return 0
  elseif listname == cfgname and stack:get_name() == "cfg:dev" then
    return stack:get_count()
  elseif listname == upgname and stack:get_name() == "battery:battery" then
    return stack:get_count()
  end
  return 0
end



machines.on_machine_execute =
function(pos, table_in, table_out, traversal)
  -- We do not check for recursion depth for crafting machines because
  -- these machines cannot be chains, so there is no problem with network size.

  -- Do not process this node more than once.
  local hash = minetest.hash_node_position(pos)
  if traversal[hash] then return end
  traversal[hash] = 0
  
  local purpose = table_in.purpose
  if purpose == "autostart_trigger" then
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
      timer:start(1.0)
    end
  end
end



-- API function to get locations of network hubs adjacent to a machine.
-- This function must return a table of all adjacent hubs.
machines.get_adjacent_network_hubs =
function(pos, tiers)
  -- If `tiers` is omitted or nil, then all tiers are allowed.
  if not tiers then tiers = {"lv", "mv", "hv"} end
  -- Return list of discovered network hubs.
  local hubs = {}
  -- List of valid adjacent locations.
  local targets = {
    {x=pos.x+1, y=pos.y, z=pos.z},
    {x=pos.x-1, y=pos.y, z=pos.z},
    {x=pos.x, y=pos.y, z=pos.z+1},
    {x=pos.x, y=pos.y, z=pos.z-1},
    {x=pos.x, y=pos.y-1, z=pos.z},
    {x=pos.x, y=pos.y+1, z=pos.z},
  }
  -- Get all adjacent nodes once.
  local nodes = {}
  for k, v in ipairs(targets) do
    local node = minetest.get_node(v)
    nodes[#nodes+1] = {node=node, pos=v}
  end
  -- Scan through adjacent nodes and find valid ones.
  for j, t in ipairs(tiers) do
    for k, v in ipairs(nodes) do
      if v.node.name == "switching_station:" .. t then
        hubs[#hubs+1] = v.pos
      end
    end
  end
  return hubs
end



-- Public API function.
-- Swap node only if current node is not the wanted node.
machines.swap_node = function(pos, name)
  local node = minetest.get_node(pos)
  if node.name == name then
		-- Node not swapped.
		return false
	end
  node.name = name
  minetest.swap_node(pos, node)

	-- Node swapped.
	return true
end




-- Public API function.
-- This function implements unified operation for all machine tools.
-- It is based on furnace cooking code, but concept applies broadly.
machines.on_machine_timer =
function(pos, elapsed, data)
  -- Get or inizialize metadata.
  local meta = minetest.get_meta(pos)
  local fuel_time = (meta:get_float("fuel_time") or 0)
  local src_time = (meta:get_float("src_time") or 0)
  local fuel_totaltime = (meta:get_float("fuel_totaltime") or 0)

  local inv = meta:get_inventory()
  local srclist = inv:get_list("src")
  local fuellist = inv:get_list("fuel")

  -- Begin cooking logic.

  -- Check if we have cookable content.
  local cooked, aftercooked = minetest.get_craft_result({
    method = data.method, 
    width = 1, 
    items = srclist,
  })
  local cookable = true

  if cooked.time == 0 then
    cookable = false
  end

  -- Check if we have enough fuel to burn.
  if fuel_time < fuel_totaltime then
    -- The furnace is currently active and has enough fuel.
    fuel_time = fuel_time + 1

    -- If there is a cookable item then check if it is ready yet.
    if cookable then
      src_time = src_time + 1
      if src_time >= cooked.time then
        -- Place result in dst list if possible.
        -- Note that separating recipes have 2 outputs, not 1.
        -- Alloying recipes have 2 inputs and 1 output.
        if data.method == "separating" then
          if inv:room_for_item("dst", cooked.item[1]) and
             inv:room_for_item("dst", cooked.item[2]) then
            inv:add_item("dst", cooked.item[1])
            inv:add_item("dst", cooked.item[2])
            inv:set_stack("src", 1, aftercooked.items[1])
          end
        elseif data.method == "alloying" then
          if inv:room_for_item("dst", cooked.item) then
            inv:add_item("dst", cooked.item)
            inv:set_stack("src", 1, aftercooked.items[1])
            inv:set_stack("src", 2, aftercooked.items[2])
          end
        else
          if inv:room_for_item("dst", cooked.item) then
            inv:add_item("dst", cooked.item)
            inv:set_stack("src", 1, aftercooked.items[1])
          end
        end
        
        src_time = 0
      end
    end
  else
    -- Machine ran out of fuel/energy.
    if cookable then
      -- Try to get cooktime from energy.
      local gotten_cooktime = machines.get_cooktime(pos, 'cfg', 'upg', cooked.time, data.demand)
      if gotten_cooktime >= cooked.time then
        fuel_totaltime = gotten_cooktime
        fuel_time = 0
      else
        -- We need to get new fuel.
        local fuel, afterfuel = minetest.get_craft_result({
          method = data.fuel, 
          width = 1, 
          items = fuellist,
        })

        if fuel.time == 0 then
          -- No valid fuel in fuel list.
          fuel_totaltime = 0
          fuel_time = 0
          src_time = 0
        else
          -- Take fuel from fuel list.
          inv:set_stack("fuel", 1, afterfuel.items[1])

          fuel_totaltime = fuel.time
          fuel_time = 0
        end
      end
    else
      -- We don't need to get new fuel since there is no cookable item.
      fuel_totaltime = 0
      fuel_time = 0
      src_time = 0
    end
  end

  -- Update formspec, infotext and node.
  local formspec = data.form.inactive()
  local item_state
  local item_percent = 0
  if cookable then
    item_percent = math_floor(src_time / cooked.time * 100)
    if item_percent > 100 then
      item_state = "100% (Output Full)"
    else
      item_state = item_percent .. "%"
    end
  else
    if srclist[1]:is_empty() then
      item_state = "Empty"
    else
      item_state = "Not " .. data.processable
    end
  end

  local fuel_state = "Empty"
  local active = "Standby"
  local result = false

  if fuel_time <= fuel_totaltime and fuel_totaltime ~= 0 then
    active = "Active"
    local fuel_percent = math_floor(fuel_time / fuel_totaltime * 100)
    fuel_state = fuel_percent .. "%"
    formspec = data.form.active(fuel_percent, item_percent)
    machines.swap_node(pos, data.swap.active)

    if data.active_sound then
      ambiance.spawn_sound_beacon("ambiance:furnace_active", pos)
    end
    
    -- Make sure timer restarts automatically.
    result = true
  else
    if not fuellist[1]:is_empty() then
      fuel_state = "0%"
    end
    machines.swap_node(pos, data.swap.inactive)
    
    -- Stop timer on the inactive furnace.
    local timer = minetest.get_node_timer(pos)
    timer:stop()
  end

  -- Compose infotext.
  local infotext = data.name .. " (" .. active .. ")\n" ..
    "Item: " .. item_state .. "\n" .. "Fuel Burn: " .. fuel_state .. "\n" ..
    "Buffered: " .. meta:get_int("eu_buffered") .. " EUs"

  -- Set meta values.
  meta:set_float("fuel_totaltime", fuel_totaltime)
  meta:set_float("fuel_time", fuel_time)
  meta:set_float("src_time", src_time)
  meta:set_string("formspec", formspec)
  meta:set_string("infotext", infotext)

  return result
end



-- API constructor for standard cooking/grinding/extracting/etc. machines.
machines.after_place_machine =
function(pos, placer, name, size, form)
  local pname = placer:get_player_name()
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  inv:set_size('src', size)
  inv:set_size('fuel', 1)
  inv:set_size('dst', 4)
  inv:set_size('cfg', 2)
  inv:set_size('upg', 2)
  
  -- Compose infotext.
  local infotext = name .. " (Standby)\n" ..
    "Item: Empty\nFuel Burn: Empty\n" ..
    "Buffered: 0 EUs"

  meta:set_string("formspec", form())
  meta:set_string("infotext", infotext)
end



-- Deliver EUs to batteries on the network. Return EUs left over.
-- This would be called by machines that produce EUs.
machines.deliver_charge_to_network =
function(from, to, charge)
  local node = minetest.get_node(to)
  local def = minetest.reg_ns_nodes[node.name]
  
  if def and def.on_machine_execute then
    local table_in = {
      purpose = "store_eu",
    }
    local table_out = {
      amount_eu = charge,
    }
    local traversal = {}
    
    -- Do not process self.
    local hash = minetest.hash_node_position(from)
    traversal[hash] = 0
          
    def.on_machine_execute(to, table_in, table_out, traversal)
    return (table_out.amount_eu or 0)
  end
  
  -- No network, so all EUs are left over.
  return charge
end



if not machines.run_once then
  local c = "machines:core"
  local f = machines.modpath .. "/init.lua"
  reload.register_file(c, f, false)

	-- A 'dummy' item that represents 1 unit of atomic energy.
	-- This item is never supposed to appear in a player's inventory.
	-- It cannot be crafted and should never be loose in the world.
	-- We register it so we can use it in machine inventory slots.
	minetest.register_craftitem(":atomic:energy", {
		description = "Energy",
		inventory_image = "electric_ball.png",

		-- Engine limit.
		stack_max = 65535,
	})
  
	dofile(machines.modpath .. "/common.lua")
	dofile(machines.modpath .. "/solar.lua")
	dofile(machines.modpath .. "/reactor.lua")
	dofile(machines.modpath .. "/windy.lua")
	dofile(machines.modpath .. "/tide.lua")
	dofile(machines.modpath .. "/panel.lua")
	dofile(machines.modpath .. "/leecher.lua")
	dofile(machines.modpath .. "/charger.lua")
	dofile(machines.modpath .. "/workshop.lua")
    dofile(machines.modpath .. "/breeder.lua")
  machines.run_once = true
end

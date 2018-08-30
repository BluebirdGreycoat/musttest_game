
networks = networks or {}
networks.modpath = minetest.get_modpath("networks")



local param2_rules = {
  [0] = "x",
  [1] = "z",
  [2] = "x",
  [3] = "z",
  
  [4] = "x",
  [5] = "y",
  [6] = "x",
  [7] = "y",
  
  [8] = "x",
  [9] = "y",
  [10] = "x",
  [11] = "y",
  
  [12] = "y",
  [13] = "z",
  [14] = "y",
  [15] = "z",
  
  [16] = "y",
  [17] = "z",
  [18] = "y",
  [19] = "z",
  
  [20] = "x",
  [21] = "z",
  [22] = "x",
  [23] = "z",
}



local direction_rules = {
  ["n"] = "z",
  ["s"] = "z",
  ["w"] = "x",
  ["e"] = "x",
  ["u"] = "y",
  ["d"] = "y",
}



-- Get cable axis alignment from a param2 value.
-- Cable nodes must have nodeboxes that match this.
-- All cable nodes must align to the same axis.
networks.cable_rotation_to_axis =
function(param2)
  if param2 >= 0 and param2 <= 23 then
    return param2_rules[param2]
  end
end



-- Get a unit vector from a cardinal direction, or up/down.
networks.direction_to_vector =
function(dir)
  local d = vector.new(0, 0, 0)
  if dir == "n" then
    d.z = 1
  elseif dir == "s" then
    d.z = -1
  elseif dir == "w" then
    d.x = -1
  elseif dir == "e" then
    d.x = 1
  elseif dir == "u" then
    d.y = 1
  elseif dir == "d" then
    d.y = -1
  else
    return nil
  end
  return d
end



-- Find a network hub, starting from a position and continuing in a direction.
-- Cable nodes (with the right axis) may intervene between hubs.
-- This function must return the position of the next hub, if possible, or nil.
networks.find_hub =
function(pos, dir, tier)
  local meta = minetest.get_meta(pos)
  
  local p = vector.new(pos.x, pos.y, pos.z)
  local d = networks.direction_to_vector(dir)
  
  local station_name = "switching_station:" .. tier
  local cable_name = "cable:" .. tier
  
  -- Max cable length. +1 because a switching station takes up 1 meter of length.
  local cable_length = cable.get_max_length(tier)+1
  
  -- Seek a limited number of meters in a direction.
  for i = 1, cable_length, 1 do
    p = vector.add(p, d)
    local node = minetest.get_node(p)
    if node.name == station_name then
      -- Compatible switching station found!
      return p
    elseif node.name == cable_name then
      -- It's a cable node. We need to check its rotation.
      local paxis = networks.cable_rotation_to_axis(node.param2)
      if paxis then
        local daxis = direction_rules[dir]
        if not daxis or paxis ~= daxis then
          -- Cable has bad axis. Stop scanning.
          return nil 
        end
      else
        -- Invalid param2. We stop scanning.
        return nil 
      end
    -- Unless these items can automatically update switching stations when removed, we can't allow this.
    --elseif minetest.get_item_group(node.name, "conductor") > 0 and minetest.get_item_group(node.name, "block") > 0 then
      -- Anything that is both in group `conductor` and `block` is treated as a cable node.
      -- This allows cables to pass through walls without requiring ugly holes.
    else
      -- Anything other than a cable node or switching station blocks search.
      return nil
    end
  end
  return nil
end



networks.refresh_hubs =
function(pos, tier)
  local meta = minetest.get_meta(pos)
  for k, v in ipairs({
    {n="n"},
    {n="s"},
    {n="e"},
    {n="w"},
    {n="u"},
    {n="d"},
  }) do
    local p = networks.find_hub(pos, v.n, tier)
    if p then
      meta:set_string(v.n, minetest.pos_to_string(p))
    else
      meta:set_string(v.n, nil)
    end
  end
end



-- Invalidate all nearby hubs from a position: NSEW, UD.
-- This should cause them to re-update their routing.
-- This would need to be done if a hub or cable is removed.
networks.invalidate_hubs =
function(pos, tier)
  for k, v in ipairs({
    {n="n"},
    {n="s"},
    {n="e"},
    {n="w"},
    {n="u"},
    {n="d"},
  }) do
    local p = networks.find_hub(pos, v.n, tier)
    if p then
      local meta = minetest.get_meta(p)
      for i, j in ipairs({
        {n="n"},
        {n="s"},
        {n="e"},
        {n="w"},
        {n="u"},
        {n="d"},
      }) do
        meta:set_string(j.n, nil)
      end
      
      -- Trigger node update.
      local timer = minetest.get_node_timer(p)
      if not timer:is_started() then
        timer:start(1.0)
      end
    end
  end
end



-- This function must return a table of all adjacent hubs.
-- Table entries shall contain position of hub and its message function.
networks.get_adjacent_hubs =
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
    local meta = minetest.get_meta(v)
    if meta:get_string("technic_machine") == "yes" then
      local nn = meta:get_string("technic_name")
      if meta:get_string("technic_type") == "switch" then
        nodes[#nodes+1] = {name=nn, pos=v}
      end
    end
  end
  -- Scan through adjacent nodes and find valid ones.
  for j, t in ipairs(tiers) do
    local nn = "switching_station:" .. t
    local def = minetest.registered_items[nn]
    for k, v in ipairs(nodes) do
      if v.name == nn then
        hubs[#hubs+1] = {pos=v.pos, on_machine_execute=def.on_machine_execute}
      end
    end
  end
  return hubs
end



-- This function must return a table of all adjacent machines.
-- Table entries shall contain position of machine and its message function.
networks.get_adjacent_machines =
function(pos, tier)
  -- Return list of discovered adjacent machines.
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
  for k, v in ipairs(targets) do
    local meta = minetest.get_meta(v)
    if meta:get_string("technic_machine") == "yes" then
      if string.find(meta:get_string("technic_tier"), tier) then
        local nn = meta:get_string("technic_name")
        -- Switching stations are NOT machines in the context of this function.
        -- This function cannot return switching stations because that would make a recursion mess.
        if nn ~= "" and not string.find(nn, "^switching_station:") then
          local def = minetest.registered_items[nn]
          assert(type(def.on_machine_execute) == "function")
          hubs[#hubs+1] = {pos=v, on_machine_execute=def.on_machine_execute}
        end
      end
    end
  end
  return hubs
end



if not networks.run_once then
  local c = "networks:core"
  local f = networks.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(networks.modpath .. "/nodestore.lua")
	dofile(networks.modpath .. "/net2.lua")
  networks.run_once = true
end

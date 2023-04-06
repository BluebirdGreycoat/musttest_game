
if not minetest.global_exists("instability") then instability = {} end
instability.modpath = minetest.get_modpath("instability")

-- Localize for speed.
local allnodes = minetest.registered_nodes
local stringf = string.find
local ipairs = ipairs
local mrandom = math.random
local after = minetest.after
local getn = minetest.get_node



-- This helper function should determine whether a node is
-- considered to be capable of supporting another node.
-- First argument is the node to check. Second argument is the node it may or may not be supporting.
-- This allows liquid nodes to support each other, but not anybody else.
local function node_considered_supporting(nn, on)
	--minetest.chat_send_all(nn .. ', ' .. on)

  if nn == "air" then return false end
  if snow.is_snow(nn) then return false end

	-- 'ignore' must be supporting, to avoid accidents and problematic bugs.
  if nn == "ignore" then return true end
  
  if stringf(nn, "^throwing:") or
      stringf(nn, "^fire:") then
      -- Treating fences as non-supporting is apparently rather annoying.
      -- Fences are used for lampposts, etc.
      --stringf(nn, "^default:fence") or
			-- Ladders are self-supporting.
      --stringf(nn, "ladder")
    return false
  end

	if on then
		-- Ladders are self-supporting.
		if stringf(nn, "ladder") and stringf(on, "ladder") then
			return true
		end

		-- Papyrus is self-supporting. Otherwise, digging 1 papyrus
		-- would cause nearby papyrus to fall, which looks bad.
		if nn == "default:papyrus" and on == "default:papyrus" then
			return true
		end

		-- Twisted vines are self-supporting.
		if stringf(nn, "default:tvine") and stringf(on, "default:tvine") then
			return true
		end
	end
   
  local def = allnodes[nn]
  if def then
    if def.liquidtype == "source" or def.liquidtype == "flowing" then
			-- Did we get a name of a node we may or may not be supporting?
			if on then
				local d2 = allnodes[on]
				if d2 then
					if def.liquidtype == "source" and d2.liquidtype == "source" then
						-- Liquid *sources* support other liquids.
						return true
					end
				end
			end
			-- Liquid does not support.
      return false
    end
    
    local dt = def.drawtype
    local pt2 = def.paramtype2
    if dt == "airlike" or
        dt == "signlike" or
        dt == "torchlike" or
        dt == "raillike" or
        dt == "plantlike" or
        dt == "firelike" or
        (dt == "nodebox" and pt2 == "wallmounted") then
      return false
    end
    
    local groups = def.groups or {}
    if groups.attached_node then
      return false
    end
  end
  
  return true
end



-- Determine if a single node is surrounded at 8 sides/corners by air.
instability.is_singlenode = function(pos, axis)
  local nn = getn(pos).name
	-- Preserve the name of the node at the center.
	local cn = nn
  if nn == "air" or nn == "ignore" then return end
  
  -- The code tries to exit as early as possible if I can determine
  -- right away the node being checked is not a singlenode.
  
  -- If the starting node isn't solid, don't bother checking.
  if not node_considered_supporting(nn) then
    return false
  end
  
  if axis == "y" then
    local sides = {
      {x=pos.x-1, y=pos.y  , z=pos.z  },
      {x=pos.x+1, y=pos.y  , z=pos.z  },
      {x=pos.x  , y=pos.y  , z=pos.z-1},
      {x=pos.x  , y=pos.y  , z=pos.z+1},
      {x=pos.x-1, y=pos.y  , z=pos.z-1},
      {x=pos.x+1, y=pos.y  , z=pos.z-1},
      {x=pos.x-1, y=pos.y  , z=pos.z+1},
      {x=pos.x+1, y=pos.y  , z=pos.z+1},
    }
    for k, v in ipairs(sides) do
      local nn = getn(v).name
      if nn ~= "air" then
        if node_considered_supporting(nn, cn) then
          return false
        end
      end
    end
    return true -- Air all around.
  elseif axis == "x" then
    local sides = {
      {x=pos.x  , y=pos.y-1, z=pos.z  },
      {x=pos.x  , y=pos.y+1, z=pos.z  },
      {x=pos.x  , y=pos.y  , z=pos.z-1},
      {x=pos.x  , y=pos.y  , z=pos.z+1},
      {x=pos.x  , y=pos.y-1, z=pos.z-1},
      {x=pos.x  , y=pos.y+1, z=pos.z-1},
      {x=pos.x  , y=pos.y-1, z=pos.z+1},
      {x=pos.x  , y=pos.y+1, z=pos.z+1},
    }
    for k, v in ipairs(sides) do
      local nn = getn(v).name
      if nn ~= "air" then
        if node_considered_supporting(nn, cn) then
          return false
        end
      end
    end
    return true -- Air all around.
  elseif axis == "z" then
    local sides = {
      {x=pos.x-1, y=pos.y  , z=pos.z  },
      {x=pos.x+1, y=pos.y  , z=pos.z  },
      {x=pos.x  , y=pos.y-1, z=pos.z  },
      {x=pos.x  , y=pos.y+1, z=pos.z  },
      {x=pos.x-1, y=pos.y-1, z=pos.z  },
      {x=pos.x+1, y=pos.y-1, z=pos.z  },
      {x=pos.x-1, y=pos.y+1, z=pos.z  },
      {x=pos.x+1, y=pos.y+1, z=pos.z  },
    }
    for k, v in ipairs(sides) do
      local nn = getn(v).name
      if nn ~= "air" then
        if node_considered_supporting(nn, cn) then
          return false
        end
      end
    end
    return true -- Air all around.
  end
end



-- Determine if the node at a position is part of a 1x1 tower of nodes.
-- (A node is part of a tower if the 8 locations around it are air.)
instability.find_tower = function(args)
  -- Argument table:
  --[[
  {
    -- Position of first node to check.
    pos = {x=..., y=..., z=...},
   
    -- Direction along the axis (positive or negative).
    dir = "p|n",
   
    -- Axis to check along (allows checking for horizontal towers).
    axis = "x|y|z",
   
    -- Number of nodes to check.
    len = ...,
  }
  --]]
  
  -- Table of nodes which are part of the tower.
  -- This can be later used in a collapsing algorithm.
  local tower_nodes = {}

  local seek = function(pos, dir, axis, len)
    for i = 1, len, 1 do
      if not instability.is_singlenode(pos, axis) then
        return -- Early exit. Can't be a tower.
      end
      tower_nodes[#tower_nodes+1] = {x=pos.x, y=pos.y, z=pos.z}
      pos = vector.add(pos, dir)
    end
  end
  
  if args.axis == "y" then
    if args.dir == "p" then
      seek(args.pos, {x=0, y=1, z=0}, args.axis, args.len)
    elseif args.dir == "n" then
      seek(args.pos, {x=0, y=-1, z=0}, args.axis, args.len)
    end
  elseif args.axis == "x" then
    if args.dir == "p" then
      seek(args.pos, {x=1, y=0, z=0}, args.axis, args.len)
    elseif args.dir == "n" then
      seek(args.pos, {x=-1, y=0, z=0}, args.axis, args.len)
    end
  elseif args.axis == "z" then
    if args.dir == "p" then
      seek(args.pos, {x=0, y=0, z=1}, args.axis, args.len)
    elseif args.dir == "n" then
      seek(args.pos, {x=0, y=0, z=-1}, args.axis, args.len)
    end
  end
  
  -- Table of tower nodes. Will be empty if not a tower.
  return tower_nodes
end



local messages = {
  "Player <%s>'s unstable structure has collapsed!",
  "Player <%s> was slapped by physics.",
  "Player <%s>'s structure offended the physics rules!",
  "Player <%s> built something unstable.",
  "Player <%s> forgot that unstable builds tend to collapse, here.",
  "A structure built by <%s> just fell down.",
}



instability.check_tower_and_collapse = function(pos, axis, dir, pname)
  local tower = instability.find_tower({
    pos = pos,
    axis = axis,
    dir = dir,
    len = 20,
  })
  
  if #tower >= 4 then
    local chance = mrandom(4, 10)
    if #tower >= chance then -- Chance to fall increases with length.
			local dropped = false

      for k, v in ipairs(tower) do
        local node = getn(v)
        if not instability.node_exempt(node.name) then
					if sfn.drop_node(v) then
						dropped = true
						core.check_for_falling(v)
					end
        end
      end
      
			-- Write to chat only if something actually fell.
			if dropped then
				local dname = rename.gpn(pname)
  	    minetest.chat_send_all("# Server: " .. string.format(messages[mrandom(1, #messages)], dname))
			end
    end
  end
end



-- Public API function.
instability.check_tower = function(pos, node, pref)
  if mrandom(1, 6) == 1 then -- Randomized checking.
    -- Some nodetypes should be exempt from checking.
		-- It is ok to build towers of these.
    if stringf(node.name, "scaffolding") then return end
    if stringf(node.name, "ladder") then return end
    if stringf(node.name, "rope") then return end
    if stringf(node.name, "chain") then return end
    
    -- Protector nodes shall be exempt!
    if stringf(node.name, "^protector:") then return end
		if stringf(node.name, "^city_block:") then return end
    
    -- Doors and beds are multi-node constructs.
    if stringf(node.name, "^doors:") then return end
    if stringf(node.name, "^beds:") then return end
    
    local pname = pref:get_player_name()
    
    instability.check_tower_and_collapse(pos, "x", "p", pname)
    instability.check_tower_and_collapse(pos, "x", "n", pname)
    
    instability.check_tower_and_collapse(pos, "y", "p", pname)
    instability.check_tower_and_collapse(pos, "y", "n", pname)
    
    instability.check_tower_and_collapse(pos, "z", "p", pname)
    instability.check_tower_and_collapse(pos, "z", "n", pname)
  end
end



instability.check_single_node = function(pos)
  if mrandom(1, 200) == 1 then
    local overhang = true
    local node = getn(pos)
    
    -- Do not cause exempt nodes to fall.
    if instability.node_exempt(node.name) then
      return
    end
    
    for i = 1, 3 do
      node = getn({x=pos.x, y=pos.y-i, z=pos.z})
      if node.name ~= "air" then
        -- If any node below the one just placed is not air, then it doesn't qualify as an overhang.
        overhang = false
        break
      end
    end
    if overhang then
      local p = {x=pos.x, y=pos.y, z=pos.z}
      node = getn(p)
      local delay = mrandom(2, 10)
      after(delay - 1.5, function()
        ambiance.sound_play("default_gravel_footstep", p, 1, 20)
      end)
      after(delay, function()
        local n2 = getn(p)
        if n2.name == node.name then
					sfn.drop_node(p)
					core.check_for_falling(p)
        end
      end)
    end
  end
end



function instability.node_exempt(name)
  if name == "air" or name == "ignore" or
      -- Because falling protectors would be very, very bad.
      stringf(name, "^protector:") or
			stringf(name, "^city_block:") or
      -- Waterlilies must be considered stable to avoid them getting destroyed.
      -- This is because water does not support, and they are floodable.
      name == "flowers:waterlily" or
      -- The ropeboxes themselves can still fall. The rope is automatically removed.
			-- We don't want to interfere with that.
      stringf(name, "^vines:rope") or
      -- Beds and doors are multi-node constructs. We must not split them.
      stringf(name, "^beds:") or
      stringf(name, "^doors:") or
			-- Falling fire is problematic.
			stringf(name, "^fire:") then
    return true
  end
end



-- Called everytime a node is dug.
function instability.check_unsupported_around(p)
  local target_nodes = {
    {x=p.x, y=p.y+1, z=p.z},
    {x=p.x, y=p.y-1, z=p.z},
    {x=p.x+1, y=p.y, z=p.z},
    {x=p.x-1, y=p.y, z=p.z},
    {x=p.x, y=p.y, z=p.z+1},
    {x=p.x, y=p.y, z=p.z-1},
  }
  for j=1, #target_nodes, 1 do
    instability.check_unsupported_single(target_nodes[j])
  end
end



-- Called from the TNT code, for instance.
function instability.check_unsupported_single(p)
  local n = getn(p)
	-- Preserve the name of the center node.
	local nn = n.name
  if not instability.node_exempt(nn) then
    local supporting_positions = {
      {x=p.x, y=p.y+1, z=p.z},
      {x=p.x, y=p.y-1, z=p.z},
      {x=p.x+1, y=p.y, z=p.z},
      {x=p.x-1, y=p.y, z=p.z},
      {x=p.x, y=p.y, z=p.z+1},
      {x=p.x, y=p.y, z=p.z-1},
    }
    local solid = false
    for i=1, #supporting_positions, 1 do
      local n = getn(supporting_positions[i])
      if node_considered_supporting(n.name, nn) then
        solid = true
        break -- No need for further checks.
      end
    end
    -- No supporting nodes!
    if not solid then
			sfn.drop_node(p)
      core.check_for_falling(p)
    end
  end
end



if not instability.run_once then
  local c = "instability:core"
  local f = instability.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  instability.run_once = true
end

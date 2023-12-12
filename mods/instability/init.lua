
if not minetest.global_exists("instability") then instability = {} end
instability.modpath = minetest.get_modpath("instability")

-- Localize for speed.
local allnodes = minetest.registered_nodes
local stringf = string.find
local ipairs = ipairs
local mrandom = math.random
local after = minetest.after
local getn = minetest.get_node



-- This helper function shall return TRUE if THIS NODE (nn) shall be considered
-- to be supporting THE OTHER NODE (on). THE OTHER NODE (on) is the one being
-- checked to see if it needs to fall.
--
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

  -- Papyrus is self-supporting. Otherwise, digging 1 papyrus
  -- would cause nearby papyrus to fall, which looks bad.
  if nn == "default:papyrus" and on == "default:papyrus" then
    return true
  end

  -- Twisted vines are self-supporting.
  if stringf(nn, "default:tvine") and stringf(on, "default:tvine") then
    return true
  end

  local this_def = allnodes[nn]
  local other_def = allnodes[on]

  -- Unknown nodes always support, to prevent accidents.
  if not this_def or not other_def then
    --minetest.chat_send_all('deadbeaf')
    return true
  end

  if this_def.liquidtype == "source" then
    if other_def.liquidtype == "source" then
      --minetest.chat_send_all('liquid supporting')
      -- Liquid *sources* support other liquid sources.
      return true
    end

    -- Liquid does not support non-liquid nodes.
    return false
  elseif this_def.liquidtype == "flowing" then
    -- Flowing liquids never support nodes.
    return false
  end

  local this_groups = this_def.groups or {}
  local other_groups = other_def.groups or {}

  local this_drawtype = this_def.drawtype
  local this_paramtype = this_def.paramtype2

  -- Climbable supports adjacent climbable if they have the same drawtype.
  -- This works for ladders, climbable vines, etc.
  if this_def.climbable and other_def.climbable and this_def.drawtype == other_def.drawtype then
    return true
  end

  -- Walkable-falling nodes support plantlike nodes and attached nodes.
  if this_def.walkable and (this_groups.falling_node or 0) ~= 0 then
    if other_def.drawtype == "plantlike" or (other_groups.attached_node or 0) ~= 0 then
      return true
    elseif (other_groups.falling_node or 0) ~= 0 then
      -- Be more conservative: support other falling nodes. If the node needs to
      -- fall anyway, the falling node code will do it. This prevents us from
      -- having issues with lots of falling nodes packed together in a pile.
      return true
    end
  end

  --minetest.chat_send_all('checking: ' .. nn .. ',' .. on)

  -- None of these drawtypes can support other nodes under normal circumstances.
  if this_drawtype == "airlike" or
      this_drawtype == "signlike" or
      this_drawtype == "torchlike" or
      this_drawtype == "raillike" or
      this_drawtype == "plantlike" or
      this_drawtype == "firelike" or
      (this_drawtype == "nodebox" and this_paramtype == "wallmounted") then
    return false
  end

  -- Attached nodes cannot support other nodes.
  if (this_groups.attached_node or 0) ~= 0 then
    return false
  end

  -- Falling nodes cannot support other nodes.
  if (this_groups.falling_node or 0) ~= 0 then
    return false
  end
  
  -- By default, node is considered supporting if we didn't handle it.
  --minetest.chat_send_all('supporting: ' .. nn .. ", supported: " .. on)
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
			if falling.could_fall_here(p) and sfn.drop_node(p) then
        core.check_for_falling(p)
        minetest.after(0.1, instability.check_unsupported_around, p)
      end
    end
  end
end



if not instability.run_once then
  local c = "instability:core"
  local f = instability.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  instability.run_once = true
end

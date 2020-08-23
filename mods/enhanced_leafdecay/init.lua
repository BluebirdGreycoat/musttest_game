
enhanced_leafdecay = enhanced_leafdecay or {}
enhanced_leafdecay.modpath = minetest.get_modpath("enhanced_leafdecay")

-- Localize for performance.
local math_random = math.random

local LEAFDECAY_MIN_TIME = 1
local LEAFDECAY_MAX_TIME = 20

local DEFAULT_RANGE = 3



-- Shall return a function suitable for `on_construct` callback.
-- Note: not called by Voxelmanip, schematics.
enhanced_leafdecay.make_leaf_constructor =
function(args)
  local functor = function(pos)
    local timer = minetest.get_node_timer(pos)
    timer:start(math_random(LEAFDECAY_MIN_TIME * 10, LEAFDECAY_MAX_TIME * 10) / 10)
  end
  return functor
end

-- Shall return a function suitable for `on_timer` callback.
enhanced_leafdecay.make_leaf_nodetimer =
function(args)
  local r = (args.range or DEFAULT_RANGE)
  local t = (args.tree or "group:tree")
  local functor = function(pos, elapsed)
    -- If we can find a trunk right away, then done.
    if utility.find_node_near_not_world_edge(pos, r, t) then
      return
    end
    
    -- If `ignore` is nearby, we can't assume there isn't a trunk.
    -- We'll need to restart the timer.
    if utility.find_node_near_not_world_edge(pos, r, "ignore") then
      return true
    end
    
    -- Drop stuff.
    local node = minetest.get_node(pos)
		-- Pass node name, because passing a node table gives wrong results.
    local stacks = minetest.get_node_drops(node.name)
    for k, v in ipairs(stacks) do
      if v ~= node.name or minetest.get_item_group(node.name, "leafdecay_drop") ~= 0 then
        local loc = {
          x = pos.x - 0.5 + math_random(),
          y = pos.y - 0.5 + math_random(),
          z = pos.z - 0.5 + math_random(),
        }
        minetest.add_item(loc, v)
      end
    end
    
    -- Remove node.
    minetest.remove_node(pos)
    minetest.check_for_falling(pos)
		instability.check_unsupported_around(pos)
  end
  return functor
end

-- Shall return a function suitable for `on_destruct` callback.
-- Note: not called by Voxelmanip, schematics.
enhanced_leafdecay.make_tree_destructor =
function(args)
  local r = (args.range or DEFAULT_RANGE)
  local l = (args.leaves or "group:leaves")
  local functor = function(pos)
    local minp = {x=pos.x-r, y=pos.y-r, z=pos.z-r}
    local maxp = {x=pos.x+r, y=pos.y+r, z=pos.z+r}
    local leaves = minetest.find_nodes_in_area(minp, maxp, l)
    
    -- Start nodetimers for all leaves in the vicinity.
    for k, v in ipairs(leaves) do
      local timer = minetest.get_node_timer(v)
			if not timer:is_started() then
				timer:start(math_random(LEAFDECAY_MIN_TIME * 10, LEAFDECAY_MAX_TIME * 10) / 10)
			end
    end
  end
  return functor
end

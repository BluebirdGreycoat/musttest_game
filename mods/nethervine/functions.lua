
-- Localize for performance.
local math_random = math.random

-- Indexed array.
-- List of nodes which nether flora can use as soil.
nethervine.flora_surfaces = {
	"rackstone:redrack",
	"rackstone:dauthsand",
}

-- List of nearby nether flora that should be notified when a flora node is removed.
nethervine.flora_nodes = {
  "nether:grass_1",
  "nether:grass_2",
  "nether:grass_3",
}

nethervine.flora_mintime = 60*3
nethervine.flora_maxtime = 60*30

function nethervine.surface_can_spawn_flora(pos)
  local name = minetest.get_node(pos).name
  local nodes = nethervine.flora_surfaces
  for i=1, #nodes do
    if string.find(nodes[i], "^group:") then
      local group = string.sub(nodes[i], 7)
      if minetest.get_item_group(name, group) ~= 0 then
        return true
      end
    elseif nodes[i] == name then
      return true
    end
  end
  return false
end

function nethervine.on_flora_construct(pos)
  if nethervine.surface_can_spawn_flora({x=pos.x, y=pos.y-1, z=pos.z}) then
    minetest.get_node_timer(pos):start(math_random(nethervine.flora_mintime, nethervine.flora_maxtime))
  end
end

function nethervine.on_flora_destruct(pos)
  -- Notify nearby flora.
  local minp = {x=pos.x-2, y=pos.y-2, z=pos.z-2}
  local maxp = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
  local flora = minetest.find_nodes_in_area_under_air(minp, maxp, nethervine.flora_nodes)
  if flora and #flora > 0 then
    for i=1, #flora do
      minetest.get_node_timer(flora[i]):start(math_random(nethervine.flora_mintime, nethervine.flora_maxtime))
    end
  end
end

function nethervine.on_flora_timer(pos, elapsed)
  local node = minetest.get_node(pos)
  if nethervine.flora_spread(pos, node) then
    minetest.get_node_timer(pos):start(math_random(nethervine.flora_mintime, nethervine.flora_maxtime))
  else
    -- Else timer should stop, cannot grow anymore.
    minetest.get_node_timer(pos):stop()
  end
end

function nethervine.on_flora_punch(pos, node, puncher, pt)
  if nethervine.surface_can_spawn_flora({x=pos.x, y=pos.y-1, z=pos.z}) then
    minetest.get_node_timer(pos):start(math_random(nethervine.flora_mintime, nethervine.flora_maxtime))
  end
end

-- Called by the bonemeal mod.
-- Returns 'true' or 'false' to indicate if a mushroom was spawned.
function nethervine.flora_spread(pos, node)
  local minp = {x=pos.x-2, y=pos.y-2, z=pos.z-2}
  local maxp = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
  local dirt = minetest.find_nodes_in_area_under_air(minp, maxp, nethervine.flora_surfaces)
  if not dirt or #dirt == 0 then
    return false
  end

  local density = nethervine.flora_density_for_surface({x=pos.x, y=pos.y-1, z=pos.z})
  local pos0 = vector.subtract(pos, 4)
  local pos1 = vector.add(pos, 4)
  if #minetest.find_nodes_in_area(pos0, pos1, "group:netherflora") > density then
    return false -- Max flora reached.
  end

  local randp = dirt[math_random(1, #dirt)]
  local airp = {x=randp.x, y=randp.y+1, z=randp.z}
  local airn = minetest.get_node_or_nil(airp)
  if not airn or airn.name ~= "air" then
    return false
  end

  -- Nether flora grows in nether regardless of light level.
  if pos.y < -25000 then
    minetest.add_node(airp, {name = node.name})
    return true
  end
  return false
end

function nethervine.flora_density_for_surface(pos)
  local cold = 0
  if minetest.find_node_near(pos, 5, {
    "group:snow",
    "group:snowy",
    "group:ice",
    "group:cold",
  }) then
    cold = -6
  end

  -- High heat makes nether plants grow denser.
  local heat = 0
  if minetest.find_node_near(pos, 3, "group:lava") then
    heat = 4
  end

  local minerals = 0
  if minetest.find_node_near(pos, 3, "glowstone:minerals") then
    minerals = 1
  end

  if minetest.get_node(pos).name == "rackstone:dauthsand" then
    return 4 + minerals + heat + cold
  end

  -- Default flower density.
  return 1 + minerals + heat + cold
end

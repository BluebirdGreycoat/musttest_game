
if not minetest.global_exists("trunkgen") then trunkgen = {} end
trunkgen.modpath = minetest.get_modpath("trunkgen")

-- Localize for performance.
local math_random = math.random



-- Utility function.
trunkgen.set_node = function(pos, node)
  if minetest.get_node(pos).name == "air" then
    minetest.set_node(pos, node)
  end
end



-- Generates a trunk base.
trunkgen.generate_bole = function(pos, nodename)
  local pr = {}
  function pr:next(min, max)
    return math_random(min, max)
  end

  local sides =
  {
    {x=pos.x-1, y=pos.y, z=pos.z},
    {x=pos.x+1, y=pos.y, z=pos.z},
    {x=pos.x, y=pos.y, z=pos.z-1},
    {x=pos.x, y=pos.y, z=pos.z+1},
  }
  
  for i=1, #sides do
    if pr:next(0, 1) == 0 then
      local p = sides[i]
      local n = pr:next(0, pr:next(1, 2))
      for j=0, n do
        local z = {x=p.x, y=p.y+j, z=p.z}
        trunkgen.set_node(z, {name=nodename})
      end
    end
  end
  
  local corners =
  {
    {x=pos.x-1, y=pos.y, z=pos.z-1},
    {x=pos.x+1, y=pos.y, z=pos.z+1},
    {x=pos.x+1, y=pos.y, z=pos.z-1},
    {x=pos.x-1, y=pos.y, z=pos.z+1},
  }
  
  for i=1, #corners do
    if pr:next(0, 1) == 0 then
      local p = corners[i]
      local z = {x=p.x, y=p.y, z=p.z}
      trunkgen.set_node(z, {name=nodename})
    end
  end
end



-- Generates a jungletree-style leaf-branch.
trunkgen.generate_jungletree_branches = function(pos, tname, lnames, minh, maxh)
  local n = math_random(1, 3) -- How many?
  
  if type(lnames) == "string" then
    lnames = {[1]=lnames}
  end
  assert(type(lnames) == "table")
  
  local positions =
  {
    {x=pos.x+1, y=pos.y, z=pos.z},
    {x=pos.x-1, y=pos.y, z=pos.z},
    {x=pos.x, y=pos.y, z=pos.z+1},
    {x=pos.x, y=pos.y, z=pos.z-1},
    
    {x=pos.x+1, y=pos.y, z=pos.z+1},
    {x=pos.x+1, y=pos.y, z=pos.z-1},
    {x=pos.x-1, y=pos.y, z=pos.z+1},
    {x=pos.x-1, y=pos.y, z=pos.z-1},
  }
  
  for i=1, n do
    local h = math_random(minh, maxh) -- How high?
    local p = vector.new(positions[math_random(1, #positions)]) -- Where?
    p.y = p.y+h
    
    -- Make!
    trunkgen.set_node(p, {name=tname})
    local lp =
    {
      {x=p.x+1, y=p.y, z=p.z},
      {x=p.x-1, y=p.y, z=p.z},
      {x=p.x, y=p.y, z=p.z+1},
      {x=p.x, y=p.y, z=p.z-1},
      
      {x=p.x+1, y=p.y, z=p.z+1},
      {x=p.x+1, y=p.y, z=p.z-1},
      {x=p.x-1, y=p.y, z=p.z+1},
      {x=p.x-1, y=p.y, z=p.z-1},
    }
    for j=1, #lp do
      local p = lp[j]
      trunkgen.set_node(p, {name=lnames[math_random(1, #lnames)]})
    end
  end
end


function trunkgen.check_trunk(pos, dist, trunk)
	for y = pos.y, pos.y + dist, 1 do
		local p = {x=pos.x, y=y, z=pos.z}
		if minetest.get_node(p).name == "air" then
			minetest.set_node(p, {name=trunk})
		end
	end
end

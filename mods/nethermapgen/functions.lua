
local random = math.random
local set_node = minetest.set_node
local get_node = minetest.get_node

local crystal_directions = {
	{x=1,   y=0,    z=0},
	{x=-1,  y=0,    z=0},
	{x=0,   y=0,    z=1},
	{x=0,   y=0,    z=-1},

	-- Duplicate entries increase the chance that this direction is taken.
	{x=0,   y=-1,   z=0},
	{x=0,   y=-1,   z=0},
	--{x=0,   y=-1,   z=0},
}

local generate_crystal -- Forward declaration needed for recursion.
generate_crystal = function(pos, rec_, tot_)
	-- Enabling this causes crystals to fail to generate on the netherealm roof.
	--if get_node(pos).name ~= "air" then return end
	set_node(pos, {name="glowstone:minerals"})
	local rec = rec_ or 0
	local tot = tot_ or random(3, 10)
	if rec >= tot then return end
	local d1 = crystal_directions[random(1, #crystal_directions)]
	local p1 = {x=pos.x+d1.x, y=pos.y+d1.y, z=pos.z+d1.z}
	generate_crystal(p1, rec+1, tot)
	if random(1, 4) == 1 then
		local d2 = crystal_directions[random(1, #crystal_directions)]
		local p2 = {x=pos.x+d2.x, y=pos.y+d2.y, z=pos.z+d2.z}
		generate_crystal(p2, rec+2, tot)
	end
end

nethermapgen.place_crystal = function(pos)
  generate_crystal(pos)
end

local find_floor_up = function(pos, limit)
	for i = 0, limit, 1 do
		local p1 = {x=pos.x, y=pos.y+i, z=pos.z} -- Node
		local p2 = {x=p1.x, y=p1.y+1, z=p1.z} -- Node above

		local n1 = get_node(p1).name
		local n2 = get_node(p2).name

		if n2 == "air" and (n1 == "rackstone:redrack" or
			n1 == "rackstone:mg_redrack" or
			n1 == "rackstone:rackstone" or
			n1 == "rackstone:mg_rackstone") then
			return p2
		end
	end
end

local find_floor_down = function(pos, limit)
	for i = 0, limit, 1 do
		local p1 = {x=pos.x, y=pos.y-i, z=pos.z} -- Node above
		local p2 = {x=p1.x, y=p1.y-1, z=p1.z} -- Node

		local n1 = get_node(p1).name
		local n2 = get_node(p2).name

		if n1 == "air" and (n2 == "rackstone:redrack" or
			n2 == "rackstone:mg_redrack" or
			n2 == "rackstone:rackstone" or
			n2 == "rackstone:mg_rackstone") then
			return p1
		end
	end
end

local fire_directions = {
  {x=1,   y=0,    z=0},
  {x=-1,  y=0,    z=0},
  {x=0,   y=0,    z=1},
  {x=0,   y=0,    z=-1},
}

local scatter_nether_fire
scatter_nether_fire = function(pos, rec_, tot_)
  local p1 = find_floor_up(pos, 2)
  if p1 == nil then p1 = find_floor_down(pos, 2) end
  if p1 == nil then return end -- No floor found.
  pos = p1
  
  set_node(pos, {name="fire:nether_flame"})
  local rec = rec_ or 0
  local tot = tot_ or random(5, 20)
  if rec >= tot then return end
  
  local d1 = fire_directions[random(1, #fire_directions)]
  local p1 = {x=pos.x+d1.x, y=pos.y+d1.y, z=pos.z+d1.z}
  scatter_nether_fire(p1, rec+1, tot)
  
  if random(1, 4) == 1 then
    local d2 = fire_directions[random(1, #fire_directions)]
    local p2 = {x=pos.x+d2.x, y=pos.y+d2.y, z=pos.z+d2.z}
    scatter_nether_fire(p2, rec+1, tot)
  end
end

nethermapgen.scatter_flames = function(pos)
  scatter_nether_fire(pos)
end

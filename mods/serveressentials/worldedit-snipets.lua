-- Set day and freeze time.
local function func()
  minetest.set_timeofday(0.5);
  minetest.after(1, function()
    if func then
      func()
    end
  end)
end func()



-- Simple light smooth.
local n = minetest.get_node
local v = vector.add

if n(pos).name ~= "air" and
    (n(v(pos, {x=1, y=0, z=0})).name == "air" and
      n(v(pos, {x=-1, y=0, z=0})).name == "air") or
    (n(v(pos, {x=0, y=0, z=1})).name == "air" and
      n(v(pos, {x=0, y=0, z=-1})).name == "air") then
  minetest.set_node(pos, {name="air"})
end



-- Another smoothing type.
local n = minetest.get_node
local v = vector.add

if n(pos).name == "air" then
  local c = 0
  if n(v(pos, {x=1, y=0, z=0})).name ~= "air" then c=c+1 end
  if n(v(pos, {x=-1, y=0, z=0})).name ~= "air" then c=c+1 end
  if n(v(pos, {x=0, y=0, z=1})).name ~= "air" then c=c+1 end
  if n(v(pos, {x=0, y=0, z=-1})).name ~= "air" then c=c+1 end

  if c >= 3 then
    minetest.set_node(pos, {name="rackstone:cobble"})
  end
end



-- Change surface node type.
if minetest.get_node(pos).name ~= "air" and
    minetest.get_node(vector.add(pos, {x=0, y=1, z=0})).name == "air" then
  minetest.set_node(pos, {name="rackstone:cobble"})
end



-- Place schematic.
--[[
//brush cubeapply 1 luatransform minetest.place_schematic(vector.add(pos, {x=-1, y=-2, z=-1}), minetest.get_worldpath() .. "/schems/pit.mts", "random", nil, true)
--]]


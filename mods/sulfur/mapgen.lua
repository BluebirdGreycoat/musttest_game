
-- Localize for performance.
local math_floor = math.floor

local c_lava = minetest.get_content_id("default:lava_source")
local c_lava_flowing = minetest.get_content_id("default:lava_flowing")
local c_stone = minetest.get_content_id("default:stone")
local c_sulfur = minetest.get_content_id("sulfur:ore")

-- Sulfur
local sulfur_buf = {}
local sulfur_noise= nil

local generate = function(vm, minp, maxp, seed)
  -- Keep mapgen within bounds. Not in nether, not in shallow caves.
  if minp.y < -24000 or maxp.y > -256 then return end
	--minetest.chat_send_all("searching for lava")

  local emin, emax = vm:get_emerged_area()
  local a = VoxelArea:new{
    MinEdge = {x = emin.x, y = emin.y, z = emin.z},
    MaxEdge = {x = emax.x, y = emax.y, z = emax.z},
  }
  vm:get_data(sulfur_buf)
  local data = sulfur_buf

  --[[
  -- Pre-pass: clean up C++ mapgen flat-slab leftovers.
  local area = a
  for z = emin.z, emax.z do
    for x = emin.x, emax.x do
      for y = emin.y, emax.y do
        local vp = area:index(x, y, z)

        -- Get the type already generated at this position.
        local ip = data[vp]

        -- Note: sometimes these will be nil, because of accessing outside the array.
        -- (We are scanning through the emin/emax range.)
        local iu = data[area:index(x, y+1, z)]
        local id = data[area:index(x, y-1, z)]

        -- HACK:
        -- Get rid of the <BEEP> flat horizontal slabs that appear at chunk top/bot edges
        -- whenever emerge threads are more than 1. We have to do this *indiscriminately*,
        -- which unfortunately modifies the terrain shape more than is actually necessary.
        if ip == c_stone then
          if (id == c_air or id == c_ignore) and (iu == c_air or iu == c_ignore) then
            data[vp] = c_air
          end
        end
      end
    end
  end
  --]]

  local pr = PseudoRandom(17 * minp.x + 42 * minp.y + 101 * minp.z)
  sulfur_noise = sulfur_noise or minetest.get_perlin(9876, 3, 0.5, 100)

	local max = math.max
	local min = math.min

  local grid_size = 5
  for x = minp.x + math_floor(grid_size / 2), maxp.x, grid_size do
  for y = minp.y + math_floor(grid_size / 2), maxp.y, grid_size do
  for z = minp.z + math_floor(grid_size / 2), maxp.z, grid_size do
    local c = data[a:index(x, y, z)]
    if (c == c_lava or c == c_lava_flowing) and sulfur_noise:get3d({x = x, y = z, z = z}) >= 0.2 then
			--minetest.chat_send_all("found lava")
      for xx = max(minp.x, x - grid_size), min(maxp.x, x + grid_size) do
      for yy = max(minp.y, y - grid_size), min(maxp.y, y + grid_size) do
      for zz = max(minp.z, z - grid_size), min(maxp.z, z + grid_size) do
        local i = a:index(xx, yy, zz)
        if data[i] == c_stone and pr:next(1, 10) <= 7 then
          data[i] = c_sulfur
        end
      end
      end
      end
    end
  end
  end
  end

  vm:set_data(data)
  --vm:write_to_map()
end

minetest.register_on_generated(function(...) generate(...) end)

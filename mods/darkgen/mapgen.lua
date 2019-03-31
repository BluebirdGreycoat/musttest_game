
-- Content IDs used with the voxel manipulator.
local c_rock   = minetest.get_content_id("default:stone")
local c_water  = minetest.get_content_id("default:water_source")
local c_silt   = minetest.get_content_id("darkage:silt")
local c_mud    = minetest.get_content_id("darkage:mud")

local c_ore1   = minetest.get_content_id("darkage:ors")
local c_ore2   = minetest.get_content_id("darkage:shale")
local c_ore3   = minetest.get_content_id("darkage:slate")
local c_ore4   = minetest.get_content_id("darkage:basaltic")
local c_ore5   = minetest.get_content_id("darkage:marble")
local c_ore6   = minetest.get_content_id("darkage:gneiss")
local c_ore7   = minetest.get_content_id("darkage:schist")
local c_ore8   = minetest.get_content_id("darkage:chalk")

local c_ore10  = minetest.get_content_id("darkage:rhyolitic_tuff")
local c_ore11  = minetest.get_content_id("darkage:tuff")

-- Both of these are craftable from existing rock types.
-- darkage:rhyolitic_tuff
-- darkage:tuff

-- These generate at ocean bottoms.
-- darkage:silt
-- darkage:mud

-- Already craftable.
-- darkage:darkdirt

-- Externally located tables for performance.
local data = {}
local noisemap1 = {}
local noisemap2 = {}
local noisemap3 = {}
local noisemap4 = {}
local noisemap5 = {}
local noisemap6 = {}
local noisemap7 = {}
local noisemap8 = {}
local noisemap9 = {}
local noisemap10= {}
local noisemap11= {}

darkgen.generate_realm = function(minp, maxp, seed)
  local nstart = darkgen.SHEET_HEIGHT

  -- Don't run for out-of-bounds mapchunks.
	-- Need -100 in order to include ocean basins under the ice.
  if minp.y > (nstart + 200) or maxp.y < (nstart - 100) then return end

  -- Grab the voxel manipulator.
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  vm:get_data(data) -- Read current map data.
  
  local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
  local area2 = VoxelArea:new{MinEdge=minp, MaxEdge=maxp}
  
  local pr = PseudoRandom(seed + 71)
  
  local x1 = maxp.x
  local y1 = maxp.y
  local z1 = maxp.z
  local x0 = minp.x
  local y0 = minp.y
  local z0 = minp.z
  
  -- Compute side lengths. 
  local side_len_x = ((x1-x0)+1)
  local side_len_y = ((y1-y0)+1)
  local side_len_z = ((z1-z0)+1)
  local sides3D = {x=side_len_x, y=side_len_y, z=side_len_z}
  local sides2D = {x=side_len_x, y=side_len_z}
  local bp3d = {x=x0, y=y0, z=z0}
  local bp2d = {x=x0, y=z0}
  
  -- Get noisemaps.
  local perlin1 = minetest.get_perlin_map(darkgen.noise1param2d, sides2D)
  perlin1:get2dMap_flat(bp2d, noisemap1)
  local perlin2 = minetest.get_perlin_map(darkgen.noise2param2d, sides2D)
  perlin2:get2dMap_flat(bp2d, noisemap2)
  local perlin3 = minetest.get_perlin_map(darkgen.noise3param2d, sides2D)
  perlin3:get2dMap_flat(bp2d, noisemap3)
  local perlin4 = minetest.get_perlin_map(darkgen.noise4param2d, sides2D)
  perlin4:get2dMap_flat(bp2d, noisemap4)
  local perlin5 = minetest.get_perlin_map(darkgen.noise5param2d, sides2D)
  perlin5:get2dMap_flat(bp2d, noisemap5)
  local perlin6 = minetest.get_perlin_map(darkgen.noise6param2d, sides2D)
  perlin6:get2dMap_flat(bp2d, noisemap6)
  local perlin7 = minetest.get_perlin_map(darkgen.noise7param2d, sides2D)
  perlin7:get2dMap_flat(bp2d, noisemap7)
  local perlin8 = minetest.get_perlin_map(darkgen.noise8param2d, sides2D)
  perlin8:get2dMap_flat(bp2d, noisemap8)
  local perlin9 = minetest.get_perlin_map(darkgen.noise9param2d, sides2D)
  perlin9:get2dMap_flat(bp2d, noisemap9)
  local perlin10 = minetest.get_perlin_map(darkgen.noise10param2d, sides2D)
  perlin10:get2dMap_flat(bp2d, noisemap10)
  local perlin11 = minetest.get_perlin_map(darkgen.noise11param2d, sides2D)
  perlin11:get2dMap_flat(bp2d, noisemap11)
  
  -- Localize commonly used functions.
  local floor = math.floor
  local ceil = math.ceil
  local abs = math.abs

	local function apply_ore(v, y, n, f, m, o)
		local bot = (nstart + f) - (n*m)
		local top = (nstart + f) + (n*m)

		if y >= bot and y <= top then
			if data[v] == c_rock then
				data[v] = o
			end
		end
	end
  
  -- First mapgen pass.
  for z = z0, z1 do
    for x = x0, x1 do
      -- Get index into 2D noise arrays.
      local nx = (x-x0)
      local nz = (z-z0)
      local ni2 = (side_len_z*nz+nx)
      ni2 = ni2 + 1 -- Lua arrays start indexing at 1, not 0. Urrrrgh. >:(
          
      local n1 = noisemap1[ni2]
      local n2 = noisemap2[ni2]
      local n3 = noisemap3[ni2]
      local n4 = noisemap4[ni2]
      local n5 = noisemap5[ni2]
      local n6 = noisemap6[ni2]
      local n7 = noisemap7[ni2]
      local n8 = noisemap8[ni2]
      local n9 = noisemap9[ni2]
      local n10= noisemap10[ni2]
      local n11= noisemap11[ni2]
      
      -- First pass through column.
      for y = y0, y1 do
        local vp = area:index(x, y, z)
        local vu = area:index(x, y+1, z)
        local vd = area:index(x, y-1, z)
        local vd2 = area:index(x, y-2, z)

				-- Layer silt at ocean bottoms.
				if data[vp] == c_rock and data[vu] == c_water then
					data[vp] = c_silt
					data[vd] = c_silt
					data[vd2] = c_mud
				end

				local mult = 40
				local off = n9 * 16
				for k = 1, 1, 1 do
					apply_ore(vp, y, n1,  0  + (k*mult) + off,  2, c_ore1)
					apply_ore(vp, y, n2,  4  + (k*mult) + off,  2, c_ore2)
					apply_ore(vp, y, n3, -4  + (k*mult) + off,  2, c_ore3)
					apply_ore(vp, y, n4, -8  + (k*mult) + off,  2, c_ore4)
					apply_ore(vp, y, n5, -12 + (k*mult) + off,  2, c_ore5)
					apply_ore(vp, y, n6,  8  + (k*mult) + off,  2, c_ore6)
					apply_ore(vp, y, n7,  12 + (k*mult) + off,  2, c_ore7)
					apply_ore(vp, y, n8,  18 + (k*mult) + off,  2, c_ore8)
				end

				apply_ore(vp, y, n10,  80 + off,  4, c_ore10)
				apply_ore(vp, y, n11,  90 + off,  4, c_ore11)
      end -- For all in Y coordinates.
    end -- For all in X coordinates.
  end -- For all in Z coordinates.
  
  -- Finalize voxel manipulator.
  vm:set_data(data)
  --vm:set_lighting({day=0, night=0})
  --vm:calc_lighting()
  --vm:update_liquids()
  vm:write_to_map()
end


cw = cw or {}
cw.modpath = minetest.get_modpath("cw")

-- A Channelwood-like realm. Endless, shallow water in all directions, with
-- trees growing out of the ocean. Trees are huge and extremely tall. Water is
-- dangerious, filled with flesh-eating fish! Trees do not burn (too wet).

cw.REALM_START = 3050
cw.BEDROCK_DEPTH = 8
cw.OCEAN_DEPTH = 8

cw.noise1param2d = {
  offset = 0,
  scale = 1,
  spread = {x=64, y=64, z=64},
  seed = 3717,
  octaves = 1,
  persist = 0.5,
  lacunarity = 2,
}

cw.noise2param2d = {
  offset = 0,
  scale = 1,
  spread = {x=32, y=32, z=32},
  seed = 5817,
  octaves = 4,
  persist = 0.8,
  lacunarity = 2,
}

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("default:stone")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_water           = minetest.get_content_id("default:water_source")

-- Externally located tables for performance.
local data = {}
local noisemap1 = {}
local noisemap2 = {}

cw.generate_realm = function(minp, maxp, seed)
  local nstart = cw.REALM_START

  -- Don't run for out-of-bounds mapchunks.
  local nfinish = nstart + 100
  if minp.y > nfinish or maxp.y < nstart then
		return
	end

  -- Grab the voxel manipulator.
	-- Read current map data.
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  vm:get_data(data)
  local area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}

  local pr = PseudoRandom(seed + 381)

  local x1 = maxp.x
  local y1 = maxp.y
  local z1 = maxp.z
  local x0 = minp.x
  local y0 = minp.y
  local z0 = minp.z

  -- Compute side lengths.
  local side_len_x = ((x1-x0)+1)
  local side_len_z = ((z1-z0)+1)
  local sides2D = {x=side_len_x, y=side_len_z}
  local bp2d = {x=x0, y=z0}

  -- Get noisemaps.
  local perlin1 = minetest.get_perlin_map(cw.noise1param2d, sides2D)
  perlin1:get2dMap_flat(bp2d, noisemap1)
  local perlin2 = minetest.get_perlin_map(cw.noise2param2d, sides2D)
  perlin2:get2dMap_flat(bp2d, noisemap2)

  -- Localize commonly used functions.
  local floor = math.floor
  local ceil = math.ceil
  local abs = math.abs

  -- First mapgen pass.
  for z = z0, z1 do
    for x = x0, x1 do
      -- Get index into 2D noise arrays.
      local nx = (x-x0)
      local nz = (z-z0)
      local ni2 = (side_len_z*nz+nx)
			-- Lua arrays start indexing at 1, not 0. Urrrrgh.
      ni2 = ni2 + 1

      local n1 = noisemap1[ni2]
      local n2 = noisemap2[ni2]

			-- Randomize height of the bedrock a bit.
			local bedrock_adjust = (nstart + cw.BEDROCK_DEPTH + pr:next(0, pr:next(1, 2)))
			local ocean_depth = (nstart + cw.BEDROCK_DEPTH + cw.OCEAN_DEPTH)

      -- First pass through column.
      for y = y0, y1 do
        local vp = area:index(x, y, z)

        if y >= nstart and y <= nfinish then
					-- Place bedrock layer.
					if y <= bedrock_adjust then
						data[vp] = c_bedrock
					elseif y <= ocean_depth then
						data[vp] = c_water
					end
        end

      end
    end
  end

  -- Finalize voxel manipulator.
	-- Note: we specifically do not generate ores! The value of this realm is in
	-- its trees.
  vm:set_data(data)
  vm:set_lighting({day=0, night=0})
  vm:calc_lighting()
  vm:update_liquids()
  vm:write_to_map()
end



if not cw.registered then
	-- Register the mapgen callback.
	if minetest.settings:get_bool("enable_channelwood", false) then
		minetest.register_on_generated(function(...)
			cw.generate_realm(...)
		end)
	end

	local c = "cw:core"
	local f = cw.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	cw.registered = true
end


-- Really simplistic mapgen that's just water survival. The ocean is deep enough
-- that survival in the depths should not be possible without special pressure
-- equipment. However, there should be lots of treasure down there ...

-- Two possible ways to play a deep water survival.
--   1) spawn under the sea floor and have to (somehow) swim to the surface.
--   2) spawn on the surface and have to dive (somehow) to get to the sea floor.

-- Mapgen Environment ONLY.
-- Not reloadable!
ww = {}
ww.modpath = minetest.get_modpath("ww")
ww.worldpath = minetest.get_worldpath()

dofile(ww.modpath .. "/noise.lua")
dofile(ww.modpath .. "/data.lua")

local REALM_START = 8650
local REALM_END = 9650
local REALM_GROUND = 8650+500
local BEDROCK_HEIGHT = REALM_START + 12

-- Localize for performance.
local random = math.random
local abs = math.abs
local floor = math.floor
local min = math.min
local max = math.max
local tan = math.tan
local sin = math.sin
local cos = math.cos

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("default:stone")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_water           = minetest.get_content_id("default:water_source")

-- Externally located tables for performance.
local data = {}
local param2_data = {}



ww.generate_realm = function(vm, minp, maxp, seed)
	-- Don't run for out-of-bounds mapchunks.
	if minp.y > REALM_END or maxp.y < REALM_START then
		return
	end

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
	vm:get_data(data)
	vm:get_param2_data(param2_data)

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local min_area = VoxelArea:new {MinEdge=minp, MaxEdge=maxp}
	local pr = PseudoRandom(seed + 7218)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Compute side lengths.
	-- Note: 2D noise maps use overgeneration coordinates/sizes.
	-- This is to support horizontal shearing.
	local side_len_x = ((x1-x0)+1)
	local side_len_y = ((y1-y0)+1)
	local side_len_z = ((z1-z0)+1)
	local sides2D = {x=(emax.x - emin.x) + 1, y=(emax.z - emin.z) + 1}
	local sides3D = {x=side_len_x, y=side_len_z, z=side_len_y}
	local bp2d = {x=emin.x, y=emax.z}
	local bp3d = {x=x0, y=y0, z=z0}

	local seafloor = ww.get_2d_noise(bp2d, sides2D, "seafloor")
	local shear1 = ww.get_3d_noise(bp3d, sides3D, "shear1")
	local shear2 = ww.get_3d_noise(bp3d, sides3D, "shear2")
	local floorchannel = ww.get_2d_noise(bp2d, sides2D, "floorchannel")

	local function get_seafloor(n2d)
		local a = REALM_START + 50
		local t = min(1, abs(floorchannel[n2d]))
		a = a + seafloor[n2d] * (tan(t) / 1.558)
		return floor(a)
	end

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				-- Get index into 3D noise arrays.
				local n3d = min_area:index(x, y, z)

				-- Shear the 2D noise coordinate offset.
				local shear_x	= floor(x + shear1[n3d])
				local shear_z = floor(z + shear2[n3d])

				-- Get index into overgenerated 2D noise arrays.
				local nx = (shear_x-emin.x)
				local nz = (shear_z-emin.z)
				local n2d = (((emax.z - emin.z) + 1) * nz + nx)
				-- Lua arrays start indexing at 1, not 0. Urrrrgh.
				n2d = n2d + 1

				local sea_floor_y = get_seafloor(n2d)

				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local cid = data[vp]

					if cid == c_air or cid == c_ignore then
						if y <= BEDROCK_HEIGHT then
							data[vp] = c_bedrock
						elseif y <= sea_floor_y then
							data[vp] = c_stone
						elseif y <= REALM_GROUND then
							data[vp] = c_water
						else
							data[vp] = c_air
						end
					end
				end
			end
		end
	end

	vm:set_data(data)
  vm:set_param2_data(param2_data)

	-- Finalize voxel manipulator.
	vm:calc_lighting()
end



minetest.register_on_generated(function(...)
	ww.generate_realm(...)
end)


-- Another hostile stone-garden realm supposedly using an advanced mapgen concept.
-- Realistic (lava?) rivers, etc. Probably will require pre-generated data.

-- Mapgen Environment ONLY.
-- Not reloadable!
pd = {}
pd.modpath = minetest.get_modpath("pd")
pd.worldpath = minetest.get_worldpath()

dofile(pd.modpath .. "/noise.lua")
dofile(pd.modpath .. "/data.lua")

local REALM_START = 15650
local REALM_END = 20650
local REALM_GROUND = 15650+4000
local BEDROCK_HEIGHT = REALM_START + 12

-- Localize for performance.
local math_random = math.random

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("default:stone")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")

-- Externally located tables for performance.
local data = {}
local param2_data = {}



pd.generate_realm = function(vm, minp, maxp, seed)
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
	local pr = PseudoRandom(seed + 5554)

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

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				-- Get index into 3D noise arrays.
				local n3d = min_area:index(x, y, z)

				-- Get index into overgenerated 2D noise arrays.
				local nx = (x-emin.x)
				local nz = (z-emin.z)
				local n2d = (((emax.z - emin.z) + 1) * nz + nx)
				-- Lua arrays start indexing at 1, not 0. Urrrrgh.
				n2d = n2d + 1

				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local cid = data[vp]

					if cid == c_air or cid == c_ignore then
						if y <= BEDROCK_HEIGHT then
							data[vp] = c_bedrock
						elseif y <= REALM_GROUND then
							data[vp] = c_stone
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
	vm:update_liquids()
end



minetest.register_on_generated(function(...)
	pd.generate_realm(...)
end)

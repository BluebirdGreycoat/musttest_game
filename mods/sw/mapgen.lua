
-- A stoneworld mapgen specializing in stupidly tall mountains.
-- Might use an advanced mapgen concept or two.

-- Mapgen Environment ONLY.
-- Not reloadable!
sw = {}
sw.modpath = minetest.get_modpath("sw")
sw.worldpath = minetest.get_worldpath()

local REALM_START = 10150
local REALM_END = 15150
local REALM_GROUND = 10150+200
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



sw.generate_realm = function(vm, minp, maxp, seed)
	-- Don't run for out-of-bounds mapchunks.
	if minp.y > REALM_END or maxp.y < REALM_START then
		return
	end

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
	vm:get_data(data)
	vm:get_param2_data(param2_data)

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local pr = PseudoRandom(seed + 672)

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

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			-- Get index into 2D noise arrays.
			local nx = (x-x0)
			local nz = (z-z0)
			local ni2 = (side_len_z*nz+nx)
			-- Lua arrays start indexing at 1, not 0. Urrrrgh.
			ni2 = ni2 + 1

			-- First pass through column.
			for y = y0, y1 do
				local vp = area:index(x, y, z)

				if y >= REALM_START and y <= REALM_END then
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
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
end



minetest.register_on_generated(function(...)
	sw.generate_realm(...)
end)

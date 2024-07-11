
-- A realm like the Outback/Midfeld, but at the maximum X,Z size.

-- Mapgen Environment ONLY.
-- Not reloadable!
ab = {}
ab.modpath = minetest.get_modpath("ab")
ab.worldpath = minetest.get_worldpath()

dofile(ab.modpath .. "/noise.lua")
dofile(ab.modpath .. "/data.lua")
dofile(ab.modpath .. "/tree.lua")

local REALM_START = 21150
local REALM_END = 23450
local REALM_GROUND = 21150+2000
local BEDROCK_HEIGHT = REALM_START + 12

-- Localize for performance.
local math_random = math.random

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("rackstone:rackstone")
local c_cobble          = minetest.get_content_id("rackstone:cobble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")

-- Externally located tables for performance.
local data = {}
local param2_data = {}



ab.generate_realm = function(vm, minp, maxp, seed)
	-- Don't run for out-of-bounds mapchunks.
	if minp.y > REALM_END or maxp.y < REALM_START then
		return
	end

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
	vm:get_data(data)
	vm:get_param2_data(param2_data)

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local pr = PseudoRandom(seed + 7612)

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
	local sides2D = {x=side_len_x, y=side_len_z}
	local sides3D = {x=side_len_x, y=side_len_z, z=side_len_y}
	local bp2d = {x=x0, y=z0}
	local bp3d = {x=x0, y=y0, z=z0}

	local grass = {}
	local trees = {}

	local function chose_ground_decor(x, y, z)
		if pr:next(1, 100) == 1 then
			trees[#trees + 1] = {x=x, y=y, z=z}
		elseif pr:next(1, 10) == 1 then
			grass[#grass + 1] = {x=x, y=y+1, z=z}
		end
	end

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			-- Get index into 2D noise arrays.
			local nx = (x-x0)
			local nz = (z-z0)
			local ni2 = (side_len_z*nz+nx)
			-- Lua arrays start indexing at 1, not 0. Urrrrgh.
			ni2 = ni2 + 1

			local ground_y = REALM_GROUND

			-- First pass through column.
			for y = y0, y1 do
				local vp = area:index(x, y, z)

				if y >= REALM_START and y <= REALM_END then
					local cid = data[vp]

					if cid == c_air or cid == c_ignore then
						if y <= BEDROCK_HEIGHT then
							data[vp] = c_bedrock
						elseif y <= ground_y then
							if y == ground_y then
								data[vp] = c_cobble
								chose_ground_decor(x, y, z)
							else
								data[vp] = c_stone
							end
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

  for k = 1, #trees do
		ab.place_acacia_tree(vm, trees[k])
  end

  for k = 1, #grass do
		if pr:next(1, 8) == 1 then
			minetest.set_node(grass[k], {name="default:dry_shrub"})
		else
			minetest.set_node(grass[k], {name="default:dry_grass2_" .. pr:next(1, 5), param2=2})
		end
  end

	-- Finalize voxel manipulator.
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
end



minetest.register_on_generated(function(...)
	ab.generate_realm(...)
end)

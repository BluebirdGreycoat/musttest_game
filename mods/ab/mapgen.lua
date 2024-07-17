
-- A realm like the Outback/Midfeld, but at the maximum X,Z size.

-- Mapgen Environment ONLY.
-- Not reloadable!
ab = {}
ab.modpath = minetest.get_modpath("ab")
ab.worldpath = minetest.get_worldpath()

dofile(ab.modpath .. "/noise.lua")
dofile(ab.modpath .. "/data.lua")
dofile(ab.modpath .. "/tree.lua")
dofile(ab.modpath .. "/tunnel.lua")
dofile(ab.modpath .. "/despeckle.lua")

local REALM_START = 21150
local REALM_END = 23450
local REALM_GROUND = 21150+2000
local BEDROCK_HEIGHT = REALM_START + 12
local TAN_OF_1 = math.tan(1)

-- Localize for performance.
local random = math.random
local floor = math.floor
local min = math.min
local max = math.max
local abs = math.abs
local tan = math.tan

local function clamp(v, minv, maxv)
	return max(minv, min(v, maxv))
end

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

	local gennotify_data = {}
	gennotify_data.minp = minp
	gennotify_data.maxp = maxp

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
	vm:get_data(data)
	vm:get_param2_data(param2_data)

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PseudoRandom(seed + 7612)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Compute side lengths.
	-- Note: noise maps use overgeneration coordinates/sizes.
	-- This is to support horizontal shearing.
	local side_len_x = ((emax.x-emin.x)+1)
	local side_len_y = ((emax.y-emin.y)+1)
	local side_len_z = ((emax.z-emin.z)+1)
	local sides2D = {x=side_len_x, y=side_len_z}
	local sides3D = {x=side_len_x, y=side_len_y, z=side_len_z}
	local bp2d = {x=emin.x, y=emin.z}
	local bp3d = {x=emin.x, y=emin.y, z=emin.z}

	local grass = {}
	local trees = {}

	local function chose_ground_decor(x, y, z)
		if pr:next(1, 100) == 1 then
			trees[#trees + 1] = {x=x, y=y, z=z}
		elseif pr:next(1, 10) == 1 then
			grass[#grass + 1] = {x=x, y=y+1, z=z}
		end
	end

	local canyonshear1 = ab.get_3d_noise(bp3d, sides3D, "canyonshear1")
	local canyonshear2 = ab.get_3d_noise(bp3d, sides3D, "canyonshear2")
	local baseterrain = ab.get_2d_noise(bp2d, sides2D, "baseterrain")
	local canyons = ab.get_2d_noise(bp2d, sides2D, "canyons")
	local canyonpath = ab.get_2d_noise(bp2d, sides2D, "canyonpath")

	local function heightfunc(x, y, z)
		-- Get index into noise arrays.
		local n3d = area:index(x, y, z)

		-- Shear the 2D noise coordinate offset.
		local shear_x	= floor(x + canyonshear1[n3d])
		local shear_z = floor(z + canyonshear2[n3d])

		shear_x = clamp(shear_x, emin.x, emax.x)
		shear_z = clamp(shear_z, emin.z, emax.z)

		local n2d = area2d:index(shear_x, shear_z)
		local n2d_steady = area2d:index(x, z)

		local canyon_offset = 0
		local canyon_noise = canyons[n2d] + (canyonpath[n2d_steady] * 0.1)

		local canyon_threshold_lower = 0.20
		local canyon_threshold_middle = 0.30
		local canyon_threshold_upper = 0.45

		if canyon_noise >= -canyon_threshold_upper and canyon_noise <= canyon_threshold_upper then
			-- Calculate detritis slope.
			local cn = abs(canyon_noise) - canyon_threshold_middle
			local a = cn / (canyon_threshold_upper - canyon_threshold_middle)
			local b = tan(a ^ 2) / TAN_OF_1
			local c = floor(b * 15)
			canyon_offset = -33 + c
		end
		if canyon_noise >= -canyon_threshold_middle and canyon_noise <= canyon_threshold_middle then
			-- Calculate detritis slope.
			local cn = abs(canyon_noise) - canyon_threshold_lower
			local a = cn / (canyon_threshold_middle - canyon_threshold_lower)
			local b = tan(a ^ 2) / TAN_OF_1
			local c = floor(b * 15)
			canyon_offset = -66 + c
		end
		if canyon_noise >= -canyon_threshold_lower and canyon_noise <= canyon_threshold_lower then
			-- Calculate detritis slope.
			local a = abs(canyon_noise / canyon_threshold_lower)
			local b = (tan(a ^ 2) / TAN_OF_1)
			local c = floor(b * 15)
			canyon_offset = -100 + c
		end

		local ground_y = REALM_GROUND + floor(baseterrain[n2d_steady] + canyon_offset)

		return ground_y, canyon_offset
	end

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			local bedrock_adjust = pr:next(0, 3)

			for y = y0, y1 do
				local ground_y, canyon_offset = heightfunc(x, y, z)

				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local cid = data[vp]

					if cid == c_air or cid == c_ignore then
						if y <= (BEDROCK_HEIGHT + bedrock_adjust) then
							data[vp] = c_bedrock
						elseif y <= ground_y then
							if y == ground_y then
								data[vp] = c_cobble
								if canyon_offset < 0 then
									chose_ground_decor(x, y, z)
								end
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

  ab.generate_tunnels(vm, minp, maxp, seed)
  ab.despeckle_terrain(vm, minp, maxp)

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
	vm:calc_lighting()
	vm:update_liquids()

	minetest.save_gen_notify("ab:mapgen_info", gennotify_data)
end



minetest.register_on_generated(function(...)
	ab.generate_realm(...)
end)


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
local c_stone           = minetest.get_content_id("darkage:basaltic")
local c_cobble          = minetest.get_content_id("darkage:basaltic_rubble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_water           = minetest.get_content_id("default:water_source")
local c_silt            = minetest.get_content_id("darkage:silt")
local c_mud             = minetest.get_content_id("darkage:mud")
local c_sand            = minetest.get_content_id("default:sand")

-- Externally located tables for performance.
local vm_data = {}
local vm_light = {}
local param2_data = {}



ww.generate_realm = function(vm, minp, maxp, seed)
	-- Don't run for out-of-bounds mapchunks.
	if minp.y > REALM_END or maxp.y < REALM_START then
		return
	end

	local gennotify_data = {}
	gennotify_data.minp = minp
	gennotify_data.maxp = maxp

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
	vm:set_lighting({day=0, night=0})
	vm:get_data(vm_data)
	vm:get_light_data(vm_light)
	vm:get_param2_data(param2_data)

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local pr = PseudoRandom(seed + 7218)

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
			local bedrock_adjust = pr:next(0, 3)

			for y = y0, y1 do
				-- Get index into 3D noise arrays.
				local n3d = area:index(x, y, z)

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
					local cid = vm_data[vp]

					if cid == c_air or cid == c_ignore then
						if y <= (BEDROCK_HEIGHT + bedrock_adjust) then
							vm_data[vp] = c_bedrock
						elseif y <= sea_floor_y then
							vm_data[vp] = c_stone
						elseif y <= REALM_GROUND then
							vm_data[vp] = c_water
						else
							vm_data[vp] = c_air
						end
					end
				end
			end
		end
	end

	-- Generate sea floor layers.
	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local vu = area:index(x, y + 1, z)
					local vd = area:index(x, y - 1, z)

					if vm_data[vd] == c_stone and vm_data[vp] == c_stone and vm_data[vu] == c_water then
						local vc = area:index(x, y + 2, z)
						local vx = area:index(x, y + 3, z)

						vm_data[vp] = c_cobble
						vm_data[vu] = c_sand

						if vm_data[vc] == c_water then
							vm_data[vc] = c_silt
						end

						if vm_data[vc] == c_silt and vm_data[vx] == c_water then
							vm_data[vx] = c_silt
						end
					end
				end
			end
		end
	end

	-- Set light data.
	for z = emin.z, emax.z do
		for x = emin.x, emax.x do
			for y = emin.y, emax.y do
				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)

					if y <= REALM_GROUND then
						vm_light[vp] = 0
					else
						vm_light[vp] = 15
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
	vm:set_light_data(vm_light)
  vm:set_param2_data(param2_data)

	-- Finalize voxel manipulator.
	vm:calc_lighting(vector.offset(emin, 0, 16, 0), vector.offset(emax, 0, -16, 0), true)

	minetest.save_gen_notify("ww:mapgen_info", gennotify_data)
end



minetest.register_on_generated(function(...)
	ww.generate_realm(...)
end)

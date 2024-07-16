
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
local TAN_OF_1 = math.tan(1)

-- Localize for performance.
local random = math.random
local abs = math.abs
local floor = math.floor
local min = math.min
local max = math.max
local tan = math.tan
local sin = math.sin
local cos = math.cos

local function clamp(v, minv, maxv)
	return max(minv, min(v, maxv))
end

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
local c_glow            = minetest.get_content_id("glowstone:luxore")
local c_lux             = minetest.get_content_id("luxore:luxore")
local c_dirt            = minetest.get_content_id("default:dirt")

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
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
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
	local shear3 = ww.get_3d_noise(bp3d, sides3D, "shear3")
	local shear4 = ww.get_3d_noise(bp3d, sides3D, "shear4")
	local floorchannel = ww.get_2d_noise(bp2d, sides2D, "floorchannel")
	local glowveins = ww.get_2d_noise(bp2d, sides2D, "glowveins")
	local seamounts = ww.get_2d_noise(bp2d, sides2D, "seamounts")
	local mtnchannel = ww.get_2d_noise(bp2d, sides2D, "mtnchannel")
	local softener = ww.get_3d_noise(bp3d, sides3D, "softener")

	local function get_seafloor(x, y, z)
		-- Get index into noise arrays.
		local n3d = area:index(x, y, z)

		-- Shear the 2D noise coordinate offset.
		local shear_x	= floor(x + shear1[n3d])
		local shear_z = floor(z + shear2[n3d])
		local shear_x2	= floor(x + shear3[n3d] * min(1, abs(softener[n3d])))
		local shear_z2 = floor(z + shear4[n3d] * min(1, abs(softener[n3d])))

		shear_x2 = clamp(shear_x2, emin.x, emax.x)
		shear_z2 = clamp(shear_z2, emin.z, emax.z)

		local n2d = area2d:index(shear_x, shear_z)
		local n2d2 = area2d:index(shear_x2, shear_z2)

		-- Calc multiplier [0, 1] for mountain noise.
		local mnoise = mtnchannel[n2d]
		local mtnchnl = (tan(min(1, abs(mnoise)) * -1 + 1) / TAN_OF_1)
		-- Sharpen curve.
		mtnchnl = mtnchnl ^ 10

		local a = REALM_START + 50
		local t = min(1, abs(floorchannel[n2d]))
		a = a + seafloor[n2d] * (tan(t) / TAN_OF_1)
		a = a + (abs(seamounts[n2d2]) * abs(mtnchnl))
		return floor(a)
	end

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			local bedrock_adjust = pr:next(0, 3)

			for y = y0, y1 do
				local sea_floor_y = get_seafloor(x, y, z)

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
		-- Get index into overgenerated 2D noise arrays.
		local nx = (x-emin.x)
		local nz = (z-emin.z)
		local n2d = (((emax.z - emin.z) + 1) * nz + nx)
		-- Lua arrays start indexing at 1, not 0. Urrrrgh.
		n2d = n2d + 1

			for y = y0, y1 do
				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local vu = area:index(x, y + 1, z)
					local vd = area:index(x, y - 1, z)

					if vm_data[vd] == c_stone and vm_data[vp] == c_stone and vm_data[vu] == c_water then
						local vc = area:index(x, y + 2, z)
						local vx = area:index(x, y + 3, z)
						local vt = area:index(x, y + 4, z)

						vm_data[vp] = c_cobble
						vm_data[vu] = c_sand

						if vm_data[vc] == c_water then
							vm_data[vc] = c_silt
						end

						if vm_data[vc] == c_silt and vm_data[vx] == c_water then
							if pr:next(1, 8) == 1 then
								vm_data[vx] = c_dirt
							else
								vm_data[vx] = c_silt
							end
						end

						if vm_data[vx] == c_silt and vm_data[vt] == c_water then
							local gn = glowveins[n2d]
							if gn > 0.5 and gn < 0.6 and pr:next(1, 3) == 1 then
								vm_data[vt] = c_glow
							end

							if gn > -0.6 and gn < -0.5 and pr:next(1, 3) == 1 then
								vm_data[vt] = c_lux
							end
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


local REALM_START = 10150
local REALM_END = 15150
local REALM_GROUND = 10150+200
local TAN_OF_1 = math.tan(1)
local XEN_BEGIN = REALM_END - 2000
local XEN_END = REALM_END

-- Localize for performance.
local random = math.random
local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min
local sin = math.sin
local cos = math.cos
local tan = math.tan
local distance = vector.distance

local function clamp(v, minv, maxv)
	return max(minv, min(v, maxv))
end

local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_stone = minetest.get_content_id("default:stone")

local vm_data = {}
local param2_data = {}

-- Main shape of Xen islands.
sw.create_3d_noise("xen1", {
	offset = 0,
	scale = 1,
	spread = {x=180, y=60, z=180},
	seed = 88192,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Where Xen spawns.
sw.create_2d_noise("xen2", {
	offset = 0,
	scale = 1,
	spread = {x=100, y=100, z=100},
	seed = 4712,
	octaves = 1,
	persist = 0.5,
	lacunarity = 2,
})

-- Holes in Xen. A gift for those who don't look where they step.
sw.create_2d_noise("xen4", {
	offset = 0,
	scale = 1,
	spread = {x=40, y=40, z=40},
	seed = 4782,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Xen Y level.
sw.create_2d_noise("xen3", {
	offset = 0,
	scale = 500,
	spread = {x=800, y=800, z=800},
	seed = 66172,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Large scale void spaces.
sw.create_2d_noise("xen5", {
	offset = 0,
	scale = 1,
	spread = {x=2000, y=2000, z=2000},
	seed = 18349,
	octaves = 8,
	persist = 0.5,
	lacunarity = 1.75,
})

function sw.generate_xen(vm, minp, maxp, seed, shear1, shear2)
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > XEN_END or maxp.y < XEN_BEGIN then
		return
	end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PcgRandom(seed + 728)

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

	vm:get_data(vm_data)
	vm:get_param2_data(param2_data)

	local xen1 = sw.get_3d_noise(bp3d, sides3D, "xen1")
	local xen2 = sw.get_2d_noise(bp2d, sides2D, "xen2")
	local xen3 = sw.get_2d_noise(bp2d, sides2D, "xen3")
	local xen4 = sw.get_2d_noise(bp2d, sides2D, "xen4")
	local xen5 = sw.get_2d_noise(bp2d, sides2D, "xen5")

	local function is_xen(x, y, z)
		local vp3d = area:index(x, y, z)

		-- Shear the 2D noise coordinate offset.
		local shear_x	= floor(x + shear1[vp3d])
		local shear_z = floor(z + shear2[vp3d])

		shear_x = clamp(shear_x, emin.x, emax.x)
		shear_z = clamp(shear_z, emin.z, emax.z)

		local vp2d = area2d:index(shear_x, shear_z)
		vp3d = area:index(shear_x, y, shear_z)

		local n1 = xen1[vp3d]
		local n2 = xen2[vp2d] -- For large islands and voids.
		local n3 = 0--xen3[vp2d] -- Xen Y-level offset.
		local n4 = xen4[vp2d] -- Holes.
		local n5 = xen5[vp2d] -- Huge void areas.

		local xen_mid = math.floor(((XEN_BEGIN+XEN_END)/2)+n3)
		local xen_middiff_up = math.floor(XEN_END - xen_mid)
		local xen_middiff_dn = math.floor(xen_mid - XEN_BEGIN)

		-- Extinction value shall be 1 at XEN MID, and 0 at both top and bottom.
		-- Using exponential falloff.
		local extinction
		if y >= xen_mid then
			extinction = ((XEN_END - y) / xen_middiff_up)
		else
			extinction = ((y - XEN_BEGIN) / xen_middiff_dn)
		end
		extinction = clamp(extinction, 0, 1)
		extinction = tan(extinction ^ 4) / TAN_OF_1

		local islands_and_voids = clamp(abs(n2), 0, 1)
		islands_and_voids = tan(islands_and_voids) / TAN_OF_1
		islands_and_voids = islands_and_voids - 0.25

		local largescale = clamp(n5, -1, 1) * 0.2

		if (n1 + (abs(n4)*0.25) - islands_and_voids + largescale) < (-1.25 + extinction) then
			return true
		end
	end

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local cid = vm_data[vp]

					if cid == c_air or cid == c_ignore then
						if is_xen(x, y, z) then
							vm_data[vp] = c_stone
						else
							vm_data[vp] = c_air
						end
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
	vm:set_param2_data(param2_data)
end

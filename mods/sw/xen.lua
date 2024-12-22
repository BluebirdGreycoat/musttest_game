
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

local NOISE_SPREAD_SCALE = 1

sw.create_3d_noise("xen1", {
	offset = 0,
	scale = 1,
	spread = {x=80*NOISE_SPREAD_SCALE, y=20*NOISE_SPREAD_SCALE, z=80*NOISE_SPREAD_SCALE},
	seed = 88192,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

sw.create_3d_noise("xen2", {
	offset = 0,
	scale = 1,
	spread = {x=20*NOISE_SPREAD_SCALE, y=20*NOISE_SPREAD_SCALE, z=20*NOISE_SPREAD_SCALE},
	seed = 16628,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

function sw.generate_xen(vm, minp, maxp, seed)
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
	local xen2 = sw.get_3d_noise(bp3d, sides3D, "xen2")

	local function is_xen(vp, x, y, z)
		local n1 = xen1[vp]
		local n2 = xen2[vp]

		local xen_mid = math.floor((XEN_BEGIN+XEN_END)/2)
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
		extinction = tan(extinction) / TAN_OF_1

		if n1 < (-1.5 + extinction) then
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
						if is_xen(vp, x, y, z) then
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

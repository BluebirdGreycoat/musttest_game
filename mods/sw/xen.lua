
local REALM_START = 10150
local REALM_END = 15150
local REALM_GROUND = 10150+200
local TAN_OF_1 = math.tan(1)
local XEN_BEGIN = REALM_END - 1000
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

local vm_data = {}
local param2_data = {}

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

	vm:set_data(vm_data)
	vm:set_param2_data(param2_data)
end

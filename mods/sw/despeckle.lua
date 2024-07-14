
local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min

-- This gets rid of floating stuff and smooths out 1 node pits or stubs.
function sw.despeckle_terrain(vm, minp, maxp)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})

	vm:get_data(vm_data)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local function space(c)
		return c == c_air
	end

	local function solid(c)
		return c ~= c_air and c ~= c_ignore and c ~= c_bedrock
	end

	local function doit()
		for z = z0, z1 do
			for x = x0, x1 do
				for y = y0, y1 do
					local vp_c = area:index(x, y, z)
					local vp_n = area:index(x, y, z + 1)
					local vp_s = area:index(x, y, z - 1)
					local vp_w = area:index(x - 1, y, z)
					local vp_e = area:index(x + 1, y, z)
					local vp_t = area:index(x, y + 1, z)
					local vp_b = area:index(x, y - 1, z)

					local cid_c = vm_data[vp_c]
					local cid_n = vm_data[vp_n]
					local cid_s = vm_data[vp_s]
					local cid_w = vm_data[vp_w]
					local cid_e = vm_data[vp_e]
					local cid_t = vm_data[vp_t]
					local cid_b = vm_data[vp_b]

					if solid(cid_c) and space(cid_t) and space(cid_b) then
						vm_data[vp_c] = cid_t
					elseif space(cid_c) and solid(cid_t) and solid(cid_b) then
						vm_data[vp_c] = cid_t
					elseif space(cid_c) and solid(cid_n) and solid(cid_s) then
						vm_data[vp_c] = cid_n
					elseif space(cid_c) and solid(cid_w) and solid(cid_e) then
						vm_data[vp_c] = cid_w
					elseif solid(cid_c) and space(cid_n) and space(cid_s) then
						vm_data[vp_c] = cid_n
					elseif solid(cid_c) and space(cid_w) and space(cid_e) then
						vm_data[vp_c] = cid_w
					end
				end
			end
		end
	end

	-- Do it twice. This is because adjustments made by the first run can result
	-- in artifacts that can be corrected by a second run.
	doit()
	doit()

	vm:set_data(vm_data)
end

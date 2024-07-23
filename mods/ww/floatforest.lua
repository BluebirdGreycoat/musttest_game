
local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_sand = minetest.get_content_id("default:sand")

local TAN_OF_1 = math.tan(1)

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min
local tan = math.tan

ww.create_2d_noise("forestpattern", {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 738,
	octaves = 5,
	persist = 0.5,
	lacunarity = 2,
})

function ww.generate_floating_forests(vm, minp, maxp, seed, ystart, yend, yground)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PcgRandom(seed + 11223)

	vm:get_data(vm_data)

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

	local forestpattern = ww.get_2d_noise(bp2d, sides2D, "forestpattern")
	local min_noise = 0
	local max_noise = 0

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= ystart and y <= yend then
					local n2d = area2d:index(x, z)
					local vp = area:index(x, y, z)
					local forest = forestpattern[n2d]

					if y == yground then
						if forest > 0.5 then
							vm_data[vp] = c_sand
						end
					end
				end
			end
		end
	end

	--print(min_noise, max_noise)
	vm:set_data(vm_data)
end

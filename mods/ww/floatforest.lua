
local vm_data = {}
local vm_param2_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_lily = minetest.get_content_id("flowers:waterlily")
local c_root = minetest.get_content_id("swamp:root")
local c_mudroot = minetest.get_content_id("swamp:root_with_mud")

local get_node = minetest.get_node
local set_node = minetest.set_node
local facedir_to_dir = minetest.facedir_to_dir

local NN_LOGMAT = "basictrees:jungletree_cube"
local TAN_OF_1 = math.tan(1)

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min
local tan = math.tan

-- Param2 horizontal branch rotations.
local branch_rotations = {4, 8, 12, 16}
local branch_directions = {2, 0, 3, 1}

ww.create_2d_noise("forestpattern", {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
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
	vm:get_param2_data(vm_param2_data)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local logmats = {}

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
	local ocean_surface = yground + 1

	local noisesteps = {
		{-1.0, -0.9},
		{-0.8, -0.7},
		{-0.6, -0.5},
		{-0.4, -0.3},
		{-0.2, -0.1},
		{0.0, 0.1},
		{0.2, 0.3},
		{0.4, 0.5},
		{0.6, 0.7},
		{0.8, 0.9},
	}

	local function forestnoise(x, z)
		local n2d = area2d:index(x, z)
		local forest = forestpattern[n2d]
		for k = 1, #noisesteps do
			local pair = noisesteps[k]
			if forest >= pair[1] and forest <= pair[2] then
				return 1
			end
		end
		return 0
	end

	for z = z0, z1 do
		for x = x0, x1 do
			local forest = forestnoise(x, z)

			if forest >= 1 then
				for y = y0, y1 do
					if y >= ystart and y <= yend then
						local vp = area:index(x, y, z)

						if y == ocean_surface then
							if pr:next(1, 6) == 1 then
								vm_data[vp] = c_lily
								vm_param2_data[vp] = pr:next(0, 3)
							end

							if pr:next(1, 10) == 1 then
								logmats[#logmats + 1] = {x=x, y=y, z=z}
							end

							if pr:next(1, 16) == 1 then
								logmats[#logmats + 1] = {x=x, y=y-1, z=z}
							end

							if pr:next(1, 16) == 1 then
								logmats[#logmats + 1] = {x=x, y=y-2, z=z}
							end

							if pr:next(1, 30) == 1 then
								logmats[#logmats + 1] = {x=x, y=y-4, z=z}
							end

							if pr:next(1, 4) == 1 then
								vm_data[vp] = c_root
							end
						elseif y == yground then
							if pr:next(1, 5) == 1 then
								vm_data[vp] = c_root
							end
						end
					end
				end
			end
		end
	end

	--print(min_noise, max_noise)
	vm:set_data(vm_data)
	vm:set_param2_data(vm_param2_data)

	local function put_logmat(pos)
		local p = vector.offset(pos, 0, -1, 0)
		local n = pr:next(2, 8)

		if pr:next(1, 6) == 1 then
			for i = 1, n do
				set_node(p, {name=NN_LOGMAT})
				p = vector.offset(p, 0, -1, 0)
			end
		else
			local diridx = pr:next(1, 4)
			local facedir = branch_directions[diridx]
			local vec = facedir_to_dir(facedir)

			for i = 1, n do
				set_node(p, {name=NN_LOGMAT, param2=branch_rotations[diridx]})
				p = vector.add(p, vec)
			end
		end
  end

  for k = 1, #logmats do
		put_logmat(logmats[k])
  end
end

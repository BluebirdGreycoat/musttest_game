
local vm_data = {}
local vm_param2_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_lily = minetest.get_content_id("flowers:waterlily")
local c_root = minetest.get_content_id("swamp:root")
local c_mudroot = minetest.get_content_id("swamp:root_with_mud")
local c_rootblock = minetest.get_content_id("sumpf:peat")
local c_rootblock2 = minetest.get_content_id("sumpf:junglestone")
local c_coarsegrass = minetest.get_content_id("default:coarsegrass")
local c_floatforest = minetest.get_content_id("sumpf:sumpf2")

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

ww.create_2d_noise("forestwidth", {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = 482,
	octaves = 5,
	persist = 0.5,
	lacunarity = 2,
})

for k = 1, 11 do
	local pr = PcgRandom(3821 + k)
	ww.create_2d_noise("forestpath_" .. k, {
		offset = 0,
		scale = 1,
		spread = {x=64, y=64, z=64},
		seed = pr:next(1, 1000),
		octaves = 3,
		persist = 0.5,
		lacunarity = 2,
	})
end

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
	local forestwidth = ww.get_2d_noise(bp2d, sides2D, "forestwidth")
	local min_noise = 0
	local max_noise = 0
	local ocean_surface = yground + 1
	local under_surface = yground - 1

	local noisesteps = {
		{-2.0, -0.9},
		{-0.8, -0.7},
		{-0.6, -0.5},
		{-0.4, -0.3},
		{-0.2, -0.1},
		{0.0, 0.1},
		{0.2, 0.3},
		{0.4, 0.5},
		{0.6, 0.7},
		{0.8, 0.9},
		{1.0, 2.0},
	}

	local forestpath = {
		ww.get_2d_noise(bp2d, sides2D, "forestpath_1"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_2"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_3"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_4"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_5"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_6"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_7"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_8"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_9"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_10"),
		ww.get_2d_noise(bp2d, sides2D, "forestpath_11"),
	}

	local function forestnoise(x, z)
		local n2d = area2d:index(x, z)
		local forestp = forestpattern[n2d]
		local forestw = min(0.1, max(-0.1, forestwidth[n2d] * 0.1))

		if forestw > 0.06 then
			return 1 + (forestw / 0.095)
		end

		for k = 1, #noisesteps do
			local pair = noisesteps[k]

			local f = forestp + forestpath[k][n2d] * 0.3
			local w = forestw

			if w < 0 then
				goto continue
			end

			local n1 = pair[1] - w
			local n2 = pair[2] + w

			-- Ensure min/max in right order.
			if n1 > n2 then
				n1, n2 = n2, n1
			end
			local D = n2 - n1

			if D > 0 and f >= n1 and f <= n2 then
				local a = f - n1
				local b = a / D

				-- b is from 0 .. 1
				-- want 0 .. 1 .. 0
				if b <= 0.5 then
					b = b / 0.5
				else
					b = b - 0.5
					b = b / 0.5
					b = b * -1 + 1
				end

				return 1 + b
			end

			::continue::
		end
		return 0
	end

	for z = z0, z1 do
		for x = x0, x1 do
			local forest = forestnoise(x, z)
			local logmat_off = 0

			if forest < 1.2 then
				logmat_off = -2
			elseif forest < 1.4 then
				logmat_off = -1
			end

			if forest >= 1 then
				for y = y0, y1 do
					if y >= ystart and y <= yend then
						local vp = area:index(x, y, z)
						local vp_up = area:index(x, y+1, z)

						if y == ocean_surface then
							if forest < 1.5 and pr:next(1, 6) == 1 then
								vm_data[vp] = c_lily
								vm_param2_data[vp] = pr:next(0, 3)
							end

							if pr:next(1, 10) == 1 then
								logmats[#logmats + 1] = {x=x, y=y+logmat_off, z=z}
							end

							if pr:next(1, 16) == 1 then
								logmats[#logmats + 1] = {x=x, y=y-1+logmat_off, z=z}
							end

							if pr:next(1, 16) == 1 then
								logmats[#logmats + 1] = {x=x, y=y-2+logmat_off, z=z}
							end

							if pr:next(1, 30) == 1 then
								logmats[#logmats + 1] = {x=x, y=y-4+logmat_off, z=z}
							end

							if forest >= 1.5 then
								if pr:next(1, 4) == 1 then
									if forest >= 1.7 then
										vm_data[vp] = c_mudroot
									else
										vm_data[vp] = c_root
									end
									if forest > 1.8 then
										vm_data[vp_up] = c_floatforest
									end
								elseif forest <= 1.7 then
									if pr:next(1, 5) <= 4 then
										vm_data[vp] = c_coarsegrass
										vm_param2_data[vp] = 2
									end
								elseif forest > 1.7 then
									vm_data[vp] = c_rootblock2
									if forest > 1.8 then
										vm_data[vp_up] = c_floatforest
									end
								end
							end
						elseif y == yground then
							if forest >= 1.5 then
								if pr:next(1, 5) == 1 then
									vm_data[vp] = c_root
								else
									vm_data[vp] = c_rootblock
								end
							end
						elseif y == under_surface then
							if forest >= 1.5 then
								if pr:next(1, 4) == 1 then
									vm_data[vp] = c_rootblock
								end
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

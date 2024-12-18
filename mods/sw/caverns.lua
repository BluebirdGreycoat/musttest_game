
local REALM_START = 10150
local REALM_END = 15150
local LAVA_SEA_HEIGHT = 10170

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min
local pr = PseudoRandom(5829)

local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_cobble = minetest.get_content_id("default:cobble")
local c_lava = minetest.get_content_id("lbrim:lava_source")

sw.create_3d_noise("cavern_noise1", {
	offset = 0,
	scale = 10,
	spread = {x=80, y=60, z=80},
	seed = 88812,
	octaves = 6,
	persist = 0.5,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise2", {
	offset = 0,
	scale = 4,
	spread = {x=72, y=64, z=72},
	seed = 88813,
	octaves = 5,
	persist = 0.6,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise3", {
	offset = 0,
	scale = 2,
	spread = {x=72, y=64, z=72},
	seed = 88814,
	octaves = 4,
	persist = 0.7,
	lacunarity = 1.5,
})

sw.create_3d_noise("cavern_noise4", {
	offset = 0,
	scale = 1,
	spread = {x=74, y=62, z=74},
	seed = 88815,
	octaves = 3,
	persist = 0.8,
	lacunarity = 1.5,
})



function sw.generate_caverns(vm, minp, maxp, seed, heightfunc)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})

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

	local caves = sw.prepare_tunnels(bp2d, sides2D, minp, maxp)

	local noisemap1 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise1")
	local noisemap2 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise2")
	local noisemap3 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise3")
	local noisemap4 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise4")

	local function is_cavern(x, y, z, ground_y)
		local idx = area:index(x, y, z)

		local n1 = noisemap1[idx]
		local n2 = noisemap2[idx]
		local n3 = noisemap3[idx]
		local n4 = noisemap4[idx]

		if y < (ground_y - (500 + (abs(n4) * 50))) then
			if ((n1 + n2) * n3) > 0.5 or n4 > 0.8 then
				return true
			end
		end

		return false
	end

	for z = z0, z1 do
		for x = x0, x1 do
			-- 0: undefined
			-- 1: stone
			-- 2: cavern
			local toggle = 0

			local ground_y = heightfunc(x, z)

			for y = y0, y1 do
				local is_floor = false
				local is_ceiling = false

				if is_cavern(x, y, z, ground_y) then
					if toggle == 1 then
						is_floor = true
					end
					toggle = 2

					local vp = area:index(x, y, z)
					local cid = vm_data[vp]

					-- Do NOT carve caverns through bedrock or "ignore".
					-- Skip air since there's nothing there anyway.
					if cid ~= c_air and cid ~= c_ignore and cid ~= c_bedrock then
						if y <= LAVA_SEA_HEIGHT then
							vm_data[vp] = c_lava
						else
							vm_data[vp] = c_air
						end
					end
				else
					if toggle == 2 then
						is_ceiling = true
					end
					toggle = 1
				end

				-- Deal with floors or ceilings as we find them in the Y-column.
				if y < ground_y and (is_floor or is_ceiling) then
					local vp = area:index(x, y, z)
					local cid = vm_data[vp]

					-- Do NOT carve caverns through bedrock or "ignore".
					if cid ~= c_ignore and cid ~= c_bedrock then
						vm_data[vp] = c_cobble
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
end

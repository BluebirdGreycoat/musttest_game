
local REALM_START = 10150
local REALM_END = 15150
local LAYER_COUNT = math.floor((REALM_END - REALM_START) / 50)
local LAVA_SEA_HEIGHT = 10170

-- Actual XEN_BEGIN is REALM_END - 2000, but don't place special tunnel stone
-- that far down because it will intersect with tall Carcorsica mountains.
local XEN_BEGIN = REALM_END - 1500
local XEN_END = REALM_END

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min
local pr = PseudoRandom(1893)

local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_stone = minetest.get_content_id("default:stone")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_bedrock2 = minetest.get_content_id("sw:teststone1_hard")
local c_lava = minetest.get_content_id("lbrim:lava_source")



sw.create_2d_noise("cave_n1", {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = pr:next(10, 1000),
	octaves = 4,
	persist = 0.7,
	lacunarity = 2.1,
})

sw.create_2d_noise("cave_n2", {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = pr:next(10, 1000),
	octaves = 4,
	persist = 0.7,
	lacunarity = 1.5,
})

sw.create_3d_noise("cave_n4", {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = pr:next(10, 1000),
	octaves = 5,
	persist = 0.7,
	lacunarity = 1.5,
})



-- Tunnels come in layers, with 3 distinct tunnels per layer, and each tunnel
-- uses two 2D noises, one for route and one for elevation.
for k = 1, LAYER_COUNT do
	sw.create_2d_noise("cave1_" .. k .. "_route", {
		offset = 0,
		scale = 1,
		spread = {x=75, y=75, z=75},
		seed = pr:next(10, 1000),
		octaves = 10,
		persist = 0.5,
		lacunarity = 1.6,
	})
	sw.create_2d_noise("cave1_" .. k .. "_height", {
		offset = 0,
		scale = 1,
		spread = {x=256, y=256, z=256},
		seed = pr:next(10, 1000),
		octaves = 4,
		persist = 0.5,
		lacunarity = 2.0,
	})
	sw.create_2d_noise("cave2_" .. k .. "_route", {
		offset = 0,
		scale = 1,
		spread = {x=75, y=75, z=75},
		seed = pr:next(10, 1000),
		octaves = 10,
		persist = 0.5,
		lacunarity = 1.6,
	})
	sw.create_2d_noise("cave2_" .. k .. "_height", {
		offset = 0,
		scale = 1,
		spread = {x=256, y=256, z=256},
		seed = pr:next(10, 1000),
		octaves = 4,
		persist = 0.5,
		lacunarity = 2.0,
	})
	sw.create_2d_noise("cave3_" .. k .. "_route", {
		offset = 0,
		scale = 1,
		spread = {x=75, y=75, z=75},
		seed = pr:next(10, 1000),
		octaves = 10,
		persist = 0.5,
		lacunarity = 1.6,
	})
	sw.create_2d_noise("cave3_" .. k .. "_height", {
		offset = 0,
		scale = 1,
		spread = {x=256, y=256, z=256},
		seed = pr:next(10, 1000),
		octaves = 4,
		persist = 0.5,
		lacunarity = 2.0,
	})
end



-- Figure out which tunnel noises are used in this map chunk.
function sw.prepare_tunnels(bp2d, sides2D, minp, maxp)
	local caves = {}
	local realm_start = REALM_START
	local num = LAYER_COUNT

	for k = 1, num do
		local y_level = realm_start + (k * 50)
		local good = true
		if minp.y > (y_level + 70) or maxp.y < (y_level - 70) then
			good = false
		end

		if good then
			-- Three separate tunnels per layer. Each tunnel needs 2 noises.
			caves[#caves + 1] = {
				{
					routemap = sw.get_2d_noise(bp2d, sides2D, "cave1_" .. k .. "_route"),
					heightmap = sw.get_2d_noise(bp2d, sides2D, "cave1_" .. k .. "_height"),
					y_level = y_level - 10,
				},
				{
					routemap = sw.get_2d_noise(bp2d, sides2D, "cave2_" .. k .. "_route"),
					heightmap = sw.get_2d_noise(bp2d, sides2D, "cave2_" .. k .. "_height"),
					y_level = y_level,
				},
				{
					routemap = sw.get_2d_noise(bp2d, sides2D, "cave3_" .. k .. "_route"),
					heightmap = sw.get_2d_noise(bp2d, sides2D, "cave3_" .. k .. "_height"),
					y_level = y_level + 10,
				},
			}
		end
	end

	return caves
end



function sw.generate_tunnels(vm, minp, maxp, seed, get_height)
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Skip generating tunnels far above surface.
  --if y0 >= (get_height(x0, z0) + 250) then
	--	return
	--end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PseudoRandom(seed + 1891)

	vm:get_data(vm_data)

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

	local noisemap1 = sw.get_2d_noise(bp2d, sides2D, "cave_n1")
	local noisemap2 = sw.get_2d_noise(bp2d, sides2D, "cave_n2")
	local noisemap4 = sw.get_3d_noise(bp3d, sides3D, "cave_n4")

	local function is_cave(x, y, z, do_fc_check)
		-- Carve long winding tunnels.
		for k = 1, #caves do
			-- For each of the 3 separate tunnels per layer.
			for j = 1, 3 do
				-- Get index into noise arrays.
				local n3d = area:index(x, y, z)
				local n2d = area2d:index(x, z)

				-- Initial cave noise values.
				local c1 = caves[k][j].routemap[n2d]
				local c2 = caves[k][j].heightmap[n2d]
				local yl = caves[k][j].y_level

				local n1 = noisemap1[n2d]
				local n2 = noisemap2[n2d]
				local n4 = noisemap4[n3d]

				-- Basic cave parameters: Y-level, passage height.
				local cnoise1 = abs(c1)
				local cnoise2 = c1
				local clevel = (yl + floor(c2 * 50)) + floor(n1 * 2)
				local cheight = 5 + abs(floor(n1 * 3))

				-- Modify cave height.
				cheight = cheight + floor(n4 * 2)

				-- Modifiers for roughening the rounding and making it less predictable.
				local z1 = abs(floor(n1))
				local z2 = abs(floor(n2))

				-- Limit determines the thickness of the cave passages.
				local limit = 0.10
				local cnoise
				local go = false

				if cnoise1 <= limit then
					cnoise = cnoise1
					go = true
				end

				if go then
					-- This bit of math is just to round off the sharp edges of the
					-- cave passages. Calculate cave top/bottom Y-values.
					local n = abs(floor((cnoise / limit) * (cheight / 2)))
					local bot = (clevel + n + z1)
					local top = (clevel + cheight - n - z2)

					if y >= bot and y <= top then
						if do_fc_check then
							local found_floor = is_cave(x, y-1, z)
							local found_ceiling = is_cave(x, y+1, z)
							local wall_n = is_cave(x, y, z+1)
							local wall_s = is_cave(x, y, z-1)
							local wall_e = is_cave(x+1, y, z)
							local wall_w = is_cave(x-1, y, z)
							-- Need to negate the second two.
							-- Should return:
							-- 1: whether this position is cave
							-- 2: whether position below is solid (found floor)
							-- 3: whether position above is solid (found ceiling)
							-- 4,5,6: whether position (at direction) is solid.
							return true, (not found_floor), (not found_ceiling), (not wall_n), (not wall_s), (not wall_e), (not wall_w)
						else
							return true
						end
					end
				end
			end
		end
	end

	local YSTRIDE = area.ystride
	local ZSTRIDE = area.zstride
	local c_cave_floor = c_stone
	local c_cave_ceiling = c_stone
	local c_cave_wall = c_stone

	if y0 >= XEN_BEGIN and y1 <= XEN_END then
		c_cave_floor = minetest.get_content_id("sw:teststone2")
		c_cave_ceiling = minetest.get_content_id("sw:teststone2")
		c_cave_wall = minetest.get_content_id("sw:teststone2")
	end

	for z = z0, z1 do
		for y = y0, y1 do
			local base_idx = area:index(x0, y, z)
			for x = x0, x1 do
				local found_cave, floor_below, ceiling_above,
					wall_n, wall_s, wall_e, wall_w =
						is_cave(x, y, z, true)

				if found_cave then
					local cid = vm_data[base_idx]

					-- Do NOT carve tunnels through bedrock or "ignore".
					-- Skip air since there's nothing there anyway.
					if cid ~= c_air and cid ~= c_ignore and cid ~= c_bedrock then
						if y <= LAVA_SEA_HEIGHT then
							vm_data[base_idx] = c_lava
						else
							vm_data[base_idx] = c_air
						end

						local below = base_idx - YSTRIDE
						local above = base_idx + YSTRIDE
						local pn = base_idx + ZSTRIDE
						local ps = base_idx - ZSTRIDE
						local pe = base_idx + 1
						local pw = base_idx - 1

						local cidb = vm_data[below]
						local cida = vm_data[above]
						local cidn = vm_data[pn]
						local cids = vm_data[ps]
						local cide = vm_data[pe]
						local cidw = vm_data[pw]

						-- Replace floor node only if node below is something other than air.
						if floor_below then
							if cidb ~= c_air and cidb ~= c_bedrock and cidb ~= c_bedrock2 then
								vm_data[below] = c_cave_floor
							end
						end

						-- Replace ceiling node only if node above is something other than air.
						if ceiling_above then
							if cida ~= c_air and cida ~= c_bedrock and cida ~= c_bedrock2 then
								vm_data[above] = c_cave_ceiling
							end
						end

						-- North wall.
						if wall_n then
							if cidn ~= c_air and cidn ~= c_bedrock and cidn ~= c_bedrock2 then
								vm_data[pn] = c_cave_wall
							end
						end

						-- South wall.
						if wall_s then
							if cids ~= c_air and cids ~= c_bedrock and cids ~= c_bedrock2 then
								vm_data[ps] = c_cave_wall
							end
						end

						-- East wall.
						if wall_e then
							if cide ~= c_air and cide ~= c_bedrock and cide ~= c_bedrock2 then
								vm_data[pe] = c_cave_wall
							end
						end

						-- West wall.
						if wall_w then
							if cidw ~= c_air and cidw ~= c_bedrock and cidw ~= c_bedrock2 then
								vm_data[pw] = c_cave_wall
							end
						end
					end
				end
				base_idx = base_idx + 1
			end
		end
	end

	vm:set_data(vm_data)
end

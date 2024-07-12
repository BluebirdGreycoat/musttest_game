
local REALM_START = 10150
local REALM_END = 15150
local LAYER_COUNT = math.floor((REALM_END - REALM_START) / 50)

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min

local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")



-- Tunnels come in layers, with 3 distinct tunnels per layer, and each tunnel
-- uses two 2D noises, one for route and one for elevation.
local pr = PseudoRandom(1893)
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



function sw.generate_tunnels(vm, minp, maxp, seed)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local pr = PseudoRandom(seed + 1891)

	vm:get_data(vm_data)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Compute side lengths.
	-- Note: 2D noise maps use overgeneration coordinates/sizes.
	-- This is to support horizontal shearing.
	local side_len_x = ((x1-x0)+1)
	local side_len_y = ((y1-y0)+1)
	local side_len_z = ((z1-z0)+1)
	local sides2D = {x=(emax.x - emin.x) + 1, y=(emax.z - emin.z) + 1}
	local sides3D = {x=side_len_x, y=side_len_z, z=side_len_y}
	local bp2d = {x=emin.x, y=emax.z}
	local bp3d = {x=x0, y=y0, z=z0}

	local caves = sw.prepare_tunnels(bp2d, sides2D, minp, maxp)

	local function is_cave(x, y, z)
		-- Carve long winding tunnels.
		for k = 1, #caves do
			-- For each of the 3 separate tunnels per layer.
			for j = 1, 3 do
				-- Get index into overgenerated 2D noise arrays.
				local nx_steady = (x-emin.x)
				local nz_steady = (z-emin.z)
				local n2d = (((emax.z - emin.z) + 1) * nz_steady + nx_steady)
				n2d = n2d + 1

				-- Initial cave noise values.
				local c1 = caves[k][j].routemap[n2d]
				local c2 = caves[k][j].heightmap[n2d]
				local yl = caves[k][j].y_level

				local n1 = 1
				local n2 = 1
				local n4 = 1

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
						return true
					end
				end
			end
		end
	end

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if is_cave(x, y, z) then
					local vp = area:index(x, y, z)
					local cid = vm_data[vp]

					-- Do NOT carve tunnels through bedrock or "ignore".
					-- Skip air since there's nothing there anyway.
					if cid ~= c_air and cid ~= c_ignore and cid ~= c_bedrock then
						vm_data[vp] = c_air
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
end


local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_obsidian = minetest.get_content_id("default:obsidian")
local c_stone = minetest.get_content_id("default:stone")

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

local minp = {x=-31000, z=-31000}
local maxp = {x=31000, z=31000}
local step = 250

local ALL_MESAS = {}
local MIN_RADIUS = 50
local MAX_RADIUS = 150
local SLOPE_WIDTH = 150
local MESA_SEED = 4718

-- Locate canyons. Canyons are located around 0.
local function get_canyon_noise(x, z)
	local bp2d = {x=x, y=z}
	local sides2D = {x=112, y=112}

	local _, canyon = ab.get_2d_noise(bp2d, sides2D, "canyons")
	local _, path1 = ab.get_2d_noise(bp2d, sides2D, "canyonpath")
	local _, path2 = ab.get_2d_noise(bp2d, sides2D, "canyonpath2")

	local p = {x=x, y=z}
	local cn = canyon:get_2d(p) + (path1:get_2d(p) * path2:get_2d(p))
	return cn
end

--------------------------------------------------------------------------------
-- Pregenerate mesa information for the entire realm!
do
	-- This decides where strings of mesas will be placed.
	local perlin = minetest.get_perlin({
		offset = 0,
		scale = 1,
		spread = {x=1024, y=1024, z=1024},
		seed = 4887,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2,
	})

	-- For sphere positions, sizes, and counts.
	local pr1 = PcgRandom(MESA_SEED + 1)

	-- For sphere contents.
	local pr2 = PcgRandom(MESA_SEED + 2)

	for x = minp.x, maxp.x, step do
		for z = minp.z, maxp.z, step do
			-- Get all necessary PRNG values first, before doing any float math.
			-- This ensures consistent results always.
			local count = pr1:next(0, 1)
			for k = 1, count do
				local rad = pr1:next(MIN_RADIUS, MAX_RADIUS)
				local px = pr1:next(x - (step / 2), x + (step / 2))
				local pz = pr1:next(z - (step / 2), z + (step / 2))
				local pos2d = {x=px, y=pz}

				-- Avoid placing mesas anywhere near canyons.
				-- We need canyon noise to know where the canyons are.
				if abs(perlin:get_2d(pos2d)) < 0.2 and abs(get_canyon_noise(x, z)) > 0.5 then
					ALL_MESAS[#ALL_MESAS + 1] = {
						pos_x = px,
						pos_z = pz,
						radius = rad,
						slope = SLOPE_WIDTH,
					}
				end
			end
		end
	end
end
print('mesa count: ' .. #ALL_MESAS)
--------------------------------------------------------------------------------

-- Get which mesas intersect this map chunk.
function ab.get_mesas(minp, maxp, mstart, mend)
	local fringe = 50
	local minx = minp.x - (MAX_RADIUS + SLOPE_WIDTH + fringe)
	local minz = minp.z - (MAX_RADIUS + SLOPE_WIDTH + fringe)
	local maxx = maxp.x + (MAX_RADIUS + SLOPE_WIDTH + fringe)
	local maxz = maxp.z + (MAX_RADIUS + SLOPE_WIDTH + fringe)

	local got = {}
	local count = #ALL_MESAS

	if maxp.y < mstart or minp.y > mend then
		return got
	end

	for k = 1, count do
		local data = ALL_MESAS[k]
		if data.pos_x >= minx and data.pos_x <= maxx then
			if data.pos_z >= minz and data.pos_z <= maxz then
				got[#got + 1] = table.copy(data)
			end
		end
	end

	return got
end

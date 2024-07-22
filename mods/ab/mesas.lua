
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
local step = 500

local ALL_MESAS = {}
local MIN_RADIUS = 250
local MAX_RADIUS = 500
local MESA_SEED = 4718

--------------------------------------------------------------------------------
-- Pregenerate mesa information for the entire realm!
do
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
			local count = pr1:next(0, 1)
			for k = 1, count do
				local rad = pr1:next(MIN_RADIUS, MAX_RADIUS)
				local px = pr1:next(x - (step / 2), x + (step / 2))
				local pz = pr1:next(z - (step / 2), z + (step / 2))
				local pos2d = {x=px, y=pz}

				if abs(perlin:get_2d(pos2d)) < 0.7 then
					ALL_MESAS[#ALL_MESAS + 1] = {
						pos_x = px,
						pos_z = pz,
						radius = rad,
					}
				end
			end
		end
	end
end
--------------------------------------------------------------------------------

-- Get which mesas intersect this map chunk.
function ab.get_mesas(minp, maxp)
	local minx = minp.x - MAX_RADIUS
	local minz = minp.z - MAX_RADIUS
	local maxx = maxp.x + MAX_RADIUS
	local maxz = maxp.z + MAX_RADIUS

	local got = {}
	local count = #ALL_MESAS

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


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
local CID = minetest.get_content_id

local vm_data = {}
local minp = {x=-31000, z=-31000}
local maxp = {x=31000, z=31000}
local step = 100

local ALL_SPHERES = {}
local MIN_RADIUS = 7
local MAX_RADIUS = 20
local MIN_Y = -10
local MAX_Y = 10
local SPHERE_SEED = 4718
local SPHERE_WALL = 4
local SPHERE_INNER = 7
local SPHERE_MISSHAPE = 4
local SPHERE_CONTENTS = {
	{CID("default:obsidian"), CID("default:obsidian"), CID("default:obsidian")},
	{CID("default:obsidian"), CID("default:obsidian"), CID("default:obsidian")},
	{CID("default:obsidian"), CID("default:obsidian"), CID("air")},
	{CID("default:obsidian"), CID("default:obsidian"), CID("air")},
	{CID("default:lava_source"), CID("default:lava_source"), CID("default:lava_source")},
	{CID("default:water_source"), CID("default:water_source"), CID("default:water_source")},
	{CID("cavestuff:glow_white_crystal"), CID("quartz:block"), CID("air")},
	{CID("darkage:darkdirt"), CID("default:dirt"), CID("default:dirt")},
}

--------------------------------------------------------------------------------
-- Pregenerate sphere information for the entire realm!
do
	local perlin = minetest.get_perlin({
		offset = 0,
		scale = 1,
		spread = {x=1024, y=1024, z=1024},
		seed = 7752,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2,
	})

	-- For sphere positions, sizes, and counts.
	local pr1 = PcgRandom(SPHERE_SEED + 1)

	-- For sphere contents.
	local pr2 = PcgRandom(SPHERE_SEED + 2)

	for x = minp.x, maxp.x, step do
		for z = minp.z, maxp.z, step do
			local count = pr1:next(1, 3)
			for k = 1, count do
				local rad = pr1:next(MIN_RADIUS, MAX_RADIUS)
				local yoff = pr1:next(MIN_Y, MAX_Y)
				local px = pr1:next(x - (step / 2), x + (step / 2))
				local pz = pr1:next(z - (step / 2), z + (step / 2))
				local pos2d = {x=px, y=pz}
				local contents = SPHERE_CONTENTS[pr2:next(1, #SPHERE_CONTENTS)]

				if abs(perlin:get_2d(pos2d)) < 0.2 then
					ALL_SPHERES[#ALL_SPHERES + 1] = {
						pos_x = px,
						pos_z = pz,
						radius = rad,
						y_offset = yoff,
						cid_1 = contents[1],
						cid_2 = contents[2],
						cid_3 = contents[3],
					}
				end
			end
		end
	end
end
--------------------------------------------------------------------------------

-- Get which spheres intersect this map chunk.
function sw.get_spheres(minp, maxp, heightfunc)
	local minx = minp.x - MAX_RADIUS
	local minz = minp.z - MAX_RADIUS
	local maxx = maxp.x + MAX_RADIUS
	local maxz = maxp.z + MAX_RADIUS

	local got = {}
	local count = #ALL_SPHERES

	for k = 1, count do
		local data = ALL_SPHERES[k]
		if data.pos_x >= minx and data.pos_x <= maxx then
			if data.pos_z >= minz and data.pos_z <= maxz then
				-- Find ground level at the center of each sphere.
				local y_level = heightfunc(data.pos_x, data.pos_z)
				local miny = minp.y - MAX_RADIUS
				local maxy = maxp.y + MAX_RADIUS

				if y_level >= miny and y_level <= maxy then
					got[#got + 1] = table.copy(data)
					got[#got].y_level = y_level
				end
			end
		end
	end

	return got
end

sw.create_3d_noise("sphereshear", {
	offset = 0,
	scale = 1,
	spread = {x=16, y=16, z=16},
	seed = 7718,
	octaves = 1,
	persist = 0.5,
	lacunarity = 2,
})

function sw.generate_spheres(vm, minp, maxp, seed, ystart, yend, heightfunc)
	local spheres = sw.get_spheres(minp, maxp, heightfunc)
	if #spheres == 0 then
		return
	end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local pr = PseudoRandom(seed + 5928)

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

	local sphereshear = sw.get_3d_noise(bp3d, sides3D, "sphereshear")

	for k = 1, #spheres do
		local data = spheres[k]

		local sphere_x = data.pos_x
		local sphere_y = data.y_level + data.y_offset
		local sphere_z = data.pos_z
		local sphere_rad = data.radius

		local minbox = {
			x = sphere_x - sphere_rad - 6,
			y = sphere_y - sphere_rad - 6,
			z = sphere_z - sphere_rad - 6,
		}
		local maxbox = {
			x = sphere_x + sphere_rad + 6,
			y = sphere_y + sphere_rad + 6,
			z = sphere_z + sphere_rad + 6,
		}

		local p1 = vector.new(sphere_x, sphere_y, sphere_z)
		local p2 = {x=0, y=0, z=0}

		local ncid_1 = c_obsidian
		local ncid_3 = data.cid_3

		-- For each dimension, do bounds checks as early as possible.
		for z = z0, z1 do
			if z >= minbox.z and z <= maxbox.z then
			for x = x0, x1 do
				if x >= minbox.x and x <= maxbox.x then
				for y = y0, y1 do
					if y >= ystart and y <= yend and y >= minbox.y and y <= maxbox.y then
						local vp = area:index(x, y, z)
						local cid = vm_data[vp]

						if cid == c_air then
							p2.x = x
							p2.y = y
							p2.z = z

							local n3d = area:index(x, y, z)
							local nrad = abs(sphereshear[n3d]) * SPHERE_MISSHAPE
							local D = floor(distance(p1, p2))

							local sphere = false
							local shell_outer = floor(sphere_rad + nrad)
							local shell_inner = floor(sphere_rad + nrad - SPHERE_WALL)
							local shell_center = floor(sphere_rad + nrad - SPHERE_INNER)

							if D <= shell_outer then
								sphere = true
							end

							if sphere then
								if D >= shell_inner then
									vm_data[vp] = ncid_1
								elseif D >= shell_center then
									if pr:next(1, 3) >= 2 then
										vm_data[vp] = data.cid_2
									else
										vm_data[vp] = data.cid_1
									end
								else
									vm_data[vp] = ncid_3
								end
							end
						end
					end
				end -- Y
				end
			end -- X
			end
		end -- Z
	end

	vm:set_data(vm_data)
end

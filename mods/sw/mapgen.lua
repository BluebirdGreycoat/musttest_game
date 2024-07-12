
-- A stoneworld mapgen specializing in stupidly tall mountains.
-- Might use an advanced mapgen concept or two.

-- Mapgen Environment ONLY.
-- Not reloadable!
sw = {}
sw.modpath = minetest.get_modpath("sw")
sw.worldpath = minetest.get_worldpath()

dofile(sw.modpath .. "/noise.lua")
dofile(sw.modpath .. "/data.lua")

local REALM_START = 10150
local REALM_END = 15150
local REALM_GROUND = 10150+200
local BEDROCK_HEIGHT = REALM_START + 12

-- Localize for performance.
local random = math.random
local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("default:stone")
local c_cobble          = minetest.get_content_id("default:cobble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")

-- Externally located tables for performance.
local data = {}
local param2_data = {}



sw.generate_realm = function(vm, minp, maxp, seed)
	-- Don't run for out-of-bounds mapchunks.
	if minp.y > REALM_END or maxp.y < REALM_START then
		return
	end

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
	vm:get_data(data)
	vm:get_param2_data(param2_data)

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local min_area = VoxelArea:new {MinEdge=minp, MaxEdge=maxp}
	local pr = PseudoRandom(seed + 672)

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

	local baseterrain = sw.get_2d_noise(bp2d, sides2D, "baseterrain")
	local shear1 = sw.get_3d_noise(bp3d, sides3D, "shear1")
	local shear2 = sw.get_3d_noise(bp3d, sides3D, "shear2")
	local softener = sw.get_3d_noise(bp3d, sides3D, "softener")

	local caves = {}
	for k = 1, 100 do
		local y_level = REALM_START + (k * 50)
		local good = true
		if minp.y > (y_level + 70) or maxp.y < (y_level - 70) then
			good = false
		end

		if good then
			caves[#caves + 1] = {
				{
					routemap = sw.get_2d_noise(bp2d, sides2D, "cave1_" .. k .. "_route"),
					heightmap = sw.get_2d_noise(bp2d, sides2D, "cave1_" .. k .. "_height"),
					y_level = y_level,
				},
				{
					routemap = sw.get_2d_noise(bp2d, sides2D, "cave2_" .. k .. "_route"),
					heightmap = sw.get_2d_noise(bp2d, sides2D, "cave2_" .. k .. "_height"),
					y_level = y_level,
				},
				{
					routemap = sw.get_2d_noise(bp2d, sides2D, "cave3_" .. k .. "_route"),
					heightmap = sw.get_2d_noise(bp2d, sides2D, "cave3_" .. k .. "_height"),
					y_level = y_level,
				},
			}
		end
	end

	local function is_cave(y, n2d)
		-- Carve long winding caves.
		for k = 1, #caves do
			for j = 1, 3 do
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

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				-- Get index into 3D noise arrays.
				local n3d = min_area:index(x, y, z)

				-- Shear the 2D noise coordinate offset.
				local shear_x	= floor(x + shear1[n3d] * min(1, abs(softener[n3d])))
				local shear_z = floor(z + shear2[n3d] * min(1, abs(softener[n3d])))

				-- Get index into overgenerated 2D noise arrays.
				local nx = (shear_x-emin.x)
				local nz = (shear_z-emin.z)
				local nx_steady = (x-emin.x)
				local nz_steady = (z-emin.z)
				local n2d = (((emax.z - emin.z) + 1) * nz + nx)
				local n2d_steady = (((emax.z - emin.z) + 1) * nz_steady + nx_steady)
				-- Lua arrays start indexing at 1, not 0. Urrrrgh.
				n2d = n2d + 1
				n2d_steady = n2d_steady + 1

				local ground_y = REALM_GROUND + floor(baseterrain[n2d])

				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local cid = data[vp]

					if cid == c_air or cid == c_ignore then
						if y <= BEDROCK_HEIGHT then
							data[vp] = c_bedrock
						elseif y <= ground_y then
							if is_cave(y, n2d_steady) then
								data[vp] = c_air
							else
								data[vp] = c_stone
							end
						else
							data[vp] = c_air
						end
					end
				end
			end
		end
	end

	vm:set_data(data)
  vm:set_param2_data(param2_data)

	-- Finalize voxel manipulator.
	vm:calc_lighting()
	vm:update_liquids()
end



minetest.register_on_generated(function(...)
	sw.generate_realm(...)
end)

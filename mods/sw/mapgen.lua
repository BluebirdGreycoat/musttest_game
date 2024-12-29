
-- A stoneworld mapgen specializing in stupidly tall mountains.
-- Might use an advanced mapgen concept or two.

-- Mapgen Environment ONLY.
-- Not reloadable!
sw = {}
sw.modpath = minetest.get_modpath("sw")
sw.worldpath = minetest.get_worldpath()

dofile(sw.modpath .. "/noise.lua")
dofile(sw.modpath .. "/data.lua")
---[====[
dofile(sw.modpath .. "/tunnel.lua")
dofile(sw.modpath .. "/despeckle.lua")
dofile(sw.modpath .. "/spheres.lua")
dofile(sw.modpath .. "/biome.lua")
dofile(sw.modpath .. "/caverns.lua")
dofile(sw.modpath .. "/xen.lua")
--]====]

local REALM_START = 10150
local REALM_END = 15150
local REALM_GROUND = 10150+200
local BEDROCK_HEIGHT = REALM_START + 12
local LAVA_SEA_HEIGHT = 10170
local TAN_OF_1 = math.tan(1)
local XEN_BEGIN = REALM_END - 2000
local XEN_END = REALM_END

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

local function clamp(v, minv, maxv)
	return max(minv, min(v, maxv))
end

---[====[
-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("default:stone")
local c_cobble          = minetest.get_content_id("default:cobble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_lava            = minetest.get_content_id("lbrim:lava_source")

-- Externally located tables for performance.
local vm_data = {}
local vm_light = {}
local param2_data = {}
--]====]



sw.generate_realm = function(vm, minp, maxp, seed)
---[====[
	seed = mapgen.get_blockseed(minp)

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > REALM_END or maxp.y < REALM_START then
		return
	end
--]====]

---[====[
	local time1 = os.clock()

	local gennotify_data = {}
	gennotify_data.minp = minp
	gennotify_data.maxp = maxp
	gennotify_data.need_mapfix = true
	gennotify_data.on_construct = {} -- Positions where 'on_construct' callbacks need to be run.
	gennotify_data.cavern_hints = {}
--]====]

	-- Grab the voxel manipulator.
	local emin, emax = vm:get_emerged_area()
---[====[
	vm:set_lighting({day=0, night=0})
	vm:get_data(vm_data)
	vm:get_light_data(vm_light)
	vm:get_param2_data(param2_data)
--]====]

	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
---[====[
	local pr = PseudoRandom(seed + 672)
--]====]

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

	local baseterrain, baseterrain_perlin = sw.get_2d_noise(bp2d, sides2D, "baseterrain")
	local continental, continental_perlin = sw.get_2d_noise(bp2d, sides2D, "continental")
	local mountains, mountains_perlin = sw.get_2d_noise(bp2d, sides2D, "mountains")
	local mtnchannel, mtnchannel_perlin = sw.get_2d_noise(bp2d, sides2D, "mtnchannel")
	local rough_terrain = sw.get_2d_noise(bp2d, sides2D, "rough_terrain")
	local cavern_noise5 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise5")
---[====[
	local shear1, shear1_perlin = sw.get_3d_noise(bp3d, sides3D, "shear1")
	local shear2, shear2_perlin = sw.get_3d_noise(bp3d, sides3D, "shear2")
	local softener, softener_perlin = sw.get_3d_noise(bp3d, sides3D, "softener")
--]====]

	local function heightfunc(x, y, z)
		-- Get index into 3D noise arrays.
		local n3d = area:index(x, y, z)
		-- Shear the 2D noise coordinate offset.
		local shear_x	= floor(x + shear1[n3d] * min(1, abs(softener[n3d])))
		local shear_z = floor(z + shear2[n3d] * min(1, abs(softener[n3d])))

		shear_x = clamp(shear_x, emin.x, emax.x)
		shear_z = clamp(shear_z, emin.z, emax.z)

		local n2d = area2d:index(shear_x, shear_z)
		local n2d_steady = area2d:index(x, z)

		--return baseterrain[n2d]

		-- Calc multiplier [0, 1] for mountain noise.
		local mtnchnl = (tan(min(1, abs(mtnchannel[n2d]))) / TAN_OF_1)
		-- Sharpen curve.
		mtnchnl = mtnchnl * mtnchnl * mtnchnl

		local ground_y = REALM_GROUND + floor(
			baseterrain[n2d] +
			continental[n2d] +
			(mountains[n2d] * mtnchnl))

		local n5 = abs(cavern_noise5[area:index(shear_x, y, shear_z)])
		if n5 > rough_terrain[n2d_steady] then
			ground_y = ground_y + 5
		end

		return floor(ground_y)
	end

	-- Simplier version of the above. Gives an approximation of the ground height.
	-- Does not include effects from shear, or small scale details.
  local function get_height(x, z)
		local pos2d = {x=x, y=z}

		-- Calc multiplier [0, 1] for mountain noise.
		local mtnchnl = (tan(min(1, abs(mtnchannel_perlin:get_2d(pos2d)))) / TAN_OF_1)
		-- Sharpen curve.
		mtnchnl = mtnchnl * mtnchnl * mtnchnl

		local ground_y = REALM_GROUND + floor(
			baseterrain_perlin:get_2d(pos2d) +
			continental_perlin:get_2d(pos2d) +
			(mountains_perlin:get_2d(pos2d) * mtnchnl))

		return ground_y
  end

---[====[
	-- First mapgen pass.
	-- Optimization: we can skip calculating the exact ground height if we KNOW we are far
	-- enough below it. The probability of this creating a glitch is very low.
	-- Generally, the more points in this list, the better our accuracy.
	local chunk_horiz_levels = {
		-- Chunk corners.
		get_height(x0, z0),
		get_height(x1, z0),
		get_height(x1, z1),
		get_height(x0, z1),

		-- Chunk center.
		get_height(floor((x0+x1)/2), floor((z0+z1)/2)),

		-- Edge midpoints.
		get_height(floor((x0+x1)/2), z0),
		get_height(x1, floor((z0+z1)/2)),
		get_height(floor((x0+x1)/2), z1),
		get_height(x0, floor((z0+z1)/2)),
	}

	-- If passed a positive diff, this function only returns TRUE if ALL tested
	-- ground points are BELOW the BOTTOM of the chunk. Useful to check if a chunk
	-- is entirely above ground in the sky.
	--
	-- If passed a negative diff, this function only returns TRUE if ALL tested
	-- ground points are ABOVE the TOP of the chunk. Useful to check if a chunk is
	-- entirely below ground, with 'diff' tolerance.
	local function far_diff(diff)
		for k, height in ipairs(chunk_horiz_levels) do
			local y_level = height + diff
			if diff < 0 and y1 >= y_level then
				-- Chunk is not far enough down.
				return false
			end
			if diff > 0 and y0 <= y_level then
				-- Chunk is not high enough up.
				return false
			end
		end
		-- y0/y1 is significantly (determined by diff) above/below all entries in the list.
		return true
	end

	if far_diff(-250) then
		--print('filling all with stone')
		-- Far below surface. Fill everything with stone.
		for z = z0, z1 do
			for x = x0, x1 do
				local bedrock_adjust = pr:next(0, 3)

				for y = y0, y1 do
					if y >= REALM_START and y <= REALM_END then
						local vp = area:index(x, y, z)
						local cid = vm_data[vp]

						if cid == c_air or cid == c_ignore then
							if y <= (BEDROCK_HEIGHT + bedrock_adjust) then
								vm_data[vp] = c_bedrock
							else
								vm_data[vp] = c_stone
							end
						end
					end
				end
			end
		end

		-- Compute underground darkness.
		for z = emin.z, emax.z do
			for y = emin.y, emax.y do
				if y >= REALM_START and y <= REALM_END then
					for x = emin.x, emax.x do
						local vp = area:index(x, y, z)
						vm_light[vp] = 0
					end
				end
			end
		end
	elseif far_diff(250) then
		-- Far above surface. Fill everything with air.
		-- Aka do nothing.

		-- Compute atmosphere light.
		for z = emin.z, emax.z do
			for y = emin.y, emax.y do
				if y >= REALM_START and y <= REALM_END then
					for x = emin.x, emax.x do
						local vp = area:index(x, y, z)
						vm_light[vp] = 15
					end
				end
			end
		end
	else
		-- We're near surface, must calculate ground height exactly.
		for z = z0, z1 do
			for x = x0, x1 do
				local bedrock_adjust = pr:next(0, 3)

				for y = y0, y1 do
					local ground_y = heightfunc(x, y, z)

					if y >= REALM_START and y <= REALM_END then
						local vp = area:index(x, y, z)
						local cid = vm_data[vp]

						if cid == c_air or cid == c_ignore then
							if y <= (BEDROCK_HEIGHT + bedrock_adjust) then
								vm_data[vp] = c_bedrock
							elseif y <= ground_y then
								vm_data[vp] = c_stone
							else
								vm_data[vp] = c_air
							end
						end
					end
				end
			end
		end

		-- Compute surface light.
		for z = emin.z, emax.z do
			for y = emin.y, emax.y do
				if y >= REALM_START and y <= REALM_END then
					for x = emin.x, emax.x do
						local ground_y = heightfunc(x, y, z)
						local vp = area:index(x, y, z)

						if y <= ground_y then
							vm_light[vp] = 0
						else
							vm_light[vp] = 15
						end
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
	vm:set_light_data(vm_light)
  vm:set_param2_data(param2_data)
--]====]

	--print("---------------------")
  --print('#1 - flat value: ' .. heightfunc(x0, y0, z0))
  --print('#2 - obj  value: ' .. get_height(x0, z0))
---[====[

	-- Handles its own validity checks.
	local xen_mapgen_wanted = sw.generate_xen(
		vm, minp, maxp, seed, shear1, shear2, gennotify_data)

	if far_diff(-100) then
		sw.generate_caverns(vm, minp, maxp, seed, get_height)
	end

	-- Generate tunnels in all chunks NOT too far above ground, and also in Xen areas.
	if not far_diff(250) or (y1 >= XEN_BEGIN and xen_mapgen_wanted) then
		sw.generate_tunnels(vm, minp, maxp, seed, get_height)
	end

  if not far_diff(-250) and not far_diff(250) then
		sw.generate_spheres(vm, minp, maxp, seed, REALM_START, REALM_END, get_height)
	end

	-- Despeckle everywhere.
	if y0 <= XEN_BEGIN or xen_mapgen_wanted then
		sw.despeckle_terrain(vm, minp, maxp)
	end

	-- Carcorsica surface decorations.
  if not far_diff(-250) and not far_diff(250) then
		sw.generate_biome(vm, minp, maxp, seed, REALM_START, REALM_END, heightfunc, get_height, gennotify_data)
	end

	-- Handles its own validity checks.
	if xen_mapgen_wanted then
		sw.generate_xen_biome(vm, minp, maxp, seed)
	end

	-- Generate ores first, so that decorations can be specified just for them.
	if y0 <= XEN_BEGIN or xen_mapgen_wanted then
		minetest.generate_ores(vm)
		minetest.generate_decorations(vm)
	end

	-- Finalize voxel manipulator.
	vm:calc_lighting(vector.offset(emin, 0, 16, 0), vector.offset(emax, 0, -16, 0), true)
	vm:update_liquids()

	-- Skip mapfix for underground sections.
	-- Note: because of Xen, we always have to mapfix the sky sections, even very high up.
	-- However, do NOT mapfix air regions high above ground but below Xen.
	if far_diff(-100) or (far_diff(250) and y0 < (XEN_BEGIN + 250)) then
		gennotify_data.need_mapfix = false
		--print('skip mapfix')
	end

	minetest.save_gen_notify("sw:mapgen_info", gennotify_data)

	local time2 = os.clock()
	print('carcorsica: mapgen time: ' .. (time2 - time1))
--]====]
end



minetest.register_on_generated(function(...)
	sw.generate_realm(...)
end)

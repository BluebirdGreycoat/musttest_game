
-- These match values in the realm-control mod.
-- Note: duplicated in the init script, they MUST match!
stoneworld = {}
stoneworld.REALM_START = 5150
stoneworld.REALM_END = 8150

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("darkage:basaltic")
local c_cobble          = minetest.get_content_id("darkage:basaltic_rubble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_lava            = minetest.get_content_id("lbrim:lava_source")
local c_lava2           = minetest.get_content_id("default:lava_source")
local c_melt            = minetest.get_content_id("cavestuff:cobble_with_rockmelt")
local c_glow            = minetest.get_content_id("glowstone:cobble")
local c_obsidian        = minetest.get_content_id("cavestuff:dark_obsidian")
local c_obsidian2       = minetest.get_content_id("default:obsidian")
local c_worm            = minetest.get_content_id("cavestuff:glow_worm")
local c_fungus          = minetest.get_content_id("cavestuff:glow_fungus")
local c_adamant         = minetest.get_content_id("default:adamant")
local c_sand            = minetest.get_content_id("cavestuff:coal_dust")

-- Externally located tables for performance.
local vm_data = {}
local vm_light = {}

local noisemap1 = {}
local noisemap3 = {}
local noisemap4 = {}
local noisemap5 = {}
local noisemap6 = {}
local noisemap7 = {}

local perlin1
local perlin3
local perlin4
local perlin5
local perlin6



--------------------------------------------------------------------------------
stoneworld.caveseed = PseudoRandom(357)

stoneworld.caveroutenoise = {
	offset = 0,
	scale = 1,
	spread = {x=75, y=75, z=75},
	seed = 0,
	octaves = 10,
	persist = 0.5,
	lacunarity = 1.6,
}

stoneworld.caveheightnoise = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = 0,
	octaves = 4,
	persist = 0.5,
	lacunarity = 2.0,
}

stoneworld.caves = stoneworld.caves or {}

if not stoneworld.registered then
	-- Construct a few cave levels every 50 meters for 3000 meters height.
	-- Multiple overlapping cave networks ensures a probability of intersection.
	for k = 1, 60 do
		-- Cave network 1.
		stoneworld.caves[#stoneworld.caves + 1] = {}
		stoneworld.caves[#stoneworld.caves].y_level = k * 50 - 10

		-- Cave network 2.
		stoneworld.caves[#stoneworld.caves + 1] = {}
		stoneworld.caves[#stoneworld.caves].y_level = k * 50

		-- Cave network 3.
		stoneworld.caves[#stoneworld.caves + 1] = {}
		stoneworld.caves[#stoneworld.caves].y_level = k * 50 + 10
	end

	for k, v in ipairs(stoneworld.caves) do
		v.noise_route = table.copy(stoneworld.caveroutenoise)
		v.noise_route.seed = stoneworld.caveseed:next()
		v.route_map = {} -- Storage for bulk noise data.

		v.noise_height = table.copy(stoneworld.caveheightnoise)
		v.noise_height.seed = stoneworld.caveseed:next()
		v.height_map = {} -- Storage for bulk noise data.
	end
end



--------------------------------------------------------------------------------
stoneworld.cavernseed = PseudoRandom(548)

stoneworld.cavernceilingnoise = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 0,
	octaves = 7,
	persist = 0.5,
	lacunarity = 1.6,
}

stoneworld.cavernfloornoise = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 0,
	octaves = 7,
	persist = 0.5,
	lacunarity = 1.6,
}

stoneworld.cavernlevelnoise = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 0,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2.0,
}

stoneworld.caverns = stoneworld.caverns or {}

if not stoneworld.registered then
	-- Construct a cavern level every 500 meters for 3000 meters height.
	for k = 1, 5 do
		stoneworld.caverns[#stoneworld.caverns + 1] = {}
		stoneworld.caverns[#stoneworld.caverns].y_level = k * 500
	end

	for k, v in ipairs(stoneworld.caverns) do
		v.noise_ceiling = table.copy(stoneworld.cavernceilingnoise)
		v.noise_ceiling.seed = stoneworld.cavernseed:next()
		v.ceiling_map = {} -- Storage for bulk noise data.

		v.noise_floor = table.copy(stoneworld.cavernfloornoise)
		v.noise_floor.seed = stoneworld.cavernseed:next()
		v.floor_map = {} -- Storage for bulk noise data.

		v.noise_level = table.copy(stoneworld.cavernlevelnoise)
		v.noise_level.seed = stoneworld.cavernseed:next()
		v.level_map = {} -- Storage for bulk noise data.
	end
end



--------------------------------------------------------------------------------
-- Bedrock layer thickness variation.
stoneworld.noise1param2d = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 2721,
	octaves = 4,
	persist = 0.7,
	lacunarity = 2.1,
}

stoneworld.noise3param2d = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 1248,
	octaves = 4,
	persist = 0.7,
	lacunarity = 1.5,
}

stoneworld.noise4param3d = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = 1762,
	octaves = 5,
	persist = 0.7,
	lacunarity = 1.5,
}

-- Used to limit where lava fortresses may spawn.
stoneworld.noise5param3d = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=128, z=1024},
	seed = 7218,
	octaves = 4,
	persist = 0.5,
	lacunarity = 2.0,
}

-- Adamantine spires.
stoneworld.noise6param2d = {
	-- Applying offset makes the spires rare, without messing with their size,
	-- as adjusting 'spread' would do.
	offset = -0.200,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = 17355,
	octaves = 7,
	persist = 0.5,
	lacunarity = 1.9,
}

-- Black sand spawning.
stoneworld.noise7param3d = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = 99382,
	octaves = 4,
	persist = 0.5,
	lacunarity = 2.0,
}



--------------------------------------------------------------------------------
stoneworld.generate_realm = function(vm, minp, maxp, seed)
	local nbeg = stoneworld.REALM_START
	local nend = stoneworld.REALM_END

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > nend or maxp.y < nbeg then
		return
	end

	-- Grab the voxel manipulator.
	-- Read current map data.
	local emin, emax = vm:get_emerged_area()
	vm:get_data(vm_data)
	vm:get_light_data(vm_light)

	-- Actual emerged area should be bigger than the chunk we're generating!
	assert(emin.y < minp.y and emin.x < minp.x and emin.z < minp.z)
	assert(emax.y > maxp.y and emax.x > maxp.x and emax.z > maxp.z)

	-- Start out by overgenerating by 1 node.
	local x1 = maxp.x + 1
	local y1 = maxp.y + 1
	local z1 = maxp.z + 1
	local x0 = minp.x - 1
	local y0 = minp.y - 1
	local z0 = minp.z - 1

	local max_area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}
	local min_area = VoxelArea:new {MinEdge={x=x0, y=y0, z=z0}, MaxEdge={x=x1, y=y1, z=z1}}

	-- Compute side lengths.
	local side_len_x = ((x1-x0)+1)
	local side_len_y = ((y1-y0)+1)
	local side_len_z = ((z1-z0)+1)
	local sides2D = {x=side_len_x, y=side_len_z}
	local sides3D = {x=side_len_x, y=side_len_z, z=side_len_y}
	local bp2d = {x=x0, y=z0}
	local bp3d = {x=x0, y=y0, z=z0}

	local pr = PseudoRandom(seed + 7114)

	------------------------------------------------------------------------------

	-- Initialize cave perlin noise objects.
	for k, v in ipairs(stoneworld.caves) do
		v.perlin_route = v.perlin_route or minetest.get_perlin_map(v.noise_route, sides2D)
		v.perlin_height = v.perlin_height or minetest.get_perlin_map(v.noise_height, sides2D)
	end

	-- Calculate bulk perlin noise for caves.
	for k, v in ipairs(stoneworld.caves) do
		-- Optimization: each cave network only goes up or down not more than 70
		-- nodes, so we can skip calculating the noise for cave networks which won't
		-- get used. We do need to set a flag so we know which ones are "good".
		local good = true
		if minp.y > (nbeg + v.y_level + 70) or maxp.y < (nbeg + v.y_level - 70) then
			good = false
		end

		if good then
			v.perlin_route:get_2d_map_flat(bp2d, v.route_map)
			v.perlin_height:get_2d_map_flat(bp2d, v.height_map)
			v.good = true
		else
			v.good = false
		end
	end

	------------------------------------------------------------------------------

	-- Initialize cavern perlin noise objects.
	for k, v in ipairs(stoneworld.caverns) do
		v.perlin_ceiling = v.perlin_ceiling or minetest.get_perlin_map(v.noise_ceiling, sides2D)
		v.perlin_floor = v.perlin_floor or minetest.get_perlin_map(v.noise_floor, sides2D)
		v.perlin_level = v.perlin_level or minetest.get_perlin_map(v.noise_level, sides2D)
	end

	-- Calculate bulk perlin noise for caverns
	for k, v in ipairs(stoneworld.caverns) do
		-- Optimization: each cavern network only goes up or down not more than 150
		-- nodes, so we can skip calculating the noise for cave networks which won't
		-- get used. We do need to set a flag so we know which ones are "good".
		local good = true
		if minp.y > (nbeg + v.y_level + 150) or maxp.y < (nbeg + v.y_level - 150) then
			good = false
		end

		if good then
			v.perlin_ceiling:get_2d_map_flat(bp2d, v.ceiling_map)
			v.perlin_floor:get_2d_map_flat(bp2d, v.floor_map)
			v.perlin_level:get_2d_map_flat(bp2d, v.level_map)
			v.good = true
		else
			v.good = false
		end
	end

	------------------------------------------------------------------------------

	-- Get noisemaps.
	perlin1 = perlin1 or minetest.get_perlin_map(stoneworld.noise1param2d, sides2D)
	perlin1:get_2d_map_flat(bp2d, noisemap1)

	perlin3 = perlin3 or minetest.get_perlin_map(stoneworld.noise3param2d, sides2D)
	perlin3:get_2d_map_flat(bp2d, noisemap3)

	perlin4 = perlin4 or minetest.get_perlin_map(stoneworld.noise4param3d, sides3D)
	perlin4:get_3d_map_flat(bp3d, noisemap4)

	perlin5 = perlin5 or minetest.get_perlin_map(stoneworld.noise5param3d, sides3D)
	perlin5:get_3d_map_flat(bp3d, noisemap5)

	perlin6 = perlin6 or minetest.get_perlin_map(stoneworld.noise6param2d, sides2D)
	perlin6:get_2d_map_flat(bp2d, noisemap6)

	perlin7 = perlin7 or minetest.get_perlin_map(stoneworld.noise7param3d, sides3D)
	perlin7:get_3d_map_flat(bp3d, noisemap7)

	-- Localize commonly used functions for speed.
	local floor = math.floor
	local ceil = math.ceil
	local abs = math.abs
	local min = math.min
	local max = math.max

	-- Flat set if we are to spawn a fortress in this mapchunk.
	-- Note: fortress WILL extend outside the mapchunk!
	local spawn_fortress = false
	local fortress_y = 0

	-- First mapgen pass. Generate stone, passages, caverns, lava, and bedrock.
	-- Use slightly overgenerated coordinates to generate material 1 node outside
	-- the normal minp/maxp bounds. This makes it possible for the second mapgen
	-- pass (decorations) to get what is at the edge of a neighbor chunk.
	for z = z0, z1 do
		for x = x0, x1 do
			-- Get index into 2D noise arrays.
			local nx = (x - x0)
			local nz = (z - z0)
			local n2d = (side_len_z*nz+nx)
			-- Lua arrays start indexing at 1, not 0. Urrrrgh.
			n2d = n2d + 1

			local miny = y0
			local maxy = y1

			-- Clamp realm end/start Y-values.
			miny = max(miny, nbeg)
			maxy = min(maxy, nend)

			-- Get 2D noise values.
			local n1 = noisemap1[n2d]
			local n2 = noisemap3[n2d]
			local n6 = noisemap6[n2d]

			-- Pass through column.
			for y = miny, maxy do
				local vp = max_area:index(x, y, z)
				local cid = vm_data[vp]
				local nid = c_stone

				-- Don't overwrite previously existing stuff (non-ignore, non-air).
				-- This avoids ruining schematics that were previously placed, or other
				-- mapchunks.
				if (cid == c_air or cid == c_ignore) then
					-- Get index into 3D noise arrays.
					local n3d = min_area:index(x, y, z)

					local n3 = noisemap5[n3d]
					local n4 = noisemap4[n3d]

					-- Carve long winding caves.
					local caves = stoneworld.caves
					for k = 1, #caves do
						-- Skip caves which aren't part of this map chunk.
						if caves[k].good then
							-- Initial cave noise values.
							local c1 = caves[k].route_map[n2d]
							local c2 = caves[k].height_map[n2d]
							local yl = caves[k].y_level

							-- Basic cave parameters: Y-level, passage height.
							local cnoise1 = abs(c1)
							local cnoise2 = c1
							local clevel = (nbeg + yl + floor(c2 * 50)) + floor(n1 * 2)
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
									nid = c_air
								end
							end
						end
					end

					-- Adamantine noise-level trigger.
					local spn = n6 + (n4 / 15)
					local spire_start = 1.080

					-- Carve caverns.
					local caverns = stoneworld.caverns
					for k = 1, #caverns do
						-- Skip caverns which aren't part of this map chunk.
						if caverns[k].good then
							-- Initial cavern noise values.
							local c1 = caverns[k].ceiling_map[n2d]
							local c2 = caverns[k].floor_map[n2d]
							local c3 = caverns[k].level_map[n2d]
							local yl = caverns[k].y_level

							-- Basic cavern parameters.
							local clevel = (nbeg + yl + floor(c3 * 40))
							local bot = floor(clevel - 15 + (c2 * 5) + n2 * 6)
							local top = floor(clevel + 15 + (c1 * 15) + n1 * 6)
							local lava = (nbeg + yl - 30)

							-- Pinch together floor and ceiling in the vicinity of spires.
							local shell_start = (spire_start - 0.200)
							if spn > shell_start then
								local tpinch = (spn - shell_start) * 50
								local bpinch = (spn - shell_start) * 70
								top = top - tpinch
								bot = bot + bpinch
							end

							-- If ceiling is far enough up, and bottom is below the lava
							-- ocean, then we have a chance to spawn a lava fortress here.
							if not spawn_fortress then
								if (top - bot) >= 50 and bot <= (lava - 5) then
									-- Use perlin noise to limit fortress spawning to regions.
									-- Using abs() will cause fortresses to spawn in winding strings.
									if abs(n3) < 0.2 then
										-- Only for the mapchunk intersecting the lava ocean.
										-- If we didn't do this check, it would be possible that the
										-- mapchunk ABOVE (or below) could also cause a fortress to
										-- spawn, causing a high probability of overlapping fortresses.
										if y == lava then
											spawn_fortress = true
											fortress_y = lava + 10
										end
									end
								end
							end

							-- Raise cavern ceiling over the lava ocean.
							-- Need to make room for the fortress spawner.
							local expanse_y = (lava + 15)
							if bot < expanse_y then
								top = top + (expanse_y - bot) * 2
							end

							if y >= bot and y <= top then
								nid = c_air
							end
							if y >= bot and y <= lava then
								nid = c_lava
							end
						end
					end

					-- Lava pools sometimes between rubble and basalt.
					if y <= (nbeg + 3) or y >= (nend - 3) then
						nid = c_lava
					end

					local l1 = ceil(abs(n1) * 6)
					local l2 = ceil(abs(n2) * 6)

					-- Rubble layer between bedrock and basalt.
					if y <= (nbeg + l1 + l2) or y >= (nend - l1 - l2) then
						nid = c_cobble
					end

					-- Adamantine spires.
					if spn > (spire_start + 0.070) then
						local m = floor(y + n4 * 6) % 10
						if m >= 0 and m <= 2 then
							nid = c_adamant
						elseif m == 3 then
							nid = c_lava2
						else
							nid = c_air
						end
					elseif spn > (spire_start + 0.040) then
						nid = c_adamant
					elseif spn > (spire_start + 0.020) then
						nid = c_obsidian2
					elseif spn > (spire_start + 0.000) then
						nid = c_obsidian
					end

					-- Generate bedrock floor and ceiling. Highest priority.
					if y <= (nbeg + l1) or y >= (nend - l1) then
						nid = c_bedrock
					end

					-- Write content ID.
					vm_data[vp] = nid
				end
			end -- End column loop.
		end
	end

	-- Second mapgen pass. Add context-specific modifications and decorations.
	-- No overgeneration, stay within minp/maxp bounds.
	for z = z0 + 1, z1 - 1 do
		for x = x0 + 1, x1 - 1 do
			local miny = (y0 + 1)
			local maxy = (y1 - 1)

			-- Clamp realm end/start Y-values.
			miny = max(miny, nbeg)
			maxy = min(maxy, nend)

			local worm = pr:next(1, 100) < 15
			local fungus = pr:next(1, 100) < 15

			for y = miny, maxy do
				-- Get index into 3D noise arrays.
				local n3d = min_area:index(x, y, z)

				local sand_threshold = abs(noisemap7[n3d])

				local vd = max_area:index(x, y - 1, z)
				local vp = max_area:index(x, y, z)
				local vu = max_area:index(x, y + 1, z)
				local vn = max_area:index(x, y, z + 1)
				local vs = max_area:index(x, y, z - 1)
				local vw = max_area:index(x - 1, y, z)
				local ve = max_area:index(x + 1, y, z)
				local vne = max_area:index(x + 1, y, z + 1)
				local vnw = max_area:index(x - 1, y, z + 1)
				local vse = max_area:index(x + 1, y, z - 1)
				local vsw = max_area:index(x - 1, y, z - 1)

				-- Get what's here already.
				local cd = vm_data[vd]
				local cp = vm_data[vp]
				local cu = vm_data[vu]
				local cn = vm_data[vn]
				local cs = vm_data[vs]
				local cw = vm_data[vw]
				local ce = vm_data[ve]
				local cne = vm_data[vne]
				local cnw = vm_data[vnw]
				local cse = vm_data[vse]
				local csw = vm_data[vsw]

				local nid = cp

				-- Stone with air both above and below becomes air.
				if cp == c_stone and cu == c_air and cd == c_air then
					nid = c_air
				end

				-- Stone next to lava becomes obsidian, but requires stone below.
				if cp == c_stone and cd == c_stone and (cn == c_lava or cs == c_lava or
						cw == c_lava or ce == c_lava or cnw == c_lava or cne == c_lava or
						csw == c_lava or cse == c_lava or cu == c_lava) then
					nid = c_obsidian
				end

				-- Stone with air above and more stone below becomes rubble.
				-- But not if already turned to obsidian.
				if nid ~= c_obsidian then
					if cp == c_stone and cu == c_air and cd == c_stone then
						if sand_threshold < 0.1 then
							nid = c_sand
						else
							nid = c_cobble

							-- Sometimes place sunstone.
							if pr:next(1, 300) == 1 then
								nid = c_glow
							end
						end
					end
				end

				-- Place glow worms on ceilings.
				if worm then
					if cp == c_air and cu == c_stone then
						nid = c_worm
					end
				end

				-- Place fungus on floors.
				if fungus then
					if cp == c_air and (cd == c_stone or cd == c_cobble) then
						nid = c_fungus
					end
				end

				-- Write content ID.
				vm_data[vp] = nid
			end
		end
	end

	-- Lighting pass. Set everything dark.
	for z = emin.z, emax.z do
		for x = emin.x, emax.x do
			for y = emin.y, emax.y do
				local vp = max_area:index(x, y, z)
				vm_light[vp] = 0
			end
		end
	end

	-- Finalize voxel manipulator.
	vm:set_data(vm_data)
	minetest.generate_ores(vm)
	vm:set_light_data(vm_light)
	vm:calc_lighting({x=emin.x, y=emin.y, z=emin.z}, {x=emax.x, y=maxp.y, z=emax.z}, true)
	--vm:write_to_map()
	vm:update_liquids()

	-- A chance to spawn a fortress. Do NOT spawn a fortress in every mapchunk
	-- that's eligible, that will crowd everything else out!
	if spawn_fortress and pr:next(1, 5) == 1 then
		local p = vector.round({
			x = floor((x0 + x1) / 2),
			y = fortress_y,
			z = floor((z0 + z1) / 2),
		})

		-- Lock X,Z coords to values divisible by 11. This is the fortress step size
		-- for "default". Doing this ensures fortresses in adjacent chunks line up.
		p.x = p.x - (p.x % 11)
		p.z = p.z - (p.z % 11)

		--[[
		minetest.after(0, function()
			fortress.generate(p, "default")
		end)
		--]]
		minetest.save_gen_notify("stoneworld:fortress_spawn_location", {pos=p})
	end
end



-- Register the mapgen callback.
minetest.register_on_generated(function(...)
	stoneworld.generate_realm(...)
end)

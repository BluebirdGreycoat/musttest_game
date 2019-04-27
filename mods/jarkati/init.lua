
jarkati = jarkati or {}
jarkati.modpath = minetest.get_modpath("jarkati")

-- These match values in the realm-control mod.
jarkati.REALM_START = 3600
jarkati.REALM_END = 3900
jarkati.SEA_LEVEL = 3740
jarkati.LAVA_LEVEL = 3610

jarkati.biomes = {}
jarkati.decorations = {}

-- Public API function.
function jarkati.register_layer(data)
	local td = table.copy(data)

	assert(type(td.node) == "string")

	-- Convert string name to content ID.
	td.cid = minetest.get_content_id(td.node)

	td.min_level = td.min_level or 1
	td.max_level = td.max_level or 1

	assert(td.min_level <= td.max_level)

	td.min_depth = td.min_depth or 1
	td.max_depth = td.max_depth or 1

	assert(td.min_depth <= td.max_depth)

	jarkati.biomes[#jarkati.biomes + 1] = td
end

-- Public API function.
function jarkati.register_decoration(data)
	local td = table.copy(data)

	-- Convert single node to table.
	if type(td.nodes) == "string" then
		td.nodes = {td.nodes}
	end

	if type(td.replace_surface) == "string" then
		td.replace_surface = {td.replace_surface}
	end

	-- Used only with the `nodes` parameter.
	td.param2 = data.param2 or {0}

	assert(type(td.nodes) == "table" or type(td.schematic) == "string" or type(td.schematic) == "table")
	assert(type(td.probability) == "number")
	assert(td.probability >= 1)

	-- Ensure all node names are actually registered!
	if td.nodes then
		for k, v in ipairs(td.nodes) do
			assert(minetest.registered_nodes[v])
		end
	end

	if not td.all_ceilings and not td.all_floors then
		td.ground_level = true
	end

	-- Default schematic parameters.
	td.rotation = data.rotation or "0"
	td.replacements = data.replacements or {}
	td.force_placement = data.force_placement or false
	td.flags = data.flags or ""

	-- Placement Y-offset is always 0 (ignored) if `place_center_y` is specified.
	if td.flags:find("place_center_y") then
		td.place_offset_y = 0
	else
		td.place_offset_y = data.place_offset_y or 0

		-- Invert for `all_ceilings` decorations.
		if td.all_ceilings and td.place_offset_y > 0 then
			td.place_offset_y = -td.place_offset_y
		end
	end

	-- The object or schematic's aprox `radius`, when checking for flat ground.
	-- Non-zero basically means all ground in the radius must be the same height.
	td.radius = data.radius or 0

	td.y_min = data.y_min or -31000
	td.y_max = data.y_max or 31000

	jarkati.decorations[#jarkati.decorations + 1] = td
end

jarkati.register_layer({
	node = "default:desert_sand",
	min_depth = 1,
	max_depth = 2,
	min_level = 1,
	max_level = 1,
})

jarkati.register_layer({
	node = "default:sand",
	min_depth = 3,
	max_depth = 3,
	min_level = 1,
	max_level = 1,
})

jarkati.register_layer({
	node = "default:desert_cobble",
	min_depth = 7,
	max_depth = 7,
	min_level = 1,
	max_level = 1,
})

jarkati.register_layer({
	node = "default:sandstone",
	min_depth = 4,
	max_depth = 6,
	min_level = 1,
	max_level = 1,
})

jarkati.register_decoration({
	nodes = "stairs:slab_desert_cobble",
	probability = 700,
	place_on = {"default:desert_sand"},
})

-- Scatter "rubble" around the bases of cliffs.
jarkati.register_decoration({
	nodes = {"default:desert_cobble", "stairs:slab_desert_cobble"},
	probability = 10,
	spawn_by = {"default:desert_stone", "default:sandstone"},
	place_on = {"default:desert_sand"},
})

jarkati.register_decoration({
	nodes = "default:dry_shrub",
	probability = 110,
	place_on = {"default:desert_sand"},
})

jarkati.register_decoration({
	nodes = {
		"default:dry_grass_1",
		"default:dry_grass_2",
		"default:dry_grass_3",
		"default:dry_grass_4",
		"default:dry_grass_5",
	},
	param2 = {2},
	probability = 50,
	place_on = {"default:desert_sand"},
	replace_surface = "default:dirt_with_dry_grass",
})

jarkati.register_decoration({
	nodes = {
		"cavestuff:redspike1",
		"cavestuff:redspike2",
		"cavestuff:redspike3",
		"cavestuff:redspike4",
	},
	param2 = {0, 1, 2, 3},
	probability = 120,
	all_floors = true,
	place_on = {"default:desert_stone"},
})

---[[
do
	local _ = {name = "air"}
	local X = {name = "default:gravel"}
	local C1 = {name = "stairs:micro_desert_sandstone", param2 = 1}
	local C2 = {name = "stairs:micro_desert_sandstone", param2 = 2}
	local C3 = {name = "stairs:micro_desert_sandstone", param2 = 0}
	local C4 = {name = "stairs:micro_desert_sandstone", param2 = 3}
	local L = {name = "stairs:slab_desert_sandstone"}
	local R = {name = "default:desert_sandstone"}
	local S = {name = "default:desert_sand"}

	jarkati.register_decoration({
		schematic = {
			size = {x=4, y=2, z=4},
			data = {
				S, R, R, S,
				C1, L, L, C3,

				R, X, X, R,
				L, _, _, L,

				R, X, X, R,
				L, _, _, L,

				S, R, R, S,
				C2, L, L, C4,
			},
		},
		force_placement = true,
		flags = "place_center_x,place_center_z",
		rotation = "random",
    place_offset_y = -1,
    radius = 3,
		probability = 800,
		place_on = {"default:desert_sand"},

    y_max = 3760,
    y_min = 3730,
	})
end
--]]

---[[
do
	local _ = {name = "air"}
	local X = {name = "default:gravel"}
	local C1 = {name = "stairs:micro_desert_sandstone", param2 = 1}
	local C2 = {name = "stairs:micro_desert_sandstone", param2 = 2}
	local C3 = {name = "stairs:micro_desert_sandstone", param2 = 0}
	local C4 = {name = "stairs:micro_desert_sandstone", param2 = 3}
	local L1 = {name = "stairs:stair_desert_sandstone", param2 = 0}
	local L2 = {name = "stairs:stair_desert_sandstone", param2 = 1}
	local L3 = {name = "stairs:stair_desert_sandstone", param2 = 2}
	local L4 = {name = "stairs:stair_desert_sandstone", param2 = 3}
	local R = {name = "default:desert_sandstone"}
	local S = {name = "default:desert_sand"}

	jarkati.register_decoration({
		schematic = {
			size = {x=4, y=2, z=4},
			data = {
				S, R, R, S,
				C1, L1, L1, C3,

				R, X, X, R,
				L2, _, _, L4,

				R, X, X, R,
				L2, _, _, L4,

				S, R, R, S,
				C2, L3, L3, C4,
			},
		},
		force_placement = true,
		flags = "place_center_x,place_center_z",
		rotation = "random",
    place_offset_y = -1,
    radius = 4,
		probability = 800,
		place_on = {"default:desert_sand"},

    y_max = 3760,
    y_min = 3730,
	})
end
--]]

---[[
do
	local _ = {name = "air"}
	local X = {name = "rackstone:nether_grit"}
	local C1 = {name = "stairs:micro_desert_sandstone", param2 = 1}
	local C2 = {name = "stairs:micro_desert_sandstone", param2 = 2}
	local C3 = {name = "stairs:micro_desert_sandstone", param2 = 0}
	local C4 = {name = "stairs:micro_desert_sandstone", param2 = 3}
	local L = {name = "stairs:slab_desert_sandstone"}
	local R = {name = "default:desert_sandstone"}
	local S = {name = "default:desert_sand"}

	jarkati.register_decoration({
		schematic = {
			size = {x=4, y=2, z=4},
			data = {
				S, R, R, S,
				C1, L, L, C3,

				R, X, X, R,
				L, _, _, L,

				R, X, X, R,
				L, _, _, L,

				S, R, R, S,
				C2, L, L, C4,
			},
		},
		force_placement = true,
		flags = "place_center_x,place_center_z",
		rotation = "random",
    place_offset_y = -1,
    radius = 3,
		probability = 2500,
		place_on = {"default:desert_sand"},

    y_max = 3750,
    y_min = 3730,
	})
end
--]]

---[[
do
	local _ = {name = "air"}
	local X = {name = "rackstone:nether_grit"}
	local C1 = {name = "stairs:micro_desert_sandstone", param2 = 1}
	local C2 = {name = "stairs:micro_desert_sandstone", param2 = 2}
	local C3 = {name = "stairs:micro_desert_sandstone", param2 = 0}
	local C4 = {name = "stairs:micro_desert_sandstone", param2 = 3}
	local L1 = {name = "stairs:stair_desert_sandstone", param2 = 0}
	local L2 = {name = "stairs:stair_desert_sandstone", param2 = 1}
	local L3 = {name = "stairs:stair_desert_sandstone", param2 = 2}
	local L4 = {name = "stairs:stair_desert_sandstone", param2 = 3}
	local R = {name = "default:desert_sandstone"}
	local S = {name = "default:desert_sand"}

	jarkati.register_decoration({
		schematic = {
			size = {x=4, y=2, z=4},
			data = {
				S, R, R, S,
				C1, L1, L1, C3,

				R, X, X, R,
				L2, _, _, L4,

				R, X, X, R,
				L2, _, _, L4,

				S, R, R, S,
				C2, L3, L3, C4,
			},
		},
		force_placement = true,
		flags = "place_center_x,place_center_z",
		rotation = "random",
    place_offset_y = -1,
    radius = 4,
		probability = 2500,
		place_on = {"default:desert_sand"},

    y_max = 3750,
    y_min = 3730,
	})
end
--]]

local NOISE_SCALE = 1

-- Base terrain height (may be modified to be negative or positive).
jarkati.noise1param2d = {
	offset = 0,
	scale = 1,
	spread = {x=128*NOISE_SCALE, y=128*NOISE_SCALE, z=128*NOISE_SCALE},
	seed = 5719,
	octaves = 6,
	persist = 0.5,
	lacunarity = 2,
}

-- Modifies frequency of vertical tunnel shafts.
jarkati.noise2param2d = {
	offset = 0,
	scale = 1,
	spread = {x=64*NOISE_SCALE, y=64*NOISE_SCALE, z=64*NOISE_SCALE},
	seed = 8827,
	octaves = 6,
	persist = 0.4, -- Amplitude multiplier.
	lacunarity = 2, -- Wavelength divisor.
}

-- Mese/tableland terrain-height modifier.
jarkati.noise3param2d = {
	offset = 0,
	scale = 1,
	spread = {x=64*NOISE_SCALE, y=64*NOISE_SCALE, z=64*NOISE_SCALE},
	seed = 54871,
	octaves = 5,
	persist = 0.5,
	lacunarity = 2,
}

-- Modifies the frequency (strength) of tablelands over big area.
jarkati.noise4param2d = {
	offset = 0,
	scale = 1,
	spread = {x=128*NOISE_SCALE, y=128*NOISE_SCALE, z=128*NOISE_SCALE},
	seed = 2819,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2,
}

-- Disjunction height modifier.
jarkati.noise5param2d = {
	offset = 0,
	scale = 1,
	spread = {x=512*NOISE_SCALE, y=512*NOISE_SCALE, z=512*NOISE_SCALE},
	seed = 3819,
	octaves = 6,
	persist = 0.7,
	lacunarity = 2,
}

-- Primary cavern noise.
jarkati.noise6param3d = {
	offset = 0,
	scale = 1,
	spread = {x=128*NOISE_SCALE, y=32*NOISE_SCALE, z=128*NOISE_SCALE},
	seed = 3817,
	octaves = 5,
	persist = 0.5,
	lacunarity = 2,
}

-- Vertical tunnel noise.
jarkati.noise7param3d = {
	offset = 0,
	scale = 1,
	spread = {x=8*NOISE_SCALE, y=64*NOISE_SCALE, z=8*NOISE_SCALE},
	seed = 7848,
	octaves = 4,
	persist = 0.7,
	lacunarity = 1.5,
}

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_desert_stone    = minetest.get_content_id("default:desert_stone")
local c_desert_cobble   = minetest.get_content_id("default:desert_cobble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_sand            = minetest.get_content_id("default:sand")
local c_desert_sand     = minetest.get_content_id("default:desert_sand")
local c_water           = minetest.get_content_id("default:water_source")
local c_lava            = minetest.get_content_id("default:lava_source")

-- Externally located tables for performance.
local vm_data = {}
local biome_data = {}
local heightmap = {}

local noisemap1 = {}
local noisemap2 = {}
local noisemap3 = {}
local noisemap4 = {}
local noisemap5 = {}
local noisemap6 = {}
local noisemap7 = {}

local perlin1
local perlin2
local perlin3
local perlin4
local perlin5
local perlin6
local perlin7

jarkati.generate_realm = function(minp, maxp, seed)
	local nbeg = jarkati.REALM_START
	local nend = jarkati.REALM_END
	local slev = jarkati.SEA_LEVEL
	local lbeg = jarkati.REALM_START
	local lend = jarkati.LAVA_LEVEL

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > nend or maxp.y < nbeg then
		return
	end

	-- Grab the voxel manipulator.
	-- Read current map data.
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(vm_data)
	local max_area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}
	local min_area = VoxelArea:new {MinEdge=minp, MaxEdge=maxp}

	-- Actual emerged area should be bigger than the chunk we're generating!
	assert(emin.y < minp.y and emin.x < minp.x and emin.z < minp.z)
	assert(emax.y > maxp.y and emax.x > maxp.x and emax.z > maxp.z)

	local pr = PseudoRandom(seed + 351)
	local dpr = PseudoRandom(seed + 2891) -- For decoration placement probability.

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Compute side lengths.
	local side_len_x = ((x1-x0)+1)
	local side_len_y = ((y1-y0)+1)
	local side_len_z = ((z1-z0)+1)
	local sides2D = {x=side_len_x, y=side_len_z}
	local sides3D = {x=side_len_x, y=side_len_z, z=side_len_y}
	local bp2d = {x=x0, y=z0}
	local bp3d = {x=x0, y=y0, z=z0}

	-- Get noisemaps.
	perlin1 = perlin1 or minetest.get_perlin_map(jarkati.noise1param2d, sides2D)
	perlin1:get2dMap_flat(bp2d, noisemap1)

	perlin2 = perlin2 or minetest.get_perlin_map(jarkati.noise2param2d, sides2D)
	perlin2:get2dMap_flat(bp2d, noisemap2)

	perlin3 = perlin3 or minetest.get_perlin_map(jarkati.noise3param2d, sides2D)
	perlin3:get2dMap_flat(bp2d, noisemap3)

	perlin4 = perlin4 or minetest.get_perlin_map(jarkati.noise4param2d, sides2D)
	perlin4:get2dMap_flat(bp2d, noisemap4)

	perlin5 = perlin5 or minetest.get_perlin_map(jarkati.noise5param2d, sides2D)
	perlin5:get2dMap_flat(bp2d, noisemap5)

	perlin6 = perlin6 or minetest.get_perlin_map(jarkati.noise6param3d, sides3D)
	perlin6:get3dMap_flat(bp3d, noisemap6)

	perlin7 = perlin7 or minetest.get_perlin_map(jarkati.noise7param3d, sides3D)
	perlin7:get3dMap_flat(bp3d, noisemap7)

	-- Localize commonly used functions for speed.
	local floor = math.floor
	local ceil = math.ceil
	local abs = math.abs
	local min = math.min
	local max = math.max

	-- Terrain height function (does not handle caves).
	local function height(z, x)
		-- Get index into 2D noise arrays.
		local nx = (x - x0)
		local nz = (z - z0)
		local ni2 = (side_len_z*nz+nx)
		-- Lua arrays start indexing at 1, not 0. Urrrrgh.
		ni2 = ni2 + 1

		local n1 = noisemap1[ni2]
		local n2 = noisemap2[ni2]
		local n3 = noisemap3[ni2]
		local n4 = noisemap4[ni2]
		local n5 = noisemap5[ni2]

		-- Calc base terrain height.
		local h = slev + (abs(n1) * 16)

		-- Modify the tableland noise parameter with this noise.
		n3 = n3 * abs(n4)
		n1 = n1 * abs(n5)

		-- If tableland noise over threshold, then flatten/invert terrain height.
		-- This generates "tablelands", buttes, etc.
		if n3 > -0.1 then
			h = slev + (n1 * 3)
		end
		-- If even farther over the threshold, then intensify/invert once again.
		-- This can result in apparent "land bridges" if the surrounding landscape
		-- is low, or it can create simple "canyons" if the surroundings are high.
		if n3 > 0.3 then
			h = slev - (n1 * 5)
		end
		if n3 > 0.6 then
			h = slev + (n1 * 8)
		end

		return h
	end

	local function cavern(x, y, z)
		local np = min_area:index(x, y, z)
		local n1 = noisemap6[np]
		local n2 = noisemap7[np]

		-- Get index into 2D noise arrays.
		local nx = (x - x0)
		local nz = (z - z0)
		local ni2 = (side_len_z*nz+nx)
		-- Lua arrays start indexing at 1, not 0. Urrrrgh.
		ni2 = ni2 + 1
		local n3 = abs(noisemap2[ni2])

		-- Reduce cavern noise at realm base.
		local d = (y - nbeg)
		if d < 0 then d = 0 end
		d = d / 16
		if d > 1 then d = 1 end
		if d < 0 then d = 0 end
		n1 = n1 * d

		-- Reduce cavern noise at surface level.
		local f = (slev - y)
		if f < 0 then f = 0 end
		f = f / 16
		if f > 1 then f = 1 end
		if f < 0 then f = 0 end
		n1 = n1 * f

		-- Expand cavern noise 50 meters below surface level, 10 meters above and below.
		local x = abs((slev - 50) - y)
		x = x * -1 + 16 -- Invert range.
		x = x / 16
		if x > 1 then x = 1 end
		if x < 0 then x = 0 end
		n1 = n1 * (1 + x)

		return (abs(n1) > 0.6 or (abs(n2) * (n3 * n3)) > 0.8)
	end

	-- Generic filler stone type.
	local c_stone = c_desert_stone

	-- First mapgen pass. Generate stone terrain shape, fill rest with air (critical).
	-- This also constructs the heightmap, which caches the height values.
	for z = z0, z1 do
		for x = x0, x1 do
			local ground = floor(height(z, x))
			heightmap[max_area:index(x, 0, z)] = ground

			local miny = (y0 - 0)
			local maxy = (y1 + 0)

			miny = max(miny, nbeg)
			maxy = min(maxy, nend)

			-- Flag set once a cave has carved away part of the surface in this column.
			-- Second flag set once the floor of the first cave is reached.
			-- Once the floor of the first cave is reached, the heightmap is adjusted.
			-- The heightmap is ONLY adjusted for caves that intersect with base ground level.
			local gc0 = false
			local gc1 = false

			-- First pass through column.
			-- Iterate downwards so we can detect when caves modify the surface height.
			for y = maxy, miny, -1 do
				local cave = cavern(x, y, z)
				local vp = max_area:index(x, y, z)
				local cid = vm_data[vp]

				-- Don't overwrite previously existing stuff (non-ignore, non-air).
				-- This avoids ruining schematics that were previously placed.
				if (cid == c_air or cid == c_ignore) then
					if cave then
						-- We've started carving a cave in this column.
						-- Don't bother flagging this unless the cave roof would be above ground level.
						if (y > ground and not gc0) then
							gc0 = true
						end

						if (y >= lbeg and y <= lend) then
							vm_data[vp] = c_lava
						else
							vm_data[vp] = c_air
						end
					else
						if y <= ground then
							-- We've finished carving a cave in this column.
							-- Adjust heightmap.
							-- But don't bother if cave floor would be above ground level.
							if (gc0 and not gc1) then
								heightmap[max_area:index(x, 0, z)] = y
								gc1 = true
							end

							vm_data[vp] = c_stone
						else
							if (y >= lbeg and y <= lend) then
								vm_data[vp] = c_lava
							else
								vm_data[vp] = c_air
							end
						end
					end
				end
			end -- End column loop.
		end
	end

	---[[
	-- Localize for speed.
	local all_biomes = jarkati.biomes
	local function biomes(biomes)
		local biome_count = 0
		for k, v in ipairs(biomes) do
			biome_count = biome_count + 1
			biome_data[biome_count] = v
		end
		return biome_data, biome_count -- Table is continuously reused.
	end

	-- Second mapgen pass. Generate topsoil layers.
	for z = z0, z1 do
		for x = x0, x1 do
			local miny = (y0 - 0)
			local maxy = (y1 + 0)

	    -- Get heightmap value at this location. This may have been adjusted by a surface cave.
			local ground = heightmap[max_area:index(x, 0, z)]

			-- Count of how many "surfaces" were detected (so far) while iterating down.
			-- 0 means we haven't found ground yet. 1 means found ground, >1 indicates a cave surface.
			local count = 0
			local depth = 0

			-- Get array and array-size of all biomes valid for this position.
			local vb, bc = biomes(all_biomes)

			-- Second pass through column. Iterate backwards for depth checking.
			for y = maxy, miny, -1 do
				if y >= nbeg and y <= nend then
					local vp0 = max_area:index(x, y, z)
					local vpu = max_area:index(x, (y - 1), z)

					if y <= ground then
						count = 1
						if vm_data[vp0] ~= c_air and vm_data[vpu] ~= c_air then
							depth = (ground - y) + 1
						else
							depth = 0
						end
					else
						count = 0
						depth = 0
					end

					-- Place topsoils & layers, etc. using current biome data.
					for i = 1, bc do
						-- Get biome data.
						local v = vb[i]

						if (count >= v.min_level and count <= v.max_level) then
							if (depth >= v.min_depth and depth <= v.max_depth) then
								vm_data[vp0] = v.cid
							end
						end
					end
				end
			end -- End column loop.
		end
	end
	--]]

	---[[
	-- Third mapgen pass. Generate bedrock layer overwriting everything else (critical).
	if not (y1 < nbeg or y0 > (nbeg + 10)) then
		for z = z0, z1 do
			for x = x0, x1 do
				-- Randomize height of the bedrock a bit.
				local bedrock = (nbeg + pr:next(5, pr:next(6, 7)))
				local miny = max(y0, nbeg)
				local maxy = min(y1, bedrock)

				-- Third pass through column.
				for y = miny, maxy do
					local vp = max_area:index(x, y, z)
					vm_data[vp] = c_bedrock
				end -- End column loop.
			end
		end
	end
	--]]

	-- Finalize voxel manipulator.
	vm:set_data(vm_data)
	minetest.generate_ores(vm)
	vm:write_to_map(false)

	-- Not needed to do this, it will be done during the "mapfix" call.
	--vm:update_liquids()

	---[[
	-- Localize for speed.
	local all_decorations = jarkati.decorations
	local decopos = {x=0, y=0, z=0}
	local set_node = minetest.set_node
	local get_node = minetest.get_node
	local put_schem = minetest.place_schematic
	local deconode = {name="", param2=0}

	local function decorate(v, x, y, z, d)
		-- Don't place decorations outside chunk boundaries.
		-- (X and Z are already checked.)
		if (y < y0 or y > y1) then
			return
		end
		if (y > v.y_max or y < v.y_min) then
	    return
		end

		decopos.x = x
		decopos.y = y
		decopos.z = z

		if v.spawn_by then
			if not minetest.find_node_near(decopos, (v.radius + 1), v.spawn_by) then
				return
			end
		end

		-- Validate the ground/ceiling surface.
		do
	    local x1 = decopos.x - v.radius
	    local x2 = decopos.x + v.radius
	    local z1 = decopos.z - v.radius
	    local z2 = decopos.z + v.radius
	    local nn

	    -- All must be a valid floor/ceiling node!
	    decopos.y = decopos.y + d
	    for x = x1, x2 do
				for z = z1, z2 do
					decopos.x = x
					decopos.z = z
					nn = get_node(decopos).name
					-- Always check to make sure we're not air, here.
					-- This avoids spawning decorations on ground that was carved away by the cavegen.
					if nn == "air" or nn == "ignore" then
						return
					end
					-- If decoration requires specific node type, check if we have it.
					if v.place_on then
						local hs = false
						for t, j in ipairs(v.place_on) do
							if j == nn then
								hs = true
								break
							end
						end
						if not hs then
							return
						end
					end
				end
	    end

	    -- All must be empty air!
	    decopos.y = decopos.y - d
	    for x = x1, x2 do
				for z = z1, z2 do
					decopos.x = x
					decopos.z = z
					nn = get_node(decopos).name
					if nn ~= "air" then
						return
					end
				end
	    end

	    -- Back to ground. Replace ground surface!
	    if v.replace_surface then
				decopos.y = decopos.y + d
				for x = x1, x2 do
					for z = z1, z2 do
						decopos.x = x
						decopos.z = z
						deconode.name = v.replace_surface[dpr:next(1, #v.replace_surface)]
						deconode.param2 = 0
						set_node(decopos, deconode)
					end
				end
	    end

	    -- Reset deco coordinates.
	    decopos.x = x
	    decopos.y = y
	    decopos.z = z
		end

		if v.nodes then
			deconode.name = v.nodes[dpr:next(1, #v.nodes)]
			deconode.param2 = v.param2[dpr:next(1, #v.param2)]
			set_node(decopos, deconode)
		elseif v.schematic then
	    decopos.y = decopos.y + v.place_offset_y
	    put_schem(decopos, v.schematic, v.rotation, v.replacements, v.force_placement, v.flags)
	    decopos.y = decopos.y - v.place_offset_y
		end
	end

	-- Fourth mapgen pass. Generate decorations using highlevel placement functions.
	-- Note: we still read the voxelmanip data! But we can't modify it.
	for z = z0, z1 do
		for x = x0, x1 do

			for k, v in ipairs(all_decorations) do

				if not (y0 > v.y_max or y1 < v.y_min) then
					if dpr:next(1, v.probability) == 1 then
						-- Don't bother with ground-level placement if 'all_floors' was specified.
						if (v.ground_level and not v.all_floors) then
							local g0 = heightmap[max_area:index(x, 0, z)]
							local g1 = (g0 + 1)
							decorate(v, x, g1, z, -1)
						end

						if (v.all_floors or v.all_ceilings) then
							local miny = (y0 - 1)
							local maxy = (y1 + 1)
							for y = maxy, miny, -1 do
								local vpa = max_area:index(x, y, z)
								local vpu = max_area:index(x, (y - 1), z)

								local cida = vm_data[vpa]
								local cidu = vm_data[vpu]

								if v.all_floors then
									if (cida == c_air and cidu ~= c_air) then
										decorate(v, x, y, z, -1)
									end
								end
								if v.all_ceilings then
									if (cida ~= c_air and cidu == c_air) then
										decorate(v, x, (y - 1), z, 1)
									end
								end
							end
						end
					end
				end

			end
		end
	end
	--]]

	-- Correct lighting and liquid flow.
	-- This works, but for some reason I have to grab a new voxelmanip object.
	-- I can't seem to fix lighting using the original mapgen object?
	-- Seems to require the full overgenerated mapchunk size if non-singlenode.
	mapfix.work(emin, emax)
end



if not jarkati.registered then
	-- Register the mapgen callback.
	minetest.register_on_generated(function(...)
		jarkati.generate_realm(...)
	end)

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_copper",
		wherein = {"default:desert_stone"},
		clust_scarcity = 6*6*6,
		clust_num_ores = 4,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_copper",
		wherein = {"default:desert_stone"},
		clust_scarcity = 15*15*15,
		clust_num_ores = 27,
		clust_size = 6,
		y_min = 3600,
		y_max = 3700,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_iron",
		wherein = {"default:desert_stone"},
		clust_scarcity = 10*10*10,
		clust_num_ores = 4,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_iron",
		wherein = {"default:desert_stone"},
		clust_scarcity = 24*24*24,
		clust_num_ores = 27,
		clust_size = 6,
		y_min = 3600,
		y_max = 3700,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_diamond",
		wherein = {"default:desert_stone"},
		clust_scarcity = 17*17*17,
		clust_num_ores = 4,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_diamond",
		wherein = {"default:desert_stone"},
		clust_scarcity = 15*15*15,
		clust_num_ores = 6,
		clust_size = 3,
		y_min = 3600,
		y_max = 3700,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_coal",
		wherein = {"default:desert_stone"},
		clust_scarcity = 8*8*8,
		clust_num_ores = 8,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	local c = "jarkati:core"
	local f = jarkati.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	jarkati.registered = true
end

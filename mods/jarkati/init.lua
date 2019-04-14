
jarkati = jarkati or {}
jarkati.modpath = minetest.get_modpath("jarkati")

-- These match values in the realm-control mod.
jarkati.REALM_START = 3600
jarkati.REALM_END = 3900
jarkati.SEA_LEVEL = 3740

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

	assert(type(td.nodes) == "table")
	assert(type(td.probability) == "number")
	assert(td.probability >= 1)

	-- Ensure all node names are actually registered!
	for k, v in ipairs(td.nodes) do
		assert(minetest.registered_nodes[v])
	end

	td.param2 = data.param2 or 0

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
	nodes = {"stairs:slab_desert_cobble"},
	probability = 700,
})

jarkati.register_decoration({
	nodes = {"default:desert_cobble"},
	probability = 10,
	spawn_by = {"default:desert_stone"},
})

jarkati.register_decoration({
	nodes = {"default:dry_shrub"},
	probability = 110,
})

jarkati.register_decoration({
	nodes = {
		"default:dry_grass_1",
		"default:dry_grass_2",
		"default:dry_grass_3",
		"default:dry_grass_4",
		"default:dry_grass_5",
	},
	param2 = 2,
	probability = 50,
})

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

jarkati.noise2param2d = {
	offset = 0,
	scale = 1,
	spread = {x=32*NOISE_SCALE, y=32*NOISE_SCALE, z=32*NOISE_SCALE},
	seed = 1123,
	octaves = 4,
	persist = 0.8,
	lacunarity = 2,
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

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_desert_stone    = minetest.get_content_id("default:desert_stone")
local c_desert_cobble   = minetest.get_content_id("default:desert_cobble")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_sand            = minetest.get_content_id("default:sand")
local c_desert_sand     = minetest.get_content_id("default:desert_sand")

-- Externally located tables for performance.
local data = {}
local biome_data = {}
local noisemap1 = {}
local noisemap2 = {}
local noisemap3 = {}
local noisemap4 = {}
local noisemap5 = {}

jarkati.generate_realm = function(minp, maxp, seed)
	local nbeg = jarkati.REALM_START
	local nend = jarkati.REALM_END
	local slev = jarkati.SEA_LEVEL

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > nend or maxp.y < nbeg then
		return
	end

	-- Grab the voxel manipulator.
	-- Read current map data.
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(data)
	local area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}

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
	local side_len_z = ((z1-z0)+1)
	local sides2D = {x=side_len_x, y=side_len_z}
	local bp2d = {x=x0, y=z0}

	-- Get noisemaps.
	local perlin1 = minetest.get_perlin_map(jarkati.noise1param2d, sides2D)
	perlin1:get2dMap_flat(bp2d, noisemap1)

	local perlin2 = minetest.get_perlin_map(jarkati.noise2param2d, sides2D)
	perlin2:get2dMap_flat(bp2d, noisemap2)

	local perlin3 = minetest.get_perlin_map(jarkati.noise3param2d, sides2D)
	perlin3:get2dMap_flat(bp2d, noisemap3)

	local perlin4 = minetest.get_perlin_map(jarkati.noise4param2d, sides2D)
	perlin4:get2dMap_flat(bp2d, noisemap4)

	local perlin5 = minetest.get_perlin_map(jarkati.noise5param2d, sides2D)
	perlin5:get2dMap_flat(bp2d, noisemap5)

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

	-- Generic filler stone type.
	local c_stone = c_desert_stone

	-- First mapgen pass. Generate stone terrain shape, fill rest with air (critical).
	for z = z0, z1 do
		for x = x0, x1 do
			local ground = floor(height(z, x))
			local miny = (y0 - 0)
			local maxy = (y1 + 0)

			-- First pass through column.
			for y = miny, maxy do
				local vp = area:index(x, y, z)
				local cid = data[vp]

				-- Don't overwrite previously existing stuff (non-ignore, non-air).
				if (cid == c_air or cid == c_ignore) then
					if y <= ground then
						data[vp] = c_stone
					else
						data[vp] = c_air
					end
				end
			end -- End column loop.
		end
	end

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
	    -- By "overscanning" we avoid missing topsoils at chunk tops/bottoms.
			local ground = floor(height(z, x))
			local miny = (y0 - 0)
			local maxy = (y1 + 0)

			-- Count of how many "surfaces" were detected (so far) while iterating down.
			-- 0 means we haven't found ground yet. 1 means found ground, >1 indicates a cave surface.
			local count = 0
			local depth = 0

			-- Get array and array-size of all biomes valid for this position.
			local vb, bc = biomes(all_biomes)

			-- Second pass through column.
			for y = miny, maxy do
				if y >= nbeg and y <= nend then
					local vp = area:index(x, y, z)

					if y <= ground then
						count = 1
						depth = ((ground - y) + 1)
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
								data[vp] = v.cid
							end
						end
					end
				end
			end -- End column loop.
		end
	end

	-- Third mapgen pass. Generate bedrock layer overwriting everything else (critical).
	for z = z0, z1 do
		for x = x0, x1 do
			-- Randomize height of the bedrock a bit.
			local bedrock = (nbeg + pr:next(5, pr:next(6, 7)))
			local miny = max(y0, nbeg)
			local maxy = min(y1, bedrock)

			-- Third pass through column.
			for y = miny, maxy do
				local vp = area:index(x, y, z)
				data[vp] = c_bedrock
			end -- End column loop.
		end
	end

	-- Finalize voxel manipulator.
	vm:set_data(data)
	--vm:set_lighting({day=0, night=0})
	minetest.generate_ores(vm)
	vm:calc_lighting()
	--vm:update_liquids() -- No liquid nodes placed.
	vm:write_to_map()

	-- Localize for speed.
	local all_decorations = jarkati.decorations
	local decopos = {x=0, y=0, z=0}
	local set_node = minetest.set_node
	local deconode = {name="", param2=0}

	-- Fourth mapgen pass. Generate decorations using highlevel placement functions.
	for z = z0, z1 do
		for x = x0, x1 do

			for k, v in ipairs(all_decorations) do
				if dpr:next(1, v.probability) == 1 then
					local g0 = floor(height(z, x))
					local g1 = (g0 + 1)

					-- Don't place decorations outside the current mapchunk.
					if (g1 >= y0 and g1 <= y1) then
						local spawn = true
						decopos.x = x
						decopos.y = g1
						decopos.z = z

						if v.spawn_by then
							if not minetest.find_node_near(decopos, 1, v.spawn_by) then
								spawn = false
							end
						end

						if spawn then
							deconode.name = v.nodes[dpr:next(1, #v.nodes)]
							deconode.param2 = v.param2
							set_node(decopos, deconode)
						end
					end
				end
			end
		end
	end
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
		clust_scarcity = 15*15*15,
		clust_num_ores = 3,
		clust_size = 5,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_iron",
		wherein = {"default:desert_stone"},
		clust_scarcity = 16*16*16,
		clust_num_ores = 3,
		clust_size = 5,
		y_min = 3600,
		y_max = 3900,
	})

	local c = "jarkati:core"
	local f = jarkati.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	jarkati.registered = true
end

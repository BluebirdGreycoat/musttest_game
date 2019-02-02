
cw = cw or {}
cw.modpath = minetest.get_modpath("cw")
cw.worldpath = minetest.get_worldpath()

if not cw.jungletree_registered then
	local _ = {name = "air", prob = 0}
	local L = {name = "default:jungleleaves", prob = 255}
	local N = {name = "default:jungleleaves", prob = 223}
	local M = {name = "default:jungleleaves", prob = 191}
	local B = {name = "default:jungletree", prob = 255, force_place = true}
	local Y = {name = "default:jungletree", prob = 191, force_place = true}
	local U = {name = "default:jungletree", prob = 127, force_place = true}
	local I = {name = "default:jungletree", prob = 255}

	local jungletree_data = {
		size = {x = 5, y = 17, z = 5},
		data = {
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			N, L, N, _, _,
			_, _, N, L, N,
			_, _, _, _, _,
			_, _, _, _, _,
			M, N, N, N, M,
			M, N, N, N, M,
			_, _, _, _, _,

			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			L, B, L, _, _,
			_, _, L, B, L,
			_, _, _, _, _,
			_, _, _, _, _,
			N, B, L, B, N,
			N, L, L, L, N,
			_, N, N, N, _,

			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, _, _,
			_, _, B, L, N,
			N, L, B, _, _,
			N, L, B, _, _,
			_, _, B, L, N,
			_, _, B, L, N,
			_, _, B, _, _,
			N, L, L, L, N,
			N, L, L, L, N,
			_, N, L, N, _,

			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, L, B, L,
			L, B, L, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, L, B, L,
			_, _, _, _, _,
			N, B, L, B, N,
			N, L, L, L, N,
			_, N, N, N, _,

			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, N, L, N,
			N, L, N, _, _,
			_, _, _, _, _,
			_, _, _, _, _,
			_, _, N, L, N,
			_, _, _, _, _,
			M, N, N, N, M,
			M, N, N, N, M,
			_, _, _, _, _,
		},
		yslice_prob = {
			{ypos=6, prob=191},
			{ypos=7, prob=191},
			{ypos=8, prob=191},
			{ypos=9, prob=191},
			{ypos=10, prob=191},
		},
	}

	local data = minetest.serialize_schematic(jungletree_data, "mts", {})
	local file = io.open(cw.worldpath .. "/cw_jungletree.mts", "w")
	file:write(data)
	file:close()

	cw.jungletree_registered = true
end

-- A Channelwood-like realm. Endless, shallow water in all directions, with
-- trees growing out of the ocean. Trees are huge and extremely tall. Water is
-- dangerious, filled with flesh-eating fish! Trees do not burn (too wet).

-- Register deadly water.
if not cw.registered then
	-- Basically just a copy of regular water, with damage_per_second.
	-- Since it's a copy and not the same, it isn't bucketable.
	local sdef = table.copy(minetest.registered_nodes["default:water_source"])
	local fdef = table.copy(minetest.registered_nodes["default:water_flowing"])

	sdef.damage_per_second = 1
	fdef.damage_per_second = 1

	sdef.liquid_alternative_flowing = "cw:water_flowing"
	sdef.liquid_alternative_source = "cw:water_source"

	fdef.liquid_alternative_flowing = "cw:water_flowing"
	fdef.liquid_alternative_source = "cw:water_source"

	minetest.register_node("cw:water_source", sdef)
	minetest.register_node("cw:water_flowing", fdef)
end

cw.REALM_START = 3050
cw.BEDROCK_DEPTH = 4
cw.OCEAN_DEPTH = 16
cw.GROUND_DEPTH = 11
cw.GROUND_HEIGHT_VARIATION = 4

-- Controls land height.
cw.noise1param2d = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = 3717,
	octaves = 5,
	persist = 0.5,
	lacunarity = 2,
}

cw.noise2param2d = {
	offset = 0,
	scale = 1,
	spread = {x=32, y=32, z=32},
	seed = 5817,
	octaves = 4,
	persist = 0.8,
	lacunarity = 2,
}

-- Content IDs used with the voxel manipulator.
local c_air             = minetest.get_content_id("air")
local c_ignore          = minetest.get_content_id("ignore")
local c_stone           = minetest.get_content_id("default:stone")
local c_bedrock         = minetest.get_content_id("bedrock:bedrock")
local c_water           = minetest.get_content_id("cw:water_source")
local c_dirt            = minetest.get_content_id("darkage:darkdirt")
local c_silt            = minetest.get_content_id("darkage:silt")
local c_mud             = minetest.get_content_id("darkage:mud")

-- Externally located tables for performance.
local data = {}
local noisemap1 = {}
local noisemap2 = {}

local JUNGLETREE_REPLACEMENTS = {
	["default:jungletree"] = "basictrees:jungletree_cube",
	["default:jungleleaves"] = "basictrees:jungletree_leaves2",
}

local RANDPOS = {
	{x=1, y=0, z=0},
	{x=-1, y=0, z=0},
	{x=0, y=0, z=1},
	{x=0, y=0, z=-1},

	-- 3 times to increase probability.
	{x=0, y=0, z=0},
	{x=0, y=0, z=0},
	{x=0, y=0, z=0},
}

cw.generate_realm = function(minp, maxp, seed)
	local nstart = cw.REALM_START

	-- Don't run for out-of-bounds mapchunks.
	local nfinish = nstart + 100
	if minp.y > nfinish or maxp.y < nstart then
		return
	end

	-- Grab the voxel manipulator.
	-- Read current map data.
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(data)
	local area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}

	local pr = PseudoRandom(seed + 381)

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
	local perlin1 = minetest.get_perlin_map(cw.noise1param2d, sides2D)
	perlin1:get2dMap_flat(bp2d, noisemap1)
	local perlin2 = minetest.get_perlin_map(cw.noise2param2d, sides2D)
	perlin2:get2dMap_flat(bp2d, noisemap2)

	-- Localize commonly used functions.
	local floor = math.floor
	local ceil = math.ceil
	local abs = math.abs

	local od = cw.OCEAN_DEPTH
	local bd = cw.BEDROCK_DEPTH
	local gd = cw.GROUND_DEPTH
	local ghv = cw.GROUND_HEIGHT_VARIATION

	local tree_positions1 = {}

	-- First mapgen pass.
	for z = z0, z1 do
		for x = x0, x1 do
			-- Get index into 2D noise arrays.
			local nx = (x-x0)
			local nz = (z-z0)
			local ni2 = (side_len_z*nz+nx)
			-- Lua arrays start indexing at 1, not 0. Urrrrgh.
			ni2 = ni2 + 1

			local n1 = noisemap1[ni2]
			local n2 = noisemap2[ni2]

			-- Randomize height of the bedrock a bit.
			local bedrock_adjust = (nstart + bd + pr:next(0, pr:next(1, 2)))

			-- Fixed ocean height.
			local ocean_depth = (nstart + od)

			-- Ground height.
			local an1 = abs(n1)
			local ground_depth = (nstart + gd + floor(an1 * ghv))
			local water_depth = (ocean_depth - ground_depth)

			if water_depth <= 2 then
				if pr:next(1, 16) == 1 then
					tree_positions1[#tree_positions1+1] = {x=x, y=ground_depth, z=z, w=an1}
				end
			elseif water_depth == 3 then
				if pr:next(1, 40) == 1 then
					tree_positions1[#tree_positions1+1] = {x=x, y=ground_depth, z=z, w=an1}
				end
			elseif water_depth == 4 then
				if pr:next(1, 300) == 1 then
					tree_positions1[#tree_positions1+1] = {x=x, y=ground_depth, z=z, w=an1}
				end
			end

			-- First pass through column.
			for y = y0, y1 do
				local vp = area:index(x, y, z)
				if y >= nstart and y <= nfinish then
					-- Get what's already here.
					local cid = data[vp]

					if cid == c_air or cid == c_ignore then
						-- Place bedrock layer.
						if y <= bedrock_adjust then
							data[vp] = c_bedrock
						elseif y < ground_depth then
							data[vp] = c_dirt
						elseif y == ground_depth then
							-- Mud appears when silt rises to water surface and above.
							if gd >= od then
								data[vp] = c_mud
							else
								data[vp] = c_silt
							end
						elseif y <= ocean_depth then
							data[vp] = c_water
						end
					end
				end

			end
		end
	end

	-- Finalize voxel manipulator.
	-- Note: we specifically do not generate ores! The value of this realm is in
	-- its trees.
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()

	for k, v in ipairs(tree_positions1) do
		local w = v.w
		if w > 1.0 then
			w = 1.0
		end
		local h = 13 * w
		v.w = nil

		-- Schematic horizontal offset.
		v.x = v.x - 2
		v.z = v.z - 2

		local path = basictrees.modpath .. "/schematics/jungle_tree_cw.mts"
		local path2 = cw.worldpath .. "/cw_jungletree.mts"
		local path3 = path2

		if h > 10 then
			path2 = path
		end

		local force_place = false
		minetest.place_schematic(v, path, "random", JUNGLETREE_REPLACEMENTS, force_place)

		if pr:next(1, 5) <= 4 then
			v.y = v.y + h
			if h > 10 then
				minetest.place_schematic(vector.add(v, RANDPOS[math.random(1, #RANDPOS)]), path2, "random", JUNGLETREE_REPLACEMENTS, force_place)
			else
				minetest.place_schematic(v, path2, "random", JUNGLETREE_REPLACEMENTS, force_place)
			end

			if pr:next(1, 3) <= 2 then
				v.y = v.y + h
				if h > 10 then
					minetest.place_schematic(vector.add(v, RANDPOS[math.random(1, #RANDPOS)]), path2, "random", JUNGLETREE_REPLACEMENTS, force_place)
				else
					minetest.place_schematic(v, path2, "random", JUNGLETREE_REPLACEMENTS, force_place)
				end

				if h >= 10 then
					if pr:next(1, 2) == 1 then
						v.y = v.y + 13
						minetest.place_schematic(v, path3, "random", JUNGLETREE_REPLACEMENTS, force_place)

						if h > 10 and pr:next(1, 3) == 1 then
							v.y = v.y + 13
							minetest.place_schematic(v, path3, "random", JUNGLETREE_REPLACEMENTS, force_place)
						end
					end
				elseif h >= 8 then
					if pr:next(1, 3) == 1 then
						v.y = v.y + 12
						minetest.place_schematic(v, path3, "random", JUNGLETREE_REPLACEMENTS, force_place)
					end
				end
			end
		end
	end
end



if not cw.registered then
	-- Register the mapgen callback.
	if minetest.settings:get_bool("enable_channelwood", false) then
		minetest.register_on_generated(function(...)
			cw.generate_realm(...)
		end)
	end

	local c = "cw:core"
	local f = cw.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	cw.registered = true
end

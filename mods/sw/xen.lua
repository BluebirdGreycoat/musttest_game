
local REALM_START = 10150
local REALM_END = 15150
local REALM_GROUND = 10150+200
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
local mod = math.fmod
local distance = vector.distance

local function clamp(v, minv, maxv)
	return max(minv, min(v, maxv))
end
-- my random change
-- another random change
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_stone = minetest.get_content_id("sw:teststone1")
local c_gravel = minetest.get_content_id("default:gravel")
local c_worm = minetest.get_content_id("cavestuff:glow_worm")
local c_fungus = minetest.get_content_id("cavestuff:glow_fungus")
local c_midnight_sun = minetest.get_content_id("aradonia:caveflower6")
local c_fire_lantern = minetest.get_content_id("aradonia:caveflower11")
local c_candle_flower = minetest.get_content_id("aradonia:caveflower12")
local c_fairy_flower = minetest.get_content_id("aradonia:caveflower8")
local c_red_vine = minetest.get_content_id("nethervine:vine")
local c_dirt = minetest.get_content_id("default:dirt")
local c_cobble_slab = minetest.get_content_id("stairs:slab_cobble")

--[[
local C_CRYSTALS = {
	minetest.get_content_id("mese_crystals:mese_crystal_ore1"),
	minetest.get_content_id("mese_crystals:mese_crystal_ore2"),
	minetest.get_content_id("mese_crystals:mese_crystal_ore3"),
	minetest.get_content_id("mese_crystals:mese_crystal_ore4"),
	minetest.get_content_id("mese_crystals:mese_crystal_ore5"),
}
--]]

local vm_data = {}
local vm_light = {}
local param2_data = {}

-- Main shape of Xen islands.
sw.create_3d_noise("xen1", {
	offset = 0,
	scale = 1,
	spread = {x=180, y=60, z=180},
	seed = 88192,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Where Xen spawns.
sw.create_2d_noise("xen2", {
	offset = 0,
	scale = 1,
	spread = {x=100, y=100, z=100},
	seed = 4712,
	octaves = 1,
	persist = 0.5,
	lacunarity = 2,
})

-- Holes in Xen. A gift for those who don't look where they step.
sw.create_2d_noise("xen4", {
	offset = 0,
	scale = 1,
	spread = {x=40, y=40, z=40},
	seed = 4782,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Xen Y level.
sw.create_2d_noise("xen3", {
	offset = 0,
	scale = 200,
	spread = {x=800, y=800, z=800},
	seed = 66172,
	octaves = 3,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Large scale void spaces.
sw.create_2d_noise("xen5", {
	offset = 0,
	scale = 1,
	spread = {x=2000, y=2000, z=2000},
	seed = 18349,
	octaves = 6,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Small floating rocks scattered near larger islands.
sw.create_3d_noise("xen6", {
	offset = 0,
	scale = 1,
	spread = {x=12, y=12, z=12},
	seed = 58812,
	octaves = 2,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Caves.
sw.create_3d_noise("xen7", {
	offset = 0,
	scale = 1,
	spread = {x=16, y=16, z=16},
	seed = 77193,
	octaves = 2,
	persist = 0.5,
	lacunarity = 1.75,
})

-- Xen biome locations.
sw.create_3d_noise("xen8", {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = 485321,
	octaves = 2,
	persist = 0.4,
	lacunarity = 1.75,
})

-- Huge islands big enough for internal caverns.
sw.create_2d_noise("xen9", {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = 172882,
	octaves = 3,
	persist = 0.5,
	lacunarity = 2,
})

function sw.generate_xen(vm, minp, maxp, seed, shear1, shear2, gennotify_data)
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > XEN_END or maxp.y < XEN_BEGIN then
		return
	end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PcgRandom(seed + 728)

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

	vm:get_data(vm_data)
	--vm:get_param2_data(param2_data)

	local xen1 = sw.get_3d_noise(bp3d, sides3D, "xen1")
	local xen2 = sw.get_2d_noise(bp2d, sides2D, "xen2")
	local xen3 = sw.get_2d_noise(bp2d, sides2D, "xen3")
	local xen4 = sw.get_2d_noise(bp2d, sides2D, "xen4")
	local xen5 = sw.get_2d_noise(bp2d, sides2D, "xen5")
	local xen6 = sw.get_3d_noise(bp3d, sides3D, "xen6")
	local xen7 = sw.get_3d_noise(bp3d, sides3D, "xen7")
	local xen9 = sw.get_2d_noise(bp2d, sides2D, "xen9")

	local REPORTED = false

	-- Returns several boolean values:
	-- 1: whether to place stone or air
	-- 2: whether the location represents a hollow cavern.
	local function is_xen(vp3d, x, y, z)
		local vp3d_steady = vp3d

		-- Shear the 2D noise coordinate offset.
		local shear_x	= floor(x + shear1[vp3d])
		local shear_z = floor(z + shear2[vp3d])

		shear_x = clamp(shear_x, emin.x, emax.x)
		shear_z = clamp(shear_z, emin.z, emax.z)

		local vp2d = area2d:index(shear_x, shear_z)
		vp3d = area:index(shear_x, y, shear_z)

		local n1 = xen1[vp3d]
		local n2 = xen2[vp2d] -- For large islands and voids.
		local n3 = xen3[vp2d] -- Xen Y-level offset.
		local n4 = xen4[vp2d] -- Holes.
		local n5 = xen5[vp2d] -- Huge void areas.
		local n6 = xen6[vp3d_steady] -- Floating rocks near larger islands.
		local n7 = xen7[vp3d] -- Cave systems.
		local n9 = xen9[vp2d] -- Huge islands.

		local xen_mid = floor(((XEN_BEGIN+XEN_END)/2)+n3)
		local xen_middiff_up = floor(XEN_END - xen_mid)
		local xen_middiff_dn = floor(xen_mid - XEN_BEGIN)

		-- Extinction value shall be 1 at XEN MID, and 0 at both top and bottom.
		-- Using exponential falloff.
		local extinction
		if y >= xen_mid then
			extinction = ((XEN_END - y) / xen_middiff_up)
		else
			extinction = ((y - XEN_BEGIN) / xen_middiff_dn)
		end
		extinction = clamp(extinction, 0, 1)
		extinction = extinction * extinction * extinction * extinction

		local islands_and_voids = clamp(abs(n2), 0, 1)
		islands_and_voids = islands_and_voids * islands_and_voids
		islands_and_voids = islands_and_voids - 0.25

		local largescale = clamp(n5, -1, 1) * 0.2

		-- For huge islands (where negative), and where positive, absolutely empty areas.
		-- Most values should hover around 0. Range [-1.75 .. 1.75], before extinction applies.
		local masscale = clamp(n9, -1, 1)
		--if not REPORTED then
		--	REPORTED = true
		--	print('masscale: ' .. masscale)
		--end

		-- 3x multiply should preserve the sign.
		masscale = masscale * masscale * masscale
		--if masscale < 0 then
		--	masscale = masscale ^ 2
		--end

		--local massivescale = (masscale * extinction)
		--local massivescale = masscale * -1.75 * extinction
		-- For testing:
		--local massivescale = -1.75 * extinction

		local left_side = (n1 + (abs(n4) * 0.25) - islands_and_voids + largescale + masscale) * extinction
		local right_side1 = (-1.25 + extinction)
		local right_side2 = (-1.0 + extinction)

		if left_side < right_side1 then
			-- Carve out cave systems.
			-- For some reason using abs() here makes chunkgen take x3 as long,
			-- but we don't really need it anyway, these look OK.
			if n7 > 0.7 then
				return false, false
			end
			-- Hollow caverns inside the big ones.
			if left_side + 0.8 < right_side1 then
				return false, true
			end
			return true, false
		end

		-- Place clusters of small islands around the edges of the big ones.
		if left_side < right_side2 then
		--if left_side - 0.5 < right_side1 then
			-- There are three layers of small islands.
			for n = -1, 1, 1 do
				-- Left and right sides of this equation are:
				-- :if within layer:             :round top/bottom:
				if abs(y - (xen_mid + n * 100)) < (5 + abs(n6) * 3) then
					if n6 < -0.5 or n6 > 0.5 then
						return true, false
					end
				end
			end
		end

		return false, false
	end

	local cavern_hints = gennotify_data.cavern_hints

	-- Shape terrain.
	for z = z0, z1 do
		for y = y0, y1 do
			if y >= REALM_START and y <= REALM_END then
				local vp = area:index(x0, y, z)

				for x = x0, x1 do
					local cid = vm_data[vp]

					if cid == c_air or cid == c_ignore then
						local xen, cavern = is_xen(vp, x, y, z)

						if xen then
							vm_data[vp] = c_stone
						else
							vm_data[vp] = c_air
						end

						if cavern then
							if mod(x, 16) == 0 and mod(y, 16) == 0 and mod(z, 16) == 0 then
								cavern_hints[#cavern_hints+1] = {x=x, y=y, z=z}
							end
						end
					end

					vp = vp + 1
				end
			end
		end
	end

	vm:set_data(vm_data)
	--vm:set_param2_data(param2_data)
end



-- Lua tip: never create closures inside a hot loop.
-- Tanks ur performance HARD.
local function fill_hollows(vm_data, area, base_idx)
	local ystride = area.ystride
	local zstride = area.zstride

	local up = base_idx + ystride * 3
	local cid_ground = vm_data[base_idx - ystride]
	local cid_replace = vm_data[base_idx]

	if cid_ground ~= c_stone or cid_replace ~= c_stone then
		return
	end

	local cid_air = vm_data[base_idx + ystride]
	if cid_air ~= c_air then
		return
	end

	local cid_above_air = vm_data[up]
	if cid_above_air ~= c_air then
		return
	end

	local cid_above_n = vm_data[up + zstride * 8]
	local cid_above_s = vm_data[up - zstride * 8]
	local cid_above_e = vm_data[up + 8]
	local cid_above_w = vm_data[up - 8]

	local count = 0
	if cid_above_n == c_stone then count = count + 1 end
	if cid_above_s == c_stone then count = count + 1 end
	if cid_above_e == c_stone then count = count + 1 end
	if cid_above_w == c_stone then count = count + 1 end

	if count >= 4 then
		vm_data[base_idx] = c_dirt
	elseif count >= 3 then
		vm_data[base_idx] = c_gravel
	end

	local dn = base_idx - ystride * 2

	-- This check prevents placing obsidian on the little islands.
	if vm_data[base_idx - ystride * 12] == c_stone then
		local cid_below_n = vm_data[dn + zstride * 8]
		local cid_below_s = vm_data[dn - zstride * 8]
		local cid_below_e = vm_data[dn + 8]
		local cid_below_w = vm_data[dn - 8]

		local bcount = 0
		if cid_below_n == c_air then bcount = bcount + 1 end
		if cid_below_s == c_air then bcount = bcount + 1 end
		if cid_below_e == c_air then bcount = bcount + 1 end
		if cid_below_w == c_air then bcount = bcount + 1 end

		-- No stone above and air below.
		if count == 0 and bcount >= 3 then
			vm_data[base_idx] = c_cobble_slab
		end
	end
end



function sw.generate_xen_biome(vm, minp, maxp, seed)
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Don't run for out-of-bounds mapchunks.
	if minp.y > XEN_END or maxp.y < XEN_BEGIN then
		return
	end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PcgRandom(seed + 728)

	--print('ystride: ' .. area.ystride)
	--print('zstride: ' .. area.zstride)

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

	vm:get_data(vm_data)

	for z = z0, z1 do
		for y = y0, y1 do
			if y >= REALM_START and y <= REALM_END then
				local base_idx = area:index(x0, y, z)
				for x = x0, x1 do
					fill_hollows(vm_data, area, base_idx)
					base_idx = base_idx + 1
				end
			end
		end
	end

	vm:set_data(vm_data)
end


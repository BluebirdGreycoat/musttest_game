
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
local distance = vector.distance

local function clamp(v, minv, maxv)
	return max(minv, min(v, maxv))
end

local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_stone = minetest.get_content_id("sw:teststone1")
local c_worm = minetest.get_content_id("cavestuff:glow_worm")
local c_fungus = minetest.get_content_id("cavestuff:glow_fungus")
local c_midnight_sun = minetest.get_content_id("aradonia:caveflower6")
local c_fire_lantern = minetest.get_content_id("aradonia:caveflower11")
local c_candle_flower = minetest.get_content_id("aradonia:caveflower12")
local c_fairy_flower = minetest.get_content_id("aradonia:caveflower8")
local c_red_vine = minetest.get_content_id("nethervine:vine")

local vm_data = {}
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
	scale = 500,
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

function sw.generate_xen(vm, minp, maxp, seed, shear1, shear2)
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

	local function is_xen(x, y, z)
		local vp3d = area:index(x, y, z)
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
		local n3 = 0--xen3[vp2d] -- Xen Y-level offset.
		local n4 = xen4[vp2d] -- Holes.
		local n5 = xen5[vp2d] -- Huge void areas.
		local n6 = xen6[vp3d_steady] -- Floating rocks near larger islands.
		local n7 = xen7[vp3d] -- Cave systems.

		local xen_mid = math.floor(((XEN_BEGIN+XEN_END)/2)+n3)
		local xen_middiff_up = math.floor(XEN_END - xen_mid)
		local xen_middiff_dn = math.floor(xen_mid - XEN_BEGIN)

		-- Extinction value shall be 1 at XEN MID, and 0 at both top and bottom.
		-- Using exponential falloff.
		local extinction
		if y >= xen_mid then
			extinction = ((XEN_END - y) / xen_middiff_up)
		else
			extinction = ((y - XEN_BEGIN) / xen_middiff_dn)
		end
		extinction = clamp(extinction, 0, 1)
		extinction = tan(extinction ^ 4) / TAN_OF_1

		local islands_and_voids = clamp(abs(n2), 0, 1)
		islands_and_voids = tan(islands_and_voids) / TAN_OF_1
		islands_and_voids = islands_and_voids - 0.25

		local largescale = clamp(n5, -1, 1) * 0.2

		local left_side = (n1 + (abs(n4) * 0.25) - islands_and_voids + largescale)
		local right_side1 = (-1.25 + extinction)
		local right_side2 = (-1.0 + extinction)

		if left_side < right_side1 then
			-- Carve out cave systems.
			-- For some reason using abs() here makes chunkgen take x3 as long,
			-- but we don't really need it anyway, these look OK.
			if n7 > 0.7 then
				return false
			end
			return true
		end

		-- Place clusters of small islands around the edges of the big ones.
		if left_side < right_side2 then
			-- Left and right sides of this equation are:
			-- :keep in 1 layer:    :round top/bottom:
			if abs(y - xen_mid) < (5 + abs(n6) * 3) then
				if n6 < -0.5 or n6 > 0.5 then
					return true
				end
			end
		end
	end

	-- Shape terrain.
	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= REALM_START and y <= REALM_END then
					local vp = area:index(x, y, z)
					local cid = vm_data[vp]

					if cid == c_air or cid == c_ignore then
						if is_xen(x, y, z) then
							vm_data[vp] = c_stone
						else
							vm_data[vp] = c_air
						end
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
	--vm:set_param2_data(param2_data)
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

	local floors = {}
	local ceilings = {}

	-- Find biome surfaces.
	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= REALM_START and y <= REALM_END then
					local vp_1 = area:index(x, y-1, z)
					local vp_2 = area:index(x, y, z)
					local vp_3 = area:index(x, y+1, z)

					local c1 = vm_data[vp_1]
					local c2 = vm_data[vp_2]
					local c3 = vm_data[vp_3]

					-- Ground surface.
					if c1 == c_stone and c2 == c_air and c3 == c_air then
						floors[#floors+1] = {x=x, y=y-1, z=z}
					end

					-- Roof surface.
					if c1 == c_air and c2 == c_air and c3 == c_stone then
						ceilings[#ceilings+1] = {x=x, y=y+1, z=z}
					end
				end
			end
		end
	end

	for k = 1, #floors do
		local p = floors[k]
		if pr:next(1, 7) == 1 then
			local vp = area:index(p.x, p.y+1, p.z)
			local plant_id = c_fungus
			local rnd1 = pr:next(1, 100)
			if rnd1 <= 5 then
				local ceiling_cid = vm_data[area:index(p.x, p.y+15, p.z)]
				-- Chose plant type.
				if ceiling_cid == c_stone then
					plant_id = c_midnight_sun
				elseif ceiling_cid == c_air then
					if pr:next(1, 5) <= 3 then
						plant_id = c_candle_flower
					else
						plant_id = c_fire_lantern
					end
				end
			elseif rnd1 <= 10 then
				-- Place fairy flowers in open areas only.
				-- We need 32 nodes to chunk top in order to run this check.
				if p.y + 32 <= emax.y then
					local j1 = p.y + 16
					local j2 = p.y + 32
					if vm_data[area:index(p.x, j1, p.z)] == c_air
					   and vm_data[area:index(p.x, j2, p.z)] == c_air then
						plant_id = c_fairy_flower
					end
				end
			end
			vm_data[vp] = plant_id
		end
	end

	for k = 1, #ceilings do
		local p = ceilings[k]
		if pr:next(1, 7) == 1 then
			-- Chose whether to place glow worm or nether vine.
			-- Nether vines grow in proximity to floors.
			local vine_id = c_worm
			if vm_data[area:index(p.x, p.y-15, p.z)] == c_stone then
				vine_id = c_red_vine
			end

			local length = pr:next(1, 4)
			-- Sometimes, a long glow worm/vine.
			if pr:next(1, 50) == 1 then
				length = pr:next(5, 16)
			end
			for j = 1, length do
				-- Keep Y in chunk bounds.
				local cd = p.y - j
				if cd >= emin.y and cd <= emax.y then
					local vp = area:index(p.x, cd, p.z)
					-- Don't erase anything existing (like stone).
					if vm_data[vp] == c_air then
						vm_data[vp] = vine_id
					end
				end
			end
		end
	end

	vm:set_data(vm_data)
	--vm:set_param2_data(param2_data)
end



local REALM_START = 10150
local REALM_END = 15150
local LAVA_SEA_HEIGHT = 10170

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min

local vm_data = {}
local param2_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_cobble = minetest.get_content_id("default:cobble")
local c_gravel = minetest.get_content_id("default:gravel")
local c_stone = minetest.get_content_id("default:stone")
local c_lava = minetest.get_content_id("lbrim:lava_source")
local c_midnight_sun = minetest.get_content_id("aradonia:caveflower6")



function sw.generate_caverns(vm, minp, maxp, seed, get_height)
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Skip generating caverns at surface and above.
  --if y0 >= (get_height(x0, z0) - 150) then
	--	return
	--end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local pr = PcgRandom(seed + 728)

	vm:get_data(vm_data)
	vm:get_param2_data(param2_data)

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

	local noisemap1 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise1")
	local noisemap2 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise2")
	local noisemap3 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise3")
	local noisemap4 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise4")
	local noisemap5 = sw.get_3d_noise(bp3d, sides3D, "cavern_noise5")

	local function is_cavern(x, y, z, ground_y)
		local idx = area:index(x, y, z)

		local n1 = noisemap1[idx]
		local n2 = noisemap2[idx]
		local n3 = noisemap3[idx]
		local n4 = noisemap4[idx]
		local n5 = noisemap5[idx]

		if y < (ground_y - (500 + (abs(n4) * 50))) then
			local noise1 = n1 + n2 + n3
			local noise2 = abs(n5)
			if noise1 < -0.2 then
				if noise1 > -0.3 and noise2 > 0.2 then
					return false
				end
				return true
			end
		end

		return false
	end

	-- First, carve out the caverns.
	for z = z0, z1 do
		for x = x0, x1 do
			local ground_y = get_height(x, z)

			for y = y0, y1 do
				if is_cavern(x, y, z, ground_y) then
					local vp = area:index(x, y, z)
					local cid = vm_data[vp]

					-- Do NOT carve caverns through bedrock or "ignore".
					-- Skip air since there's nothing there anyway.
					if cid ~= c_air and cid ~= c_ignore and cid ~= c_bedrock then
						if y <= LAVA_SEA_HEIGHT then
							vm_data[vp] = c_lava
						else
							vm_data[vp] = c_air
						end
					end
				end
			end
		end
	end

	local floortargets = {}
	local ceilingtargets = {}

	-- Second, find floors and ceilings for decorations.
	for z = z0, z1 do
		for x = x0, x1 do
			local ground_y = get_height(x, z)

			for y = y0, y1 do
				if is_cavern(x, y, z, ground_y) then
					local vd2 = area:index(x, y-2, z)
					local vd1 = area:index(x, y-1, z) -- Surface.
					local vp = area:index(x, y, z) -- Air above.
					local vu1 = area:index(x, y+1, z)
					local vu2 = area:index(x, y+2, z)

					-- Detect floors.
					if vm_data[vp] == c_air and vm_data[vd1] == c_stone and vm_data[vd2] == c_stone
					   and vm_data[vu1] == c_air and vm_data[vu2] == c_air then
						vm_data[vd1] = c_cobble
						floortargets[#floortargets+1] = {x=x, y=y, z=z}
					end

					-- Detect ceilings.
					if vm_data[vp] == c_air and vm_data[vu1] == c_stone and vm_data[vu2] == c_stone
					   and vm_data[vd1] == c_air and vm_data[vd2] == c_air then
						vm_data[vu1] = c_cobble
						ceilingtargets[#ceilingtargets+1] = {x=x, y=y, z=z}
					end
				end
			end
		end
	end

	local function choose_item(items)
		if type(items) == "table" then
			local item = items[pr:next(1, #items)]
			if type(item) == "table" then
				return item.id, item.param2 or 0
			else
				-- It should be a single content ID.
				return item, 0
			end
		else
			-- It should be a single content ID.
			return items, 0
		end
	end

	local function place_items(positions, items)
		for k = 1, #positions do
			local p = positions[k]
			local vp = area:index(p.x, p.y, p.z)
			local cid, pm2 = choose_item(items)
			vm_data[vp] = cid
			param2_data[vp] = pm2
		end
	end

	local flowers = {}
	for k = 1, #floortargets do
		if pr:next(1, 256) == 1 then
			flowers[#flowers+1] = floortargets[k]
		end
	end

	place_items(flowers, c_midnight_sun)

	vm:set_data(vm_data)
	vm:set_param2_data(param2_data)
end

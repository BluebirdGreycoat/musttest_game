
local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_cobble = minetest.get_content_id("rackstone:cobble")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min

function ab.generate_biome(vm, minp, maxp, seed, ystart, yend, heightfunc)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PseudoRandom(seed + 418)

	vm:get_data(vm_data)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local grass = {}
	local trees = {}

	local function chose_ground_decor(x, y, z)
		if pr:next(1, 100) == 1 then
			trees[#trees + 1] = {x=x, y=y, z=z}
		elseif pr:next(1, 10) == 1 then
			grass[#grass + 1] = {x=x, y=y+1, z=z}
		end
	end

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= ystart and y <= yend then
					local vp_c = area:index(x, y, z)
					local vp_u = area:index(x, y + 1, z)

					local cid_c = vm_data[vp_c]
					local cid_u = vm_data[vp_u]

					if cid_c ~= c_air and cid_c ~= c_ignore and cid_c ~= c_bedrock then
						if cid_u == c_air then
							-- We have found a surface.
							local ground_y = heightfunc(x, y, z)

							vm_data[vp_c] = c_cobble

							if y >= ground_y then
								chose_ground_decor(x, y, z)
							end
						end
					end
				end
			end
		end
	end

	vm:set_data(vm_data)

  for k = 1, #trees do
		ab.place_acacia_tree(vm, trees[k])
  end

  for k = 1, #grass do
		if pr:next(1, 8) == 1 then
			minetest.set_node(grass[k], {name="default:dry_shrub"})
		else
			minetest.set_node(grass[k], {name="default:dry_grass2_" .. pr:next(1, 5), param2=2})
		end
  end
end

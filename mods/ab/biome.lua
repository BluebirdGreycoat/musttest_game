
local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_stone = minetest.get_content_id("rackstone:rackstone")
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

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= ystart and y <= yend then
					local vp_c = area:index(x, y, z)
					local vp_u = area:index(x, y + 1, z)

					local cid_c = vm_data[vp_c]
					local cid_u = vm_data[vp_u]

					if cid_c == c_stone and cid_u == c_air then
						-- We have found a surface.
						local ground_y, canyon_offset = heightfunc(x, y, z)

						-- Only cobble the surface, skip caves.
						if y == ground_y then
							vm_data[vp_c] = c_cobble
						end

						if y >= ground_y then
							local grassed = false
							if pr:next(1, 6) == 1 then
								grass[#grass + 1] = {x=x, y=y+1, z=z}
								grassed = true
							end

							if canyon_offset < 0 and not grassed then
								if pr:next(1, 100) == 1 then
									trees[#trees + 1] = {x=x, y=y, z=z}
								end
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
		if pr:next(1, 7) == 1 then
			minetest.set_node(grass[k], {name="default:dry_shrub"})
		else
			minetest.set_node(grass[k], {name="default:dry_grass2_" .. pr:next(1, 5), param2=2})
		end
  end
end


local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_stone = minetest.get_content_id("default:stone")
local c_cobble = minetest.get_content_id("default:cobble")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_obsidian = minetest.get_content_id("default:obsidian")
local c_gravel = minetest.get_content_id("default:gravel")

local NN_DEAD_CORAL = "default:coral_skeleton"

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min

-- Param2 horizontal branch rotations.
local branch_rotations = {4, 8, 12, 16}
local branch_directions = {2, 0, 3, 1}

local sphere_base_locations = {
	{x=1, y=0, z=0},
	{x=-1, y=0, z=0},
	{x=0, y=0, z=1},
	{x=0, y=0, z=-1},
	{x=1, y=1, z=0},
	{x=-1, y=1, z=0},
	{x=0, y=1, z=1},
	{x=0, y=1, z=-1},
	{x=1, y=0, z=1},
	{x=1, y=0, z=-1},
	{x=-1, y=0, z=1},
	{x=-1, y=0, z=-1},
	{x=1, y=1, z=1},
	{x=1, y=1, z=-1},
	{x=-1, y=1, z=1},
	{x=-1, y=1, z=-1},
}

function sw.generate_biome(vm, minp, maxp, seed, ystart, yend, heightfunc)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PcgRandom(seed + 592)

	--print('pos: ' .. minetest.pos_to_string(minp) .. ', blockseed: ' .. seed .. ', rnd: ' .. pr:next())

	vm:get_data(vm_data)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local grass = {}
	local deadcorals = {}

	local function generate_deco_positions(tb, mapchunk_chance, count, cluster_count, cluster_rad)
		if pr:next(1, mapchunk_chance) == 1 then
			for k = 1, count do
				local x = x0 + pr:next(0, (x1 - x0))
				local z = z0 + pr:next(0, (z1 - z0))

				tb[#tb + 1] = {
					x = x,
					z = z,
				}

				for i = 1, cluster_count do
					tb[#tb + 1] = {
						x = x + pr:next(-cluster_rad, cluster_rad),
						z = z + pr:next(-cluster_rad, cluster_rad),
					}
				end
			end
		end
	end

	generate_deco_positions(deadcorals, 3, 3, pr:next(3, 6), 2)
	generate_deco_positions(grass, 1, 50, 3, 2)

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= ystart and y <= yend then
					local vp_c = area:index(x, y, z)
					local vp_u = area:index(x, y + 1, z)

					local cid_c = vm_data[vp_c]
					local cid_u = vm_data[vp_u]

					if cid_c ~= c_air and cid_c ~= c_ignore and cid_c ~= c_obsidian and cid_u == c_air then
						-- We have found a surface.
						local ground_y = heightfunc(x, y, z)

						-- Only cobble the surface, skip caves.
						if y == ground_y then
							vm_data[vp_c] = c_cobble

							-- Surround base of obsidian spheres with special material.
							for k = 1, #sphere_base_locations do
								local v = sphere_base_locations[k]
								local c = vm_data[area:index(x+v.x, y+v.y, z+v.z)]
								if c == c_obsidian then
									vm_data[vp_c] = c_gravel
									break
								end
							end
						end
					end
				end
			end
		end
	end

	vm:set_data(vm_data)

  local function place_ground_decorations(decolist, decofunc)
		for k = 1, #decolist do
			local x = decolist[k].x
			local z = decolist[k].z
			for y = y1, y0, -1 do
				if y >= ystart and y <= yend then
					local vp_c = area:index(x, y, z)
					local vp_u = area:index(x, y + 1, z)
					local ground_y = heightfunc(x, y, z)

					local cid_c = vm_data[vp_c]
					local cid_u = vm_data[vp_u]

					if cid_c == c_cobble and cid_u == c_air then
						if y >= ground_y then
							-- On surface, not in canyon or mesa.
							local p = {x=x, y=y, z=z}
							decofunc(p)

							-- Goto next item.
							break
						end
					end
				end
			end
		end
	end

	local function put_deadcoral(pos)
		local p = vector.offset(pos, 0, 1, 0)
		local n = pr:next(2, 3)

		if pr:next(1, 6) == 1 then
			for i = 1, n do
				minetest.set_node(p, {name=NN_DEAD_CORAL})
				p = vector.offset(p, 0, 1, 0)
			end
		else
			local diridx = pr:next(1, 4)
			local facedir = branch_directions[diridx]
			local vec = minetest.facedir_to_dir(facedir)

			for i = 1, n do
				minetest.set_node(p, {name=NN_DEAD_CORAL})
				p = vector.add(p, vec)
			end
		end
  end

  local function put_grass(pos)
		local p = vector.offset(pos, 0, 1, 0)
		minetest.set_node(p, {name="default:dry_shrub"})
	end

	place_ground_decorations(grass, put_grass)
	place_ground_decorations(deadcorals, put_deadcoral)
end

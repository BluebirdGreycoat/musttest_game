
-- List of allowed chest nodes.
local CHEST_NAMES = {
	-- Duplicated for probability.
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",
	"chests:chest_public_closed",
	"chests:chest_public_closed",
	"morechests:ironchest_public_closed",
}

local POS_TO_STR = minetest.pos_to_string



function fortress.v2.write_map(params)
	local minp = table.copy(params.spawn_pos)
	local maxp = table.copy(params.spawn_pos)

	-- Calculate voxelmanip area bounds.
	for _, v in ipairs(params.build.schems) do
		if v.pos.x < minp.x then minp.x = v.pos.x end
		if v.pos.x + v.size.x > maxp.x then maxp.x = v.pos.x + v.size.x end

		if v.pos.y < minp.y then minp.y = v.pos.y end
		if v.pos.y + v.size.y > maxp.y then maxp.y = v.pos.y + v.size.y end

		if v.pos.z < minp.z then minp.z = v.pos.z end
		if v.pos.z + v.size.z > maxp.z then maxp.z = v.pos.z + v.size.z end
	end

	params.log("action", "Writing fortress to map.")
	params.log("action", "POS: " .. POS_TO_STR(params.spawn_pos))
	params.log("action", "MINP: " .. POS_TO_STR(minp))
	params.log("action", "MAXP: " .. POS_TO_STR(maxp))
	params.log("action", "Volume: " .. POS_TO_STR(vector.subtract(maxp, minp)))

	params.vm_minp = minp
	params.vm_maxp = maxp

	local MAPGENTIME0 = os.clock()

	-- Build callback function. When the map is loaded, we can spawn the fortress.
	local cb = function(blockpos, action, calls_remaining)
		-- Check if there was an error.
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			params.log("error", "Failed to emerge area to spawn fortress.")
			return
		end

		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

		local MAPGENTIME1 = os.clock()
		local ELAPSEDTIME = MAPGENTIME1 - MAPGENTIME0
		params.log("action", string.format("%.2f", ELAPSEDTIME) ..
			" seconds elapsed emerging fort region.")

		-- Actually spawn the fortress once map completely loaded.
		fortress.v2.apply_layout(params)

		-- If we stopped prematurely, save important data for a "continuation" run.
		if not params.final_flag then
			-- Clear data NOT needed for a continuation.
			-- This lets continuations write only the new parts of the fort, instead
			-- of rewriting everything all over again.
			params.build.schems = {}
			params.build.chests = {}
			params.vm_minp = nil
			params.vm_maxp = nil
			params.final_flag = false
			fortress.v2.CONTINUATION_PARAMS = params
			params.log("action", "Fortgen params SAVED for continuation.")
		else
			-- Avoid leaking this on a successful run.
			fortress.v2.CONTINUATION_PARAMS = nil
		end
	end

	-- Load entire map region, generating chunks as needed.
	-- Overgenerate ceiling to try to avoid lighting issues in caverns.
	-- Doing this seems to be the trick.
	-- This will FAIL if in cavern, but ceiling is more than 100 nodes up!
	local omaxp = vector.offset(maxp, 0, 100, 0)
	minetest.emerge_area(minp, omaxp, cb)
end



local function place_all_chests(params)
	-- Track how many chests we successfully add, and what types.
	local chest_count = 0
	local totals = {}
	local random = params.yeskings

	for k, v in ipairs(params.build.chests) do
		local p = v.pos
		local n = minetest.get_node(p)
		local f = minetest.get_node(vector.offset(p, 0, -1, 0))

		-- Only if location not already occupied, and floor is brick.
		if n.name == "air" and f.name == "rackstone:brick_black" then
			-- Random chest node and rotation.
			local rotation = random(0, 3)
			local nodename = CHEST_NAMES[random(1, #CHEST_NAMES)]

			minetest.set_node(p, {name=nodename, param2=rotation})
			fortress.add_loot_items(p, v.loot)

			-- Increment totals.
			chest_count = chest_count + 1
			totals[v.loot] = (totals[v.loot] or 0) + 1
		end
	end

	params.log("action", "Spawned " .. chest_count .. " total chests.")
	for loot, count in pairs(totals) do
		params.log("action", "Spawned " .. count .. " " .. loot .. " chests.")
	end
end



-- To be called once map region fully loaded.
function fortress.v2.apply_layout(params)
	local minp = table.copy(params.vm_minp)
	local maxp = table.copy(params.vm_maxp)
	local step = params.step

	if fortress.is_protected(minp, maxp) then
		params.log("error", "Cannot spawn fortress, protection is present.")
		return
	end

	local TIME0 = os.clock()

	local put_schem = minetest.place_schematic_on_vmanip
	local vm = minetest.get_voxel_manip(minp, maxp)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}

	local c_air = minetest.get_content_id("air")
	local c_brick = minetest.get_content_id("rackstone:brick_black")
	local c_block = minetest.get_content_id("rackstone:blackrack_block")
	local c_slab = minetest.get_content_id("stairs:slab_rackstone_brick_black")
	local c_debug = minetest.get_content_id("wool:yellow")
	local c_debug_start = minetest.get_content_id("wool:red")

	-- Note: replacements can only be sensibly defined for the entire fortress
	-- sheet as a whole. Defining custom replacement lists for individual fortress
	-- sections would NOT work the way you expect! Blame Minetest.
	local rp = params.replacements or {}

	-- Sort chunks by priority. Lowest priority first. This matters for schems
	-- that have 'force' == true, since they can overwrite what's already there.
	table.sort(params.build.schems,
		function(a, b) return a.priority < b.priority end)

	for k, v in ipairs(params.build.schems) do
		put_schem(vm, v.pos, v.file, v.rotation, rp, v.force)
	end

	-- Helper to decorate at a particular position.
	local function decorate(vm_data, pos, size)
		local x0 = pos.x
		local y0 = pos.y
		local z0 = pos.z
		local x1 = pos.x + size.x - 1
		local y1 = pos.y + size.y - 1
		local z1 = pos.z + size.z - 1
		local rng = params.yeskings

		for z = z0, z1 do
			for x = x0, x1 do
				for y = y0, y1 do
					local vpu = area:index(x, y - 1, z)
					local vpa = area:index(x, y, z)
					local cidu = vm_data[vpu]
					local cida = vm_data[vpa]
					if cidu == c_brick and cida == c_air then
						if rng(0, 150) == 0 then
							if rng(0, 10) > 0 then
								vm_data[vpu] = c_slab
							else
								vm_data[vpu] = c_air
							end
						elseif rng(0, 200) == 0 then
							vm_data[vpa] = c_slab
						elseif rng(0, 100) == 0 then
							vm_data[vpu] = c_block
						end
					end
				end
			end
		end
	end

	-- Set param2 values of all nodes in chunk to specific values defined by
	-- chunk data.
	local function set_param2(vm_data, vm_param2_data, pos, size, param2nodes)
		local param2 = {}
		for k, v in pairs(param2nodes) do
			param2[minetest.get_content_id(k)] = 0
		end

		local x0 = pos.x
		local y0 = pos.y
		local z0 = pos.z
		local x1 = pos.x + size.x - 1
		local y1 = pos.y + size.y - 1
		local z1 = pos.z + size.z - 1
		local rng = params.yeskings

		for z = z0, z1 do
			for x = x0, x1 do
				for y = y0, y1 do
					local vp = area:index(x, y, z)
					local cid = vm_data[vp]
					local p2 = param2[cid]
					if p2 then vm_param2_data[vp] = p2 end
				end
			end
		end
	end

	-- Wait till all schematics have been placed, then we can do 'vm:get_data().'
	local vm_data = {}
	local vm_param2_data = {}
	vm:get_data(vm_data)
	vm:get_param2_data(vm_param2_data)

	-- This takes place AFTER all schems have already been placed.
	-- Now we can do decorations/param2 adjustments, etc.
	for k, v in ipairs(params.build.schems) do
		decorate(vm_data, v.pos, v.size) -- Pos should be in worldspace.

		if v.set_param2_rotations then
			set_param2(vm_data, vm_param2_data, v.pos, v.size, v.set_param2_rotations)
		end
	end

	if params.bad_chunkpos then
		params.log("error", "Writing debug wool.")

		local function make_worldpos(chunkpos)
			local step = params.step
			local spawn = params.spawn_pos
			local add = vector.add
			local mul = vector.multiply
			local realpos = add(spawn, mul(chunkpos, step))
			return realpos
		end

		local function putwool(vm_data, pos, step, area, content)
			local x0 = pos.x
			local y0 = pos.y
			local z0 = pos.z
			local x1 = pos.x + step.x - 1
			local y1 = pos.y + step.y - 1
			local z1 = pos.z + step.z - 1

			for z = z0, z1 do
				for x = x0, x1 do
					for y = y0, y1 do
						if ((x == x0 or x == x1) and (y == y0 or y == y1)) or
								((x == x0 or x == x1) and (z == z0 or z == z1)) or
									((y == y0 or y == y1) and (z == z0 or z == z1)) then
							local vp = area:index(x, y, z)
							vm_data[vp] = content
						end
					end
				end
			end
		end

		local errorpos = make_worldpos(params.bad_chunkpos)
		local startpos = make_worldpos({x=0, y=0, z=0})

		putwool(vm_data, errorpos, step, area, c_debug)
		putwool(vm_data, startpos, step, area, c_debug_start)
	end

	vm:set_data(vm_data)
	vm:set_param2_data(vm_param2_data)
	vm:write_to_map(true)

	-- Add loot chests.
	place_all_chests(params)

	local TIME1 = os.clock()
	params.log("action", string.format("%.2f", TIME1 - TIME0) ..
		" seconds elapsed writing fort with voxelmanip.")

	-- Last-ditch effort to fix these darn lighting issues.
	mapfix.work(minp, maxp)

	-- Report success, and how long it took.
	params.log("action", "Fortgen completed after " ..
		math.floor(os.time() - params.time) .. " seconds.")
end

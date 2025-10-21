
-- List of allowed chest nodes.
local CHEST_NAMES = {
	-- Duplicated for probability.
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",

	"chests:chest_public_closed",
	"morechests:ironchest_public_closed",
}

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string



function fortress.v2.expand_all_schems(params)
	local spawn_pos = params.spawn_pos
	local chunkstep = params.step
	local vec_add = vector.add
	local vec_mul = vector.multiply

	for poshash, chunkname in pairs(params.traversal.determined) do
		-- Don't repeat if already done.
		if not params.traversal.completed[poshash] then
			local chunkpos = UNHASH_POSITION(poshash)
			local schempos = vec_add(spawn_pos, vec_mul(chunkpos, chunkstep))
			local altname = params.override_chunk_schems[poshash]

			if altname then
				-- If we got IGNORE at this position from 'override_chunk_schems', then
				-- don't place any schematics.
				if altname ~= "IGNORE" then
					local chunkdata = params.chunks[altname]
					fortress.v2.expand_single_schem(schempos, chunkdata, params)
					fortress.v2.collect_chests(schempos, chunkdata, params)
				end
			else
				local chunkdata = params.chunks[chunkname]
				fortress.v2.expand_single_schem(schempos, chunkdata, params)
				fortress.v2.collect_chests(schempos, chunkdata, params)
			end
		end
		-- Mark as done.
		params.traversal.completed[poshash] = true
	end

	minetest.log("action", "Added " .. #params.build.schems ..
		" schematics to fortress layout.")
	minetest.log("action", "Added " .. #params.build.chests ..
		" chests to fortress layout.")
end



function fortress.v2.expand_single_schem(schempos, chunkdata, params)
	-- Obtain relevant parameters for this section of fortress.
	-- A chunk may contain multiple schematics to place, each with their own
	-- parameters and chance to spawn.

	-- Not all chunks specify schems, e.g., "air" chunks.
	if not chunkdata.schem then return end

	-- Calculate size of chunk. This is a rough guess which defaults to the
	-- fortress step size.
	local size = vector.multiply((chunkdata.size or {x=1, y=1, z=1}), params.step)

	-- Add schems which are part of this chunk.
	-- A chunk may have multiple schems with different parameters.
	local thischunk = chunkdata.schem
	for k, v in ipairs(thischunk) do
		local chance = v.chance or 100

		if params.yeskings(1, 100) <= chance then
			local file = v.file
			local path = params.schemdir .. "/" .. file .. ".mts"
			local offset = table.copy(v.offset or {x=0, y=0, z=0})
			local force = true
			local priority = v.priority or 0

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if offset.x_min then
				offset.x = params.yeskings(offset.x_min, offset.x_max)
				offset.x_min = nil
				offset.x_max = nil
			end
			if offset.y_min then
				offset.y = params.yeskings(offset.y_min, offset.y_max)
				offset.y_min = nil
				offset.y_max = nil
			end
			if offset.z_min then
				offset.z = params.yeskings(offset.z_min, offset.z_max)
				offset.z_min = nil
				offset.z_max = nil
			end

			if type(v.force) == "boolean" then
				force = v.force
			end

			local rotation = v.rotation or "0"
			local realschempos = vector.add(schempos, offset)

			-- Add fortress section to construction queue.
			params.build.schems[#params.build.schems + 1] = {
				file = path,
				pos = vector.new(realschempos),
				size = size,
				rotation = rotation,
				force = force,
				replacements = params.replacements,
				priority = priority,
			}
		end
	end
end



function fortress.v2.write_map(params)
	local minp = table.copy(params.spawn_pos)
	local maxp = table.copy(params.spawn_pos)

	-- Calculate voxelmanip area bounds.
	for k, v in ipairs(params.build.schems) do
		if v.pos.x < minp.x then
			minp.x = v.pos.x
		end
		if v.pos.x + v.size.x > maxp.x then
			maxp.x = v.pos.x + v.size.x
		end

		if v.pos.y < minp.y then
			minp.y = v.pos.y
		end
		if v.pos.y + v.size.y > maxp.y then
			maxp.y = v.pos.y + v.size.y
		end

		if v.pos.z < minp.z then
			minp.z = v.pos.z
		end
		if v.pos.z + v.size.z > maxp.z then
			maxp.z = v.pos.z + v.size.z
		end
	end

	minetest.log("action", "Fortress POS: " .. POS_TO_STR(params.spawn_pos))
	minetest.log("action", "Fortress MINP: " .. POS_TO_STR(minp))
	minetest.log("action", "Fortress MAXP: " .. POS_TO_STR(maxp))
	minetest.log("action", "Volume: " .. POS_TO_STR(vector.subtract(maxp, minp)))

	params.vm_minp = minp
	params.vm_maxp = maxp

	-- Build callback function. When the map is loaded, we can spawn the fortress.
	local cb = function(blockpos, action, calls_remaining)
		-- Check if there was an error.
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			minetest.log("error", "Failed to emerge area to spawn fortress.")
			return
		end

		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

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
			minetest.log("action", "Fortgen params saved for continuation.")
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



-- To be called once map region fully loaded.
function fortress.v2.apply_layout(params)
	local minp = table.copy(params.vm_minp)
	local maxp = table.copy(params.vm_maxp)
	local step = params.step

	if fortress.is_protected(minp, maxp) then
		minetest.log("error", "Cannot spawn fortress, protection is present.")
		return
	end

	local vm = minetest.get_voxel_manip(minp, maxp)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new {MinEdge=emin, MaxEdge=emax}

	local c_air = minetest.get_content_id("air")
	local c_brick = minetest.get_content_id("rackstone:brick_black")
	local c_block = minetest.get_content_id("rackstone:blackrack_block")
	local c_slab = minetest.get_content_id("stairs:slab_rackstone_brick_black")

	-- Note: replacements can only be sensibly defined for the entire fortress
	-- sheet as a whole. Defining custom replacement lists for individual fortress
	-- sections would NOT work the way you expect! Blame Minetest.
	local rp = params.replacements or {}

	-- Sort chunks by priority. Lowest priority first. This matters for schems
	-- that have 'force' == true, since they can overwrite what's already there.
	table.sort(params.build.schems,
		function(a, b)
			return a.priority < b.priority
		end)

	for k, v in ipairs(params.build.schems) do
		minetest.place_schematic_on_vmanip(
			vm, v.pos, v.file, v.rotation, rp, v.force)
	end

	-- Helper to decorate at a particular position.
	local vm_data = {}
	local function decorate(pos)
		local x0 = pos.x
		local y0 = pos.y
		local z0 = pos.z
		local x1 = pos.x + step.x
		local y1 = pos.y + step.y
		local z1 = pos.z + step.z
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

	-- Wait till all schematics have been placed, then we can do 'vm:get_data().'
	vm:get_data(vm_data)
	for k, v in ipairs(params.build.schems) do
		decorate(v.pos) -- Pos should be in worldspace.
	end

	vm:set_data(vm_data)
	vm:write_to_map(true)

	-- Add loot chests.
	-- Track how many chests we successfully add, and what types.
	local totals = {chests = 0}
	for k, v in ipairs(params.build.chests) do
		local p = v.pos
		local n = minetest.get_node(p)
		local f = minetest.get_node(vector.offset(p, 0, -1, 0))

		-- Only if location not already occupied, and floor is brick.
		if n.name == "air" and f.name == "rackstone:brick_black" then
			local param2 = params.yeskings(0, 3)
			local cname = CHEST_NAMES[params.yeskings(1, #CHEST_NAMES)]
			minetest.set_node(p, {name=cname, param2=param2})
			fortress.add_loot_items(p, v.loot)
			totals.chests = totals.chests + 1
			totals[v.loot] = (totals[v.loot] or 0) + 1
		end
	end

	minetest.log("action", "Added " .. totals.chests .. " chests to fortress")
	for k, v in pairs(totals) do
		if k ~= "chests" then
			minetest.log("action", "Added " .. v .. " " .. k .. " chests")
		end
	end

	-- Last-ditch effort to fix these darn lighting issues.
	mapfix.work(minp, maxp)

	-- Report success, and how long it took.
	minetest.log("action", "Finished generating fortress pattern in " ..
		math.floor(os.time() - params.time) .. " seconds!")

	minetest.log("action", "Fortress generated with seed: " .. params.randomseed)
end



-- Read chunk data and calculate where to place chests.
-- Store chest locations in the builder data.
function fortress.v2.collect_chests(schempos, chunkdata, params)
	if not chunkdata.chests then
		return
	end

	local all_chests = params.build.chests
	local used_locations = {} -- Don't overwrite chests.

	for k, v in ipairs(chunkdata.chests) do
		-- Spawn loot chest only if chance succeeds.
		if params.yeskings(1, 100) <= v.chance then
			local p2 = table.copy(v.pos)

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if p2.x_min then
				p2.x = params.yeskings(p2.x_min, p2.x_max)
				p2.x_min = nil
				p2.x_max = nil
			end
			if p2.y_min then
				p2.y = params.yeskings(p2.y_min, p2.y_max)
				p2.y_min = nil
				p2.y_max = nil
			end
			if p2.z_min then
				p2.z = params.yeskings(p2.z_min, p2.z_max)
				p2.z_min = nil
				p2.z_max = nil
			end

			local loc = vector.add(schempos, p2)
			local hash = HASH_POSITION(loc)

			if not used_locations[hash] then
				used_locations[hash] = true

				all_chests[#all_chests + 1] = {
					pos = loc,
					loot = v.loot,
				}
			end
		end
	end
end

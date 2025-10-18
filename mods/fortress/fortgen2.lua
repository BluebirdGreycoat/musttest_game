-- This file implements a *BETTER* constraint-rule based dungeon generator.

-- List of allowed chest nodes.
local CHEST_NAMES = {
	-- Duplicated for probability.
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",
	"morechests:woodchest_public_closed",

	"chests:chest_public_closed",
	"morechests:ironchest_public_closed",
}

-- Map direction strings to vectors.
local KEYDIRS = {
	["+x"] = {x= 1, y= 0, z= 0},
	["-x"] = {x=-1, y= 0, z= 0},
	["+y"] = {x= 0, y= 1, z= 0},
	["-y"] = {x= 0, y=-1, z= 0},
	["+z"] = {x= 0, y= 0, z= 1},
	["-z"] = {x= 0, y= 0, z=-1},
}

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string

-- Direction names.
local DIRNAME = {
	NORTH = "+z",
	SOUTH = "-z",
	EAST  = "+x",
	WEST  = "-x",
	UP    = "+y",
	DOWN  = "-y",
}



function fortress.gen_init(spawn_pos)
	local function get_all_chunk_names(chunks)
		local name_set = {}
		for name, _ in pairs(chunks) do name_set[name] = true end
		return name_set
	end

	local params = {
		-- Algorithm start time.
		time = os.time(),

		-- Commonly used items.
		spawn_pos = vector.copy(vector.round(spawn_pos)),
		step = fortress.genfort_data.step,
		max_extent = fortress.genfort_data.max_extent,
		chunks = fortress.genfort_data.chunks,
		initial_chunks = fortress.genfort_data.initial_chunks,
		replacements = fortress.genfort_data.replacements,
		schemdir = fortress.genfort_data.schemdir,

		-- The traversal "grid" (sparse). Indexed by chunk hash position.
		-- Contains entries for "fully determined" tiles, and potential neighbors.
		traversal = {
			determined = {},
			potential = {},
		},

		-- Initialize build table to an empty array. This array describes all schems
		-- which must be placed, and their parameters, once the fortress generation
		-- algorithm is complete.
		build = {
			schems = {},
			chests = {},
		},

		-- Limits. Indexed by chunk name, values are current usage count.
		chunk_limits = {},

		-- A list of ALL available chunk names defined by the data.
		-- It's useful to have this precalculated.
		chunk_names = get_all_chunk_names(fortress.genfort_data.chunks),

		-- NOTE: during mapgen, additional keys 'vm_minp' and 'vm_maxp' are added to
		-- this table. There may be others!
	}

	-- Add initial to the list of indeterminates.
	-- Just one possibility with a chance of 100.
	-- The initial chunk always begins at {x=0, y=0, z=0} in "chunk space".
	local initial_chunk = params.initial_chunks[
		math.random(1, #params.initial_chunks)]

	params.traversal.potential[HASH_POSITION({x=0, y=0, z=0})] = {
		[initial_chunk] = true,
	}

	return params
end



-- This is the core of the Wave Function Collapse (TM) algorithm.
-- It's just marketing lingo. This is actually just a rules-constraint system.
-- Function must be called in a loop until it says 'enough!'
function fortress.process_next_chunk(params)
	-- Core queues/lists used by the algorithm.
	local all_chunks = params.chunks
	local chunk_names = params.chunk_names
	local determined = params.traversal.determined
	local potential = params.traversal.potential
	local chunk_limits = params.chunk_limits
	local poshash, newchunks = next(potential)

	local function select_random_chunk()
		local choices = {}
		-- First build array from dictionary set.
		for name, _ in pairs(newchunks) do
			choices[#choices + 1] = name
		end
		return choices[math.random(1, #choices)]
	end

	-- Filter chunk names by their global usage limits.
	local function get_limited_chunks()
		local filtered = {}
		for chunkname, _ in pairs(chunk_names) do
			local thischunk = all_chunks[chunkname]
			if thischunk.limit then
				if (chunk_limits[chunkname] or 0) < thischunk.limit then
					filtered[chunkname] = true
				end
			else
				-- No limit applied to this chunk name.
				filtered[chunkname] = true
			end
		end
		return filtered
	end

	-- Returns the INTERSECTION of elements in two input lists.
	-- Both lists should be indexed by chunkname key. Value is ignored.
	local function intersect(a, b)
		local set = {}
		for key, _ in pairs(b) do set[key] = true end
		local res = {}
		for key, _ in pairs(a) do if set[key] then res[key] = true end end
		return res
	end

	-- Query whether a chunk position is within max extents.
	-- This prevents the fortress generator from generating infinitely.
	local function chunkpos_ok(pos)
		local minp = {
			x = -params.max_extent.x,
			y = -params.max_extent.y,
			z = -params.max_extent.z,
		}
		local maxp = {
			x = params.max_extent.x,
			y = params.max_extent.y,
			z = params.max_extent.z,
		}

		if pos.x >= minp.x and pos.x <= maxp.x
				and pos.y >= minp.y and pos.y <= maxp.y
				and pos.z >= minp.z and pos.z <= maxp.z then
			return true
		end
	end

	-- No new possibilities? We're done.
	if not poshash then return end

	-- We will jump here if neighbor checks failed.
	-- Abort entirely if we do this too many times (prevent infinite loop).
	local try_count = 0
	local try_limit = 100
	::try_again::

	-- Step 0: select a random chunk from the list of possibilities.
	local chunkname = select_random_chunk()
	local chunkpos = UNHASH_POSITION(poshash)
	local chunkdata = all_chunks[chunkname]

	minetest.log("action",
		"Processing chunk: " .. chunkname .. " at " .. POS_TO_STR(chunkpos))

	-- Returns the neighbors a chunk defines for a direction, if it has any.
	local function get_chunk_neighbors(dir)
		if not chunkdata.valid_neighbors then return {} end
		if not chunkdata.valid_neighbors[dir] then return {} end
		return chunkdata.valid_neighbors[dir]
	end

	-- Step 1: collect neighbors. We only do this if the selected chunk defines
	-- neighbors. If it does, those neighbors must be matched against any existing
	-- neighbors already contained in the 'potential' list (indexed by hash).
	local neighbors_to_update
	if chunkdata.valid_neighbors then
		neighbors_to_update = {
			[DIRNAME.NORTH] = {},
			[DIRNAME.SOUTH] = {},
			--[DIRNAME.EAST] = {},
			--[DIRNAME.WEST] = {},
			--[DIRNAME.UP] = {},
			--[DIRNAME.DOWN] = {},
		}

		-- Compute additional intersections to narrow down the lists.
		local dirs_out_of_bounds = {}
		for dir, _ in pairs(neighbors_to_update) do
			-- Since 'chunk_names' contains ALL chunk names, this should result in a
			-- list containing just the valid chunk neighbors for current chunk. Leave
			-- this as a sanity check (in case a chunk defines neighbors in its data
			-- that don't actually exist).
			local filt = intersect(chunk_names, get_chunk_neighbors(dir))

			local neighborpos = vector.add(chunkpos, KEYDIRS[dir])
			local neighborhash = HASH_POSITION(neighborpos)

			-- If defined neighbors exist in the 'potential' list, the result must be
			-- the INTERSECTION of both lists. This might result in the list being
			-- EMPTY, which indicates we need to backtrack/try again.
			if potential[neighborhash] then
				filt = intersect(filt, potential[neighborhash])
			end

			-- This also might result in the list becoming empty, if the already-
			-- determined neighbor isn't a valid neighbor of the selected chunk.
			if determined[neighborhash] then
				local detchunk = determined[neighborhash]
				filt = intersect(filt, {[detchunk]=true})
			else
				-- Filter chunks by limits. This has to be done EXCLUSIVE of checking
				-- allowed neighbors against already-determined neighbors (see above)
				-- because that neighbor may have been the last allowed.
				filt = intersect(get_limited_chunks(), filt)
			end

			-- Add neighbors for this direction only if in bounds (prevents infinite
			-- neighbor expansion). This is a hack, ideally we'd want to cut the
			-- fortress off smoothly instead of sharply.
			if chunkpos_ok(neighborpos) then
				neighbors_to_update[dir] = filt
			else
				-- Otherwise add this direction to the set of dirs to REMOVE entirely.
				dirs_out_of_bounds[dir] = true
			end
		end

		-- Delete directions that exceed fort bounds.
		-- Do not simply leave their lists empty, because that would confuse things.
		for dir, _ in pairs(dirs_out_of_bounds) do
			minetest.log("action", "Dir " .. dir .. " out of bounds, deleting.")
			neighbors_to_update[dir] = nil
		end

		-- Now (and this is very important) if any of the neighbor lists are EMPTY,
		-- we have made a mistake and we must cancel this iteration, so we can
		-- hopefully chose a different path the next time we enter this function.
		for dir, chunks in pairs(neighbors_to_update) do
			if not next(chunks) then
				try_count = try_count + 1
				if try_count > try_limit then
					minetest.log("action", "Iteration canceled.")
					minetest.log("action", "Dir: " .. dir)
					minetest.log("action", "After " .. try_limit .. " iterations.")
					return
				end
				goto try_again
			end
		end
	end

	-- Step 2: add current chunk to list of fully-determined chunks.
	-- Remove this entry from the list of indeterminate (possible) chunks.
	determined[poshash] = chunkname
	potential[poshash] = nil

	-- Step 3: update the limits count.
	chunk_limits[chunkname] = (chunk_limits[chunkname] or 0) + 1

	-- Step 4: update neighbor lists.
	-- We skip this if the current chunk (we just added to 'determined') has no
	-- defined neighbors.
	if neighbors_to_update then
		for dir, chunks in pairs(neighbors_to_update) do
			if next(chunks) then -- Keep data structure clean; skip empties.
				local neighborpos = vector.add(chunkpos, KEYDIRS[dir])
				local neighborhash = HASH_POSITION(neighborpos)
				-- Also, do not add to 'potential' if already defined in 'determined.'
				-- This prevents trying to overwrite parts already generated.
				if not determined[neighborhash] then
					potential[neighborhash] = chunks
				end
			end
		end
	end

	-- Finished one iteration successfully.
	return true
end



-- API function for mapgens.
function fortress.make_fort(spawn_pos)
	local params = fortress.gen_init(spawn_pos)

	minetest.log("action", "Computing fortress pattern @ " ..
		POS_TO_STR(vector.round(params.spawn_pos)) .. "!")

	local runmore = fortress.process_next_chunk(params)
	while runmore do runmore = fortress.process_next_chunk(params) end

	fortress.expand_all_schems(params)
	fortress.write_to_map(params)
end



-- Called from debug chatcommand.
function fortress.genfort_chatcmd(name, param)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	fortress.make_fort(vector.round(player:get_pos()))
end



function fortress.expand_all_schems(params)
	local spawn_pos = params.spawn_pos
	local chunkstep = params.step

	for poshash, chunkname in pairs(params.traversal.determined) do
		local chunkpos = UNHASH_POSITION(poshash)
		local schempos = vector.add(spawn_pos, vector.multiply(chunkpos, chunkstep))
		local chunkdata = params.chunks[chunkname]
		fortress.expand_single_schem(schempos, chunkdata, params)
	end
end



function fortress.expand_single_schem(schempos, chunkdata, params)
	-- Obtain relevant parameters for this section of fortress.
	-- A chunk may contain multiple schematics to place, each with their own
	-- parameters and chance to spawn.

	-- Calculate size of chunk.
	local size = vector.multiply((chunkdata.size or {x=1, y=1, z=1}), params.step)

	-- Add schems which are part of this chunk.
	-- A chunk may have multiple schems with different parameters.
	local thischunk = chunkdata.schem
	for k, v in ipairs(thischunk) do
		local chance = v.chance or 100

		if math.random(1, 100) <= chance then
			local file = v.file
			local path = params.schemdir .. "/" .. file .. ".mts"
			local offset = table.copy(v.offset or {x=0, y=0, z=0})
			local force = true
			local priority = v.priority or 0

			-- The position adjustment setting may specify min/max values for each
			-- dimension coordinate.
			if offset.x_min then
				offset.x = math.random(offset.x_min, offset.x_max)
				offset.x_min = nil
				offset.x_max = nil
			end
			if offset.y_min then
				offset.y = math.random(offset.y_min, offset.y_max)
				offset.y_min = nil
				offset.y_max = nil
			end
			if offset.z_min then
				offset.z = math.random(offset.z_min, offset.z_max)
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



function fortress.write_to_map(params)
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
		fortress.apply_genfort(params)
	end

	-- Load entire map region, generating chunks as needed.
	-- Overgenerate ceiling to try to avoid lighting issues in caverns.
	-- Doing this seems to be the trick.
	-- This will FAIL if in cavern, but ceiling is more than 100 nodes up!
	local omaxp = vector.offset(maxp, 0, 100, 0)
	minetest.emerge_area(minp, omaxp, cb)
end



-- To be called once map region fully loaded.
function fortress.apply_genfort(params)
	local minp = table.copy(params.vm_minp)
	local maxp = table.copy(params.vm_maxp)

	if fortress.is_protected(minp, maxp) then
		minetest.log("error", "Cannot spawn fortress, protection is present.")
		return
	end

	local vm = minetest.get_voxel_manip(minp, maxp)

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

	vm:write_to_map(true)

	-- Add loot chests.
	for k, v in ipairs(params.build.chests) do
		local p = v.pos
		local n = minetest.get_node(p)

		-- Only if location not already occupied.
		if n.name == "air" then
			local param2 = math.random(0, 3)
			local cname = CHEST_NAMES[math.random(1, #CHEST_NAMES)]
			minetest.set_node(p, {name=cname, param2=param2})
			fortress.add_loot_items(p, v.loot)
		end
	end

	-- Last-ditch effort to fix these darn lighting issues.
	mapfix.work(minp, maxp)

	-- Report success, and how long it took.
	minetest.log("action", "Finished generating fortress pattern in " ..
		math.floor(os.time() - params.time) .. " seconds!")
end

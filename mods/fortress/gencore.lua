
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

	local function select_next_potential()
		-- No potentials available? Return nil.
		if not next(potential) then return nil end

		-- Build array listing all potential location hashes and chunk sets.
		-- An ordered array is necessary to sort them and chose highest priority.
		local array = {}
		for positionhash, chunks in pairs(potential) do
			local chunkcount = 0
			for chunkname, _ in pairs(chunks) do
				chunkcount = chunkcount + 1
			end
			array[#array + 1] = {
				chunkpos = positionhash,
				chunkcount = chunkcount,
			}
		end

		-- Now sort the array so that lowest-entropy potentials are at the front.
		table.sort(array, function(a, b) return a.chunkcount < b.chunkcount end)

		-- Now build an array of all potentials at front with the same chunk count.
		-- These are considered "ties" which must be broken randomly.
		local firstcount = array[1].chunkcount
		local ties = {}
		for k, v in ipairs(array) do
			if v.chunkcount == firstcount then
				ties[#ties + 1] = v
			else
				break
			end
		end

		-- Now choose random from the list of tied potentials.
		-- This is what we'll return to the caller, as position-hash + chunk names.
		local choice = ties[math.random(1, #ties)]
		return choice.chunkpos, potential[choice.chunkpos]
	end

	-- Select a random chunk; must return the chosen chunk's name.
	-- We take into account the chunk's probability, but this only matters if
	-- there are multiple possible chunk names to choose from.
	local function select_random_chunk(all_chunks, selectable_chunks)
		local allchoices = {}
		local choices = {}

		-- First build array from dictionary set.
		for name, _ in pairs(selectable_chunks) do
			local prob = (all_chunks[name].probability or 100)
			if prob > 0 then  -- Skip zero-prob choices to optimize
				choices[#choices + 1] = {name=name, prob=prob}
			end

			-- This will be used as fallback incase zero-prob elements result in there
			-- being no elements in the 'choices' array.
			allchoices[#allchoices + 1] = {name=name, prob=prob}
		end

		-- Now, add up all the probabilities to find a max value.
		-- Max prob should never be zero. But it might be (e.g., testing), so handle
		-- it.
		local max_prob = 0
		for k, v in ipairs(choices) do max_prob = max_prob + v.prob end

		-- Fallback to uniform selection if necessary.
		if max_prob == 0 or #choices == 0 then
			if #allchoices > 0 then
				return allchoices[math.random(1, #allchoices)].name
			end
			-- Function precondition broken (there never was anything to select).
			return nil
		end

		-- Now get a random int from 1 to max prob.
		local number = math.random(1, max_prob)

		-- Now find out which name our number matches, and return that.
		-- Cumulative selection.
		local cumulative = 0
		for _, v in ipairs(choices) do
			cumulative = cumulative + v.prob
			if number <= cumulative then
				return v.name
			end
		end

		-- Fallback, if for some reason we get here (shouldn't happen).
		return choices[math.random(1, #choices)].name
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

	-- Filter chunk names by their fallback flag.
	-- These are the only chunks allowed to be placed at the fortress extent
	-- limits.
	local function get_fallback_chunks()
		local filtered = {}
		for chunkname, _ in pairs(chunk_names) do
			local thischunk = all_chunks[chunkname]
			if thischunk.fallback then
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

	local function near_extent_border(pos)
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
		minp = vector.offset(minp, 2, 2, 2)
		maxp = vector.offset(maxp, -2, -2, -2)

		if pos.x <= minp.x or pos.x >= maxp.x
				or pos.y <= minp.y or pos.y >= maxp.y
				or pos.z <= minp.z or pos.z >= maxp.z then
			return true
		end
	end

	-- Chose next potential to expand/compute, with lowest-entropy chunks having
	-- highest priority, and ties broken randomly.
	local poshash, selectable_chunks = select_next_potential()
	local all_limited_chunks = get_limited_chunks()
	local all_fallback_chunks = get_fallback_chunks()

	-- No new possibilities? We're done.
	if not poshash then return end

	-- We will jump here if neighbor checks failed.
	-- Abort entirely if we do this too many times (prevent infinite loop).
	local try_count = 0
	local try_limit = 100
	::try_again::

	-- Step 0: select a random chunk from the list of possibilities.
	-- This takes into account competing chunk probabilities.
	-- BUG: sometimes chunkname is nil? But this should not happen unless somehow
	-- there are NO 'selectable_chunks' to choose from, but how could that happen?
	local chunkname = select_random_chunk(all_chunks, selectable_chunks)
	local chunkpos = UNHASH_POSITION(poshash)
	local chunkdata = all_chunks[chunkname]

	-- Handle this hopefully very rare error.
	if not chunkname or not chunkdata then
		params.algorithm_fail = true
		minetest.log("error", "Fail: chunkname or chunkdata is nil!")
		return
	end

	minetest.log("action",
		"Processing chunk: " .. chunkname .. " at " .. POS_TO_STR(chunkpos) ..
		", try count: " .. try_count)

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
			[DIRNAME.EAST] = {},
			[DIRNAME.WEST] = {},
			[DIRNAME.UP] = {},
			[DIRNAME.DOWN] = {},
		}

		-- Compute additional intersections to narrow down the lists.
		local dirs_to_ignore = {}
		for dir, _ in pairs(neighbors_to_update) do
			-- Since 'chunk_names' contains ALL chunk names, this should result in a
			-- list containing just the valid chunk neighbors for current chunk. Leave
			-- this as a sanity check (in case a chunk defines neighbors in its data
			-- that don't actually exist).
			local filt = intersect(chunk_names, get_chunk_neighbors(dir))

			local neighborpos = vector.add(chunkpos, KEYDIRS[dir])
			local neighborhash = HASH_POSITION(neighborpos)

			-- If the current chunk defines NO NEIGHBORS for this direction, we
			-- interpret that ALL neighbors are permitted, no restriction.
			if not next(filt) then
				dirs_to_ignore[dir] = true
				goto nextdir
			end

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
				-- because that neighbor may have been the last allowed per limits.
				filt = intersect(all_limited_chunks, filt)
			end

			-- Add neighbors for this direction only if in bounds (prevents infinite
			-- neighbor expansion).
			if chunkpos_ok(neighborpos) then
				-- If near extent boundaries, additionally filter chunks, allowing only
				-- fallback chunks to be used here.
				if near_extent_border(neighborpos) then
					neighbors_to_update[dir] = intersect(all_fallback_chunks, filt)
				else
					neighbors_to_update[dir] = filt
				end
			else
				-- Otherwise add this direction to the set of dirs to REMOVE entirely.
				dirs_to_ignore[dir] = true
			end

			-- Jump here if this iteration is to be skipped, goto next dir.
			::nextdir::
		end

		-- Delete directions that exceed fort bounds.
		-- Do not simply leave their lists empty, because that would confuse things.
		for dir, _ in pairs(dirs_to_ignore) do
			neighbors_to_update[dir] = nil
		end

		-- Now (and this is very important) if any of the neighbor lists are EMPTY,
		-- we have made a mistake and we must cancel this iteration, so we can
		-- hopefully chose a different path the next time we enter this function.
		-- This obviously skips directions that we explicitly ignored earlier.
		for dir, chunks in pairs(neighbors_to_update) do
			if not next(chunks) then
				try_count = try_count + 1
				if try_count > try_limit then
					minetest.log("warning", "Iteration canceled!")
					minetest.log("warning", "Dir: " .. dir)
					minetest.log("warning", "Chunk: " .. chunkname)
					minetest.log("warning", "Pos: " .. POS_TO_STR(chunkpos))
					minetest.log("warning", "After " .. try_limit .. " iterations.")
					-- Treat this as a non-fatal error for now, but it means the generated
					-- fort will have missing sections.
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
				-- Calculate the index hash of the neighboring position.
				local neighborpos = vector.add(chunkpos, KEYDIRS[dir])
				local neighborhash = HASH_POSITION(neighborpos)

				-- Also, do not add to 'potential' if already defined in 'determined.'
				-- This prevents trying to overwrite parts already generated.
				if not determined[neighborhash] then
					local finalchunks = chunks

					-- Finally, if the chunkdata defines enabled neighbors, we should
					-- additionally filter the neighbor chunk list by that.
					--
					-- Note that if 'enabled_neighbors' is not present then only data from
					-- 'valid_neighbors' is used (filtered as above in this function).
					if chunkdata.enabled_neighbors then
						local enabled_dir = chunkdata.enabled_neighbors[dir]
						if enabled_dir then
							finalchunks = intersect(chunks, enabled_dir)
						end
					end

					potential[neighborhash] = finalchunks
				end
			end
		end
	end

	-- Finished one iteration successfully.
	return true
end

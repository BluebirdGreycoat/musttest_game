
local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string



local function lock_spawnpos(p, s)
	local np = vector.copy(p)

	-- Lock X,Z,Y coords to values divisible by fortress step size.
	-- Doing this helps adjacent fortresses line up neatly.
	np.x = np.x - (np.x % s.x)
	np.y = np.y - (np.y % s.y)
	np.z = np.z - (np.z % s.z)

	return np
end



-- Weighted probability selector function.
local function select_max_extent(params, fortdata)
	local list = fortdata.max_extents
	local prng = params.yeskings

	local allchoices = {}
	local choices = {}

	-- First build array from dictionary set.
	for _, data in pairs(list) do
		local prob = (data.weight or 100)
		if prob > 0 then  -- Skip zero-prob choices to optimize
			choices[#choices + 1] =
				{data={x=data.x, y=data.y, z=data.z}, prob=prob}
		end

		-- This will be used as fallback incase zero-prob elements result in there
		-- being no elements in the 'choices' array.
		allchoices[#allchoices + 1] =
			{data={x=data.x, y=data.y, z=data.z}, prob=prob}
	end

	-- Now, add up all the probabilities to find a max value.
	-- Max prob should never be zero. But it might be (e.g., testing), so handle
	-- it.
	local max_prob = 0
	for k, v in ipairs(choices) do max_prob = max_prob + v.prob end

	-- Fallback to uniform selection if necessary.
	if max_prob == 0 or #choices == 0 then
		if #allchoices > 0 then
			return allchoices[prng(1, #allchoices)].data
		end
		-- Function precondition broken (there never was anything to select).
		return nil
	end

	-- Now get a random int from 1 to max prob.
	local number = prng(1, max_prob)

	-- Cumulative selection.
	local cumulative = 0
	for _, v in ipairs(choices) do
		cumulative = cumulative + v.prob
		if number <= cumulative then
			return v.data
		end
	end

	-- Fallback, if for some reason we get here (shouldn't happen).
	return choices[prng(1, #choices)].data
end



local function validate_fortdata(params)
	-- Make sure all 'valid_neighbors' and 'enabled_neighbors' actually exist.
	-- This catches problems with wrongly named neighbors.
	for _, chunkdata in pairs(params.chunks) do
		if chunkdata.valid_neighbors then
			for dir, list in pairs(chunkdata.valid_neighbors) do
				for chunkname, _ in pairs(list) do
					if not params.chunks[chunkname] then
						params.log("error", "Chunk " .. chunkname .. " does not exist!")
						return
					end
				end
			end
		end

		if chunkdata.enabled_neighbors then
			for dir, list in pairs(chunkdata.enabled_neighbors) do
				for chunkname, _ in pairs(list) do
					if not params.chunks[chunkname] then
						params.log("error", "Chunk " .. chunkname .. " does not exist!")
						return
					end
				end
			end
		end
	end

	return true
end



local function choose_initial_chunk(params)
	-- Sanity checks.
	if not params.initial_chunks or #params.initial_chunks == 0 then
		params.log("error", "No initial starter chunks to choose from.")
		return -- Handle error.
	end

	local choices = params.initial_chunks
	local initial_chunk = choices[params.yeskings(1, #choices)]

	-- The user can override.
	if params.starting_chunk then
		initial_chunk = params.starting_chunk
	end

	if not params.chunks[initial_chunk] then
		params.log("error", "Invalid starting chunk.")
		return -- Handle error.
	end

	-- The initial chunk always begins at {x=0, y=0, z=0} in "chunk space".
	params.traversal.potential[HASH_POSITION({x=0, y=0, z=0})] = {
		[initial_chunk] = true,
	}
	params.starting_chunk = initial_chunk

	return true
end



function fortress.v2.gen_init(user_params)
	local FORTDATA = user_params.fortress_data

	-- Get random seed, or generate one ourselves.
	local randomseed = user_params.user_seed or math.random(0, 65534)

	local function get_all_chunk_names(chunks)
		local name_set = {}
		for name, _ in pairs(chunks) do name_set[name] = true end
		return name_set
	end

	local params = {
		-- NOTE: Key 'algorithm_fail' is set if something errored and NOTHING should
		-- be written to map.

		-- Replaceable log function.
		log = user_params.log or minetest.log,

		-- Optional table to store user-readable results, statistics etc.
		-- If our caller passes us a table, they can read results from it after the
		-- algorithm has returned.
		user_results = user_params.user_results or {},

		-- Commonly used items.
		spawn_pos = vector.copy(vector.round(user_params.spawn_pos)),
		step = FORTDATA.step,
		chunks = FORTDATA.chunks,
		initial_chunks = FORTDATA.initial_chunks,
		replacements = FORTDATA.replacements,
		schemdir = FORTDATA.schemdir,

		-- Key 'max_extent' is set, chosen from list of allowed sizes in fort data.
		-- Key 'final_flag' is set when fortgen algorithm finishes on its own.

		-- The traversal "grid" (sparse). Indexed by chunk hash position.
		-- Contains entries for "fully determined" tiles, and potential neighbors.
		traversal = {
			determined = {},
			potential = {},

			-- This will store chunk locations which have already been expanded and
			-- written once to map, so that we don't write them again during a
			-- continuation.
			completed = {},
		},

		-- Indexed by chunk hash position.
		-- This is a table of "large chunks" whose schems should override locations
		-- in '[traversal.determined].'
		override_chunk_schems = {},

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
		chunk_names = get_all_chunk_names(FORTDATA.chunks),

		-- Used to generate random numbers for reproducability.
		-- This is especially required for debugging leftists.
		--
		-- Also successfully debugs the following:
		--   Antifa (Brownshirts)
		--   BLM (Burn Loot'n'Murder)
		--   Hamas (We love death!)
		--   Democrats (everybody I don't like is Hitler)
		--   People who celebrated Kirk's murder (see above)
		--   Candace Owens (who, strangely, seems to have gone full retard)
		trump = PcgRandom(randomseed),
		randomseed = randomseed, -- Save for later.

		-- Keeps track of the number of fortgen iterations performed so far.
		iterations = 0,
		last_max_iterations = 0,

		-- If 'true', nothing will be written to map, but everything else will be
		-- done. Useful for testing the algorithm with changes to fort data.
		dry_run = user_params.dry_run,

		-- The user can specify a specific starting chunk, instead of letting the
		-- algorithm choose one at random. This key is ALSO set when we choose our
		-- own chunk, if the user didn't specify.
		starting_chunk = user_params.starting_chunk,

		-- Array list of all chunks created.
		-- Elements are subtables with position hash and chunk name.
		chunk_usage = {},

		-- List of notifications to be processed after the fort is written.
		-- These are not triggered for dry runs or partial generation.
		notifications = {},
		notify_func = FORTDATA.on_schem_notify,

		-- NOTE: during mapgen, additional keys 'vm_minp' and 'vm_maxp' are added to
		-- this table. There may be others!
	}

	-- This provides +1 to my ability to anger "nokings" protesters.
	params.yeskings = function(min, max)
		return params.trump:next(min, max)
	end

	-- Store seed number in user results.
	params.user_results.seednumber = params.randomseed

	-- Chose how big the fortress will be.
	params.max_extent = select_max_extent(params, FORTDATA)
	params.log("action", "Fortress extents: " .. POS_TO_STR(params.max_extent))
	params.log("action", "Fortress seed: " .. params.randomseed)

	-- Adjust spawn position to a multiple of the fortress "step" size.
	params.spawn_pos = lock_spawnpos(params.spawn_pos, params.step)

	-- Choose our initial starting chunk.
	if not choose_initial_chunk(params) then return end

	-- Sanity check.
	if not validate_fortdata(params) then return end

	-- Success.
	return true, params
end

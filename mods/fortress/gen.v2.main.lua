
-- V2 namespace.
fortress.v2 = fortress.v2 or {}

-- This stores ALL generated fortress chunks allocated THIS session.
-- The fort algorithm queries this table during its generating iterations to see
-- if a particular position was already occupied by a previously-generated fort.
fortress.v2.OCCUPIED_LOCATIONS = {}

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string



-- API function for mapgens.
function fortress.v2.make_fort(user_params)
	-- Get continuation parameters, or INIT new parameters.
	local success, params = true, fortress.v2.CONTINUATION_PARAMS
	if not fortress.v2.CONTINUATION_PARAMS then
		success, params = fortress.v2.gen_init(user_params)
		if not success then return end
	end
	fortress.v2.CONTINUATION_PARAMS = nil -- Don't leak, it'll screw up debugging.

	-- Algorithm start time.
	params.time = os.time()

	if user_params.max_iterations and user_params.max_iterations < 1 then
		minetest.log("action", "No iterations to execute.")
		return
	end

	if user_params.max_iterations then
		params.last_max_iterations =
			params.last_max_iterations + user_params.max_iterations
	end

	minetest.log("action", "Computing fortress pattern @ " ..
		POS_TO_STR(vector.round(params.spawn_pos)) .. "!")
	minetest.log("action", "Current iteration count: " .. params.iterations)

	local runmore = false
	params.final_flag = false

	repeat
		-- Break if user specified max iterations have been reached.
		-- This is useful for debugging.
		if user_params.max_iterations
				and params.iterations >= params.last_max_iterations then
			goto skip_setting_final_flag
		end

		runmore = fortress.v2.process_chunk(params)
		params.iterations = params.iterations + 1
	until not runmore

	-- This flag only set if we exited the loop normally, not due to max
	-- iterations being reached!
	minetest.log("action", "Fortgen iterations self-terminated.")
	params.final_flag = true
	::skip_setting_final_flag::

	if not next(params.traversal.determined) then
		minetest.log("error", "No chunks to generate.")
		return
	end

	minetest.log("action", "Fortgen ended after " ..
		params.iterations .. " iterations.")

	-- This flag set only if algorithm ran into a fatal error.
	-- This should never happen, but I've seen it happen exactly once, and if it
	-- does we must NOT write anything to map.
	if not params.algorithm_fail then
		local spawn_pos = params.spawn_pos
		local step = params.step

		-- Before writing anything to the map (which actually happens in a mapgen
		-- callback), first save all determined locations we'll occupy to a global
		-- map.
		if params.final_flag then -- Only after fortgen completed normally.
			for hash, chunkname in pairs(params.traversal.determined) do
				local chunkpos = UNHASH_POSITION(hash)
				local realpos = vector.add(spawn_pos, vector.multiply(chunkpos, step))
				local finalhash = HASH_POSITION(realpos)
				fortress.v2.OCCUPIED_LOCATIONS[finalhash] = chunkname
			end
		end

		fortress.v2.expand_all_schems(params)
		fortress.v2.write_map(params)
	else
		minetest.log("error", "Something failed in fortress algorithm!")
		minetest.log("error", "Not writing anything to map.")
	end
end


-- V2 namespace.
fortress.v2 = fortress.v2 or {}

-- This stores ALL generated fortress chunks allocated THIS session.
-- The fort algorithm queries this table during its generating iterations to see
-- if a particular position was already occupied by a previously-generated fort.
-- Note that in order for this to be efficient, fortress spawn locations need to
-- be locked to multiples of the fortress step size. See INIT function.
fortress.v2.OCCUPIED_LOCATIONS = {}

local HASH_POSITION = minetest.hash_node_position
local UNHASH_POSITION = minetest.get_position_from_hash
local POS_TO_STR = minetest.pos_to_string



local function save_occupied_locations(params)
	local spawn_pos = params.spawn_pos
	local step = params.step
	local vec_add = vector.add
	local vec_mul = vector.multiply
	local occupied = fortress.v2.OCCUPIED_LOCATIONS

	for hash, chunkname in pairs(params.traversal.determined) do
		local chunkpos = UNHASH_POSITION(hash)
		local realpos = vec_add(spawn_pos, vec_mul(chunkpos, step))
		local finalhash = HASH_POSITION(realpos)
		occupied[finalhash] = chunkname
	end
end



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
	params.final_flag = true
	::skip_setting_final_flag::

	if not next(params.traversal.determined) then
		minetest.log("error", "No chunks were added to fortress layout.")
		return
	end

	if params.final_flag then
		minetest.log("action", "Fortgen quit after " ..
			params.iterations .. " iterations.")
	else
		minetest.log("action", "Fortgen ABORTED after " ..
			params.iterations .. " iterations.")
	end

	-- This flag set only if algorithm ran into a fatal error.
	if not params.algorithm_fail then
		-- Before writing anything to the map (which actually happens in a mapgen
		-- callback), first save all determined locations we'll occupy to a global
		-- map. Only after fortgen completed normally.
		if params.final_flag and not params.dry_run then
			save_occupied_locations(params)
		end

		fortress.v2.process_layout(params)

		-- Skip writing to map for dry runs.
		if not params.dry_run then
			fortress.v2.write_map(params)
		end
	else
		minetest.log("error", "Fortgen algorithm failure!")
		minetest.log("error", "Not writing anything to map.")
	end
end

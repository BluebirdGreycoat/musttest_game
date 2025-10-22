
function fortress.v2.get_chat_command_params_desc()
	return "[<seednumber>|clear|dryrun [<seednumber>]] [<iterationcount>]"
end

-- Called when user types /help genfort.
function fortress.v2.show_command_help(pname)
	local strings = {
		"Spawn a v2 fortress (rule-constrained) at your location.",
		"Command usages:",
		"    /genfort <seednumber>",
		"    /genfort <seednumber> <iterationcount>",
		"    /genfort clear",
		"    /genfort dryrun",
		"    /genfort dryrun <seednumber>",
		"    /genfort dryrun <seednumber> <iterationcount>",
		"    /genfort test",
		"Include \"quiet\" in any command to suppress chat output.",
		"Use \"force\" to force writing to map even if fortgen fails.",
	}

	for k, v in ipairs(strings) do
		minetest.chat_send_player(pname, "# Server: " .. v)
	end
end



local function pluralize(count, singular, plural)
	if count == 1 then
		return singular
	end

	return plural
end



local function report_chunks_never_used(pname, user_params, all_chunks)
	local chunks_used = user_params.chunks_used
	if not chunks_used then
		minetest.chat_send_player(pname, "# Server: Chunk use info not available.")
		return
	end

	-- First build a set of all chunk names.
	local all_names = {}
	for name, _ in pairs(all_chunks) do
		all_names[name] = true
	end

	-- Now find all names in 'all_names' not existing in 'chunks_used.'
	local excluded = {}
	for name, _ in pairs(all_names) do
		if not chunks_used[name] then
			excluded[name] = true
		end
	end

	-- Convert list of excluded chunks to array.
	local namelist = {}
	for name, _ in pairs(excluded) do
		namelist[#namelist + 1] = name
	end

	if #namelist > 0 then
		local str = table.concat(namelist, ", ")
		minetest.chat_send_player(pname,
			"# Server: " .. pluralize(#namelist, "Chunk", "Chunks") ..
				" not used: " .. str .. ".")
	else
		minetest.chat_send_player(pname,
			"# Server: All available chunks were used at least once.")

		-- Sort by usage count.
		local usages = user_params.chunk_counts or {}
		local allnames = {}

		for name, v in pairs(user_params.chunk_counts) do
			allnames[#allnames + 1] = name
		end

		table.sort(allnames, function(a, b)
			return (usages[a] or 0) < (usages[b] or 0)
		end)

		local topnum = math.min(10, #namelist)
		local leastusedstr = table.concat(namelist, ", ", 1, topnum)
		minetest.chat_send_player(pname,
			"# Server: The " .. topnum .. " least-used " ..
				pluralize(topnum, "chunk was", "chunks were") .. ": " ..
					leastusedstr .. ".")
	end
end



-- Called from debug chat command.
function fortress.v2.chat_command(pname, textparam)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	local args = textparam:split(" ")
	if args[1] == "clear" then
		if fortress.v2.has_saved_info() then
			minetest.chat_send_player(pname,
				"# Server: Genfort continuation params cleared.")
		else
			minetest.chat_send_player(pname, "# Server: Nothing to be done.")
		end
		fortress.v2.clear_saved_info()
		return
	end

	local run_tests = false
	local dry_run = false
	local seednum_offset = 1
	local maxiter_offset = 2

	local quiet = false
	local force_write = false

	for k, v in ipairs(args) do
		if v == "quiet" then quiet = true end
		if v == "force" then force_write = true end
	end

	if args[1] == "dryrun" then
		dry_run = true
		seednum_offset = 2
		maxiter_offset = 3
	elseif args[1] == "test" then
		-- Running tests means we don't care about other arguments.
		run_tests = true
	end

	local randseed = args[seednum_offset] and tonumber(args[seednum_offset])
	if randseed then randseed = math.abs(math.floor(randseed)) end

	local maxiter = args[maxiter_offset] and tonumber(args[maxiter_offset])
	if maxiter then maxiter = math.abs(math.floor(maxiter)) end

	if randseed then
		minetest.log("action", "User specified SEED: " .. randseed)
	end
	if maxiter then
		minetest.log("action", "User specified Iteration Count: " .. maxiter)
	end

	-- Log to chat and debug.txt, or be quiet.
	local chatlogger = function(info, text)
		minetest.log(info, text)
		minetest.chat_send_player(pname, "# Server: " .. text)
	end
	if quiet or run_tests then chatlogger = nil end

	if run_tests then
		local test_count = 100
		local errors = 0
		local time0 = os.clock()

		local user_results = {}
		local bad_seeds = {}

		for k = 1, test_count do
			-- Saved info will mess up tests.
			fortress.v2.clear_saved_info()

			if not fortress.v2.make_fort({
				-- Required parameters.
				spawn_pos = vector.round(player:get_pos()),
				fortress_data = fortress.v2.fortress_data,

				dry_run = true,
				log = chatlogger,

				-- The algorithm will output result statistics here.
				user_results = user_results,
			}) then
				errors = errors + 1
				if user_results.seednumber then
					bad_seeds[#bad_seeds + 1] = user_results.seednumber
				end
			end
		end

		local time1 = os.clock()
		local elapsed = time1 - time0

		minetest.chat_send_player(pname,
			"# Server: Ran " .. test_count .. " tests. " .. errors .. " " ..
				pluralize(errors, "error", "errors") .. ".")
		minetest.chat_send_player(pname,
			"# Server: " .. string.format("%.2f", elapsed) .. " seconds elapsed.")

		report_chunks_never_used(pname, user_results,
			fortress.v2.fortress_data.chunks)

		-- Report which seed numbers errored.
		if #bad_seeds > 0 then
			minetest.chat_send_player(pname,
				"# Server: Bad seeds: " .. table.concat(bad_seeds, ", ") .. ".")
		end
	else
		fortress.v2.make_fort({
			-- Required parameters.
			spawn_pos = vector.round(player:get_pos()),
			fortress_data = fortress.v2.fortress_data,

			-- Optional parameters.
			user_seed = randseed,
			max_iterations = maxiter,
			dry_run = dry_run,
			force_write = force_write,

			-- If nil, the fortgen will write to debug.txt by default.
			log = chatlogger,
		})
	end
end

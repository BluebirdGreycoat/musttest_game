
function fortress.v2.get_chat_command_params_desc()
	return "[<seednumber>|clear|dryrun [<seednumber>]] [<iterationcount>]"
end

-- Called when user types /help genfort.
function fortress.v2.show_command_help(pname)
	local strings = {
		"Spawn a v2 fortress (rule-constrained) at your location.",
		"Common command usages:",
		"    /genfort seed=<seednumber>",
		"    /genfort seed=<seednumber> iterations=<count>",
		"    /genfort clear",
		"    /genfort dryrun",
		"    /genfort dryrun seed=<seednumber>",
		"    /genfort dryrun seed=<seednumber> iterations=<count>",
		"    /genfort test",
		"    /genfort force seed=<seednumber>",
		"Include \"quiet\" in any command to suppress chat output.",
		"Use \"force\" to force writing to map even if fortgen fails.",
		"Use \"start=<chunkname>\" to start with a specific chunk.",
		"Use \"require=<chunkname>\" to generate a fort that includes that chunk.",
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
	end

	-- Sort by usage count.
	local usages = user_params.chunk_counts or {}
	local allnames = {}

	for name, v in pairs(user_params.chunk_counts) do
		allnames[#allnames + 1] = name
	end

	table.sort(allnames, function(a, b)
		return (usages[a] or 0) < (usages[b] or 0)
	end)

	local topnum = math.min(10, #allnames)
	local leastusedstr = table.concat(allnames, ", ", 1, topnum)
	minetest.chat_send_player(pname,
		"# Server: The " .. topnum .. " least-used " ..
			pluralize(topnum, "chunk was", "chunks were") .. ": " ..
				leastusedstr .. ".")
end



-- Called from debug chat command.
function fortress.v2.chat_command(pname, textparam)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	local args = textparam:split(" ")

	local randseed = nil
	local maxiter = nil
	local run_tests = false
	local dry_run = false
	local starting_chunk = nil
	local required_chunk = nil
	local quiet = false
	local force_write = false

	-- Parse arguments.
	for k, v in ipairs(args) do
		if v == "quiet" then quiet = true end
		if v == "force" then force_write = true end
		if v == "dryrun" then dry_run = true end
		if v == "test" then run_tests = true end

		if v:find("start=") then
			local chunkname = string.split(v, "=")[2]
			if chunkname and fortress.v2.fortress_data.chunks[chunkname] then
				starting_chunk = chunkname
			else
				minetest.chat_send_player(pname, "# Server: Invalid chunk name.")
				return
			end
		end

		if v == "clear" then
			if fortress.v2.has_saved_info() then
				minetest.chat_send_player(pname,
					"# Server: Genfort continuation params cleared.")
			else
				minetest.chat_send_player(pname, "# Server: Nothing to be done.")
			end
			fortress.v2.clear_saved_info()
			return
		end

		if v:find("seed=") then
			local seedstr = string.split(v, "=")[2]
			if seedstr and tonumber(seedstr) then
				randseed = math.abs(math.floor(tonumber(seedstr)))
			else
				minetest.chat_send_player(pname, "# Server: Invalid seed.")
				return
			end
		end

		if v:find("iterations=") then
			local iterstr = string.split(v, "=")[2]
			if iterstr and tonumber(iterstr) then
				maxiter = math.abs(math.floor(tonumber(iterstr)))
			else
				minetest.chat_send_player(pname, "# Server: Invalid iteration count.")
				return
			end
		end

		if v:find("require=") then
			local chunkname = string.split(v, "=")[2]
			if chunkname and fortress.v2.fortress_data.chunks[chunkname] then
				required_chunk = chunkname
			else
				minetest.chat_send_player(pname, "# Server: Invalid chunk name.")
				return
			end
		end
	end

	if dry_run and force_write then
		minetest.chat_send_player(pname, "# Server: Mutually exclusive options.")
		return
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

				-- Max iterations and starting seed are NOT used in tests.
				starting_chunk = starting_chunk,
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
		-- If the user has asked for a fort containing a specific chunk,
		-- then iterate fortress layout generation until we find that chunk being
		-- used, or we reach max iterations.
		if required_chunk then
			minetest.chat_send_player(pname, "# Server: Searching for chunk ...")

			local user_results = {}
			local try_count = 100
			local success = false

			for k = 1, try_count do
				-- Saved info will mess up tests.
				fortress.v2.clear_saved_info()

				fortress.v2.make_fort({
					-- Required parameters.
					spawn_pos = vector.round(player:get_pos()),
					fortress_data = fortress.v2.fortress_data,

					-- Max iterations and starting seed are NOT used here,
					-- since they don't make sense for our purpose.
					starting_chunk = starting_chunk,
					dry_run = true,

					-- The algorithm will output result statistics here.
					user_results = user_results,
				})

				if user_results.chunks_used then
					if user_results.chunks_used[required_chunk] then
						randseed = user_results.seednumber
						success = true
						break
					end
				end
			end

			if not success then
				minetest.chat_send_player(pname,
					"# Server: Could not find fortress layout containing " ..
						required_chunk .. " after " .. try_count .. " iterations.")

				return
			end

			local count = user_results.chunk_counts[required_chunk]
			minetest.chat_send_player(pname,
				"# Server: Chunk " .. required_chunk .. " was used " .. count .. " " ..
					pluralize(count, "time", "times") .. ".")
		end

		fortress.v2.make_fort({
			-- Required parameters.
			spawn_pos = vector.round(player:get_pos()),
			fortress_data = fortress.v2.fortress_data,

			-- Optional parameters.
			user_seed = randseed,
			max_iterations = maxiter,
			dry_run = dry_run,
			force_write = force_write,
			starting_chunk = starting_chunk,

			-- If nil, the fortgen will write to debug.txt by default.
			log = chatlogger,
		})
	end
end

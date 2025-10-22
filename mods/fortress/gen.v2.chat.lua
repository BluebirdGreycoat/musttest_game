
function fortress.v2.get_chat_command_params_desc()
	return "[<seednumber>|clear|dryrun [<seednumber>]] [<iterationcount>]"
end

local function pluralize(count, singular, plural)
	if count == 1 then
		return singular
	end

	return plural
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
			minetest.log("action", "Genfort continuation params cleared.")
		end
		fortress.v2.clear_saved_info()
		return
	end

	local run_tests = false
	local dry_run = false
	local seednum_offset = 1
	local maxiter_offset = 2

	local quiet = false
	for k, v in ipairs(args) do
		if v == "quiet" then quiet = true end
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
		-- Saved info will mess up tests.
		fortress.v2.clear_saved_info()

		local test_count = 100
		local errors = 0
		local time0 = os.clock()

		for k = 1, test_count do
			if not fortress.v2.make_fort({
				-- Required parameters.
				spawn_pos = vector.round(player:get_pos()),
				fortress_data = fortress.v2.fortress_data,

				dry_run = true,
				log = chatlogger,
			}) then
				errors = errors + 1
			end
		end

		local time1 = os.clock()
		local elapsed = time1 - time0

		minetest.chat_send_player(pname,
			"# Server: Ran " .. test_count .. " tests. " .. errors .. " " ..
				pluralize(errors, "error", "errors") .. ".")
		minetest.chat_send_player(pname,
			"# Server: " .. string.format("%.2f", elapsed) .. " seconds elapsed.")
	else
		fortress.v2.make_fort({
			-- Required parameters.
			spawn_pos = vector.round(player:get_pos()),
			fortress_data = fortress.v2.fortress_data,

			-- Optional parameters.
			user_seed = randseed,
			max_iterations = maxiter,
			dry_run = dry_run,

			-- If nil, the fortgen will write to debug.txt by default.
			log = chatlogger,
		})
	end
end

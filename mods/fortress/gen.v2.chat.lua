
function fortress.v2.get_chat_command_params_desc()
	return "[<seednumber>|clear|dryrun [<seednumber>]] [<iterationcount>]"
end



-- Called from debug chat command.
function fortress.v2.chat_command(pname, textparam)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	local args = textparam:split(" ")
	if args[1] == "clear" then
		if fortress.v2.CONTINUATION_PARAMS or fortress.v2.OCCUPIED_LOCATIONS then
			minetest.log("action", "Genfort continuation params cleared.")
		end
		fortress.v2.CONTINUATION_PARAMS = nil
		fortress.v2.OCCUPIED_LOCATIONS = {}
		return
	end

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
	if quiet then chatlogger = nil end

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

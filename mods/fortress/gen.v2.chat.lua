
function fortress.v2.get_chat_command_params_desc()
	return "[<seednumber>|clear|dryrun] [<iterationcount>]"
end



-- Called from debug chat command.
function fortress.v2.chat_command(name, textparam)
	local player = minetest.get_player_by_name(name)
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
	if args[1] == "dryrun" then dry_run = true end

	local randseed = args[1] and tonumber(args[1]) -- Or nil
	if randseed then randseed = math.abs(math.floor(randseed)) end

	local maxiter = args[2] and tonumber(args[2]) -- Or nil
	if maxiter then maxiter = math.abs(math.floor(maxiter)) end

	if randseed then
		minetest.log("action", "User specified SEED: " .. randseed)
	end
	if maxiter then
		minetest.log("action", "User specified Iteration Count: " .. maxiter)
	end

	fortress.v2.make_fort({
		-- Required parameters.
		spawn_pos = vector.round(player:get_pos()),
		fortress_data = fortress.v2.fortress_data,

		-- Optional parameters.
		user_seed = randseed,
		max_iterations = maxiter,
		dry_run = dry_run,
	})
end

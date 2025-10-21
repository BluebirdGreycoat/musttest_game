
-- Called from debug chatcommand.
function fortress.v2.chat_command(name, textparam)
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then
		return
	end

	local args = textparam:split(" ")
	if args[1] == "clear" then
		if fortress.v2.CONTINUATION_PARAMS or fortress.v2.OCCUPIED_LOCATIONS then
			minetest.log("action", "Continuation params cleared.")
		end
		fortress.v2.CONTINUATION_PARAMS = nil
		fortress.v2.OCCUPIED_LOCATIONS = {}
		return
	end

	local user_seed = args[1] and tonumber(args[1]) -- Or nil
	if user_seed then user_seed = math.floor(user_seed) end -- Make integer.
	if user_seed then user_seed = math.abs(user_seed) end -- Make positive.

	local max_iterations = args[2] and tonumber(args[2]) -- Or nil
	if max_iterations then max_iterations = math.floor(max_iterations) end
	if max_iterations then max_iterations = math.abs(max_iterations) end

	if user_seed then
		minetest.log("action", "Fortgen user_seed: " .. user_seed)
	end
	if max_iterations then
		minetest.log("action", "Fortgen max_iterations: " .. max_iterations)
	end

	fortress.v2.make_fort({
		spawn_pos = vector.round(player:get_pos()),
		user_seed = user_seed,
		max_iterations = max_iterations,
	})
end


-- Called when player uses "manage_claims" button in cityblock GUI.
-- Responsible for logging and sending messages to the player.
city_block.register_callback("log_borough_action", "cityblock", function(params)
	local pname = params.pname
	local pos = params.pos
	core.log('action', "[cityblock] " .. dump(params, "")) -- Debugging.

	if params.refused then
		if not params.have_time then
			minetest.chat_send_player(pname,
				("# Server: This system is not available on city blocks placed before %s.")
				:format( os.date("!%Y/%m/%d", city_block.BOROUGH_MIN_ACTIVATION_TIME) )
			)
		end
		if not params.have_xp then
			minetest.chat_send_player(pname,
				("# Server: You need %d Build XP to use borough controls.")
				:format(city_block.BUILDXP_FOR_MAYOR))
		end
	end

	if params.refused then
		core.log("action", ("[cityblock] <%s> was refused access to mayoral functions at %s."):
			format(pname, minetest.pos_to_string(pos)))
	else
		core.log("action", ("[cityblock] <%s> gained access to mayoral functions at %s."):
			format(pname, minetest.pos_to_string(pos)))
	end
end)

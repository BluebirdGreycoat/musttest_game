
minetest.register_privilege("defenestrate", {
	description = "User can defenestrate others.",
	give_to_singleplayer = false,
})

-- Something that needs to happen to some politicians!
minetest.register_chatcommand("defenestrate", {
	params = "<player>",
	description = "Throw someone (presumably out of a window).",
	privs = {defenestrate=true},

	func = function(pname, param)
		local player = minetest.get_player_by_name(rename.grn(param))
		if not player then
			return false, "Cannot defenestrate unknown target <" .. param .. ">."
		end

		default.detach_player_if_attached(player)

		local rng = math.random
		local vel = {x=rng(-20, 20), y=6, z=rng(-20, 20)}
		player:add_velocity(vel)
		return true, "Target defenestrated."
	end,
})

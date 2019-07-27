
jail = jail or {}
jail.modpath = minetest.get_modpath("jail")


local function jailposition(player)
	local pos = {x=0, y=-50, z=0}
	if player:get_pos().y < -25000 then
		pos.y = -30765
	end
	return pos
end


function jail.go_to_jail(player, bcb)
	local pname = player:get_player_name()

	local cb = function(...)
		portal_sickness.on_use_portal(pname)
		bcb(...)
	end

	local jailpos = jailposition(player)
	preload_tp.preload_and_teleport(pname, jailpos, 32, nil, bcb, nil, true)
end


local jail_data = {
	name = "Colony Jail",
	codename = "jail:jail",
	position = jailposition,
	min_dist = 30,
}



jail_data.on_success = function(name)
	local dname = rename.gpn(name)
	minetest.chat_send_all("# Server: <" .. dname .. "> sent to jail for no particular reason.")
end



jail_data.suppress = function(name)
    local player = minetest.get_player_by_name(name)
    if player and player:is_player() then
        if vector.distance(player:getpos(), jail_data.position(player)) < jail_data.min_dist then
            minetest.chat_send_player(name, "# Server: Error: security override. Recall is disabled within convict re-education block.")
						easyvend.sound_error(name)
            return true -- Too close to jail.
        end
    end
end
jail.suppress = jail_data.suppress



passport.register_recall(jail_data)

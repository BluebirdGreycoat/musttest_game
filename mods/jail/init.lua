
jail = jail or {}
jail.modpath = minetest.get_modpath("jail")


local function jailposition(player)
	local pos = {x=0, y=-50, z=0}
	if player:get_pos().y < -25000 then
		pos.y = -30765
	end
	return pos
end

-- This function shall be called only when player escapes jail via hack, etc.
-- Shall return the player to the nearest jail within their current dimension.
function jail.on_player_escaped_jail(pref)
	local jp = jailposition(pref)
	preload_tp.preload_and_teleport(pref:get_player_name(), jp, 8, nil, nil, true)
end

function jail.is_player_in_jail(pref)
	local jp = jailposition(pref) -- Get position of jail.
	local pp = pref:get_pos() -- Position of player.
	local dt = vector.distance(jp, pp) -- Distance between points.
	if dt > 20 then
		return false -- Player is NOT in jail!
	end
	return true -- Player is in jail.
end

function jail.check_player_in_jail(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local meta = pref:get_meta()
		if meta:get_int("should_be_in_jail") == 1 then
			-- Here we check to make sure player actually is still in jail!
			if not jail.is_player_in_jail(pref) then
				jail.on_player_escaped_jail(pref)
			end

			-- Check again in 1 second.
			minetest.after(1, jail.check_player_in_jail, pname)
		end
	end -- Else player has logged out.
	-- Checks will resume when player (any player) logs in again.
end


function jail.go_to_jail(player, bcb)
	local pname = player:get_player_name()

	local fwrap = function(...)
		local pref = minetest.get_player_by_name(pname)
		if pref then
			jail.notify_sent_to_jail(pref)
		end

		if bcb then
			bcb(...)
		end
	end

	local jailpos = jailposition(player)
	preload_tp.preload_and_teleport(pname, jailpos, 32, nil, fwrap, nil, true)
end

function jail.notify_sent_to_jail(pref)
	-- Set key on player indicating that they should currently be in jail.
	-- This key should be cleared only if they leave jail through legit means!
	local meta = pref:get_meta()
	meta:set_int("should_be_in_jail", 1)
end

function jail.notify_player_death(pref)
	local meta = pref:get_meta()
	meta:set_int("should_be_in_jail", 0)
end



local jail_data = {
	name = "Colony Jail",
	codename = "jail:jail",
	position = jailposition,
	min_dist = 30,
}



jail_data.on_success = function(name)
	local pref = minetest.get_player_by_name(name)
	if pref then
		jail.notify_sent_to_jail(pref)
		local dname = rename.gpn(name)
		minetest.chat_send_all("# Server: <" .. dname .. "> sent to jail for no particular reason.")
	end
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

minetest.register_on_joinplayer(function(pref)
	minetest.after(5, jail.check_player_in_jail, pref:get_player_name())
end)

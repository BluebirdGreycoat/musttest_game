
jail = jail or {}
jail.modpath = minetest.get_modpath("jail")
jail.noclip_radius = 15 -- Max distance of player from jail.

-- Localize vector.distance() for performance.
local vector_distance = vector.distance



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
	default.detach_player_if_attached(pref) -- Otherwise teleport could fail.
	local pname = pref:get_player_name()

	local cb = function(pname)
		local pref = minetest.get_player_by_name(pname)
		if pref then
			-- AFTER player has been teleported back, damage them.
			pref:set_pos(jp)
			pref:set_hp(pref:get_hp() - 1)
		end
	end

	preload_tp.execute({
		player_name = pname,
		target_position = jp,
		emerge_radius = 8,
		post_teleport_callback = cb,
		callback_param = pname,
		force_teleport = true,
		send_blocks = false,
		particle_effects = false,
	})
end

function jail.is_player_in_jail(pref)
	local jp = jailposition(pref) -- Get position of jail.
	local pp = pref:get_pos() -- Position of player.
	local dt = vector_distance(jp, pp) -- Distance between points.
	if dt > jail.noclip_radius then
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

	preload_tp.execute({
		player_name = pname,
		target_position = jailpos,
		emerge_radius = 32,
		post_teleport_callback = fwrap,
		force_teleport = true,
		send_blocks = true,
		particle_effects = true,
	})
end

function jail.notify_sent_to_jail(pref)
	-- Set key on player indicating that they should currently be in jail.
	-- This key should be cleared only if they leave jail through legit means!
	local meta = pref:get_meta()
	meta:set_int("should_be_in_jail", 1)

	minetest.after(1, jail.check_player_in_jail, pref:get_player_name())
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
        if vector_distance(player:getpos(), jail_data.position(player)) < jail_data.min_dist then
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

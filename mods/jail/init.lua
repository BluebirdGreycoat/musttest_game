
jail = jail or {}
jail.modpath = minetest.get_modpath("jail")
jail.noclip_radius = 15 -- Max distance of player from jail.

-- Localize vector.distance() for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add



function jail.notify_jail_destruct(pos)
	local p1 = vector_add(pos, {x=-1, y=0, z=-1})
	local p2 = vector_add(pos, {x=1, y=0, z=1})
	local positions, counts = minetest.find_nodes_in_area(p1, p2, "city_block:cityblock")

	for k, v in ipairs(positions) do
		city_block.erase_jail(v)
	end
end



function jail.get_nearest_jail_pos(player)
	local pp = vector_round(player:get_pos())

	-- Find the location of the nearest player-constructed jail.
	local jails = city_block:nearest_jails_to_position(pp, 1, 3000)
	if jails[1] then
		return vector_add(jails[1].pos, {x=0, y=1, z=0})
	end
end

-- This function shall be called only when player escapes jail via hack, etc.
-- Shall return the player to the nearest jail within their current dimension.
function jail.on_player_escaped_jail(pref)
	local jp = jail.get_nearest_jail_pos(pref)
	if not jp then
		-- If there's no nearby jail we might as well let them out.
		-- As if the player died.
		jail.notify_player_death(pref)
		return
	end

	default.detach_player_if_attached(pref) -- Otherwise teleport could fail.
	local pname = pref:get_player_name()

	local cb = function(pname)
		local pref = minetest.get_player_by_name(pname)
		if pref then
			-- AFTER player has been teleported back, damage them.
			pref:set_pos(jp)
			pref:set_hp(pref:get_hp() - 1)

			minetest.chat_send_player(
				pname, "# Server: Nope. You go right back to jail, crook!")
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
	local jp = jail.get_nearest_jail_pos(pref) -- Get position of jail.
	if not jp then
		return false -- No jails available, player cannot be in one.
	end

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
		end -- Else player is no longer marked to be in jail.
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

	local jailpos = jail.get_nearest_jail_pos(player)
	if not jailpos then
		return -- Failed to send player to jail.
	end

	preload_tp.execute({
		player_name = pname,
		target_position = jailpos,
		emerge_radius = 32,
		post_teleport_callback = fwrap,
		force_teleport = true,
		send_blocks = true,
		particle_effects = true,
	})

	-- Player should be sent to jail successfully, no reason for error right now.
	return true
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


jail.discharge_pref = jail.notify_player_death



if not jail.registered then
	local c = "jail:core"
	local f = jail.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	local jail_data = {
		name = "Jail",
		codename = "jail:jail",
		position = function(...) return jail.get_nearest_jail_pos(...) end,
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
			if jail.is_player_in_jail(player) then
				minetest.chat_send_player(name, "# Server: Error: security override. Recall is disabled within convict re-education block.")
				easyvend.sound_error(name)
				return true -- Too close to jail.
			end
		end
	end
	jail.suppress = jail_data.suppress

	-- The jail recall is mandatory.
	-- It is not grouped with other recall buttons in the passport formspec.
	passport.register_recall(jail_data)

	minetest.register_on_joinplayer(function(pref)
		minetest.after(5, jail.check_player_in_jail, pref:get_player_name())
	end)

	jail.registered = true
end

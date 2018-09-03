
-- Realm Control Mod.
-- This mod manages realm boundaries and prevents players from moving freely
-- between realms/dimensions without programmatic intervention.
rc = rc or {}
rc.modpath = minetest.get_modpath("rc")

rc.players = rc.players or {}

-- API function.
-- Check player position and current realm. If not valid, reset player to last
-- valid location. If last valid location not found, reset them to 0,0,0.
-- This function should be called from a global-step callback somewhere.
function rc.check_position(player)
	local p = player:get_pos()
	local n = player:get_player_name()

	local reset = false -- Flag set if player out-of-bounds.

	-- Bounds check to avoid an engine bug. These coordinates should be the last
	-- row of nodes at the map edge. This way, we never teleport the player to a
	-- location that is strictly outside the world boundaries, if they trigger it.
	if p.x < -30912 or p.x > 30927 or
			p.y < -30912 or p.y > 30927 or
			p.z < -30912 or p.z > 30927 then
		-- Some old clients, it seems, can randomly cause this problem.
		-- Or someone is deliberately triggering it.
		reset = true
	end

	if reset then
		-- Player is out-of-bounds. Reset to last known good position.
		minetest.chat_send_all("# Server: Player <" .. rename.gpn(n) ..
			"> was caught outside dimension boundaries!")

		-- Notify wield3d we'll adjusting the player position.
		-- Wielded item entities don't like sudden movement.
		wield3d.on_teleport()

		if rc.players[n] then
			player:set_pos(rc.players[n])
		else
			-- Return to central spawn.
			player:set_pos({x=0, y=-7, z=0})
		end

		-- Damage player. Prevents them triggering this indefinitely.
		if player:get_hp() > 0 then
			player:set_hp(player:get_hp() - 2)
			if player:get_hp() <= 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(n) ..
					"> found death in the Void.")
			end
		end

		return
	end

	-- If we got this far, the player is not out of bounds.
	-- Record last known good position.
	do
		local ps = rc.players[n]
		ps.x = p.x
		ps.y = p.y
		ps.z = p.z
	end
end

function rc.on_joinplayer(player)
	local n = player:get_player_name()
	local p = player:get_pos()
	rc.players[n] = p
end

function rc.on_leaveplayer(player, timeout)
	local n = player:get_player_name()
	rc.players[n] = nil
end

if not rc.registered then
	minetest.register_on_joinplayer(function(...)
		return rc.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return rc.on_leaveplayer(...)
	end)

	local c = "rc:core"
	local f = rc.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	rc.registered = true
end

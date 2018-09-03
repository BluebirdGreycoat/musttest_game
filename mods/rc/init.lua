
-- Realm Control Mod.
-- This mod manages realm boundaries and prevents players from moving freely
-- between realms/dimensions without programmatic intervention.
rc = rc or {}
rc.players = rc.players or {}
rc.modpath = minetest.get_modpath("rc")

-- Known realms. Min/max area positions should not overlap!
rc.realms = {
	{
		name = "overworld", -- Default/overworld realm.
		minp = {x=-30912, y=-30912, z=-30912},
		maxp = {x=30927, y=500, z=30927},
		orig = {x=0, y=-7, z=0}, -- Respawn point, if necessary.
	},
}

-- API function. Get string name of the current realm the player is in.
function rc.current_realm(player)
	local p = player:get_pos()

	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is player within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return v.name
		end
	end

	-- Not in any realm?
	return ""
end

-- API function.
-- Check player position and current realm. If not valid, reset player to last
-- valid location. If last valid location not found, reset them to 0,0,0.
-- This function should be called from a global-step callback somewhere.
function rc.check_position(player)
	local p = player:get_pos()
	local n = player:get_player_name()

	local reset -- Table set if player out-of-bounds.

	-- Bounds check to avoid an engine bug. These coordinates should be the last
	-- row of nodes at the map edge. This way, we never teleport the player to a
	-- location that is strictly outside the world boundaries, if they trigger it.
	if p.x < -30912 or p.x > 30927 or
			p.y < -30912 or p.y > 30927 or
			p.z < -30912 or p.z > 30927 then
		-- Some old clients, it seems, can randomly cause this problem.
		-- Or someone is deliberately triggering it.
		reset = {}
		reset.spawn = {x=0, y=-7, z=0}
	end

	-- Do bounds checks for individual realms.
	if not reset then
		for k, v in ipairs(rc.realms) do
			-- Is player within boundaries of the realm they are supposed to be in?
			if rc.players[n].realm == v.name then
				local minp = v.minp
				local maxp = v.maxp

				if p.x < minp.x or p.x > maxp.x or
						p.y < minp.y or p.y > maxp.y or
						p.z < minp.z or p.z > maxp.z then
					reset = {}
					reset.spawn = v.orig -- Use current realm's respawn coordinates.
					break
				end
			end
		end
	end

	if reset then
		-- Player is out-of-bounds. Reset to last known good position.
		minetest.chat_send_all("# Server: Player <" .. rename.gpn(n) ..
			"> was caught in the inter-dimensional plane!")

		-- Notify wield3d we're adjusting the player position.
		-- Wielded item entities don't like sudden movement.
		wield3d.on_teleport()

		if player:get_hp() > 0 and rc.players[n] then
			player:set_pos(rc.players[n].pos)
		else
			-- Return to realm's origin point.
			player:set_pos(reset.spawn)
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
	-- Record last known good position. Realm name should be same as before.
	do
		local ps = rc.players[n].pos
		ps.x = p.x
		ps.y = p.y
		ps.z = p.z
	end
end

function rc.on_joinplayer(player)
	local n = player:get_player_name()
	local p = player:get_pos()
	-- Player's current dimension is determined from position on login.
	rc.players[n] = {
		pos = p,
		realm = rc.current_realm(player),
	}
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

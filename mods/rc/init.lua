
-- Realm Control Mod.
-- This mod manages realm boundaries and prevents players from moving freely
-- between realms/dimensions without programmatic intervention.
rc = rc or {}
rc.players = rc.players or {}
rc.modpath = minetest.get_modpath("rc")

-- Known realms. Min/max area positions should not overlap!
rc.realms = {
	{
		id = 1, -- REALM ID. Code relies on this.
		name = "overworld", -- Default/overworld realm.
		description = "Overworld",
		minp = {x=-30912, y=-30912, z=-30912},
		maxp = {x=30927, y=500, z=30927},
		gate_minp = {x=-30000, y=-30800, z=-30000},
		gate_maxp = {x=30000, y=-10, z=30000},
		orig = {x=0, y=-7, z=0}, -- Respawn point, if necessary.
		ground = -9,
		sealevel = 0,
		windlevel = 20,
	},
	{
		id = 2, -- REALM ID. Code relies on this.
		name = "channelwood", -- Forest realm. 250 meters high.
		description = "Channelwood",
		minp = {x=-30912, y=3050, z=-30912},
		maxp = {x=30927, y=3300, z=30927},
		gate_minp = {x=-30000, y=3065, z=-30000},
		gate_maxp = {x=30000, y=3067, z=30000},
		orig = {x=0, y=-7, z=0}, -- Respawn point, if necessary.
		ground = 3066,
		sealevel = 3066,
		windlevel = 3100,
	},
}

function rc.pos_to_string(pos)
	local success, level = rc.get_ground_level_at_pos(pos)
	if success then
		local y = pos.y
		pos.y = pos.y - level
		local s = minetest.pos_to_string(pos)
		pos.y = y
		return s
	end

	-- Use absolute coordinates.
	return minetest.pos_to_string(pos)
end

function rc.get_realm_data(name)
	for k, v in ipairs(rc.realms) do
		if v.name == name then
			return v
		end
	end
	return nil
end

function rc.get_random_realm_gate_position(origin)
	if rc.is_valid_realm_pos(origin) then
		if origin.y >= 80 and origin.y <= 1000 then
			-- If gateway is positioned in the Overworld mountains,
			-- permit easy realm hopping.
			local realm = rc.realms[math.random(1, #rc.realms)]
			assert(realm)

			local pos = {
				x = math.random(realm.gate_minp.x, realm.gate_maxp.x),
				y = math.random(realm.gate_minp.y, realm.gate_maxp.y),
				z = math.random(realm.gate_minp.z, realm.gate_maxp.z),
			}

			return pos
		elseif origin.y > 1000 then
			-- The gateway is positioned in a realm somewhere.
			-- 9/10 times the exit point stays in the same realm.
			-- Sometimes a realm hop is possible.
			local realm
			if math.random(1, 10) == 1 then
				realm = rc.realms[math.random(1, #rc.realms)]
			else
				realm = rc.get_realm_data(rc.current_realm_at_pos(origin))
			end
			assert(realm)

			-- Not more than 5000 meters away from origin!
			local pos = {
				x = math.random(-5000, 5000) + origin.x,
				y = math.random(-5000, 5000) + origin.y,
				z = math.random(-5000, 5000) + origin.z,
			}

			local min = math.min
			local max = math.max

			-- Clamp position to ensure we remain within realm boundaries.
			pos.x = max(realm.gate_minp.x, min(pos.x, realm.gate_maxp.x))
			pos.y = max(realm.gate_minp.y, min(pos.y, realm.gate_maxp.y))
			pos.z = max(realm.gate_minp.z, min(pos.z, realm.gate_maxp.z))

			return pos
		end
	end

	local realm = rc.get_realm_data("overworld")
	assert(realm)

	-- Player is in the Overworld or Nether. Use old Gateway behavior!
	-- Not more than 5000 meters in any direction, and MUST stay in the Overworld
	-- (or the Nether).
	local pos = {
		x = math.random(-5000, 5000) + origin.x,
		y = math.random(-5000, 5000) + origin.y,
		z = math.random(-5000, 5000) + origin.z,
	}

	local min = math.min
	local max = math.max

	-- Clamp position.
	pos.x = max(realm.gate_minp.x, min(pos.x, realm.gate_maxp.x))
	pos.y = max(realm.gate_minp.y, min(pos.y, realm.gate_maxp.y))
	pos.z = max(realm.gate_minp.z, min(pos.z, realm.gate_maxp.z))

	return pos
end

function rc.is_valid_gateway_region(pos)
	local p = vector.round(pos)
	for k, v in ipairs(rc.realms) do
		local gate_minp = v.gate_minp
		local gate_maxp = v.gate_maxp

		-- Is position within realm boundaries suitable for a gateway?
		if p.x >= gate_minp.x and p.x <= gate_maxp.x and
				p.y >= gate_minp.y and p.y <= gate_maxp.y and
				p.z >= gate_minp.z and p.z <= gate_maxp.z then
			return true
		end
	end

	-- Not in any realm?
	return false
end

function rc.is_valid_realm_pos(pos)
	local p = vector.round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return true
		end
	end

	-- Not in any realm?
	return false
end

function rc.get_ground_level_at_pos(pos)
	local p = vector.round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return true, v.ground
		end
	end

	-- Not in any realm?
	return false, nil
end

function rc.get_sea_level_at_pos(pos)
	local p = vector.round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return true, v.sealevel
		end
	end

	-- Not in any realm?
	return false, nil
end

function rc.get_wind_level_at_pos(pos)
	local p = vector.round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return true, v.windlevel
		end
	end

	-- Not in any realm?
	return false, nil
end

-- API function. Get string name of the current realm the player is in.
function rc.current_realm(player)
	local p = vector.round(player:get_pos())
	return rc.current_realm_at_pos(p)
end

function rc.current_realm_at_pos(p)
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

function rc.realm_description_at_pos(p)
	-- Special realm name.
	if p.y < -25000 then
		return "Netherworld"
	elseif p.y < -5000 then
		return "Caverns"
	end

	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is player within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return v.description
		end
	end

	-- Not in any realm?
	return "Void"
end

-- API function.
-- Check player position and current realm. If not valid, reset player to last
-- valid location. If last valid location not found, reset them to 0,0,0.
-- This function should be called from a global-step callback somewhere.
function rc.check_position(player)
	local p = vector.round(player:get_pos())
	local n = player:get_player_name()

	-- Data not initialized yet.
	if not rc.players[n] then
		return
	end

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

	-- Check if player is currently in the void.
	if not reset then
		if rc.players[n].realm == "" then
			reset = {}
			reset.spawn = {x=0, y=-7, z=0}
		end
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
		if not gdac_invis.is_invisible(n) then
			minetest.chat_send_all("# Server: Player <" .. rename.gpn(n) ..
				"> was caught in the inter-dimensional void!")
		end

		-- Notify wield3d we're adjusting the player position.
		-- Wielded item entities don't like sudden movement.
		wield3d.on_teleport()

		if player:get_hp() > 0 and rc.players[n] then
			-- Return player to last known good position.
			player:set_pos(rc.players[n].pos)
		else
			-- Return to realm's origin point.
			player:set_pos(reset.spawn)

			-- Update which realm the player is supposed to be in.
			-- (We might have crossed realms depending on what happened above.)
			rc.notify_realm_update(player, reset.spawn)
		end

		-- Damage player. Prevents them triggering this indefinitely.
		if player:get_hp() > 0 then
			player:set_hp(player:get_hp() - 2)
			if player:get_hp() <= 0 then
				if not gdac_invis.is_invisible(n) then
					minetest.chat_send_all("# Server: <" .. rename.gpn(n) ..
						"> found death in the void.")
				end
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

-- API function. Call this whenever a player teleports,
-- or lawfully changes realm. You can pass a player object or a name.
function rc.notify_realm_update(player, pos)
	local p = vector.round(pos)
	local n = ""
	if type(player) == "string" then
		n = player
	else
		n = player:get_player_name()
	end
	local tb = rc.players[n]
	tb.pos = p
	tb.realm = rc.current_realm_at_pos(p)
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


-- Localize for performance.
local vector_round = vector.round

local function realm_to_actual(name)
	name = name:lower()
	for k, v in ipairs(rc.realms) do
		local desc = v.description:lower()
		if v.name == name or desc == name then
			return v.name
		end
	end
	return name
end

function serveressentials.do_teleport(name, param)
	name = name:trim()
	param = param:trim()

	-- Returns (pos, true) if found, otherwise (pos, false)
	local function find_free_position_near(pos)
		pos = vector_round(pos)
		local tries = {
			{x=1,y=0,z=0},
			{x=-1,y=0,z=0},
			{x=0,y=0,z=1},
			{x=0,y=0,z=-1},
		}
		for _, d in ipairs(tries) do
			local p = {x = pos.x+d.x, y = pos.y+d.y, z = pos.z+d.z}
			local n = core.get_node_or_nil(p)
			if n and n.name then
				local def = core.registered_nodes[n.name]
				if def and not def.walkable then
					if rc.is_valid_realm_pos(p) then
						return p, true
					end
				end
			end
		end
		return pos, false
	end

	-- Teleport player some distance in a cardinal direction.
	local teleportee = nil
	local distance = nil
	local direction = nil
	direction, distance = string.match(param, "^([^ ]+) *: *([%d]+)$")
	distance = tonumber(distance)

	if direction and distance then
		teleportee = minetest.get_player_by_name(name)
		if teleportee then
			local pname = teleportee:get_player_name()
			if default.player_attached[pname] or teleportee:get_attach() then
				return false, "Cannot teleport attached player."
			end

			distance = math.floor(distance)
			local havedir = false
			local pos = vector.round(teleportee:get_pos())

			if direction == "north" or direction == "n" then
				pos.z = pos.z + distance
				havedir = true
			elseif direction == "south" or direction == "s" then
				pos.z = pos.z - distance
				havedir = true
			elseif direction == "west" or direction == "w" then
				pos.x = pos.x - distance
				havedir = true
			elseif direction == "east" or direction == "e" then
				pos.x = pos.x + distance
				havedir = true
			elseif direction == "up" or direction == "u" then
				pos.y = pos.y + distance
				havedir = true
			elseif direction == "down" or direction == "d" then
				pos.y = pos.y - distance
				havedir = true
			end

			if havedir then
				if not rc.is_valid_realm_pos(pos) then
					return false, "Cannot teleport outside of any realm."
				end

				rc.notify_realm_update(pname, pos)
				jail.discharge_pref(teleportee)
				teleportee:set_pos(pos)
				return true, "Teleporting " .. distance .. " meters " .. direction .. "."
			end
		end
	end

	-- Teleport player to absolute coordinates.
	local teleportee = nil
	local p = {}
	p.x, p.y, p.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x = tonumber(p.x)
	p.y = tonumber(p.y)
	p.z = tonumber(p.z)
	if p.x and p.y and p.z then
		p = vector_round(p)
		local lm = 31000
		if p.x < -lm or p.x > lm or p.y < -lm or p.y > lm or p.z < -lm or p.z > lm then
			return false, "Cannot teleport out of map bounds."
		end
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm."
		end
		teleportee = core.get_player_by_name(name)
		if teleportee then
			if default.player_attached[teleportee:get_player_name()] or teleportee:get_attach() then
				return false, "Cannot teleport attached player."
			end

			local o = vector_round(teleportee:get_pos())
			rc.notify_realm_update(teleportee:get_player_name(), p)
			jail.discharge_pref(teleportee)
			teleportee:set_pos(p)
			return true, "Teleporting from " .. rc.pos_to_namestr(o) .. " to " .. core.pos_to_string(p) .. ", which is @ " .. rc.pos_to_namestr(p) .. "."
		end
	end

	-- Teleport player to relative realm coordinates.
	local teleportee = nil
	local p = {}
	local realm = nil
	--minetest.chat_send_player(name, param)
	realm, p.x, p.y, p.z = string.match(param, "^([^ ]+) *: *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x = tonumber(p.x)
	p.y = tonumber(p.y)
	p.z = tonumber(p.z)
	--minetest.chat_send_player(name, "Got: " .. realm .. ":" .. p.x .. "," .. p.y .. "," .. p.z)
	if realm and p.x and p.y and p.z then
		p = rc.realmpos_to_pos(realm_to_actual(realm), p)
		if not p then
			return false, "Cannot interpret realm coordinates."
		end
		local lm = 31000
		if p.x < -lm or p.x > lm or p.y < -lm or p.y > lm or p.z < -lm or p.z > lm then
			return false, "Cannot teleport out of map bounds."
		end
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm."
		end
		teleportee = core.get_player_by_name(name)
		if teleportee then
			if default.player_attached[teleportee:get_player_name()] or teleportee:get_attach() then
				return false, "Cannot teleport attached player."
			end

			local o = vector_round(teleportee:get_pos())
			rc.notify_realm_update(teleportee:get_player_name(), p)
			jail.discharge_pref(teleportee)
			teleportee:set_pos(p)
			return true, "Teleporting from " .. rc.pos_to_namestr(o) .. " to " .. rc.pos_to_namestr(p) .. "."
		end
	end

	-- Teleport self to target player.
	local teleportee = nil
	local p = nil
	local target_name = nil
	target_name = param:match("^([^ ]+)$")
	teleportee = core.get_player_by_name(name)
	if target_name then
		local target = core.get_player_by_name(target_name)
		if target then
			p = vector_round(target:get_pos())
		end
	end
	if teleportee and p then
		p = find_free_position_near(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm."
		end

		if default.player_attached[teleportee:get_player_name()] or teleportee:get_attach() then
			return false, "Cannot teleport attached player."
		end

		local o = vector_round(teleportee:get_pos())
		rc.notify_realm_update(teleportee:get_player_name(), p)
		jail.discharge_pref(teleportee)
		teleportee:set_pos(p)
		return true, "Teleporting from " .. rc.pos_to_namestr(o) .. " to <" .. rename.gpn(target_name) .. "> at " .. rc.pos_to_namestr(p) .. "."
	end

	if not core.check_player_privs(name, {bring=true}) then
		return false, "You don't have permission to teleport other players (missing bring privilege)."
	end

	-- Teleport target player to target coordinates.
	local teleportee = nil
	local p = {}
	local teleportee_name = nil
	teleportee_name, p.x, p.y, p.z = param:match("^([^ ]+) +([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x, p.y, p.z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
	if teleportee_name then
		teleportee = core.get_player_by_name(teleportee_name)
	end
	if teleportee and p.x and p.y and p.z then
		p = vector_round(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries."
		end

		if default.player_attached[teleportee:get_player_name()] or teleportee:get_attach() then
			return false, "Cannot teleport attached player."
		end

		local o = vector_round(teleportee:get_pos())
		rc.notify_realm_update(teleportee:get_player_name(), p)
		jail.discharge_pref(teleportee)
		teleportee:set_pos(p)
		return true, "Teleporting <" .. rename.gpn(teleportee_name) .. "> from " .. rc.pos_to_namestr(o) .. " to " .. core.pos_to_string(p) .. ", which is @ " .. rc.pos_to_namestr(p) .. "."
	end

	-- Teleport target player to realm relative coordinates.
	local teleportee = nil
	local p = {}
	local teleportee_name = nil
	local realm = nil
	teleportee_name, realm, p.x, p.y, p.z = param:match("^([^ ]+) +([^ ]+) *: *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x, p.y, p.z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
	if teleportee_name then
		teleportee = core.get_player_by_name(teleportee_name)
	end
	if teleportee and realm and p.x and p.y and p.z then
		p = rc.realmpos_to_pos(realm_to_actual(realm), p)
		if not p then
			return false, "Cannot interpret realm coordinates."
		end
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries."
		end

		if default.player_attached[teleportee:get_player_name()] or teleportee:get_attach() then
			return false, "Cannot teleport attached player."
		end

		local o = vector_round(teleportee:get_pos())
		rc.notify_realm_update(teleportee:get_player_name(), p)
		jail.discharge_pref(teleportee)
		teleportee:set_pos(p)
		return true, "Teleporting <" .. rename.gpn(teleportee_name) .. "> from " .. rc.pos_to_namestr(o) .. " to " .. rc.pos_to_namestr(p) .. "."
	end

	-- Teleport player to another player.
	local teleportee = nil
	local p = nil
	local teleportee_name = nil
	local target_name = nil
	teleportee_name, target_name = string.match(param, "^([^ ]+) +([^ ]+)$")
	if teleportee_name then
		teleportee = core.get_player_by_name(teleportee_name)
	end
	if target_name then
		local target = core.get_player_by_name(target_name)
		if target then
			p = target:get_pos()
		end
	end
	if teleportee and p then
		p = vector_round(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries."
		end

		if default.player_attached[teleportee:get_player_name()] or teleportee:get_attach() then
			return false, "Cannot teleport attached player."
		end

		p = find_free_position_near(p)
		local o = vector_round(teleportee:get_pos())
		rc.notify_realm_update(teleportee:get_player_name(), p)
		jail.discharge_pref(teleportee)
		teleportee:set_pos(p)
		return true, "Teleporting <" .. rename.gpn(teleportee_name) .. "> from " .. rc.pos_to_namestr(o) .. " to <" .. rename.gpn(target_name) .. "> at " .. rc.pos_to_namestr(p) .. "."
	end

	return false, 'Invalid parameters or player not found (see /help teleport).'
end

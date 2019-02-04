
serveressentials = serveressentials or {}
serveressentials.modpath = minetest.get_modpath("serveressentials")

function serveressentials.get_short_stack_desc(stack)
	local def = minetest.registered_items[stack:get_name()]
	local meta = stack:get_meta()
	local description = meta:get_string("description")
	if description ~= "" then
		return utility.get_short_desc(description):trim()
	elseif def and def.description then
		return utility.get_short_desc(def.description):trim()
	end
end

function serveressentials.whereis(pname, param)
	local target
	if param and param ~= "" then
		target = param
	else
		-- If no argument given, run function for all players.
		local players = minetest.get_connected_players()
		for _, player in ipairs(players) do
			local param = player:get_player_name()
			serveressentials.whereis(pname, param)
		end
		return
	end

	local player = minetest.get_player_by_name(target)
	if not player then
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> is not online!")
		return
	end

	local pos = vector.round(player:get_pos())
	local owner = protector.get_node_owner(pos) or ""

	local area = "in unclaimed territory"
	if owner ~= "" then
		area = "on land claimed by <" .. rename.gpn(owner) .. ">"
	end

	local nearby = ""
	local plist = {}

	local allplayers = minetest.get_connected_players()
	for _, player in ipairs(allplayers) do
		local pn = player:get_player_name() or ""
		if pn ~= target and vector.distance(player:get_pos(), pos) <= 64 then
			plist[#plist+1] = rename.gpn(pn)
		end
	end

	nearby = "{" .. table.concat(plist, ", ") .. "}"
	local HP = "HP=" .. player:get_hp()
	local wieldname = serveressentials.get_short_stack_desc(player:get_wielded_item())
	if not wieldname or wieldname == "" then
		wieldname = "nothing"
	else
		wieldname = "'" .. wieldname .. "'"
	end
	local wielding = "wielding " .. wieldname

	minetest.chat_send_player(pname,
		"# Server: Player <" .. rename.gpn(target) .. ">: in the " .. rc.realm_description_at_pos(pos) .. " at " .. rc.pos_to_string(pos) .. ", " ..
		HP .. ", " .. wielding .. ", " .. area .. ". Nearby: " .. nearby .. ".")
end



function serveressentials.do_teleport(name, param)
	name = name:trim()
	param = param:trim()

	-- Returns (pos, true) if found, otherwise (pos, false)
	local function find_free_position_near(pos)
		pos = vector.round(pos)
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

	local teleportee = nil
	local p = {}
	p.x, p.y, p.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x = tonumber(p.x)
	p.y = tonumber(p.y)
	p.z = tonumber(p.z)
	if p.x and p.y and p.z then
		p = vector.round(p)
		local lm = 31000
		if p.x < -lm or p.x > lm or p.y < -lm or p.y > lm or p.z < -lm or p.z > lm then
			return false, "Cannot teleport out of map bounds."
		end
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm."
		end
		teleportee = core.get_player_by_name(name)
		if teleportee then
			teleportee:set_pos(p)
			rc.notify_realm_update(teleportee:get_player_name(), p)
			return true, "Teleporting to " .. core.pos_to_string(p) .. ", which is @ " .. rc.pos_to_namestr(p) .. "."
		end
	end

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
		p = rc.realmpos_to_pos(realm, p)
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
			teleportee:set_pos(p)
			rc.notify_realm_update(teleportee:get_player_name(), p)
			return true, "Teleporting to " .. rc.pos_to_namestr(p) .. "."
		end
	end

	local teleportee = nil
	local p = nil
	local target_name = nil
	target_name = param:match("^([^ ]+)$")
	teleportee = core.get_player_by_name(name)
	if target_name then
		local target = core.get_player_by_name(target_name)
		if target then
			p = vector.round(target:get_pos())
		end
	end
	if teleportee and p then
		p = find_free_position_near(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport outside of any realm."
		end
		teleportee:set_pos(p)
		rc.notify_realm_update(teleportee:get_player_name(), p)
		return true, "Teleporting to <" .. rename.gpn(target_name) .. "> at " .. rc.pos_to_namestr(p) .. "."
	end

	if not core.check_player_privs(name, {bring=true}) then
		return false, "You don't have permission to teleport other players (missing bring privilege)."
	end

	local teleportee = nil
	local p = {}
	local teleportee_name = nil
	teleportee_name, p.x, p.y, p.z = param:match("^([^ ]+) +([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x, p.y, p.z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
	if teleportee_name then
		teleportee = core.get_player_by_name(teleportee_name)
	end
	if teleportee and p.x and p.y and p.z then
		p = vector.round(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries."
		end
		teleportee:set_pos(p)
		rc.notify_realm_update(teleportee:get_player_name(), p)
		return true, "Teleporting <" .. rename.gpn(teleportee_name) .. "> to " .. core.pos_to_string(p) .. ", which is @ " .. rc.pos_to_namestr(p) .. "."
	end

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
		p = vector.round(p)
		if not rc.is_valid_realm_pos(p) then
			return false, "Cannot teleport players outside realm boundaries."
		end
		p = find_free_position_near(p)
		teleportee:set_pos(p)
		rc.notify_realm_update(teleportee:get_player_name(), p)
		return true, "Teleporting <" .. rename.gpn(teleportee_name) .. "> to <" .. rename.gpn(target_name) .. "> at " .. rc.pos_to_namestr(p) .. "."
	end

	return false, 'Invalid parameters or player not found (see /help teleport).'
end



if not serveressentials.registered then
	assert(minetest.registered_chatcommands["teleport"])
	minetest.override_chatcommand("teleport", {
		func = function(name, param)
			wield3d.on_teleport()
			local result, str = serveressentials.do_teleport(name, param)
			minetest.chat_send_player(name, "# Server: " .. str)
		end,
	})

	minetest.register_privilege("whereis", {
		description = "Player may use the /whereis command to locate other players.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("whereis", {
		params = "[<player>]",
		description = "Locate a player or the caller.",
		privs = {whereis=true},

		func = function(...)
			return serveressentials.whereis(...)
		end
	})

	local c = "serveressentials:core"
	local f = serveressentials.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	serveressentials.registered = true
end






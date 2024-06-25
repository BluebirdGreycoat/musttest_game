
tape_measure = {}
local WAYPOINT_DISTANCE_LIMIT = 256

local function measure(stack, player, pointed)
	if not stack or not player or not pointed then
		return
	end

	local controls = player:get_player_control()
	local pos

	if controls.aux1 then
		pos = vector.round(player:get_pos())
	elseif pointed.type == "node" then
		if controls.sneak then
			pos = pointed.above
		else
			pos = pointed.under
		end
	else
		return
	end

	if not pos then
		return
	end

	if not rc.is_valid_realm_pos(pos) then
		return
	end

	local pname = player:get_player_name()
	local meta = stack:get_meta()
	local realm = meta:get("start_realm") -- Returns nil if not present.
	local start = meta:get("start_pos") -- Returns nil if not present.
	local spos = minetest.pos_to_string(pos)

	if (not start) or (rc.current_realm_at_pos(pos) ~= realm) then
		meta:set_string("start_pos", spos)
		meta:set_string("start_realm", rc.current_realm_at_pos(pos))
		minetest.chat_send_player(pname, "# Server: Start position set to " .. rc.pos_to_namestr(pos) .. ".")
		return stack
	end

	start = minetest.string_to_pos(start)
	minetest.chat_send_player(pname, "# Server: End position set to " .. rc.pos_to_namestr(pos) .. ".")
	meta:set_string("start_pos", "")
	meta:set_string("start_realm", "")

	local dist = vector.distance(start, pos)
	dist = string.format("%s", math.floor(dist * 100) / 100).."m"

	local offset = vector.subtract(pos, start)
	local x, y, z = math.abs(offset.x), math.abs(offset.y), math.abs(offset.z)
	local size = {x=x+1, y=y+1, z=z+1}

	minetest.chat_send_player(
		pname, "# Server: Distance: " .. dist .. " | Size: " ..
		minetest.pos_to_string(size) .. ".")

	return stack
end

local player_waypoints = {}

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	player_waypoints[pname] = nil
end)

minetest.register_on_dieplayer(function(player)
	local pname = player:get_player_name()
	local data = player_waypoints[pname]
	if data then
		player:hud_remove(data.id)
		player_waypoints[pname] = nil
	end
end)

function tape_measure.realm_check(pname)
	local data = player_waypoints[pname]
	if not data then
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local realm = rc.current_realm(pref)

	-- Remove waypoint if realm changed.
	if realm ~= data.realm then
		pref:hud_remove(data.id)
		player_waypoints[pname] = nil
		return
	end

	-- Remove waypoint if player went too far.
	if vector.distance(data.pos, pref:get_pos()) > WAYPOINT_DISTANCE_LIMIT then
		pref:hud_remove(data.id)
		player_waypoints[pname] = nil
		return
	end

	minetest.after(1, function()
		tape_measure.realm_check(pname)
	end)
end

local function waypoint(stack, player, pointed)
	if not player or not pointed then
		return
	end

	local controls = player:get_player_control()

	if pointed.type == "node" and not controls.sneak then
		local pos = pointed.under
		local node = minetest.get_node(pos)
		local def = minetest.registered_nodes[node.name]
		if def and def.on_rightclick then
			return def.on_rightclick(pos, node, player, stack, pointed) or stack, nil
		end
	end

	local pos

	if controls.aux1 then
		pos = vector.round(player:get_pos())
	elseif pointed.type == "node" then
		if controls.sneak then
			pos = pointed.above
		else
			pos = pointed.under
		end
	end

	local pname = player:get_player_name()
	local point = player_waypoints[pname]

	if point then
		if pos and not vector.equals(pos, point.pos) then
			player:hud_change(point.id, "world_pos", pos)
			player_waypoints[pname].pos = pos
			player_waypoints[pname].realm = rc.current_realm_at_pos(pos)
		else
			player:hud_remove(point.id)
			player_waypoints[pname] = nil
		end
		return
	end

	if not pos then
		return
	end

	local id = player:hud_add({
		type = "waypoint",
		name = "Tape Measure Mark",
		number = 0xFFFFFF,
		world_pos = pos,
	})

	player_waypoints[pname] = {
		id = id,
		pos = pos,
		realm = rc.current_realm_at_pos(pos),
	}

	minetest.after(1, function()
		tape_measure.realm_check(pname)
	end)
end

minetest.register_tool("tape_measure:tape_measure", {
	description = "Tape Measure",
	inventory_image = "tape_measure_inv.png",
	wield_image = "tape_measure_wield.png",
	groups = {tool = 1},
	on_use = measure,
	on_place = waypoint,
	on_secondary_use = waypoint,
})

dofile(minetest.get_modpath("tape_measure") .. "/crafting.lua")

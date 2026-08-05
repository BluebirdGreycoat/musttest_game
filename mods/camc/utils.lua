
--- Compute an over-shoulder camera position,
--- preserving the same look direction.
-- @param pos table  Player position {x, y, z}
-- @param yaw number  Horizontal look angle from player:get_look_horizontal()
-- @return table      New position {x, y, z}
local function get_right_shoulder_pos(pos, yaw)
	-- Right vector
	local right_x = math.cos(yaw)
	local right_z = math.sin(yaw)

	-- Backward vector (opposite of forward)
	local back_x = math.sin(yaw)
	local back_z = -math.cos(yaw)

	local backdist = 0.7
	local rightdist = 0.5
	local updist = 0.3

	return {
		x = pos.x + rightdist * right_x + backdist * back_x,
		y = pos.y + updist,
		z = pos.z + rightdist * right_z + backdist * back_z,
	}
end

function camc.snap_to(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	-- Not allowed to find cloaked or invisible.
	if cloaking.is_cloaked(pname) or gdac_invis.is_invisible(pname) then
		return
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		return
	end
	if not camc.player_is_camera(pcam) then
		return
	end

	local to_pos = pref:get_pos()

	local yaw = pref:get_look_horizontal()
	local pitch = pref:get_look_vertical()
	local rshoulderpos = get_right_shoulder_pos(to_pos, yaw)

	if not rc.is_valid_realm_pos(rshoulderpos) then
		return
	end

	if camc.viewpoint_buried(rshoulderpos) then
		rshoulderpos = to_pos
	end

	rc.notify_realm_update(pcam, rshoulderpos)

	pcam:set_pos(rshoulderpos)
	pcam:set_look_horizontal(yaw)
	pcam:set_look_vertical(pitch)

	return true
end

local function calc_look_at(player_pos, randomize)
	-- Place the camera some distance away, slightly above the player,
	-- at a random angle around them, and compute yaw/pitch so it looks
	-- directly at the player (downward).

	local distance = 9     -- horizontal distance from player
	local height   = 3.5   -- how far above the player

	if randomize then
		-- Random fractions.
		distance = math.random(200, 1000) / 100
		height = math.random(-500, 500) / 100
	end

	local angle = math.random() * math.pi * 2

	local offset = vector.new(
		math.cos(angle) * distance,
		height,
		math.sin(angle) * distance
	)

	local cam_pos = vector.add(player_pos, offset)

	-- Direction from camera to player (normalized)
	local dir = vector.direction(cam_pos, player_pos)

	local yaw   = minetest.dir_to_yaw(dir)
	local pitch = math.asin(-dir.y)

	return cam_pos, yaw, pitch
end

function camc.look_at(target)
	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if not pcam then
		return
	end
	if not camc.player_is_camera(pcam) then
		return
	end

	local target_p
	if type(target) == "string" then
		local pref = minetest.get_player_by_name(target)
		if not pref then
			return
		end
		target_p = pref:get_pos()
	elseif type(target) == "table" and target.x and target.y and target.z then
		target_p = target
	elseif type(target) == "userdata" then
		target_p = target:get_pos()
	end
	if not target_p then
		return
	end

	local cam_pos, yaw, pitch = calc_look_at(target_p)

	local function head_pos(cam_pos)
		return vector.add(cam_pos, {x=0, y=1.7, z=0})
	end

	-- If camera is buried, try a few times to find a good spot.
	if camc.viewpoint_buried(head_pos(cam_pos)) then
		local success = false
		for k = 1, camc.CAMERA_BURIED_NUM_RETRIES do
			cam_pos, yaw, pitch = calc_look_at(target_p, true)
			if not camc.viewpoint_buried(head_pos(cam_pos)) then
				success = true
				break
			end
		end

		if not success then
			return
		end
	end

	if not rc.is_valid_realm_pos(cam_pos) then
		return
	end

	rc.notify_realm_update(pcam, cam_pos)
	pcam:set_pos(cam_pos)
	pcam:set_look_horizontal(yaw)
	pcam:set_look_vertical(pitch)

	return true
end

-- Send server response to specific player and play error sound.
function camc.system_error(pname, errmsg)
	minetest.chat_send_player(pname, "# Server: " .. errmsg)
	easyvend.sound_error(pname)
end

function camc.system_response(pname, message)
	minetest.chat_send_player(pname, "# Server: " .. message)
end

function camc.check_player_existence(pname)
	return minetest.get_player_by_name(pname)
end

function camc.get_pref_complain_if_inexistent(pname)
	local pref = camc.check_player_existence(pname)
	if not pref then
		camc.system_response(pname, "You failed the existence test.")
	end
	return pref
end

function camc.send_region_to_player(player, minp, maxp)
	-- Convert node positions to mapblock positions
	local min_bp = vector.floor(vector.divide(minp, 16))
	local max_bp = vector.floor(vector.divide(maxp, 16))

	-- Send every mapblock in the region
	for x = min_bp.x, max_bp.x do
		for y = min_bp.y, max_bp.y do
			for z = min_bp.z, max_bp.z do
				player:send_mapblock(vector.new(x, y, z))
			end
		end
	end
end

--- Returns true if and only if the line segment from p1 to p2
--- contains no walkable (solid) nodes.
--- Uses the engine's Raycast (selection boxes) and explicitly tests the
--- walkable property.
function camc.has_clear_line_of_sight(p1, p2)
	-- objects = false, liquids = false
	local ray = minetest.raycast(p1, p2, false, false)

	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local def  = minetest.registered_nodes[node.name]

			-- Treat unknown / unloaded nodes as non-blocking.
			-- Change the condition if you prefer the opposite behaviour.
			if def and def.walkable then
				return false
			end
		end
	end

	return true
end

-- Get regular, hauntable players.
function camc.get_regular_players()
	local regular = {}
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if not gdac.player_is_admin(v) and not camc.player_is_camera(v) then
			local pname = v:get_player_name()
			if player_labels.query_nametag_onoff(pname) == true then
				regular[#regular + 1] = v
			end
		end
	end
	return regular
end

function camc.viewpoint_buried(pos)
	local hp = pos
	local d = 0.2
	local t = {
		vector.add(hp, {x=d, y=0, z=0}),
		vector.add(hp, {x=-d, y=0, z=0}),
		vector.add(hp, {x=0, y=0, z=d}),
		vector.add(hp, {x=0, y=0, z=-d}),
		vector.add(hp, {x=0, y=d, z=0}),
		vector.add(hp, {x=0, y=-d, z=0}),
	}
	for i = 1, #t do
		local p = t[i]
		local nn = minetest.get_node(p).name
		if nn ~= "air" then
			local ndef = minetest.registered_nodes[nn] or {}
			if ndef.walkable then
				return true
			end
		end
	end
end

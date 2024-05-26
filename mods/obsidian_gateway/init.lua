
if not minetest.global_exists("obsidian_gateway") then obsidian_gateway = {} end
obsidian_gateway.modpath = minetest.get_modpath("obsidian_gateway")

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_random = math.random



-- Gateway schematic.
local o = {"default:obsidian", "griefer:grieferstone", "cavestuff:dark_obsidian", "cavestuff:glow_obsidian"}
local a = function(name)
	-- Bones check needed here to prevent players from blocking a gate by dying in
	-- it. E.g., bones never decay while a hacker is online.
	if name == "air" or name == "bones:bones" then
		return true
	end

	if name == "nether:portal_liquid" or name == "nether:portal_hidden" then
		return true
	end
end

local gate_northsouth = {
	data = {
		{p={x=0, y=0, z=0}, n=o},
		{p={x=1, y=0, z=0}, n=o},
		{p={x=2, y=0, z=0}, n=o},
		{p={x=3, y=0, z=0}, n=o},
		{p={x=0, y=1, z=0}, n=o},
		{p={x=0, y=2, z=0}, n=o},
		{p={x=0, y=3, z=0}, n=o},
		{p={x=0, y=4, z=0}, n=o},
		{p={x=1, y=4, z=0}, n=o},
		{p={x=2, y=4, z=0}, n=o},
		{p={x=3, y=4, z=0}, n=o},
		{p={x=3, y=1, z=0}, n=o},
		{p={x=3, y=2, z=0}, n=o},
		{p={x=3, y=3, z=0}, n=o},
		{p={x=1, y=1, z=0}, n=a},
		{p={x=2, y=1, z=0}, n=a},
		{p={x=1, y=2, z=0}, n=a},
		{p={x=2, y=2, z=0}, n=a},
		{p={x=1, y=3, z=0}, n=a},
		{p={x=2, y=3, z=0}, n=a},
	},
	minp = {x=0, y=0, z=0},
	maxp = {x=3, y=4, z=0},
}

local gate_eastwest = {
	data = {
		{p={x=0, y=0, z=0}, n=o},
		{p={x=0, y=0, z=1}, n=o},
		{p={x=0, y=0, z=2}, n=o},
		{p={x=0, y=0, z=3}, n=o},
		{p={x=0, y=1, z=0}, n=o},
		{p={x=0, y=2, z=0}, n=o},
		{p={x=0, y=3, z=0}, n=o},
		{p={x=0, y=4, z=0}, n=o},
		{p={x=0, y=4, z=1}, n=o},
		{p={x=0, y=4, z=2}, n=o},
		{p={x=0, y=4, z=3}, n=o},
		{p={x=0, y=1, z=3}, n=o},
		{p={x=0, y=2, z=3}, n=o},
		{p={x=0, y=3, z=3}, n=o},
		{p={x=0, y=1, z=1}, n=a},
		{p={x=0, y=1, z=2}, n=a},
		{p={x=0, y=2, z=1}, n=a},
		{p={x=0, y=2, z=2}, n=a},
		{p={x=0, y=3, z=1}, n=a},
		{p={x=0, y=3, z=2}, n=a},
	},
	minp = {x=0, y=0, z=0},
	maxp = {x=0, y=4, z=3},
}

obsidian_gateway.gate_ns_data = gate_northsouth
obsidian_gateway.gate_ew_data = gate_eastwest



-- Quickly check for protection in an area.
local function check_protection(pos, radius)
	-- How much beyond the radius to check for protections.
	local e = 3

	local minp = vector.new(pos.x-(radius+e), pos.y-(radius+e), pos.z-(radius+e))
	local maxp = vector.new(pos.x+(radius+e), pos.y+(radius+e), pos.z+(radius+e))

	-- Step size, to avoid checking every single node.
	-- This assumes protections cannot be smaller than this size.
	local ss = 3
	local check = minetest.test_protection

	for x=minp.x, maxp.x, ss do
		for y=minp.y, maxp.y, ss do
			for z=minp.z, maxp.z, ss do
				if check({x=x, y=y, z=z}, "") then
					-- Protections are present.
					return true
				end
			end
		end
	end

	-- Nothing in the area is protected.
	return false
end



-- Get a list of node positions inside the gate's frame.
function obsidian_gateway.door_positions(origin, northsouth)
	local airpoints
	if northsouth then
		local o = origin
		airpoints = {
			{x=o.x+1, y=o.y+1, z=o.z+0},
			{x=o.x+2, y=o.y+1, z=o.z+0},
			{x=o.x+1, y=o.y+2, z=o.z+0},
			{x=o.x+2, y=o.y+2, z=o.z+0},
			{x=o.x+1, y=o.y+3, z=o.z+0},
			{x=o.x+2, y=o.y+3, z=o.z+0},
		}
	else
		local o = origin
		airpoints = {
			{x=o.x+0, y=o.y+1, z=o.z+1},
			{x=o.x+0, y=o.y+1, z=o.z+2},
			{x=o.x+0, y=o.y+2, z=o.z+1},
			{x=o.x+0, y=o.y+2, z=o.z+2},
			{x=o.x+0, y=o.y+3, z=o.z+1},
			{x=o.x+0, y=o.y+3, z=o.z+2},
		}
	end
	return airpoints
end



function obsidian_gateway.spawn_liquid(origin, northsouth, returngate, force)
	local color = 6
	local rotation = 1
	local str_origin = minetest.pos_to_string(origin)

	if northsouth then
		rotation = 0
	end

	if returngate then
		color = 5
	end

	-- Node's drawtype is "colorfacedir".
	local node = {
		name = "nether:portal_liquid",
		param2 = (color * 32 + rotation),
	}

	local vadd = vector.add
	local airpoints = obsidian_gateway.door_positions(origin, northsouth)
	local spawned = false

	local count = #airpoints
	for k = 1, count, 1 do
		local p = airpoints[k]
		local oldnode = minetest.get_node(p)

		-- Make sure node to be replaced is air. If we were to overwrite any
		-- existing portal liquid, that would cause callbacks to run, which would
		-- interfere with what we're doing here.
		if oldnode.name == "air" then
			-- Run 'on_construct' callbacks, etc.
			minetest.set_node(p, node)

			-- This tells the particle code (inside node's on_timer) what color to use.
			local meta = minetest.get_meta(p)
			if returngate then
				meta:set_string("color", "red")
			else
				meta:set_string("color", "gold")
			end
			meta:set_string("gate_origin", str_origin)
			meta:set_string("gate_northsouth", tostring(northsouth))

			meta:mark_as_private({"color", "gate_origin", "gate_northsouth"})

			spawned = true
		elseif force and oldnode.name == "nether:portal_hidden" then
			minetest.swap_node(p, node)

			-- Manually execute callback.
			local ndef = minetest.registered_nodes[node.name]
			ndef.on_construct(p)

			-- Do not need to set "color" meta here, the hidden node already has it.
			-- Same with 'gate_origin'.

			spawned = true
		end
	end

	if spawned then
		ambiance.sound_play("nether_portal_ignite", origin, 1.0, 64)
	end
end



-- Determine whether the gateway has active portal liquid.
function obsidian_gateway.have_liquid(origin, northsouth)
	local airpoints = obsidian_gateway.door_positions(origin, northsouth)
	local total = 0

	local count = #airpoints
	for k = 1, count, 1 do
		local p = airpoints[k]
		local node = minetest.get_node(p)

		if node.name == "nether:portal_liquid" then
			total = total + 1
		end
	end

	return (total == 6)
end



-- Get gate's origin and northsouth/eastwest orientation.
function obsidian_gateway.get_origin_and_dir(pos)
	local meta = minetest.get_meta(pos)
	local str_origin = meta:get_string("gate_origin")
	local str_northsouth = meta:get_string("gate_northsouth")

	local origin = minetest.string_to_pos(str_origin)
	if origin then
		-- Returns origin, true/false.
		return origin, (str_northsouth == "true")
	end
end



function obsidian_gateway.remove_liquid(pos, points)
	local node = {name="air"}
	local removed = false
	local count = #points

	for k = 1, count, 1 do
		local v = points[k]
		local n = minetest.get_node(v)

		if n.name == "nether:portal_liquid" then
			-- Must use 'swap_node' to avoid triggering further callbacks on the
			-- portal liquid node (and nearby portal liquid nodes).
			minetest.swap_node(v, node)
			removed = true
		elseif n.name == "nether:portal_hidden" then
			minetest.swap_node(v, node)
			-- Node is hidden, so do not set 'removed' flag (removal makes no sound).
		end
	end
	if removed then
		ambiance.sound_play("nether_portal_extinguish", pos, 1.0, 64)
	end
end



function obsidian_gateway.regenerate_liquid(target, northsouth)
	local success, so, ap, ns, key, po =
		obsidian_gateway.find_gate(target, northsouth)

	-- Spawn portal liquid only if there is a gate here with the expected
	-- orientation. Force liquid placement over hidden portal nodes.
	if success then
		local meta = minetest.get_meta(so)
		local isreturngate = (meta:get_int("obsidian_gateway_return_gate_" .. key) == 1)

		obsidian_gateway.spawn_liquid(so, ns, isreturngate, true)
	end
end



function obsidian_gateway.find_gate(pos, require_ns)
	local result
	local points
	local counts
	local origin

	local northsouth
	local ns_key
	local playerorigin

	-- Find the gateway (threshold under player)!
	result, points, counts, origin =
		schematic_find.detect_schematic(pos, gate_northsouth)

	northsouth = true
	ns_key = "ns"

	if result then
		playerorigin = vector.add(origin, {x=1, y=1, z=0})
	end

	if not result then
		-- Couldn't find northsouth gateway, so try to find eastwest.
		result, points, counts, origin =
			schematic_find.detect_schematic(pos, gate_eastwest)

		northsouth = false
		ns_key = "ew"

		if result then
			playerorigin = vector.add(origin, {x=0, y=1, z=1})
		end
	end

	-- Early exit.
	if not result then
		return
	end

	-- If a specific orientation is required, then check that.
	if require_ns ~= nil then
		if northsouth ~= require_ns then
			return
		end
	end

	-- Store locations of air/portal nodes inside the gateway.
	local airpoints = {}
	if result then
		for k, v in ipairs(points) do
			local nn = minetest.get_node(v).name
			if nn == "air" or nn == "nether:portal_liquid" or
					nn == "nether:portal_hidden" then
				airpoints[#airpoints+1] = v
			end
		end
	end

	-- Did we find a working gateway?
	local yes = false
	if result then
		local o = counts["default:obsidian"] or 0
		local d = counts["cavestuff:dark_obsidian"] or 0
		local c = counts["cavestuff:glow_obsidian"] or 0
		local g = counts["griefer:grieferstone"] or 0
		local a = (#airpoints == 6)
		if (o + d + c) == 12 and g == 2 and a == true then
			yes = true
		end
	end

	if yes then
		return true, origin, airpoints, northsouth, ns_key, playerorigin
	end
end



function obsidian_gateway.attempt_activation(pos, player, itemstring)
	local pname = player:get_player_name()
	local ppos = vector_round(player:get_pos())

	local under = utility.node_under_pos(player:get_pos())
	local inside = vector.add(under, {x=0, y=1, z=0})
	local nodeunder = minetest.get_node(under).name
	-- Player must be standing on one of these.
	if nodeunder ~= "default:obsidian" and
			nodeunder ~= "griefer:grieferstone" and
			nodeunder ~= "cavestuff:dark_obsidian" and
			nodeunder ~= "cavestuff:glow_obsidian" then
		-- This triggers when other types of portals are used, so is incorrect to display this chat.
		--minetest.chat_send_player(pname, "# Server: You need to be standing in the gateway for it to work!")
		return
	end

	local success
	local origin
	local northsouth
	local ns_key
	local playerorigin
	local airpoints

	success, origin, airpoints, northsouth, ns_key, playerorigin =
		obsidian_gateway.find_gate(pos)

	if not success then
		return
	end

	-- Add/update sound beacon.
	ambiance.spawn_sound_beacon("soundbeacon:gate", origin, 20, 1)
	ambiance.replay_nearby_sound_beacons(origin, 6)

	if sheriff.is_cheater(pname) then
		if sheriff.punish_probability(pname) then
			sheriff.punish_player(pname)
			return
		end
	end

	local target
	local meta = minetest.get_meta(origin)
	-- By spliting the key names by ns/ew, I ensure connected portals don't
	-- stomp on each other's data.
	target = minetest.string_to_pos(meta:get_string("obsidian_gateway_destination_" .. ns_key))
	--if not target then
	--	minetest.chat_send_player(pname, "# Server: Gateway has no destination! Aborting.")
	--	return
	--end

	-- Enable this if any serious problems occur.
	--if pname ~= gdac.name_of_admin then
	--	minetest.chat_send_player(pname, "# Server: Safety abort! Gateways are locked until further notice due to an error in the code.")
	--	return
	--end

	-- If activating the gate in the OUTBACK, and player previously died in
	-- MIDFELD, send them back to MIDFELD, do NOT send them to the overworld.
	if rc.current_realm_at_pos(origin) == "abyss" then
		if player:get_meta():get_int("abyss_return_midfeld") == 1 then
			target = obsidian_gateway.get_midfeld_spawn()
		end
	end

	-- Gates CANNOT be initialized in the Abyss!
	-- (Only the outgoing realm-gate is useable.)
	-- This prevents players from building their own gates in the Abyss.
	if not target and rc.current_realm_at_pos(origin) == "abyss" then
		minetest.after(0, function()
			-- Detonate some TNT!
			tnt.boom(vector.add(ppos, {x=math_random(-3, 3), y=0, z=math_random(-3, 3)}), {
				radius = 3,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 5,
				disable_drops = true,
			})
		end)
		return
	end

	local isreturngate = (meta:get_int("obsidian_gateway_return_gate_" .. ns_key) == 1)
	local actual_owner = meta:get_string("obsidian_gateway_owner_" .. ns_key)
	local isowner = (actual_owner == pname)

	local first_time_init = false

	minetest.log("action", pname .. " activated gateway @ " .. minetest.pos_to_string(pos))

	-- Initialize gateway for the first time.
	if itemstring == "pearl" then
	if not target or (meta:get_string("obsidian_gateway_success_" .. ns_key) ~= "yes" and not isreturngate) then
		-- Target is valid then this could be an OLD gate with old metadata.
		-- This can ALSO happen if player initializes a new gate twice or more times before
		-- the first initialization completes.
		if target and not isreturngate and meta:get_string("obsidian_gateway_success_" .. ns_key) == "" then
			minetest.chat_send_player(pname, "# Server: It looks like this could possibly be an OLD gate! Aborting for safety reasons.")
			minetest.chat_send_player(pname, "# Server: If this Gateway was previously functioning normally, please mail the admin with the coordinates.")
			minetest.chat_send_player(pname, "# Server: If this is a Gate that you have just constructed, you can safely ignore this message.")
			minetest.chat_send_player(pname, "# Server: The Gateway's EXIT location is @ " .. rc.pos_to_namestr(target) .. ".")
			minetest.after(1.5, function() easyvend.sound_error(pname) end)
			return 
		end
		-- Algorithm for locating the destination.

		-- Get a potential gate location.
		target = rc.get_random_realm_gate_position(pname, origin)

		-- Is target outside bounds?
		local bad = function(target, origin)
			-- Handle nil.
			if not target then
				return true
			end
			-- Don't allow exit points near the colonies.
			if vector_distance(target, {x=0, y=0, z=0}) < 1000 or
				vector_distance(target, {x=0, y=-30790, z=0}) < 1000 then
				return true
			end
			-- Exit must not be too close to start.
			if vector_distance(target, origin) < 100 then
				return true
			end
			-- Or too far.
			-- This causes too many failures.
			-- Note: this is now handled by the 'rc' mod.
			--if vector_distance(target, origin) > 7000 then
			--	return true
			--end
			if not rc.is_valid_gateway_region(target) then
				return true
			end
		end

		-- Keep trying until the target is within bounds.
		local num_tries = 0
		while bad(target, origin) do
			target = rc.get_random_realm_gate_position(pname, origin)
			num_tries = num_tries + 1

			-- Max 3 tries.
			if num_tries >= 2 then
				---[[
				minetest.after(0, function()
					-- Detonate some TNT!
					tnt.boom(vector.add(ppos, {x=math_random(-3, 3), y=0, z=math_random(-3, 3)}), {
						radius = 3,
						ignore_protection = false,
						ignore_on_blast = false,
						damage_radius = 5,
						disable_drops = true,
					})
				end)
				--]]
				return
			end
		end

		meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(target))
		meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)

		meta:mark_as_private({
			"obsidian_gateway_destination_" .. ns_key,
			"obsidian_gateway_owner_" .. ns_key
		})

		first_time_init = true
		isowner = true
	else
		-- Used a pearl but gate already activated.
		return
	end
	end -- Itemstring is "pearl".

	-- Happens if gate is not initialized and we didn't use a pearl to activate it.
	if not target then
		return
	end

	-- Event horizon color depends on whether we are a return gate.
	obsidian_gateway.spawn_liquid(origin, northsouth, isreturngate)

	if gdac.player_is_admin(pname) then
		isowner = true
	end

	-- Let everyone use gates owned by the admin.
	if actual_owner == gdac.name_of_admin then
		isowner = true
	end

	-- Slightly randomize player's exit coordinates.
	-- Without changing the coordinates of the gateway.
	local pdest
	if northsouth then
		pdest = vector.add(target, {x=math_random(0, 1), y=0, z=0})
	else
		pdest = vector.add(target, {x=0, y=0, z=math_random(0, 1)})
	end
	pdest = vector_round(pdest)

	-- Make sure target is within some realm.
	-- This generally should not happen.
	if not rc.is_valid_realm_pos(pdest) then
		return
	end

	-- Collect any friends to bring along.
	local friendstobring = {}
	local allplayers = minetest.get_connected_players()
	for k, v in ipairs(allplayers) do
		if v:get_player_name() ~= pname then
			if vector_distance(v:get_pos(), player:get_pos()) < 3 then
				friendstobring[#friendstobring+1] = v:get_player_name()
			end
		end
	end

	portal_cb.call_before_use({
		gate_origin = origin,
		gate_orientation = ns_key, -- "ns" or "ew"
		player_name = pname,
		teleport_destination = table.copy(pdest),
	})

	-- Create a gateway at the player's destination.
	-- This gateway links back to the first.
	-- If it is destroyed, the player is stuck!
	preload_tp.execute({
		player_name = pname,
		target_position = pdest,
		emerge_radius = 32,
		particle_effects = true,

		-- Force teleport on first init.
		-- This should reduce problems due to the player moving around and canceling
		-- the teleport on a new gate.
		force_teleport = first_time_init,

		pre_teleport_callback = function()
			-- Cancel teleport if origin gate does not have portal liquid.
			if not obsidian_gateway.have_liquid(origin, northsouth) then
				minetest.chat_send_player(pname, "# Server: Portal disrupted.")
				-- Cancel transport.
				return true
			end

			-- Don't build return portal on top of someone's protected stuff.
			if first_time_init then
				if check_protection(vector.add(target, {x=0, y=3, z=0}), 5) then
					minetest.chat_send_player(pname, "# Server: Return-gate construction FAILED due to protection near " .. rc.pos_to_namestr(target) .. ".")

					-- Clear data for the initial gate. This will permit the player to retry without tearing everything down and building it again.
					local meta = minetest.get_meta(origin)
					meta:set_string("obsidian_gateway_success_" .. ns_key, "")
					meta:set_string("obsidian_gateway_destination_" .. ns_key, "")
					meta:set_string("obsidian_gateway_owner_" .. ns_key, "")

					meta:mark_as_private({
						"obsidian_gateway_success_" .. ns_key,
						"obsidian_gateway_destination_" .. ns_key,
						"obsidian_gateway_owner_" .. ns_key
					})

					-- Cancel transport.
					return true
				end
			end

			-- Build return portal (only if not already using a return portal).
			-- Also, only build return portal on first use of the initial portal.
			if not isreturngate and first_time_init then
				if northsouth then
					-- Place northsouth gateway.
					local path = obsidian_gateway.modpath .. "/obsidian_gateway_northsouth.mts"
					local gpos = vector.add(target, {x=-1, y=-1, z=0})
					minetest.place_schematic(gpos, path, "0", nil, true)
					local meta = minetest.get_meta(gpos)
					meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
					meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)
					meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 1)

					meta:mark_as_private({
						"obsidian_gateway_destination_" .. ns_key,
						"obsidian_gateway_owner_" .. ns_key,
						"obsidian_gateway_return_gate_" .. ns_key
					})
				else
					-- Place eastwest gateway.
					local path = obsidian_gateway.modpath .. "/obsidian_gateway_eastwest.mts"
					local gpos = vector.add(target, {x=0, y=-1, z=-1})
					minetest.place_schematic(gpos, path, "0", nil, true)
					local meta = minetest.get_meta(gpos)
					meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
					meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)
					meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 1)

					meta:mark_as_private({
						"obsidian_gateway_destination_" .. ns_key,
						"obsidian_gateway_owner_" .. ns_key,
						"obsidian_gateway_return_gate_" .. ns_key
					})
				end
			end

			-- Mark the initial gate as success.
			-- If this is not done, then gate will assume it is not initialized
			-- the next time it is used. This fixes a bug where the return gate is
			-- not properly constructed if the player moves during transport
			-- (because this callback function doesn't get called).
			if not isreturngate and first_time_init then
				local meta = minetest.get_meta(origin)
				meta:set_string("obsidian_gateway_success_" .. ns_key, "yes")
				meta:mark_as_private("obsidian_gateway_success_" .. ns_key)
			end

			-- If the destination is the Abyss, then kill player first.
			-- This helps to prevent player from bringing any foreign items into this realm.
			-- Note: this relies on the teleport code already checking all other preconditions
			-- first. I.e., if this callback returns 'false', then the player absolutely
			-- will be teleported.
			if rc.current_realm_at_pos(pdest) == "abyss" then
				-- Dump player bones, as if they died.
				-- This should behave exactly as if the player died, with the exception of
				-- setting the player's health to 0.
				bones.dump_bones(pname, true)
				local pref = minetest.get_player_by_name(pname)
				pref:set_hp(pova.get_active_modifier(pref, "properties").hp_max)
				pref:get_meta():set_string("last_death_pos", "") -- Fake death.
				give_initial_stuff.give(pref)
			end

			-- Always regenerate portal liquid in the destination portal.
			-- (It will often be missing since no one was near it.)
			-- This function will check if there actually is a gate, here.
			obsidian_gateway.regenerate_liquid(target, northsouth)

			-- If the player is someone other than the owner, using this Gate has consequences.
			if not isowner then
				-- This function is already called normally, when a Gate is used.
				-- Calling it again here, effectively doubles the chance that the user
				-- starts feeling rather ill.
				portal_sickness.on_use_portal(pname)
			end
		end,

		post_teleport_callback = function()
			portal_cb.call_after_use({
				gate_origin = origin,
				gate_orientation = ns_key, -- "ns" or "ew"
				player_name = pname,
				teleport_destination = table.copy(pdest),
			})

			-- Any others in area get brought along, too.
			for k, v in ipairs(friendstobring) do
				local friend = minetest.get_player_by_name(v)
				if friend then
					local fname = friend:get_player_name()

					preload_tp.execute({
						player_name = fname,
						target_position = pdest,
						particle_effects = true,

						pre_teleport_callback = function()
							-- If the destination is the Abyss, then kill player first.
							-- Note: this relies on the teleport code already checking all other preconditions
							-- first. I.e., if this callback returns 'false', then the player absolutely
							-- will be teleported.
							if rc.current_realm_at_pos(pdest) == "abyss" then
								-- Dump player bones, as if they died.
								-- This should behave exactly as if the player died, with the exception of
								-- setting the player's health to 0.
								bones.dump_bones(fname, true)
								local pref = minetest.get_player_by_name(fname)
								pref:set_hp(pova.get_active_modifier(pref, "properties").hp_max)
								pref:get_meta():set_string("last_death_pos", "") -- Fake death.
								give_initial_stuff.give(pref)
							end
						end,

						force_teleport = true,
						send_blocks = true,
					})

					portal_sickness.on_use_portal(fname)
				end
			end

			-- Update liquids around on first init.
			if first_time_init then
				minetest.after(2, function()
					mapfix.execute(target, 10)
				end)
			end

			ambiance.spawn_sound_beacon("soundbeacon:gate", target, 20, 1)
			ambiance.replay_nearby_sound_beacons(target, 6)
			portal_sickness.on_use_portal(pname)

			-- Clear player's "died in MIDFELD" flag, once transport to MIDFELD succeeded.
			if rc.current_realm_at_pos(target) == "midfeld" then
				local pref = minetest.get_player_by_name(pname)
				if pref then
					pref:get_meta():set_int("abyss_return_midfeld", 0)
				end
			end
		end,

		teleport_sound = "nether_portal_usual",
		send_blocks = true,
	})

	return true
end



-- To be called inside node's 'on_destruct' callback.
-- Note: 'transient' is ONLY true when node to be destructed is portal liquid!
function obsidian_gateway.on_damage_gate(pos, transient)
	-- First, perform some cheap checks to see if there could possibly be a gate
	-- at this location. We only perform the expensive checks if the cheap checks
	-- pass!
	local minp = vector.add(pos, {x=-4, y=-4, z=-4})
	local maxp = vector.add(pos, {x=4, y=4, z=4})
	local names = {
		"default:obsidian",
		"cavestuff:dark_obsidian",
		"cavestuff:glow_obsidian",
		"griefer:grieferstone",
		"nether:portal_liquid",
		"nether:portal_hidden",
	}

	local points, counts = minetest.find_nodes_in_area(minp, maxp, names)
	if #points == 0 then
		return
	end
	local doorpoints = points

	-- Remove all portal-liquid nodes. (Will play sound if any removed.)
	-- First, try to get gate origin from meta. If this fails, then we use the
	-- 'points' array as a fallback (old behavior).
	local origin, northsouth = obsidian_gateway.get_origin_and_dir(pos)
	if origin then
		doorpoints = obsidian_gateway.door_positions(origin, northsouth)
	end
	minetest.after(0, obsidian_gateway.remove_liquid, pos, doorpoints)

	-- If transient "pop" of portal liquid nodes, then do not continue further to
	-- actually damage the gate.
	if transient then
		return
	end

	-- A valid gate requires exactly 2 oerkki stone.
	-- (There may be additional oerkki stone not part of the gate.)
	if counts["griefer:grieferstone"] < 2 then
		return
	end

	do
		local o = counts["default:obsidian"] or 0
		local d = counts["cavestuff:dark_obsidian"] or 0
		local c = counts["cavestuff:glow_obsidian"] or 0

		-- Including the node that will be removed (we should have been called
		-- inside of 'on_destruct' for a given node), there should be 12 obsidian
		-- remaining, otherwise cannot be a valid gate. (There may be additional
		-- obsidian nearby not part of the gate.)
		if (o + d + c) < 12 then
			return
		end
	end

	-- Cheap checks completed, now do the expensive check.
	if not obsidian_gateway.find_gate(pos) then
		return
	end

	-- If we reach here, we know we have a valid gate attached to this position.
	-- We don't care if it is a NS or EW-facing gate.

	-- This has a chance to destroy one of the oerkki stones, which costs some
	-- resources to craft again. But don't spawn lava in overworld. The point of
	-- this is to make it a bit more costly to constantly reset the gate if you
	-- don't like where it goes. Note: using 'swap_node' first in order to prevent
	-- calling additional callbacks.
	local idx = math.random(1, #points)
	local tar = points[idx]
	minetest.swap_node(tar, {name="air"})
	minetest.set_node(tar, {name="fire:basic_flame"})
	ambiance.sound_play("nether_rack_destroy", pos, 1.0, 64)
end



dofile(obsidian_gateway.modpath .. "/flame_staff.lua")



if not obsidian_gateway.run_once then
	local c = "obsidian_gateway:core"
	local f = obsidian_gateway.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	obsidian_gateway.run_once = true
end

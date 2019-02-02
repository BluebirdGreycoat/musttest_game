
obsidian_gateway = obsidian_gateway or {}
obsidian_gateway.modpath = minetest.get_modpath("obsidian_gateway")



-- Gateway schematic.
local o = {"default:obsidian", "griefer:grieferstone", "cavestuff:dark_obsidian", "cavestuff:glow_obsidian"}
local a = "air"

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



function obsidian_gateway.attempt_activation(pos, player)
	local pname = player:get_player_name()
	local ppos = vector.round(vector.add(utility.get_foot_pos(player:get_pos()), {x=0, y=0.3, z=0}))

	local under = vector.add(ppos, {x=0, y=-1, z=0})
	local inside = vector.add(under, {x=0, y=1, z=0})
	local nodeunder = minetest.get_node(under).name
	-- Player must be standing on one of these.
	if nodeunder ~= "default:obsidian" and
			nodeunder ~= "griefer:grieferstone" and
			nodeunder ~= "cavestuff:dark_obsidian" then
		-- This triggers when other types of portals are used, so is incorrect to display this chat.
		--minetest.chat_send_player(pname, "# Server: You need to be standing in the gateway for it to work!")
		return
	end

	local result
	local points
	local counts
	local origin

	local northsouth
	local ns_key
	local playerorigin

	-- Find the gateway (threshold under player)!
	result, points, counts, origin =
		schematic_find.detect_schematic(inside, gate_northsouth)
	northsouth = true
	ns_key = "ns"
	if result then
		playerorigin = vector.add(origin, {x=1, y=1, z=0})
	end
	if not result then
		-- Couldn't find northsouth gateway, so try to find eastwest.
		result, points, counts, origin =
			schematic_find.detect_schematic(inside, gate_eastwest)
		northsouth = false
		ns_key = "ew"
		if result then
			playerorigin = vector.add(origin, {x=0, y=1, z=1})
		end
	end

	-- Debugging.
	if not result then
		--minetest.chat_send_player(pname, "# Server: Bad gateway.")
		return
	end

	-- Store locations of air inside the portal gateway.
	local airpoints = {}
	if result then
		for k, v in ipairs(points) do
			if minetest.get_node(v).name == "air" then
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
		if (o + d + c) == 12 and g == 2 then
			yes = true
		end
	end
	if not yes then
		return
	end

	minetest.log("action", pname .. " activated gateway @ " .. minetest.pos_to_string(pos))

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
	--if pname ~= "MustTest" then
	--	minetest.chat_send_player(pname, "# Server: Safety abort! Gateways are locked until further notice due to an error in the code.")
	--	return
	--end

	local isreturngate = (meta:get_int("obsidian_gateway_return_gate_" .. ns_key) == 1)
	local isowner = (meta:get_string("obsidian_gateway_owner_" .. ns_key) == pname)

	local first_time_init = false

	-- Initialize gateway for the first time.
	if not target or (meta:get_string("obsidian_gateway_success_" .. ns_key) ~= "yes" and not isreturngate) then
		-- Target is valid then this could be an OLD gate with old metadata.
		if target and not isreturngate and meta:get_string("obsidian_gateway_success_" .. ns_key) == "" then
			minetest.chat_send_player(pname, "# Server: It looks like this could possibly be an OLD gate! Aborting for safety reasons.")
			minetest.chat_send_player(pname, "# Server: If this Gateway was previously functioning normally, please mail the admin with the coordinates.")
			minetest.chat_send_player(pname, "# Server: If this is a Gate that you have just constructed, you can safely ignore this message.")
			minetest.chat_send_player(pname, "# Server: The Gateway's EXIT location is @ " .. minetest.pos_to_string(target) .. ".")
			minetest.after(1.5, function() easyvend.sound_error(pname) end)
			return 
		end
		-- Algorithm for locating the destination.

		-- Get a potential gate location.
		target = rc.get_random_realm_gate_position(origin)

		-- Is target outside bounds?
		local bad = function(target, origin)
			-- Don't allow exit points near the colonies.
			if vector.distance(target, {x=0, y=0, z=0}) < 2000 or
				vector.distance(target, {x=0, y=-30790, z=0}) < 2000 then
				return true
			end
			-- Exit must not be too close to start.
			if vector.distance(target, origin) < 500 then
				return true
			end
			-- Or too far.
			-- This causes too many failures.
			--if vector.distance(target, origin) > 7000 then
			--	return true
			--end
			if not rc.is_valid_gateway_region(target) then
				return true
			end
		end

		-- Keep trying until the target is within bounds.
		local num_tries = 0
		while bad(target, origin) do
			target = rc.get_random_realm_gate_position(origin)
			num_tries = num_tries + 1

			if num_tries >= 25 then
				--[[
				minetest.after(0, function()
					-- Detonate some TNT!
					tnt.boom(vector.add(ppos, {x=math.random(-3, 3), y=0, z=math.random(-3, 3)}), {
						radius = 3,
						ignore_protection = false,
						ignore_on_blast = false,
						damage_radius = 3,
						disable_drops = true,
					})
				end)
				--]]
				return
			end
		end

		meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(target))
		meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)

		first_time_init = true
		isowner = true
	end

		--minetest.chat_send_player(pname, "# Server: Safety ABORT #2.")
		--do return end

	if gdac.player_is_admin(pname) then
		isowner = true
	end

	-- Slightly randomize player's exit coordinates.
	-- Without changing the coordinates of the gateway.
	local pdest
	if northsouth then
		pdest = vector.add(target, {x=math.random(0, 1), y=0, z=0})
	else
		pdest = vector.add(target, {x=0, y=0, z=math.random(0, 1)})
	end

	-- Collect any friends to bring along.
	local friendstobring = {}
	local allplayers = minetest.get_connected_players()
	for k, v in ipairs(allplayers) do
		if v:get_player_name() ~= pname then
			if vector.distance(v:get_pos(), player:get_pos()) < 3 then
				friendstobring[#friendstobring+1] = v:get_player_name()
			end
		end
	end

	-- Create a gateway at the player's destination.
	-- This gateway links back to the first.
	-- If it is destroyed, the player is stuck!
	preload_tp.preload_and_teleport(pname, pdest, 32,
		function()
			if not isowner then
				-- Grief portal if used by someone other than owner.
				local plava = airpoints[math.random(1, #airpoints)]
				--minetest.chat_send_all("# Server: Attempting to grief gateway @ " .. minetest.pos_to_string(plava) .. "!")
				if minetest.get_node(plava).name == "air" then
					if plava.y < -10 then
						minetest.set_node(plava, {name="default:lava_source"})
					else
						minetest.set_node(plava, {name="fire:basic_flame"})
					end
				end
			end
			-- Don't build return portal on top of someone's protected stuff.
			if first_time_init then
				if check_protection(vector.add(target, {x=0, y=3, z=0}), 5) then
					minetest.chat_send_player(pname, "# Server: Return-gate construction FAILED due to protection near " .. minetest.pos_to_string(target) .. ".")

					-- Clear data for the initial gate. This will permit the player to retry without tearing everything down and building it again.
					local meta = minetest.get_meta(origin)
					meta:set_string("obsidian_gateway_success_" .. ns_key, "")
					meta:set_string("obsidian_gateway_destination_" .. ns_key, "")
					meta:set_string("obsidian_gateway_owner_" .. ns_key, "")

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
				else
					-- Place eastwest gateway.
					local path = obsidian_gateway.modpath .. "/obsidian_gateway_eastwest.mts"
					local gpos = vector.add(target, {x=0, y=-1, z=-1})
					minetest.place_schematic(gpos, path, "0", nil, true)
					local meta = minetest.get_meta(gpos)
					meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
					meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)
					meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 1)
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
		end,
		function()
			for k, v in ipairs(friendstobring) do
				local friend = minetest.get_player_by_name(v)
				if friend then
					preload_tp.preload_and_teleport(friend:get_player_name(), pdest, 16, nil, nil, nil, true)
				end
			end

			-- Update liquids around on first init.
			if first_time_init then
				minetest.after(2, function()
					mapfix.execute(target, 10)
				end)
			end
		end, nil, false, "nether_portal_usual")
end



if not obsidian_gateway.run_once then
	local c = "obsidian_gateway:core"
	local f = obsidian_gateway.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	obsidian_gateway.run_once = true
end

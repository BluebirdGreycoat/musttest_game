
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

	meta:mark_as_private({"gate_origin", "gate_northsouth"})

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



function obsidian_gateway.get_gate_player_spawn_pos(pos, dir)
	if dir == "ns" then
		return vector.add(pos, {x=1.5, y=1.5, z=0})
	elseif dir == "ew" then
		return vector.add(pos, {x=0, y=1.5, z=1.5})
	else
		return pos
	end
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

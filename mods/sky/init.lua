
sky = sky or {}
sky.modpath = minetest.get_modpath("sky")
sky.players = sky.players or {}



-- Localize for speed.
local get_node = minetest.get_node
local all_nodes = minetest.registered_nodes
local ns_nodes = minetest.reg_ns_nodes
local vector_distance = vector.distance
local vector_round = vector.round
local vector_equals = vector.equals
local get_connected_players = minetest.get_connected_players
local random = math.random
local string_find = string.find



-- Public API function.
-- Used in the ambiance mod to determine the surface a player stands on.
function sky.get_last_walked_node(pname)
	local data = sky.players[pname]
	if data then
		return data.snode
	end
	return ""
end
function sky.get_last_walked_nodeabove(pname)
	local data = sky.players[pname]
	if data then
		return data.wnode
	end
	return ""
end



-- Private function!
-- This is the default `on_walkover' action.
local function default_on_walkover(pos, name, player)
	local pname = player:get_player_name()

	-- Admin doesn't trigger default actions.
	if gdac.player_is_admin(pname) then
		return
	end

	-- Do not trigger if position is protected.
	if minetest.test_protection(pos, "") then
		return
	end

	if get_node(pos).name ~= name then
		return
	end

	local test_and_drop = function(p2)
		-- Don't drop if protected.
		if minetest.test_protection(p2, "") then
			return
		end
		local overhang = true
		for i = 1, 4, 1 do
			local node = get_node({x=p2.x, y=p2.y-i, z=p2.z})
			if node.name ~= "air" then
				overhang = false
				break
			end
		end
		if overhang then
			sfn.drop_node(p2)
			core.check_for_falling(p2)
			return true
		end
	end

	-- Drop several nodes under the player to ensure a likelihood of
	-- causing the player to fall down.
	local positions = {
		-- Test and drop lower nodes first.
		{x=pos.x, y=pos.y-1, z=pos.z},
		{x=pos.x+1, y=pos.y-1, z=pos.z},
		{x=pos.x-1, y=pos.y-1, z=pos.z},
		{x=pos.x, y=pos.y-1, z=pos.z+1},
		{x=pos.x, y=pos.y-1, z=pos.z-1},

		{x=pos.x, y=pos.y, z=pos.z},
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x, y=pos.y, z=pos.z-1},
	}
	local play_sound = false
	for k, v in ipairs(positions) do
		if test_and_drop(v) then
			play_sound = true
		end
	end
	if play_sound then
		ambiance.sound_play("default_gravel_footstep", pos, 1, 20)
	end
end



-- Private function!
--
-- This handles skycolor updates and `on_player_walk_over' calls.
-- The walk-over calls are used in plenty of places, so do not break this!
-- Also, we handle movement speed based on current node walked on.
local function update_player(player, pname, pdata, playerpos, nodepos)
	-- Player doesn't walk over nodes if attached to some vehicle.
	if not default.player_attached[pname] then
		-- Get node player is standing ON.
		local snode = get_node(nodepos)
		local sname = snode.name

		-- Don't modify movement or call walk-over callbacks if node is air.
		-- This prevents players from getting better movement speed by hopping constantly.
		if sname ~= "air" and sname ~= "ignore" then
			local sdef = ns_nodes[sname] or all_nodes[sname] or {}

			-- Get node player is walking IN, not ON.
			-- Plants shall slow players down!
			local wnode = get_node(vector.add(nodepos, {x=0, y=1, z=0}))
			local wname = wnode.name

			-- Recompute movement speed only if either walked nodename changes.
			if sname ~= pdata.snode or wname ~= pdata.wnode then
				if sdef.movement_speed_depends then
					-- Assume node is slab-like and has a standard 'flat' orientation.
					local p2 = snode.param2
					local is_flat = false
					if p2 >= 0 and p2 <= 3 then
						is_flat = true
					elseif p2 >= 20 and p2 <= 23 then
						is_flat = true
					end
					if is_flat then
						-- If slab is flat and has a parent type, use the parent type.
						local def2 = ns_nodes[sdef.movement_speed_depends] or {}
						if def2 then sdef = def2 end
					end
				end

				local smult = sdef.movement_speed_multiplier or default.NORM_SPEED
				local jmult = sdef.movement_jump_multiplier or default.NORM_JUMP
				sprint.set_speed_multiplier(pname, smult)
				sprint.set_jump_multiplier(pname, jmult)

				if wname ~= "air" then
					-- But ignore doors.
					if not string.find(wname, "^doors:") then
						local wdef = ns_nodes[wname] or all_nodes[wname] or {}
						local smult2 = wdef.movement_speed_multiplier or default.NORM_SPEED
						local jmult2 = wdef.movement_jump_multiplier or default.NORM_JUMP
						sprint.set_speed_multiplier(pname, smult2)
						sprint.set_jump_multiplier(pname, jmult2)
					end
				end

				-- Record the name of the last walked node.
				-- This is used by the ambiance mod to determine walked surface type.
				pdata.snode = sname
				pdata.wnode = wname
			end

			-- Execute `on_walkover' callback for current walked node.
			-- Note, this must only be called ONCE for the walked node!
			-- This is ensured because we are only called max once per position.
			if sdef.walkable and sdef.on_player_walk_over then
				sdef.on_player_walk_over(nodepos, player)
			end

			-- The default action is only rarely taken.
			if random(1, 500) == 1 then
				default_on_walkover(nodepos, sname, player)
			end
		end -- Air/ignore check.
	end

	-- Update player's sky colors. Use flags to avoid extra calls.
	if vector_distance(playerpos, pdata.ppos) > 5 then
		if rc.position_underground(playerpos) and pdata.sky == 0 then
			if playerpos.y > -25000 and pdata.sky ~= 1 then
				-- Cave background.
				player:set_sky({a=255, r=0, g=0, b=0}, "plain", {})
				pdata.sky = 1
			elseif pdata.sky ~= 2 then
				-- Nether background.
				player:set_sky({a=255, r=10, g=0, b=0}, "plain", {})
				pdata.sky = 2
			end
		elseif not rc.position_underground(playerpos) and pdata.sky ~= 0 then
			player:set_sky({}, "regular", {})
			pdata.sky = 0
		end

		pdata.ppos = playerpos
	end
end



-- Private function! (Registered callback.)
local timer = 0
function sky.on_globalstep(dtime)
	timer = timer + dtime
	if timer < 0.25 then return end
	timer = 0

	local players = get_connected_players()
	local datas = sky.players
	for i=1, #players do
		local player = players[i]
		local pname = player:get_player_name()

		local ppos = player:get_pos()
		local rpos = vector_round(ppos)
		local pdata = datas[pname]

		if not vector_equals(pdata.rpos, rpos) then
			local npos = utility.node_under_pos(ppos)

			update_player(player, pname, pdata, ppos, npos)
			pdata.rpos = rpos
		end
	end
end



function sky.on_joinplayer(player)
	local ppos = player:get_pos()
	local rpos = vector_round(ppos)
	local npos = utility.node_under_pos(ppos)

	-- Initialize player data.
	local pname = player:get_player_name()
	sky.players[pname] = {
		ppos = {x=0, y=0, z=0}, -- Last known player position.
		rpos = rpos, -- Last known player position, rounded.
		snode = "", -- Name of last walked node.
		wnode = "", -- Name of last node above walked node.
		sky = 0, -- Current sky colors flag.
	}

	local pdata = sky.players[pname]

	-- Update player on first join.
	update_player(player, pname, pdata, ppos, npos)
end



function sky.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()
	sky.players[pname] = nil
end



if not sky.run_once then
	minetest.register_on_joinplayer(function(...)
		sky.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return sky.on_leaveplayer(...)
	end)

	minetest.register_globalstep(function(...)
		sky.on_globalstep(...)
	end)

	local c = "sky:core"
	local f = sky.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	sky.run_once = true
end


-- The algorithm here is useful for much more than dirt management. It can also
-- handle any kind of behavior for any node similarly to an ABM, *except* liquids.
-- The node must be in the `dirtspread_notify` group, and be registered somewhere.
-- If the node's logic changes it, make sure to use `minetest.add_node` in order
-- to make the update logic cascade.

if not minetest.global_exists("dirtspread") then dirtspread = {} end
dirtspread.modpath = minetest.get_modpath("dirtspread")
dirtspread.delay = 1.5
dirtspread.index = dirtspread.index or 0
dirtspread.positions = dirtspread.positions or {} -- Indexed cache table.
dirtspread.blocks = dirtspread.blocks or {}

-- Groups:
--
-- `dirt_type`             (any and all dirt types in the game).
-- `sterile_dirt_type`     (dirt which cannot grow anything).
-- `raw_dirt_type`         (dirt without snow, grass, or other decoration).
-- `non_sterile_dirt_type` (dirt theoretically capable of growing plants).
-- `hoed_dirt_type`        (dirt which has been hoed into rows).
-- `dry_dirt_type`         (dirt which is dry).
-- `grassy_dirt_type`      (dirt with grassy decoration).
-- `snowy_dirt_type`       (dirt with snow on top).
-- `leafy_dirt_type`       (dirt with leaf-litter on top).
-- `non_raw_dirt_type`     (any dirt with decoration, grass or otherwise).
-- `permafrost_type`       (all permafrost nodes).
--
-- Other Notable Groups:
--
-- `water`
-- `lava`
-- `snow`
-- `snowy`
-- `cold`
-- `wet`
-- `sand`
-- `gravel`
-- `leaves`
--
-- Names:
--
-- `default:dirt`
-- `darkage:darkdirt`
-- `default:dirt_with_grass`
-- `default:dirt_with_grass_footsteps`
-- `moregrass:darkgrass`
-- `default:dirt_with_dry_grass`
-- `default:dirt_with_snow`
-- `default:dark_dirt_with_snow`
-- `default:dry_dirt_with_snow`
-- `default:dirt_with_rainforest_litter`
-- `default:dark_dirt_with_rainforest_litter`
-- `default:dry_dirt_with_rainforest_litter`
-- `default:dirt_with_coniferous_litter`
-- `default:dark_dirt_with_coniferous_litter`
-- `default:dry_dirt_with_coniferous_litter`
-- `default:dry_dirt`
-- `default:dry_dirt_with_dry_grass`
-- `farming:soil`
-- `farming:soil_wet`
-- `farming:desert_sand_soil`
-- `farming:desert_sand_soil_wet`
-- `default:permafrost`
-- `default:permafrost_with_snow`
-- `default:permafrost_with_stones`
-- `default:permafrost_with_snow_and_stones`
-- `default:permafrost_with_moss`
-- `default:permafrost_with_moss_and_stones`
-- `sand:sand_with_ice_crystals`
-- `default:sand`
-- `default:desert_sand`
-- `default:gravel`
-- `default:snowblock`



-- Called whenever a timer on any active node expires.
function dirtspread.on_timer(pos, elapsed)
	-- If `ignore` is nearby, we're next to an unloaded mapchunk.
	-- We cannot assume we'll have enough data to execute the active block function.
	-- We'll need to restart the timer and try again later.
	if utility.find_node_near_not_world_edge(pos, 1, "ignore") then
		return true
	end

	local node = minetest.get_node(pos)
	local ndef = dirtspread.get_active_block(node.name)
	if ndef and ndef.func then
		-- If the function returns `true`, restart the timer.
		if ndef.func(table.copy(pos), node) then
			local timer = minetest.get_node_timer(pos)
			timer:start(math.random(ndef.min_time, ndef.max_time))
		end
	end
end



-- Called to update nodes around the given position (possibly including self).
local minp = {x=0, y=0, z=0}
local maxp = {x=0, y=0, z=0}
function dirtspread.on_notify_around(pos)
	minp.x = pos.x - 1
	minp.y = pos.y - 1
	minp.z = pos.z - 1

	maxp.x = pos.x + 1
	maxp.y = pos.y + 1
	maxp.z = pos.z + 1

	local positions = minetest.find_nodes_in_area(minp, maxp, "group:dirtspread_notify")
	for i=1, #positions, 1 do
		local p2 = positions[i]
		local node = minetest.get_node(p2)
		local ndef = dirtspread.get_active_block(node.name)
		if ndef then
			local timer = minetest.get_node_timer(p2)

			-- Alert: sometimes this can fail because the timer, for some reason, is
			-- already started and has a huge timeout value (> 659000). Very odd!
			-- In any case, it makes sense to reset the timer whenever something changes.
			--[[
			if not timer:is_started() then
			end
			--]]

			timer:start(math.random(ndef.min_time, ndef.max_time))
		end
	end
end



-- Called whenever a node is added or removed (any node, not just nodes around dirt!).
-- Warning: may be called many times in quick succession (e.g., falling nodes).
function dirtspread.on_environment(pos)
	-- Add position to table of positions to be updated later.
	local poss = dirtspread.positions
	local idex = dirtspread.index + 1

	local p = poss[idex]
	if p then
		p.x = pos.x
		p.y = pos.y
		p.z = pos.z
	else
		poss[idex] = {x=pos.x, y=pos.y, z=pos.z}
	end

	dirtspread.index = idex
end



-- Called periodically to update nodes.
-- This is not part of the public API!
function dirtspread.periodic_execute()
	local endx = dirtspread.index
	local count = 0

	-- Update just 50 nodes per run.
	-- This spreads out the updates over time.
	if endx > 0 then
		table.shuffle(dirtspread.positions, 1, endx)
	end

	while endx > 0 and count < 50 do
		dirtspread.on_notify_around(dirtspread.positions[endx])
		endx = endx - 1
		count = count + 1
	end

	dirtspread.index = endx
	minetest.after(dirtspread.delay, dirtspread.periodic_execute)
end



-- Execute any remaining updates on shutdown.
-- This is not part of the public API!
function dirtspread.on_shutdown()
	local endx = dirtspread.index
	local poss = dirtspread.positions

	while endx > 0 do
		dirtspread.on_notify_around(poss[endx])
		endx = endx - 1
	end

	dirtspread.index = endx
end



-- Obtain the data for a registered active block.
function dirtspread.get_active_block(name)
	return dirtspread.blocks[name] -- May return nil.
end



function dirtspread.register_active_block(name, data)
	-- Update node definition. Node must already have been registered!
	local ndef = minetest.registered_nodes[name]
	assert(ndef)

	local newdata = {
		min_time = data.min_time or 1,
		max_time = data.max_time or 1,
		func = data.func,
	}
	assert(newdata.min_time >= 0)
	assert(newdata.max_time >= 0)
	assert(newdata.min_time <= newdata.max_time)
	dirtspread.blocks[name] = newdata

	-- Node must be added to the `dirtspread_notify` group.
	local g = table.copy(ndef.groups or {})
	g.dirtspread_notify = 1

	-- Hook `on_timer`.
	-- FIXME: What happens when node already has timer callback?!
	-- We end up overriding the original timeout value and messing things up!
	local on_timer
	if ndef.on_timer then
		local old = ndef.on_timer
		on_timer = function(pos, elapsed)
			-- FIXME: what happens if the dirtspread timer does NOT return true
			-- (e.g., it set a new random expiry time), and the original nodetimer (old)
			-- DOES return true (e.g., it has its own idea of when the next timeout
			-- should happen)? This is a logic/time conflict which might cause strange
			-- bugs with certain nodes if they BOTH have their own nodetimer, and are
			-- also registered with the dirtspread code.
			local b1 = dirtspread.on_timer(pos, elapsed)
			local b2 = old(pos, elapsed)

			-- If either returns true, we have to restart the timer.
			if b1 or b2 then
				return true
			end
		end
	else
		on_timer = function(pos, elapsed)
			-- If the dirtspread timer func returns true, we have to restart the timer.
			if dirtspread.on_timer(pos, elapsed) then
				return true
			end
		end
	end

	-- TNT uses voxelmanip, need to hook the `on_blast` method.
	-- Update 12/10/23: Why do we do this? Can't remember now ...
	-- Disabling this causes a HUGE performance improvement when blasting
	-- dirt/sand.
	--
	-- I still can't remember why I hooked this function in the first place.
	-- All it did was add the position to the update queue, but since the node
	-- would most likely fall, the position would be out-of-date anyway!
	--[[
	local on_blast
	if ndef.on_blast then
		local old = ndef.on_blast
		on_blast = function(pos, intensity)
			dirtspread.on_environment(pos)
			return old(pos, intensity)
		end
	else
		on_blast = function(pos, intensity)
			dirtspread.on_environment(pos)
		end
	end
	--]]

	minetest.override_item(name, {
		groups = g,
		on_timer = on_timer,
		--on_blast = on_blast,
	})
end



-- File is reloadable.
dofile(dirtspread.modpath .. "/registrations.lua")



if not dirtspread.registered then
	-- Hook `minetest.remove_node`. This is called only when player removes a node, not for mods!
	local remove_node_copy = minetest.remove_node
	function minetest.remove_node(pos)
		local res = remove_node_copy(pos)
		dirtspread.on_environment(pos)
		return res
	end

	minetest.after(dirtspread.delay, dirtspread.periodic_execute)
	minetest.register_on_shutdown(function() dirtspread.on_shutdown() end)

	local c = "dirtspread:core"
	local f = dirtspread.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	dirtspread.registered = true
end


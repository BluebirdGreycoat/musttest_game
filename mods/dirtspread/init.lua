
-- The algorithm here is useful for much more than dirt management. It can also
-- handle any kind of behavior for any node similarly to an ABM, *except* liquids.
-- The node must be in the `dirtspread_notify` group, and be registered somewhere.
-- If the node's logic changes it, make sure to use `minetest.add_node` in order
-- to make the update logic cascade.

dirtspread = dirtspread or {}
dirtspread.modpath = minetest.get_modpath("dirtspread")
dirtspread.delay = 0.5
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



-- Called whenever a timer on any dirt node expires.
-- Note: only called for dirt/soil/permafrost/sand/gravel nodes.
function dirtspread.on_timer(pos, elapsed)
	--minetest.chat_send_player("MustTest", "On timer: " .. minetest.pos_to_string(pos))

	local node = minetest.get_node(pos)
	local ndef = dirtspread.get_active_block(node.name)
	if ndef and ndef.func then
		-- If the function returns `true`, restart the timer.
		if ndef.func(table.copy(pos), node) then
			local timer = minetest.get_node_timer(pos)
			timer:start(ndef.min_time, ndef.max_time)
		end
	end
end



-- Called to update nodes around the given position (possibly including self).
local minp = {x=0, y=0, z=0}
local maxp = {x=0, y=0, z=0}
function dirtspread.on_notify_around(pos)
	--minetest.chat_send_player("MustTest", "Notify: " .. minetest.pos_to_string(pos))

	minp.x = pos.x - 1
	minp.y = pos.y - 1
	minp.z = pos.z - 1

	maxp.x = pos.x + 1
	maxp.y = pos.y + 1
	maxp.z = pos.z + 1

	local positions = minetest.find_nodes_in_area(minp, maxp, "group:dirtspread_notify")
	--minetest.chat_send_player("MustTest", "Counts: " .. #positions)
	for i=1, #positions, 1 do
		local p2 = positions[i]
		local node = minetest.get_node(p2)
		local ndef = dirtspread.get_active_block(node.name)
		if ndef then
			--minetest.chat_send_player("MustTest", "Got nodedef: " .. minetest.pos_to_string(p2))

			local timer = minetest.get_node_timer(p2)
			if not timer:is_started() then
				-- Alert: sometimes this can fail because the timer, for some reason, is
				-- already started and has a huge timeout value (> 659000). Very odd!

				--minetest.chat_send_player("MustTest", "Started timer: " .. minetest.pos_to_string(p2))

				timer:start(ndef.min_time, ndef.max_time)
			end
		end
	end
end



-- Called whenever a node is added or removed (any node, not just nodes around dirt!).
-- Warning: may be called many times in quick succession (e.g., falling nodes).
function dirtspread.on_environment(pos)
	--minetest.chat_send_player("MustTest", "Environment: " .. minetest.pos_to_string(pos))

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
function dirtspread.periodic_execute()
	local endx = dirtspread.index

	-- Update just 1 node per run.
	if endx > 0 then
		dirtspread.on_notify_around(dirtspread.positions[endx])
		dirtspread.index = endx - 1
	end

	minetest.after(dirtspread.delay, dirtspread.periodic_execute)
end



function dirtspread.get_active_block(name)
	return dirtspread.blocks[name] -- May return nil.
end



function dirtspread.register_active_block(name, data)
	local newdata = {
		min_time = data.min_time or 1,
		max_time = data.max_time or 1,
		func = data.func,
	}
	assert(newdata.min_time >= 0)
	assert(newdata.max_time >= 0)
	assert(newdata.min_time <= newdata.max_time)
	dirtspread.blocks[name] = newdata
end



-- File is reloadable.
--dofile(dirtspread.modpath .. "/registrations.lua")



if not dirtspread.registered then
	-- Hook `minetest.remove_node`. This is called only when player removes a node, not for mods!
	local remove_node_copy = minetest.remove_node
	function minetest.remove_node(pos)
		local res = remove_node_copy(pos)
		dirtspread.on_environment(pos)
		return res
	end

	minetest.after(dirtspread.delay, dirtspread.periodic_execute)

	local c = "dirtspread:core"
	local f = dirtspread.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	dirtspread.registered = true
end


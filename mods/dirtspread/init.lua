
dirtspread = dirtspread or {}
dirtspread.modpath = minetest.get_modpath("dirtspread")
dirtspread.delay = 5
dirtspread.index = 1
dirtspread.positions = dirtspread.positions or {} -- Indexed cache table.

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



-- Called whenever a dirt node of any type is constructed.
-- Note: only called for dirt nodes.
function dirtspread.on_construct(pos)
end



-- Called whenever a timer on any dirt node expires.
-- Note: only called for dirt nodes.
function dirtspread.on_timer(pos, elapsed)
end



-- Called to update a dirt node, possibly changing it to another type.
function dirtspread.on_notify(pos)
end



-- Called whenever a node is added or removed (any node, not just nodes around dirt!).
-- Warning: may be called many times in quick succession (e.g., falling nodes).
function dirtspread.on_environment(pos)
	-- Add position to table of positions to be updated later.
	local poss = dirtspread.positions
	local idex = dirtspread.index

	local p = poss[idex]
	if p then
		p.x = pos.x
		p.y = pos.y
		p.z = pos.z
	else
		poss[idex] = {x=pos.x, y=pos.y, z=pos.z}
	end

	idex = idex + 1
end



-- Called periodically to update nodes.
function dirtspread.periodic_execute()
	local poss = dirtspread.positions
	local exec = dirtspread.on_notify
	local endx = dirtspread.index - 1

	for i=1, endx, 1 do
		exec(poss[i])
	end

	dirtspread.index = 1
	minetest.after(dirtspread.delay, dirtspread.periodic_execute)
end



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



-- Depreciated.
--[[
-- Convert dirt to something that fits the environment.
minetest.register_abm({
  label = "Grass/Snow Spread",
	nodenames = {"default:dirt"},
	neighbors = {
		"group:spreading_dirt_type",
		"group:grass",
		"group:dry_grass",
		"group:snow",
	},
    
	interval = 20/2 * default.ABM_TIMER_MULTIPLIER,
	chance = 100/2 * default.ABM_CHANCE_MULTIPLIER,
    
	catch_up = false,
	action = function(pos, node)
		-- Get node above: pos, name, def, groups.
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
		local node_above = minetest.get_node_or_nil(above)
		if not node_above then return end
		local name_above = node_above.name
		local ndef_above = minetest.registered_nodes[name_above]
		if not ndef_above then return end
		local groups_above = ndef_above.groups or {}

		local below = {x=pos.x, y=pos.y-1, z=pos.z}
		local node_below = minetest.get_node_or_nil(below)
		if not node_below then return end
		local name_below = node_below.name
		local ndef_below = minetest.registered_nodes[name_below]
		if not ndef_below then return end
		local groups_below = ndef_below.groups or {}

		-- If snow is above, turn to dirt-with-snow. This happens at any altitude in any light condition.
		if groups_above.snow and groups_above.snow > 0 then
			minetest.set_node(pos, {name = "default:dirt_with_snow"})
			return
		end

		-- If cold is below, turn to sterile dirt. This happens at any altitude in any light condition.
		if groups_below.cold and groups_below.cold > 0 then
			minetest.set_node(pos, {name = "darkage:darkdirt"})
			return
		end

		-- These checks depend on having enough light!
		if (minetest.get_node_light(above) or 0) >= 13 then
			-- Actions to take only if dirt is near surface, above surface, or in other realms.
			if pos.y >= -30 then
				-- Look for likely neighbors with the spreading dirt property.
				local p2 = minetest.find_node_near(pos, 1, {"group:spreading_dirt_type"})
				if p2 then
					-- But the node needs to be under air in this case.
					local n2 = minetest.get_node(above)
					if n2.name == "air" then
						local n3 = minetest.get_node(p2)
						minetest.set_node(pos, {name = n3.name})
						return
					end
				end
			end

			-- If dirt turns to dirt-with-grass, any sterile dirt nearby ceases to be sterile.
			-- This makes it possible to reclaim sterile dirt (there is no way otherwise).
			local spread_dirt = function(pos)
				local p2 = minetest.find_node_near(pos, 1, "darkage:darkdirt")
				if p2 then
					minetest.set_node(p2, {name = "default:dirt"})
				end
			end

			-- If node above is one of these plant types, then grow grass or similar.
			-- Note that this can happen at any altitude (but will not spread naturally if underground).
			if groups_above.junglegrass and groups_above.junglegrass > 0 then
				minetest.set_node(pos, {name = "moregrass:darkgrass"})
				return
			elseif groups_above.dry_grass and groups_above.dry_grass > 0 then
				minetest.set_node(pos, {name = "default:dirt_with_dry_grass"})
				return
			elseif groups_above.grass and groups_above.grass > 0 then
				minetest.set_node(pos, {name = "default:dirt_with_grass"})
				return
			end
		else
			return
		end

		-- If we reach here, the dirt is not being cultivated. Slowly turn to sterile dirt.
		-- Partly this causes dirt loss if players do not take care of their dirt, and
		-- partly this reduces the number of eligible nodes to run the ABM.
		if math.random(1, 100) == 1 then
			minetest.set_node(pos, {name="darkage:darkdirt"})
		end
	end
})
--]]



-- Depreciated.
--[[
function dirtspread.dirt_covered_check(pos)
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "soil") ~= 0 then
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		local name = minetest.get_node(above).name

    -- Shortcut avoids the expensive table lookup for most common cases.
    if name == "air" then return end

		local nodedef = minetest.reg_ns_nodes[name]
		if name ~= "ignore" and nodedef and not ((nodedef.sunlight_propagates or
				nodedef.paramtype == "light") and
				nodedef.liquidtype == "none") then
			minetest.set_node(pos, {name = "default:dirt"})
		end
	end
end



function dirtspread.dirt_on_timer(pos, elapsed)
	dirtspread.dirt_covered_check(pos)
end



function dirtspread.check_dirt_covered_timer(pos)
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "soil") ~= 0 then
		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(math.random(10, 120))
		end
	end
end
--]]




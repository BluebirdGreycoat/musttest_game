
dirtspread = dirtspread or {}
dirtspread.modpath = minetest.get_modpath("dirtspread")



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


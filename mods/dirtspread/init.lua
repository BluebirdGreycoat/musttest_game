
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
		-- default:dirt does nothing if underground.
		-- [MustTest]
		if pos.y < -30 then
			return
		end

		-- Most likely case, half the time it's too dark for this.
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		if (minetest.get_node_light(above) or 0) < 13 then
			return
		end

		-- Look for likely neighbors.
		local p2 = minetest.find_node_near(pos, 1, {"group:spreading_dirt_type"})
		if p2 then
			-- But the node needs to be under air in this case.
			local n2 = minetest.get_node(above)
			if n2 and n2.name == "air" then
				local n3 = minetest.get_node(p2)
				minetest.set_node(pos, {name = n3.name})
				return
			end
		end

		-- Anything on top?
		local n2 = minetest.get_node(above)
		if not n2 then return end

		local name = n2.name

		-- Convert dirt to something else based on what is on top.
		if minetest.get_item_group(name, "snow") ~= 0 then
			minetest.set_node(pos, {name = "default:dirt_with_snow"})
		elseif minetest.get_item_group(name, "junglegrass") ~= 0 then
			minetest.set_node(pos, {name = "moregrass:darkgrass"})
		elseif minetest.get_item_group(name, "dry_grass") ~= 0 then
			minetest.set_node(pos, {name = "default:dirt_with_dry_grass"})
		elseif minetest.get_item_group(name, "grass") ~= 0 then
			minetest.set_node(pos, {name = "default:dirt_with_grass"})
		end
	end
})


--[[
minetest.register_craft({
	output = "default:dirt_with_snow",
	recipe = {
		{"default:snow"},
		{"default:dirt"},
	},
})
--]]



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


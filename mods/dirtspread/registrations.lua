
-- File is reloadable.

local INTERACTION_DATA = {
	["default:dirt"] = {
		when_buried = "darkage:darkdirt",

		-- The lava/fire checks always search all possible neighbors.
		-- The lava check always searchs up to 3 nodes away.
		when_lava_nearby = "darkage:darkdirt",
		when_fire_nearby = "default:dry_dirt",

		when_ice_above = "default:permafrost",
		when_ice_below = "default:permafrost",
		when_ice_nearby = "default:permafrost",

		when_snow_above = "default:dirt_with_snow",
		when_snow_below = "default:permafrost",
		when_snow_nearby = "default:dirt_with_snow",

		when_sand_above = "darkage:darkdirt",
		when_sand_below = "default:dry_dirt",
		when_sand_nearby = "default:dry_dirt",

		-- Shall return the nodename to set, or "" to leave unchanged.
		-- Return boolean second parameter to indicate whether to wait.
		when_flora_above = function(pos, light, name, def, groups)
			if groups.junglegrass and groups.junglegrass > 0 then
				if light >= 13 then
					return "moregrass:darkgrass", false
				else
					return "", true
				end
			elseif groups.dry_grass and groups.dry_grass > 0 then
				if light >= 13 then
					return "default:dirt_with_dry_grass", false
				else
					return "", true
				end
			elseif groups.grass and groups.grass > 0 then
				if light >= 13 then
					return "default:dirt_with_grass", false
				else
					return "", true
				end
			end

			return "", false
		end,

		-- These control which neighbors are generally searched.
		search_all_neighbors = false,
		search_flat_diagonals = false,
		search_vertical_diagonals = true,
	},

	["default:permafrost"] = {
		when_lava_nearby = "darkage:darkdirt",
		when_fire_nearby = "default:dry_dirt",

		when_snow_above = "default:permafrost_with_snow",
		when_flora_above = "default:permafrost_with_moss",
	},
}



local MIN_TIME = 1
local MAX_TIME = 5



-- If function uses `minetest.add_node`, neighbor nodes will be notified again.
-- This can create a cascade effect, which may or may not be desired.
-- Return `true` to restart the timer and call this function again later (useful if you need to wait before changing the node).
local HANDLER = function(pos, node)
	-- Get the interaction data table for this active block.
	local interaction_data = INTERACTION_DATA[node.name]
	if not interaction_data then
		return
	end

	local above = {x=pos.x, y=pos.y+1, z=pos.z}
	local below = {x=pos.x, y=pos.y-1, z=pos.z}

	-- Get current light level above node.
	local light_above = minetest.get_node_light(above) or 0

	-- Action when node is in complete darkness (is buried, no light).
	if interaction_data.when_buried then
		local sides_6 = {
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y+1, z=pos.z},
			{x=pos.x, y=pos.y-1, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+1},
			{x=pos.x, y=pos.y, z=pos.z-1},
		}

		local light = 0
		for k, v in ipairs(sides_6) do
			local ll = minetest.get_node_light(v, 0.5) or 0
			light = light + ll

			-- Early exit if light is detected quickly.
			if light > 0 then
				break
			end
		end

		if light == 0 then
			node.name = interaction_data.when_buried
			minetest.add_node(pos, node)
			return
		end
	end

	-- Action when there is lava nearby.
	if interaction_data.when_lava_nearby then
		if minetest.find_node_near(pos, 3, "group:lava") then
			node.name = interaction_data.when_lava_nearby
			minetest.add_node(pos, node)
			return
		end
	end

	-- Action when there is fire nearby.
	if interaction_data.when_fire_nearby then
		if minetest.find_node_near(pos, 1, "group:fire") then
			node.name = interaction_data.when_fire_nearby
			minetest.add_node(pos, node)
			return
		end
	end

	-- Get what's to the 4 sides (not including center or corners).
	local sides_to_search = {
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z-1},
		{x=pos.x, y=pos.y, z=pos.z+1},
	}

	if interaction_data.search_all_neighbors then
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y, z=pos.z-1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y, z=pos.z-1})

		table.insert(sides_to_search, {x=pos.x, y=pos.y-1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y-1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y-1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x, y=pos.y-1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x, y=pos.y-1, z=pos.z-1})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y-1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y-1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y-1, z=pos.z-1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y-1, z=pos.z-1})

		table.insert(sides_to_search, {x=pos.x, y=pos.y+1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y+1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y+1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x, y=pos.y+1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x, y=pos.y+1, z=pos.z-1})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y+1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y+1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y+1, z=pos.z-1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y+1, z=pos.z-1})
	elseif interaction_data.search_flat_diagonals then
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y, z=pos.z-1})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y, z=pos.z-1})
	elseif interaction_data.search_vertical_diagonals then
		table.insert(sides_to_search, {x=pos.x+1, y=pos.y-1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y-1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x, y=pos.y-1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x, y=pos.y-1, z=pos.z-1})

		table.insert(sides_to_search, {x=pos.x+1, y=pos.y+1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x-1, y=pos.y+1, z=pos.z})
		table.insert(sides_to_search, {x=pos.x, y=pos.y+1, z=pos.z+1})
		table.insert(sides_to_search, {x=pos.x, y=pos.y+1, z=pos.z-1})
	end

	-- This is needed so that which side gets checked first isn't predictable.
	table.shuffle(sides_to_search)

	local find_nearby = function(names)
		if type(names) == "string" then
			for k, v in ipairs(sides_to_search) do
				local n2 = minetest.get_node(v)
				if n2.name == names then
					return v
				elseif string.find(names, "^group:") then
					local g = string.sub(names, string.len("group:") + 1)
					local d2 = minetest.registered_nodes[n2.name]
					local g2 = {}
					if d2 then
						g2 = d2.groups or {}
					end
					if g2[g] and g2[g] > 0 then
						return v
					end
				end
			end
		elseif type(names) == "table" then
			for k, v in ipairs(sides_to_search) do
				local n2 = minetest.get_node(v)
				for _, n in ipairs(names) do
					if n2.name == n then
						return v
					elseif string.find(n, "^group:") then
						local g = string.sub(n, string.len("group:") + 1)
						local d2 = minetest.registered_nodes[n2.name]
						local g2 = {}
						if d2 then
							g2 = d2.groups or {}
						end
						if g2[g] and g2[g] > 0 then
							return v
						end
					end
				end
			end
		end
	end

	local execute_action = function(node_or_group)
		local above_key = "when_" .. node_or_group .. "_above"
		local below_key = "when_" .. node_or_group .. "_below"
		local nearby_key = "when_" .. node_or_group .. "_nearby"

		-- Action above.
		if interaction_data[above_key] then
			local n2 = minetest.get_node(above)
			local d2 = minetest.registered_nodes[n2.name]
			local g2 = {}
			if d2 then
				g2 = d2.groups or {}
			end
			if g2[node_or_group] and g2[node_or_group] > 0 then
				if type(interaction_data[above_key]) == "string" then
					node.name = interaction_data[above_key]
					minetest.add_node(pos, node)
					return
				elseif type(interaction_data[above_key] == "function" then
					local ret, wait = interaction_data[above_key](pos, light_above, n2.name, d2, g2)
					if ret and ret ~= "" then
						node.name = ret
						minetest.add_node(pos, node)
						return
					elseif wait then
						return true
					end
				end
			end
		end

		-- Action below.
		if interaction_data[below_key] then
			local n2 = minetest.get_node(below)
			local d2 = minetest.registered_nodes[n2.name]
			local g2 = {}
			if d2 then
				g2 = d2.groups or {}
			end
			if g2[node_or_group] and g2[node_or_group] > 0 then
				if type(interaction_data[below_key]) == "string" then
					node.name = interaction_data[below_key]
					minetest.add_node(pos, node)
					return
				elseif type(interaction_data[below_key] == "function" then
					local ret, wait = interaction_data[below_key](pos, light_above, n2.name, d2, g2)
					if ret and ret ~= "" then
						node.name = ret
						minetest.add_node(pos, node)
						return
					elseif wait then
						return true
					end
				end
			end
		end

		-- Action nearby.
		if interaction_data[nearby_key] then
			if find_nearby(node_or_group) then
				if type(interaction_data[nearby_key]) == "string" then
					node.name = interaction_data[nearby_key]
					minetest.add_node(pos, node)
					return
				elseif type(interaction_data[nearby_key] == "function" then
					local ret, wait = interaction_data[nearby_key](pos, light_above, n2.name, d2, g2)
					if ret and ret ~= "" then
						node.name = ret
						minetest.add_node(pos, node)
						return
					elseif wait then
						return true
					end
				end
			end
		end
	end

	for key, data in pairs(interaction_data) do
		if key:find("^when_") then
			-- Skip these special keys.
			if key ~= "when_buried" and key ~= "when_lava_nearby" and key ~= "when_fire_nearby" then
				if key:find("_above$") or key:find("_below$") or key:find("_nearby$") then
					local first = key:find("_") + 1
					local last = key:find("_[^_]*$") - 1
					local part = key:sub(first, last)
					local wait = execute_action(part)
					if wait then
						return true
					end
				end
			end
		end
	end
end



-- Register a common handler for all dirt/soil/permafrost/sand nodes.
for NODE_NAME, DATA in pairs(INTERACTION_DATA) do
	dirtspread.register_active_block(NODE_NAME, {
		min_time = MIN_TIME,
		max_time = MAX_TIME,

		func = function(...)
			return HANDLER(...)
		end,
	})
end



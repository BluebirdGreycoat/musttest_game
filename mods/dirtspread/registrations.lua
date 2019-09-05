
-- File is reloadable.

local INTERACTION_DATA = {
	["default:dirt"] = {
		if_buried = "darkage:darkdirt",

		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:dry_dirt",

		when_group_ice_above = "default:permafrost",
		when_group_ice_below = "default:permafrost",
		when_group_ice_nearby = "default:permafrost",

		when_group_snow_above = "default:dirt_with_snow",
		when_group_snow_below = "default:permafrost",
		when_group_snow_nearby = "default:dirt_with_snow",

		when_group_snowy_nearby = "default:dirt_with_snow",

		when_group_sand_above = "darkage:darkdirt",
		when_group_sand_below = "default:dry_dirt",
		when_group_sand_nearby = "default:dry_dirt",

		when_default_dirt_with_grass_nearby = function(pos, light, name, def, groups)
			if light < 13 then
				return "", true -- Wait a bit.
			end

			return "default:dirt_with_grass", false -- Done.
		end,

		when_default_dirt_with_dry_grass_nearby = function(pos, light, name, def, groups)
			if light < 13 then
				return "", true -- Wait a bit.
			end

			return "default:dirt_with_dry_grass", false -- Done.
		end,

		when_moregrass_darkgrass_nearby = function(pos, light, name, def, groups)
			if light < 13 then
				return "", true -- Wait a bit.
			end

			return "moregrass:darkgrass", false -- Done.
		end,

		-- Shall return the nodename to set, or "" to leave unchanged.
		-- Return boolean second parameter to indicate whether to wait.
		when_group_flora_above = function(pos, light, name, def, groups)
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

			return "", false -- Nothing to be done.
		end,
	},

	["default:dirt_with_grass"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:dirt_with_dry_grass",

		when_group_snow_above = "default:dirt_with_snow",
		when_group_ice_below = "default:permafrost_with_moss",
	},

	["default:dirt_with_dry_grass"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:dirt",

		when_group_snow_above = "default:dirt_with_snow",
		when_group_ice_below = "default:permafrost_with_moss",
	},

	["moregrass:darkgrass"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:dirt_with_dry_grass",

		when_group_snow_above = "default:dirt_with_snow",
		when_group_ice_below = "default:permafrost_with_moss",
	},

	["default:dirt_with_snow"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:dirt",
	},

	["default:permafrost"] = {
		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:dirt",

		when_group_snow_above = "default:permafrost_with_snow",
		when_group_flora_above = "default:permafrost_with_moss",
	},

	["default:permafrost_with_moss"] = {
		if_buried = "default:permafrost",
		if_covered = "default:permafrost",

		when_group_lava_nearby = "darkage:darkdirt",
		when_group_fire_nearby = "default:permafrost",

		when_group_snow_above = "default:permafrost_with_snow",
		when_default_cobble_above = "default:permafrost_with_stones",
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
	if interaction_data.if_buried then
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
			node.name = interaction_data.if_buried
			minetest.add_node(pos, node)
			return
		end
	end

	-- Action when the node is covered (by liquid or walkable node).
	-- A node is covered if the node above it takes up a whole block.
	-- There shall be a seperate facility for handling partial nodes.
	if interaction_data.if_covered then
		local n2 = minetest.get_node(above)
		local d2 = minetest.registered_nodes[n2.name]
		
		if d2 then
			local walkable = d2.walkable
			local liquid = d2.liquidtype or "none"
	
			if walkable or liquid ~= "none" then
				node.name = interaction_data.if_covered
				minetest.add_node(pos, node)
				return
			end
		end
	end

	-- Get what's to the 4 sides (not including center or corners).
	local neighbors = {
		-- Adjacent horizontal sides.
		{x=pos.x-1, y=pos.y,   z=pos.z  },
		{x=pos.x+1, y=pos.y,   z=pos.z  },
		{x=pos.x,   y=pos.y,   z=pos.z-1},
		{x=pos.x,   y=pos.y,   z=pos.z+1},

		-- Horizontal diagonals.
		{x=pos.x+1, y=pos.y,   z=pos.z+1},
		{x=pos.x-1, y=pos.y,   z=pos.z+1},
		{x=pos.x+1, y=pos.y,   z=pos.z-1},
		{x=pos.x-1, y=pos.y,   z=pos.z-1},

		-- Directly below.
		{x=pos.x,   y=pos.y-1, z=pos.z  },

		-- Adjacent sides below.
		{x=pos.x+1, y=pos.y-1, z=pos.z  },
		{x=pos.x-1, y=pos.y-1, z=pos.z  },
		{x=pos.x,   y=pos.y-1, z=pos.z+1},
		{x=pos.x,   y=pos.y-1, z=pos.z-1},

		-- Adjacent diagonals below.
		{x=pos.x+1, y=pos.y-1, z=pos.z+1},
		{x=pos.x-1, y=pos.y-1, z=pos.z+1},
		{x=pos.x+1, y=pos.y-1, z=pos.z-1},
		{x=pos.x-1, y=pos.y-1, z=pos.z-1},

		-- Directly above.
		{x=pos.x,   y=pos.y+1, z=pos.z  },

		-- Adjacent sides above.
		{x=pos.x+1, y=pos.y+1, z=pos.z  },
		{x=pos.x-1, y=pos.y+1, z=pos.z  },
		{x=pos.x,   y=pos.y+1, z=pos.z+1},
		{x=pos.x,   y=pos.y+1, z=pos.z-1},

		-- Adjacent diagonals above.
		{x=pos.x+1, y=pos.y+1, z=pos.z+1},
		{x=pos.x-1, y=pos.y+1, z=pos.z+1},
		{x=pos.x+1, y=pos.y+1, z=pos.z-1},
		{x=pos.x-1, y=pos.y+1, z=pos.z-1},
	}

	-- This is needed so that the order in which neighbors are checked is random.
	table.shuffle(neighbors)

	local find_nearby = function(names)
		if type(names) == "string" then
			for k, v in ipairs(neighbors) do
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
			for k, v in ipairs(neighbors) do
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

	local execute_action = function(is_group, gkey, node_or_group)
		local above_key = "when_" .. gkey .. "_above"
		local below_key = "when_" .. gkey .. "_below"
		local nearby_key = "when_" .. gkey .. "_nearby"

		-- Action above.
		if interaction_data[above_key] then
			local n2 = minetest.get_node(above)
			local d2 = minetest.registered_nodes[n2.name]
			local g2 = {}
			if d2 then
				g2 = d2.groups or {}
			end
			local good = false
			if is_group then
				if g2[node_or_group] and g2[node_or_group] > 0 then
					good = true
				end
			else
				if n2.name == node_or_group then
					good = true
				end
			end
			if good then
				if type(interaction_data[above_key]) == "string" then
					node.name = interaction_data[above_key]
					minetest.add_node(pos, node)
					return false, true -- Don't wait, done.
				elseif type(interaction_data[above_key]) == "function" then
					local ret, wait = interaction_data[above_key](pos, light_above, n2.name, d2, g2)
					if ret and ret ~= "" then
						node.name = ret
						minetest.add_node(pos, node)
						return false, true -- Don't wait, done.
					elseif wait then
						return true, false -- Wait, not done.
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
			local good = false
			if is_group then
				if g2[node_or_group] and g2[node_or_group] > 0 then
					good = true
				end
			else
				if n2.name == node_or_group then
					good = true
				end
			end
			if good then
				if type(interaction_data[below_key]) == "string" then
					node.name = interaction_data[below_key]
					minetest.add_node(pos, node)
					return false, true -- Don't wait, done.
				elseif type(interaction_data[below_key]) == "function" then
					local ret, wait = interaction_data[below_key](pos, light_above, n2.name, d2, g2)
					if ret and ret ~= "" then
						node.name = ret
						minetest.add_node(pos, node)
						return false, true -- Don't wait, done.
					elseif wait then
						return true, false -- Wait, not done.
					end
				end
			end
		end

		-- Action nearby.
		if interaction_data[nearby_key] then
			local find_name = node_or_group
			if is_group then
				find_name = "group:" .. find_name
			end
			local p2 = find_nearby(find_name)
			if p2 then
				if type(interaction_data[nearby_key]) == "string" then
					node.name = interaction_data[nearby_key]
					minetest.add_node(pos, node)
					return false, true -- Don't wait, done.
				elseif type(interaction_data[nearby_key]) == "function" then
					local n2 = minetest.get_node(p2)
					local d2 = minetest.registered_nodes[n2.name]
					if d2 then
						local g2 = d2.groups or {}
						local ret, wait = interaction_data[nearby_key](pos, light_above, n2.name, d2, g2)
						if ret and ret ~= "" then
							node.name = ret
							minetest.add_node(pos, node)
							return false, true -- Don't wait, done.
						elseif wait then
							return true, false -- Wait, not done.
						end
					end
				end
			end
		end
	end

	-- Keep track of which keys have already been processed.
	local done_parts = {}

	for key, data in pairs(interaction_data) do
		if key:find("^when_") then
			if key:find("_above$") or key:find("_below$") or key:find("_nearby$") then
				local _, first = key:find("^when_group_")
				local is_group = true
				if not first then
					_, first = key:find("^when_")
					is_group = false
				end
				first = first + 1
				local last = key:find("_[^_]*$") - 1
				local part = key:sub(first, last)
				local gkey = part
				if not is_group then
					-- Need to replace the first '_' in `part` with a ':'.
					local p = part:find('_')
					part = part:sub(1, p-1) .. ':' .. part:sub(p+1)
				else
					gkey = "group_" .. gkey
				end
				if not done_parts[part] then
					minetest.chat_send_all(gkey .. ", " .. part)
					local wait, done = execute_action(is_group, gkey, part)
					if wait then
						return true
					elseif done then
						return
					end
					done_parts[part] = true
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



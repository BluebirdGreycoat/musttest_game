
-- File is reloadable.

local INTERACTION_DATA = {
	["default:dirt"] = {
		-- Node turns to this if buried.
		if_buried = "darkage:darkdirt",

		if_covered = {
			-- Ignore these nodes when checking whether node is covered by something.
			-- Note: non-walkable nodes are always ignored by default.
			ignore = {"group:snow", "group:snowy"},
		},

		-- The key name doesn't actually matter, it can be anything,
		-- as long as it begins with "when_" and ends with "_near".
		when_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt",
		},

		when_ice_near = {
			nodenames = "group:ice",
			if_nearby = "default:permafrost",
		},

		when_snow1_near = {
			nodenames = {"group:snow"},
			if_above = "default:dirt_with_snow",
			if_below = "default:permafrost",
		},

		when_snow2_near = {
			nodenames = {"group:snow", "group:snowy"},
			if_nearby = "default:dirt_with_snow",
			require_not_covered = true,
		},

		when_sand_near = {
			nodenames = "group:sand",
			if_above = "darkage:darkdirt",
			if_below = "default:dry_dirt",
			if_nearby = "default:dry_dirt",
		},

		when_grass1_near = {
			nodenames = {"default:dirt_with_grass", "default:dirt_with_grass_footsteps"},
			require_not_covered = true,

			if_adjacent_side = function(pos, light, name, def, groups)
				if light < 13 then
					return "", true -- Wait a bit.
				end

				return "default:dirt_with_grass", false -- Done.
			end,
		},

		when_grass2_near = {
			nodenames = "default:dirt_with_dry_grass",
			require_not_covered = true,

			if_adjacent_side = function(pos, light, name, def, groups)
				if light < 13 then
					return "", true -- Wait a bit.
				end

				return "default:dirt_with_dry_grass", false -- Done.
			end,
		},

		when_grass3_near = {
			nodenames = "moregrass:darkgrass",
			require_not_covered = true,

			if_adjacent_side = function(pos, light, name, def, groups)
				if light < 13 then
					return "", true -- Wait a bit.
				end

				return "moregrass:darkgrass", false -- Done.
			end,
		},

		-- Shall return the nodename to set, or "" to leave unchanged.
		-- Return boolean second parameter to indicate whether to wait.
		when_flora_near = {
			nodenames = "group:flora",
			require_not_covered = true,

			if_above = function(pos, light, name, def, groups)
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
	},

	["default:dirt_with_grass"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_group_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt_with_dry_grass",
		},

		when_group_snow_near = {
			nodenames = "group:snow",
			if_above = "default:dirt_with_snow",
		},

		when_group_ice_near = {
			nodenames = "group:ice",
			if_below = "default:permafrost_with_moss",
			require_not_covered = true,
		},
	},

	["default:dirt_with_dry_grass"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_group_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt",
		},

		when_group_snow_near = {
			nodenames = "group:snow",
			if_above = "default:dirt_with_snow",
		},

		when_group_ice_near = {
			nodenames = "group:ice",
			if_below = "default:permafrost_with_moss",
			require_not_covered = true,
		},
	},

	["moregrass:darkgrass"] = {
		if_buried = "default:dirt",
		if_covered = "default:dirt",

		when_group_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_group_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt_with_dry_grass",
		},

		when_group_snow_near = {
			nodenames = "group:snow",
			if_above = "default:dirt_with_snow",
			require_not_covered = true,
		},

		when_group_ice_near = {
			nodenames = "group:ice",
			if_below = "default:permafrost_with_moss",
			require_not_covered = true,
		},
	},

	["default:dirt_with_snow"] = {
		if_buried = "default:dirt",

		if_covered = {
			ignore = "group:snow",
			action = "default:dirt",
		},

		when_group_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_group_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt",
		},
	},

	["default:permafrost"] = {
		when_group_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_group_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt",
		},

		when_group_snow_near = {
			nodenames = "group:snow",
			if_above = "default:permafrost_with_snow",
		},

		when_group_flora_near = {
			nodenames = "group:flora",
			if_above = "default:permafrost_with_moss",
			require_not_covered = true,
		},
	},

	["default:permafrost_with_moss"] = {
		if_buried = "default:permafrost",

		if_covered = {
			ignore = "default:cobble",
			action = "default:permafrost",
		},

		when_group_lava_near = {
			nodenames = "group:lava",
			if_nearby = "darkage:darkdirt",
		},

		when_group_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:permafrost",
		},

		when_group_snow_near = {
			nodenames = "group:snow",
			if_above = "default:permafrost_with_snow",
		},

		when_default_cobble_near = {
			nodenames = "default:cobble",
			if_above = "default:permafrost_with_stones",
		},
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

	local node_has_name_or_group = function(nn, name)
		local tt = type(name)
		if tt == "string" then
			if nn == name then
				return true
			elseif name:find("^group:") then
				local g = name:sub(name:len() + 1)
				local d = minetest.registered_nodes[nn]
				if d then
					local g2 = d.groups or {}
					if g2[g] and g2[g] > 0 then
						return true
					end
				end
			end
		elseif tt == "table" then
			for _, n in ipairs(name) do
				if nn == n then
					return true
				elseif n:find("^group:") then
					local g = n:sub(n:len() + 1)
					local d = minetest.registered_nodes[nn]
					if d then
						local g2 = d.groups or {}
						if g2[g] and g2[g] > 0 then
							return true
						end
					end
				end
			end
		end
	end

	-- Action when the node is covered (by liquid or walkable node).
	-- A node is covered if the node above it takes up a whole block.
	-- There shall be a seperate facility for handling partial nodes.
	local is_covered = false

	-- Check whether the node is covered.
	do
		local n2 = minetest.get_node(above)

		local ignore = false
		local dt = interaction_data.if_covered
		if type(dt) == "table" then
			if dt.ignore and node_has_name_or_group(n2.name, dt.ignore) then
				ignore = true
			end
		end

		if not ignore then
			local d2 = minetest.registered_nodes[n2.name]
			if d2 then
				local walkable = d2.walkable
				local liquid = d2.liquidtype or "none"

				if walkable or liquid ~= "none" then
					is_covered = true
				end
			end
		end
	end

	-- Action to take if the node is covered by liquid or walkable.
	if interaction_data.if_covered and is_covered then
		local dt = interaction_data.if_covered
		if type(dt) == "string" then
			node.name = dt
			minetest.add_node(pos, node)
			return
		elseif type(dt) == "table" then
			if dt.action then
				node.name = dt.action
				minetest.add_node(pos, node)
				return
			end
		end
	end

	-- Get what's to the 4 sides (not including center or corners).
	local all_neighbors = {
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
	table.shuffle(all_neighbors)

	local neighbors_above = {
		{x=pos.x, y=pos.y+1, z=pos.z},
	}

	local neighbors_below = {
		{x=pos.x, y=pos.y-1, z=pos.z},
	}

	local neighbors_beside_4 = {
		{x=pos.x-1, y=pos.y,   z=pos.z  },
		{x=pos.x+1, y=pos.y,   z=pos.z  },
		{x=pos.x,   y=pos.y,   z=pos.z-1},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
	}

	local find_nearby = function(neighbors, names)
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
				local d2
				local g2
				for _, n in ipairs(names) do
					if n2.name == n then
						return v
					elseif string.find(n, "^group:") then
						local g = string.sub(n, string.len("group:") + 1)
						d2 = d2 or minetest.registered_nodes[n2.name]
						g2 = g2 or d2.groups or {}
						if g2[g] and g2[g] > 0 then
							return v
						end
					end
				end
			end
		end
	end

	local function do_nodecheck(callback, neighbors, nodenames)
		local p2 = find_nearby(neighbors, nodenames)
		if p2 then
			if type(callback) == "string" then
				node.name = callback
				minetest.add_node(pos, node)
				return false, true -- Don't wait, done.
			elseif type(callback) == "function" then
				local n2 = minetest.get_node(p2)
				local d2 = minetest.registered_nodes[n2.name]
				if d2 then
					local g2 = d2.groups or {}
					local ret, wait = callback(pos, light_above, n2.name, d2, g2)
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

	local execute_action = function(data)
		-- Action above.
		if data.if_above then
			local wait, done = do_nodecheck(data.if_above, neighbors_above, data.nodenames)
			if wait or done then
				return wait, done
			end
		end

		-- Action below.
		if data.if_below then
			local wait, done = do_nodecheck(data.if_below, neighbors_below, data.nodenames)
			if wait or done then
				return wait, done
			end
		end

		-- Action if adjacent to 1 of 4 sides.
		if data.if_adjacent_side then
			local wait, done = do_nodecheck(data.if_adjacent_side, neighbors_beside_4, data.nodenames)
			if wait or done then
				return wait, done
			end
		end

		-- Action nearby.
		if data.if_nearby then
			local wait, done = do_nodecheck(data.if_nearby, all_neighbors, data.nodenames)
			if wait or done then
				return wait, done
			end
		end
	end

	for key, data in pairs(interaction_data) do
		if key:find("^when_") and key:find("_near$") then
			if not (data.require_not_covered and is_covered) then
				local wait, done = execute_action(data)
				if wait then
					return true
				elseif done then
					return
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



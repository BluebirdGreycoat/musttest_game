
-- File is reloadable.

-- Nodes update to their environment every 30 seconds to 15 minutes.
local MIN_TIME = 30
local MAX_TIME = 60*15

local INTERACTION_DATA = {
	["default:dirt"] = {
		-- Node turns to this if buried (node surrounded by nodes that block light).
		if_buried = "darkage:darkdirt",

		if_covered = {
			-- Ignore these nodes when checking whether node is covered by something.
			-- Note: non-walkable/buildable_to nodes are always ignored by default.
			ignore = {"group:snow", "group:leaves", "group:fence", "group:door", "group:trapdoor"},
		},

		-- If present, this table informs the algorithm what order to apply `when_*_near` checks.
		-- This may be needed in order to break endless looping interactions.
		-- Checks are performed in the order in which they appear here.
		-- Note that if you use this table, then all checks MUST be listed. Checks which are
		-- not listed will not be applied!
		action_ordering = {
			"lava",
			"fire",
			"ice",
			"snow1",
			"snow2",
			"sand",
			"flora",
			"leaves",
			"grass",
		},

		-- The key name doesn't actually matter, it can be anything,
		-- as long as it begins with "when_" and ends with "_near".
		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
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

		when_grass_near = {
			nodenames = {"default:dirt_with_grass", "default:dirt_with_grass_footsteps", "default:dirt_with_dry_grass", "moregrass:darkgrass"},
			require_not_covered = true,

			-- If value is not a string, then it must be a function.
			-- The signature is `pos`, `light`, `loc`, `name`, `def`, `groups`.
			-- `pos` is the position of the current node, `loc` is the triggering neighbor position.
			-- Can return nothing if nothing is to be done.
			if_adjacent_side = function(pos, light, loc, name, def, groups)
				if light < 13 then
					return "", true -- Wait a bit.
				end

				-- Special case.
				if name == "default:dirt_with_grass_footsteps" then
					name = "default:dirt_with_grass"
				end

				return name
			end,
		},

		-- Shall return the nodename to set, or "" to leave unchanged.
		-- Return boolean second parameter to indicate whether to wait.
		when_flora_near = {
			nodenames = {"group:flora", "default:dry_shrub"},
			require_not_covered = true,

			if_above = function(pos, light, loc, name, def, groups)
				if name == "default:dry_shrub" then
					return "default:dry_dirt"
				end

				if groups.junglegrass and groups.junglegrass > 0 then
					if light >= 13 then
						return "moregrass:darkgrass"
					else
						return "", true
					end
				elseif groups.dry_grass and groups.dry_grass > 0 then
					if light >= 13 then
						return "default:dirt_with_dry_grass"
					else
						return "", true
					end
				elseif groups.grass and groups.grass > 0 then
					if light >= 13 then
						return "default:dirt_with_grass"
					else
						return "", true
					end
				end
			end,
		},

		when_leaves_near = {
			nodenames = "group:leaves",

			if_above = function(pos, light, loc, name, def, groups)
				local water = minetest.find_node_near(pos, 5, "group:water")
				if water then
					return "default:dirt_with_rainforest_litter"
				else
					return "default:dirt_with_coniferous_litter"
				end
			end,
		},
	},

	["default:dirt_with_grass"] = {
		if_buried = "default:dirt",

		if_covered = {
			ignore = {"group:fence", "group:door", "group:trapdoor"},
			action = "default:dirt",
		},

		action_ordering = {
			"lava",
			"fire",
			"snow",
			"ice",
			"sand",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt_with_dry_grass",
			require_not_covered = true,
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_adjacent_side = "default:dirt_with_dry_grass",
			require_not_covered = true,
		},

		when_ice_near = {
			nodenames = "group:ice",
			if_nearby = "default:dirt_with_dry_grass",
			require_not_covered = true,
		},

		when_sand_near = {
			nodenames = "group:sand",
			if_adjacent_side = "default:dirt_with_dry_grass",
			require_not_covered = true,
		},
	},

	["default:dirt_with_dry_grass"] = {
		if_buried = "default:dirt",

		if_covered = {
			ignore = {"group:fence", "group:door", "group:trapdoor"},
			action = "default:dirt",
		},

		action_ordering = {
			"lava",
			"fire",
			"snow",
			"ice",
			"sand",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt",
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:dirt_with_snow",
			require_not_covered = true,
		},

		when_ice_near = {
			nodenames = "group:ice",
			if_nearby = "default:dirt",
			require_not_covered = true,
		},

		when_sand_near = {
			nodenames = "group:sand",
			if_adjacent_side = "default:dry_dirt_with_dry_grass",
			require_not_covered = true,
		},
	},

	["moregrass:darkgrass"] = {
		if_buried = "default:dirt",

		if_covered = {
			ignore = {"group:fence", "group:door", "group:trapdoor"},
			action = "default:dirt",
		},

		action_ordering = {
			"lava",
			"fire",
			"snow",
			"cold",
			"sand",
			"dry",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt_with_dry_grass",
			require_not_covered = true,
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:dirt_with_snow",
			require_not_covered = true,
		},

		when_cold_near = {
			nodenames = {"group:ice", "group:cold", "group:snowy"},
			if_nearby = "default:dirt_with_grass",
			require_not_covered = true,
		},

		when_sand_near = {
			nodenames = "group:sand",
			if_adjacent_side = "default:dirt_with_dry_grass",
			require_not_covered = true,
		},

		when_dry_near = {
			nodenames = {"default:dirt_with_dry_grass", "default:dry_dirt_with_dry_grass", "darkage:darkdirt", "default:dry_dirt"},
			if_nearby = "default:dirt_with_grass",
			require_not_covered = true,
		},
	},

	["default:dirt_with_snow"] = {
		if_buried = "default:dirt",

		if_covered = {
			ignore = {"group:snow", "group:fence", "group:door", "group:trapdoor"},
			action = "default:dirt",
		},

		action_ordering = {
			"lava",
			"fire",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dirt",
		},
	},

	["darkage:darkdirt"] = {
		if_covered = {
			ignore = {"group:snow", "group:ice", "group:leaves"},
		},

		action_ordering = {"snow", "ice", "leaves", "minerals"},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:dark_dirt_with_snow",
			if_adjacent_side = "default:dark_dirt_with_snow",
			require_not_covered = true,
		},

		when_minerals_near = {
			nodenames = "glowstone:minerals",
			require_not_covered = true,

			if_below = function(pos, light, loc, name, def, groups)
				-- The minerals are used up.
				minetest.remove_node(loc)

				-- But regular dirt is made.
				return "default:dirt"
			end,
		},

		when_ice_near = {
			nodenames = "group:ice",
			if_above = "default:permafrost",
			if_below = "default:permafrost",
			if_adjacent_side = "default:permafrost",
		},

		when_leaves_near = {
			nodenames = "group:leaves",

			if_above = function(pos, light, loc, name, def, groups)
				local water = minetest.find_node_near(pos, 5, "group:water")
				if water then
					return "default:dark_dirt_with_rainforest_litter"
				else
					return "default:dark_dirt_with_coniferous_litter"
				end
			end,
		},
	},

	["default:dark_dirt_with_snow"] = {
		if_covered = {
			ignore = "group:snow",
			action = "darkage:darkdirt",
		},

		action_ordering = {"lava", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "darkage:darkdirt",
		},
	},

	["default:dry_dirt"] = {
		if_buried = "darkage:darkdirt",

		if_covered = {
			ignore = {"group:snow", "group:leaves"},
		},

		action_ordering = {"lava", "water", "snow", "leaves"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_water_near = {
			nodenames = "group:water",
			if_nearby = "default:dirt",
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_nearby = "default:dry_dirt_with_snow",
		},

		when_leaves_near = {
			nodenames = "group:leaves",

			if_above = function(pos, light, loc, name, def, groups)
				local water = minetest.find_node_near(pos, 5, "group:water")
				if water then
					return "default:dry_dirt_with_rainforest_litter"
				else
					return "default:dry_dirt_with_coniferous_litter"
				end
			end,
		},
	},

	["default:dry_dirt_with_snow"] = {
		if_buried = "default:dry_dirt",

		if_covered = {
			ignore = "group:snow",
			action = "default:dry_dirt",
		},

		action_ordering = {"lava", "water", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_water_near = {
			nodenames = "group:water",
			if_nearby = "default:dirt_with_snow",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt",
		},
	},

	["default:dirt_with_rainforest_litter"] = {
		if_buried = "default:dirt",
		if_covered = {
			ignore = "group:leaves",
			action = "default:dirt",
		},

		action_ordering = {"lava", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt_with_rainforest_litter",
		},
	},

	["default:dirt_with_coniferous_litter"] = {
		if_buried = "default:dirt",
		if_covered = {
			ignore = "group:leaves",
			action = "default:dirt",
		},

		action_ordering = {"lava", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt_with_coniferous_litter",
		},
	},

	["default:dark_dirt_with_rainforest_litter"] = {
		if_buried = "darkage:darkdirt",
		if_covered = {
			ignore = "group:leaves",
			action = "darkage:darkdirt",
		},

		action_ordering = {"lava", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "darkage:darkdirt",
		},
	},

	["default:dark_dirt_with_coniferous_litter"] = {
		if_buried = "darkage:darkdirt",
		if_covered = {
			ignore = "group:leaves",
			action = "darkage:darkdirt",
		},

		action_ordering = {"lava", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "darkage:darkdirt",
		},
	},

	["default:dry_dirt_with_rainforest_litter"] = {
		if_buried = "default:dry_dirt",
		if_covered = {
			ignore = "group:leaves",
			action = "default:dry_dirt",
		},

		action_ordering = {"lava", "water", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_water_near = {
			nodenames = "group:water",
			if_nearby = "default:dirt_with_rainforest_litter",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt",
		},
	},

	["default:dry_dirt_with_coniferous_litter"] = {
		if_buried = "default:dry_dirt",
		if_covered = {
			ignore = "group:leaves",
			action = "default:dry_dirt",
		},

		action_ordering = {"lava", "water", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_water_near = {
			nodenames = "group:water",
			if_nearby = "default:dirt_with_coniferous_litter",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt",
		},
	},

	["default:dry_dirt_with_dry_grass"] = {
		if_buried = "default:dry_dirt",
		if_covered = "default:dry_dirt",

		action_ordering = {"lava", "water", "fire"},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_water_near = {
			nodenames = "group:water",
			if_nearby = "default:dirt_with_dry_grass",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:dry_dirt",
		},
	},

	["default:permafrost"] = {
		if_covered = {
			ignore = {
				"group:snow",
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
				"group:ice",
			},
		},

		action_ordering = {
			"lava",
			"fire",
			"snow",
			"cobble",
			"grass",
			"flora",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "darkage:darkdirt",
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:permafrost_with_snow",
			require_not_covered = true,
		},

		when_cobble_near = {
			nodenames = {
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
				"group:ice", -- Also brings stone in permafrost to the surface.
			},
			if_above = "default:permafrost_with_stones",
		},

		when_flora_near = {
			nodenames = "group:flora",
			if_above = "default:permafrost_with_moss",
			require_not_covered = true,
		},

		when_grass_near = {
			nodenames = {"moregrass:darkgrass", "default:dirt_with_grass"},
			if_adjacent_side = "default:permafrost_with_moss",
		},
	},

	["default:permafrost_with_snow"] = {
		if_covered = {
			ignore = {
				"group:snow",
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
			},
			action = "default:permafrost",
		},

		action_ordering = {
			"lava",
			"fire",
			"cobble",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:permafrost",
		},

		when_cobble_near = {
			nodenames = {
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
			},
			if_above = "default:permafrost_with_snow_and_stones",
		},
	},

	["default:permafrost_with_stones"] = {
		if_buried = "default:permafrost",

		if_covered = {
			ignore = "group:snow",
		},

		action_ordering = {
			"lava",
			"snow",
			"flora",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:permafrost_with_snow_and_stones",
		},

		when_flora_near = {
			nodenames = "group:flora",
			if_above = "default:permafrost_with_moss_and_stones",
			require_not_covered = true,
		},
	},

	["default:permafrost_with_snow_and_stones"] = {
		if_covered = {
			ignore = {
				"group:snow",
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
			},
			action = "default:permafrost_with_stones",
		},

		action_ordering = {
			"lava",
			"fire",
			"cobble",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:permafrost_with_stones",
		},

		when_cobble_near = {
			nodenames = {
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
			},
			if_above = "default:permafrost_with_stones",
		},
	},

	["default:permafrost_with_moss"] = {
		if_buried = "default:permafrost",

		if_covered = {
			ignore = {
				"group:snow",
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
			},
			action = "default:permafrost",
		},

		action_ordering = {
			"lava",
			"fire",
			"snow",
			"cobble",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:permafrost",
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:permafrost_with_snow",
			if_adjacent_side = "default:permafrost_with_snow",
			require_not_covered = true,
		},

		when_cobble_near = {
			nodenames = {
				"default:cobble",
				"cavestuff:cobble_with_moss",
				"cavestuff:cobble_with_lichen",
				"cavestuff:cobble_with_algae",
				"cavestuff:cobble_with_salt",
				"cavestuff:cobble",
			},
			if_above = "default:permafrost_with_stones",
		},
	},

	["default:permafrost_with_moss_and_stones"] = {
		if_buried = "default:permafrost",

		if_covered = {
			ignore = {"group:snow"},
			action = "default:permafrost_with_stones",
		},

		action_ordering = {
			"lava",
			"fire",
			"snow",
		},

		when_lava_near = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "darkage:darkdirt",
		},

		when_fire_near = {
			nodenames = "group:fire",
			if_nearby = "default:permafrost_with_stones",
		},

		when_snow_near = {
			nodenames = "group:snow",
			if_above = "default:permafrost_with_snow_and_stones",
			require_not_covered = true,
		},
	},

	["default:sand"] = {
		when_snow_near = {
			nodenames = {"group:snow", "group:ice"},
			if_nearby = "sand:sand_with_ice_crystals",
		},
	},

	["default:snow"] = {
		action_ordering = {"lava", "fire"},

		when_lava_nearby = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "fire:basic_flame",
		},

		when_fire_nearby = {
			nodenames = "group:fire",
			if_nearby = "air",
		},
	},

	["default:snowblock"] = {
		action_ordering = {"lava", "fire"},

		when_lava_nearby = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "fire:basic_flame",
		},

		when_fire_nearby = {
			nodenames = "group:fire",
			if_nearby = "air",
		},
	},

	["snow:footprints"] = {
		action_ordering = {"lava", "fire"},

		when_lava_nearby = {
			nodenames = {"group:lava", "group:rockmelt"},
			if_nearby = "fire:basic_flame",
		},

		when_fire_nearby = {
			nodenames = "group:fire",
			if_nearby = "air",
		},
	},
}

-- Copy.
INTERACTION_DATA["default:dirt_with_grass_footsteps"] = INTERACTION_DATA["default:dirt_with_grass"]



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
			if interaction_data.if_buried ~= node.name then
				node.name = interaction_data.if_buried
				minetest.add_node(pos, node)
				minetest.check_for_falling(pos)
				return
			end
		end
	end

	local node_has_name_or_group = function(nn, name)
		local tt = type(name)
		if tt == "string" then
			if nn == name then
				return true
			elseif name:find("^group:") then
				local g = name:sub(7)
				local d = minetest.registered_nodes[nn]
				if d then
					local g2 = d.groups or {}
					if g2[g] and g2[g] > 0 then
						return true
					end
				end
			end
		elseif tt == "table" then
			local d
			local g2
			for _, n in ipairs(name) do
				if nn == n then
					return true
				elseif n:find("^group:") then
					local g = n:sub(7)

					-- No mater how many groups/names to test against, get the node def and groups only once.
					if not d then
						d = minetest.registered_nodes[nn]
					end
					if not g2 then
						g2 = d and d.groups or {}
					end

					if g2[g] and g2[g] > 0 then
						return true
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

				-- Buildable-to nodes cannot cover other nodes.
				if not d2.buildable_to then
					if walkable or liquid ~= "none" then
						is_covered = true
					end
				end
			end
		end
	end

	-- Action to take if the node is covered by liquid or walkable.
	if interaction_data.if_covered and is_covered then
		local dt = interaction_data.if_covered
		if type(dt) == "string" then
			if node.name ~= dt then
				node.name = dt
				minetest.add_node(pos, node)
				minetest.check_for_falling(pos)
				return
			end
		elseif type(dt) == "table" then
			if dt.action then
				if dt.action ~= node.name then
					node.name = dt.action
					minetest.add_node(pos, node)
					minetest.check_for_falling(pos)
					return
				end
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
	table.shuffle(neighbors_beside_4)

	local find_nearby = function(neighbors, names)
		for k, v in ipairs(neighbors) do
			local n2 = minetest.get_node(v)
			if node_has_name_or_group(n2.name, names) then
				return v
			end
		end
	end

	local function do_nodecheck(callback, neighbors, nodenames)
		local p2 = find_nearby(neighbors, nodenames)
		if p2 then
			if type(callback) == "string" then
				if node.name ~= callback then
					node.name = callback
					minetest.add_node(pos, node)
					minetest.check_for_falling(pos)
					return false, true -- Don't wait, done.
				end
			elseif type(callback) == "function" then
				local n2 = minetest.get_node(p2)
				local d2 = minetest.registered_nodes[n2.name]
				if d2 then
					local g2 = d2.groups or {}
					local ret, wait = callback(pos, light_above, p2, n2.name, d2, g2)
					if ret and ret ~= "" then
						if node.name ~= ret then
							node.name = ret
							minetest.add_node(pos, node)
							minetest.check_for_falling(pos)
							return false, true -- Don't wait, done.
						end
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

	-- Apply checks in specific order.
	if interaction_data.action_ordering then
		for _, key in ipairs(interaction_data.action_ordering) do
			local data = interaction_data["when_" .. key .. "_near"]
			if data then
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
	else
		-- Apply checks in whatever order the keys happen to be stored in.
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



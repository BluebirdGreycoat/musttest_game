
-- It actually makes sense to build paths in your fields now, otherwise
-- you'll have to constantly hoe where you step!
--
-- Note: not checking protection here. Griefing someone's field this way is
-- "non-destructive", easy to restore.
local function trample_dirt(pos, player)
	local meta = minetest.get_meta(pos)
	local count = meta:get_int("trampled")

	if count >= 3 then
		local node_above = minetest.get_node(vector.add(pos, {x=0, y=1, z=0}))

		-- Only if no plant above.
		if node_above.name == "air" then
			local node = minetest.get_node(pos)
			local ndef = minetest.registered_nodes[node.name]

			if ndef and ndef.soil and ndef.soil.base then
				node.name = ndef.soil.base
				minetest.set_node(pos, node)
			end
		else
			-- Something above? Let's check if it's a plant, BWHAHAHA.
			local ndef = minetest.registered_nodes[node_above]
			if ndef and ndef._farming_prev_plant then
				local node = minetest.get_node(pos)
				node.name = ndef._farming_prev_plant
				minetest.set_node(pos, node)
				-- Not restarting node timer, this also stops plant from growing further.
			end
		end

		return
	end

	meta:set_int("trampled", count + 1)
	meta:mark_as_private("trampled")
end



local nodebox_hoedsoil = {
	{0, 0, 0, 16, 15, 16},
	{0, 15, 2, 16, 15.5, 7},
	{0, 15, 9, 16, 15.5, 14},
}
for k, v in ipairs(nodebox_hoedsoil) do
	for m, n in ipairs(v) do
		local p = nodebox_hoedsoil[k][m]
		p = p / 16
		p = p - 0.5
		nodebox_hoedsoil[k][m] = p
	end
end


minetest.override_item("default:dirt", {
	soil = {
		base = "default:dirt",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	}
})

minetest.override_item("default:dirt_with_grass", {
	soil = {
		base = "default:dirt_with_grass",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	}
})

minetest.override_item("moregrass:darkgrass", {
	soil = {
		base = "moregrass:darkgrass",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	}
})

minetest.override_item("default:dirt_with_dry_grass", {
	soil = {
		base = "default:dirt_with_dry_grass",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	}
})

minetest.register_node("farming:soil", {
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodebox_hoedsoil,
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	description = "Soil",
	movement_speed_multiplier = default.SLOW_SPEED,
	tiles = {"default_dirt.png^farming_soil.png", "default_dirt.png"},
	drop = "default:dirt",
	groups = utility.dig_groups("dirt", {not_in_creative_inventory = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, hoed_dirt_type = 1, soil = 2, grassland = 1, falling_node = 1, field = 1, want_notify = 1}),
	sounds = default.node_sound_dirt_defaults(),
	soil = {
		base = "default:dirt",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	},

	on_notify = function(pos, other)
		if other.y == pos.y+1 then
			farming.notify_soil_single(pos)
		end
	end,

	on_timer = function(...)
		farming.on_soil_notify(...)
	end,

  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,

	on_player_walk_over = trample_dirt,
})

minetest.register_node("farming:soil_wet", {
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodebox_hoedsoil,
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	description = "Wet Soil",
	movement_speed_multiplier = default.SLOW_SPEED,
	tiles = {"default_dirt.png^farming_soil_wet.png", "default_dirt.png^farming_soil_wet_side.png"},
	drop = "default:dirt",
	groups = utility.dig_groups("dirt", {not_in_creative_inventory = 1, dirt_type = 1, non_raw_dirt_type = 1, non_sterile_dirt_type = 1, hoed_dirt_type = 1, soil = 3, wet = 1, grassland = 1, falling_node = 1, field = 1, want_notify = 1}),
	sounds = default.node_sound_dirt_defaults(),
	soil = {
		base = "default:dirt",
		dry = "farming:soil",
		wet = "farming:soil_wet"
	},

	on_notify = function(pos, other)
		if other.y == pos.y+1 then
			farming.notify_soil_single(pos)
		end
	end,

	on_timer = function(...)
		farming.on_soil_notify(...)
	end,

  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:dirt"})
  end,

	on_player_walk_over = trample_dirt,
})

minetest.override_item("default:desert_sand", {
	soil = {
		base = "default:desert_sand",
		dry = "farming:desert_sand_soil",
		wet = "farming:desert_sand_soil_wet"
	}
})

minetest.register_node("farming:desert_sand_soil", {
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodebox_hoedsoil,
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	description = "Desert Sand Soil",
	movement_speed_multiplier = default.SLOW_SPEED,
	drop = "default:desert_sand",
	tiles = {"farming_desert_sand_soil.png", "default_desert_sand.png"},
	groups = utility.dig_groups("sand", {not_in_creative_inventory = 1, falling_node = 1, sand = 1, soil = 2, desert = 1, field = 1, fall_damage_add_percent=-20, want_notify = 1}),
	sounds = default.node_sound_sand_defaults(),
	soil = {
		base = "default:desert_sand",
		dry = "farming:desert_sand_soil",
		wet = "farming:desert_sand_soil_wet"
	},

	on_notify = function(pos, other)
		if other.y == pos.y+1 then
			farming.notify_soil_single(pos)
		end
	end,

	on_timer = function(...)
		farming.on_soil_notify(...)
	end,

  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:desert_sand"})
  end,

	on_player_walk_over = trample_dirt,
})

minetest.register_node("farming:desert_sand_soil_wet", {
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodebox_hoedsoil,
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	description = "Wet Desert Sand Soil",
	movement_speed_multiplier = default.SLOW_SPEED,
	drop = "default:desert_sand",
	tiles = {"farming_desert_sand_soil_wet.png", "farming_desert_sand_soil_wet_side.png"},
	groups = utility.dig_groups("sand", {falling_node = 1, sand = 1, not_in_creative_inventory = 1, soil = 3, wet = 1, desert = 1, field = 1, fall_damage_add_percent=-20, want_notify = 1}),
	sounds = default.node_sound_sand_defaults(),
	soil = {
		base = "default:desert_sand",
		dry = "farming:desert_sand_soil",
		wet = "farming:desert_sand_soil_wet"
	},

	on_notify = function(pos, other)
		if other.y == pos.y+1 then
			farming.notify_soil_single(pos)
		end
	end,

	on_timer = function(...)
		farming.on_soil_notify(...)
	end,

  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="default:desert_sand"})
  end,

	on_player_walk_over = trample_dirt,
})

minetest.register_node("farming:straw", {
	description = "Straw\n\nA soft material to fall on.",
	tiles = {"farming_straw.png"},
	is_ground_content = false,
	groups = utility.dig_groups("straw", {flammable=4, fall_damage_add_percent=-30, falling_node=1}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

minetest.register_node("farming:straw_weathered", {
	description = "Weathered Straw\n\nA soft material to fall on.",
	tiles = {"farming_straw_weathered.png"},
	is_ground_content = false,
	groups = utility.dig_groups("straw", {flammable=5, fall_damage_add_percent=-30, falling_node=1}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
})

-- Translate timer callback to update callback.
function farming.on_soil_notify(pos, elapsed)
	local node = minetest.get_node(pos)
	farming.on_update_soil(pos, node)
end

-- Called whenever soil is notified to update via timer.
-- This was originally an ABM function.
function farming.on_update_soil(pos, node)
	local n_def = minetest.reg_ns_nodes[node.name] or nil
	local wet = n_def.soil.wet or nil
	local base = n_def.soil.base or nil
	local dry = n_def.soil.dry or nil
	if not n_def or not n_def.soil or not wet or not base or not dry then
		return
	end

	pos.y = pos.y + 1
	local nn = minetest.get_node_or_nil(pos)
	if not nn or not nn.name then
		return
	end
	local nn_def = minetest.reg_ns_nodes[nn.name] or nil
	pos.y = pos.y - 1

	if not nn_def or (nn_def.walkable and minetest.get_item_group(nn.name, "plant") == 0) then
		minetest.add_node(pos, {name = base})
		return
	end
	-- check if there is water nearby
	local wet_lvl = minetest.get_item_group(node.name, "wet")

	-- Distance needed for water increased from 3 to 4 meters, to compensate for dirt being a falling node.
	-- [MustTest]
	local radius = 4
	if minetest.find_node_near(pos, radius, {"group:water"}) then
		-- if it is dry soil and not base node, turn it into wet soil
		if wet_lvl == 0 then
			minetest.add_node(pos, {name = wet})
			farming.notify_soil_single(pos)
		end
	else
		-- only turn back if there are no unloaded blocks (and therefore
		-- possible water sources) nearby
		if not minetest.find_node_near(pos, radius, {"ignore"}) then
			-- turn it back into base if it is already dry
			if wet_lvl == 0 then
				-- only turn it back if there is no plant/seed on top of it
				if minetest.get_item_group(nn.name, "plant") == 0 and minetest.get_item_group(nn.name, "seed") == 0 then
					minetest.add_node(pos, {name = base})
					-- Base dirt doesn't need soil notifications.
				end

			-- if its wet turn it back into dry soil
			elseif wet_lvl == 1 then
				minetest.add_node(pos, {name = dry})
				farming.notify_soil_single(pos)
			end
		end
	end
end


for i = 1, 5 do
	minetest.override_item("default:grass_"..i, {
		drop = {
			max_items = 1,
			items = {
				{items = {'farming:seed_wheat'}, rarity = 5},
			},
		},
		shears_drop = "default:grass_dummy",
	})
end

for i = 1, 5 do
	minetest.override_item("default:grass_"..i.."_hanging", {
		drop = {
			max_items = 1,
			items = {
				{items = {'farming:seed_wheat'}, rarity = 5},
			},
		},
		shears_drop = "default:grass_dummy",
	})
end

for i = 1, 5 do
	minetest.override_item("default:dry_grass2_"..i, {
		drop = {
			max_items = 1,
			items = {
				{items = {'potatoes:seed'}, rarity = 5},
			},
		},
	})
end

for i = 1, 5 do
	minetest.override_item("default:dry_grass2_"..i.."_hanging", {
		drop = {
			max_items = 1,
			items = {
				{items = {'potatoes:seed'}, rarity = 5},
			},
		},
	})
end

minetest.override_item("default:junglegrass", {
	drop = {
		max_items = 1,
		items = {
			{items = {'farming:seed_cotton'}, rarity = 8},
			{items = {'default:stick'}},
		},
	},
	shears_drop = "default:junglegrass",
})


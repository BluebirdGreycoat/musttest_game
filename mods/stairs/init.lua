-- Minetest 0.4 mod: stairs
-- See README.txt for licensing and other information.

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random



-- Global namespace for functions

local S = function(str) return str end

stairs = {}

local function pixel_box(x1, y1, z1, x2, y2, z2)
	return {
		x1 / 16 - 0.5,
		y1 / 16 - 0.5,
		z1 / 16 - 0.5,
		x2 / 16 - 0.5,
		y2 / 16 - 0.5,
		z2 / 16 - 0.5,
	}
end

-- Also used by walls.
function stairs.setup_nodedef_callbacks(subname, def)
	if string.find(subname, "ice") or string.find(subname, "snow") then
		assert(not def.on_construct)
		def.on_construct = function(pos)
			if rc.ice_melts_at_pos(pos) then
				minetest.get_node_timer(pos):start(math_random(ice.minmax_time()))
			end
		end

		assert(not def.on_timer)
		def.on_timer = function(pos, elapsed)
			if rc.ice_melts_at_pos(pos) then
				minetest.add_node(pos, {name="default:water_flowing"})
			end
		end
	end
end

function stairs.rotate_and_place(itemstack, placer, pt)
	if pt.type == "node" then
		local node = minetest.get_node(pt.under)
		if node.name == itemstack:get_name() then
			local param2 = node.param2
			return minetest.item_place(itemstack, placer, pt, param2)
		end
	end
	return minetest.rotate_node(itemstack, placer, pt)
end

dofile(minetest.get_modpath("stairs") .. "/slopes.lua")

local slabs_defs = {
	["_quarter"] =				{num=4,		light=0.25, is_flat=true, description="Quarter Slab"},
	["_three_quarter"] =	{num=12,	light=0.75, is_flat=true, description="Three-Quarter Slab"},
	["_1"] =							{num=1,		light=1/16, is_flat=true, description="1/16 Slab"},
	["_2"] =							{num=2,		light=2/16, is_flat=true, description="1/8 Slab"},
	["_14"] =							{num=14,	light=14/16, is_flat=true, description="7/8 Slab"},
	["_15"] =							{num=15,	light=15/16, is_flat=true, description="15/16 Slab"},

	["_two_sides"] = {
		description = "1/16 2-Sided Corner Panel",
		nodebox = {
			{ -0.5, -0.5, -0.5, 0.5, -7/16, 7/16 },
			{ -0.5, -0.5, 7/16, 0.5, 0.5, 0.5 },
		}
	},
	["_three_sides"] = {
		description = "1/16 3-Sided Corner Panel",
		nodebox = {
			{ -7/16, -0.5, -0.5, 0.5, -7/16, 7/16 },
			{ -7/16, -0.5, 7/16, 0.5, 0.5, 0.5 },
			{ -0.5, -0.5, -0.5, -7/16, 0.5, 0.5 },
		}
	},
	["_three_sides_u"] = {
		description = "1/16 3-Sided U Panel",
		nodebox = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, -7/16 },
			{ -0.5, -0.5, -7/16, 0.5, -7/16, 7/16 },
			{ -0.5, -0.5, 7/16, 0.5, 0.5, 0.5 },
		}
	},
	["_four_sides"] = {
		description = "1/16 4-Sided Nook Panel",
		nodebox = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, -7/16 },
			{ -0.5, -0.5, -7/16, 0.5, -7/16, 7/16 },
			{ -0.5, -0.5, 7/16, 0.5, 0.5, 0.5 },
			{ -0.5, -7/16, -7/16, -7/16, 0.5, 7/16 },
		}
	},
	["_hole"] = {
		description = "1/16 Murderhole Full",
		nodebox = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, -7/16},
			{-0.5, -0.5, 0.5, 0.5, 0.5, 7/16},
			{-0.5, -0.5, -7/16, -7/16, 0.5, 7/16},
			{0.5, -0.5, -7/16, 7/16, 0.5, 7/16},
		}
	},
	["_two_opposite"] = {
		description = "Double Panel 1/16 Opposing",
		nodebox = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, -7/16},
			{-0.5, -0.5, 0.5, 0.5, 0.5, 7/16},
		}
	},
	["_pit"] = {
		description = "1/16 Paneled Box Full",
		nodebox = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, -7/16 },
			{ -0.5, -0.5, -7/16, 0.5, -7/16, 7/16 },
			{ -0.5, -0.5, 7/16, 0.5, 0.5, 0.5 },
			{ -0.5, -7/16, -7/16, -7/16, 0.5, 7/16 },
			{ -7/16, 0.5, -7/16, 0.5, 7/16, 7/16 },
		}
	},
	["_pit_half"] = {
		description = "1/16 Paneled Box Half",
		nodebox = {
			{ -0.5, -0.5, -0.5, 0.0, 0.5, -7/16 },
			{ -0.5, -0.5, -7/16, 0.0, -7/16, 7/16 },
			{ -0.5, -0.5, 7/16, 0.0, 0.5, 0.5 },
			{ -0.5, -7/16, -7/16, -7/16, 0.5, 7/16 },
			{ -7/16, 0.5, -7/16, 0.0, 7/16, 7/16 },
		}
	},
	["_hole_half"] = {
		description = "1/16 Murderhole Half",
		nodebox = {
			{-0.5, -0.5, -0.5,  0.5,   0, -7/16},
			{-0.5, -0.5, 0.5,   0.5,   0, 7/16},
			{-0.5, -0.5, -7/16, -7/16, 0, 7/16},
			{0.5, -0.5, -7/16,  7/16,  0, 7/16},
		}
	},
}

function stairs.register_extra_slabs(subname, recipeitem, groups, images, description, sounds)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	local defs = table.copy(slabs_defs)

	-- Do not modify function argument.
	local groups = table.copy(groups)
	groups.not_in_craft_guide = 1
	groups.stairs_slab = 1
	groups.stairs_node = 1
  
	local ndef = minetest.registered_items[recipeitem]
	assert(ndef)

	for alternate, num in pairs(defs) do
		local def

		if num.num then
			def = {
				node_box = {
					type = "fixed",
					fixed = {-0.5, -0.5, -0.5, 0.5, (num.num/16)-0.5, 0.5},
				}
			}
		elseif num.nodebox then
			def = {
				node_box = {
					type = "fixed",
					fixed = num.nodebox,
				}
			}
		end
    
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    def.on_place = function(...) return stairs.rotate_and_place(...) end
    def.groups = groups
    def.sounds = sounds
		def.description = description .. " " .. (num.description or "Slab")
    def.tiles = stair_images
		def.light_source = math.ceil(ndef.light_source*(num.light or 0))
		def._stairs_parent_material = recipeitem

		-- Only for flat slabs.
		if num.is_flat then
			def.movement_speed_depends = recipeitem
		end
    
		stairs.setup_nodedef_callbacks(subname, def)

		minetest.register_node(":stairs:slab_" .. subname .. alternate, def)
	end

  if recipeitem then
		circular_saw.register_node(recipeitem, subname)
  end
end

local stairs_defs = {
	["_half"] = {
		description = "Left Half Stair",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0, 0, 0.5},
				{-0.5, 0, 0, 0, 0.5, 0.5},
			},
		},
		light=3/8,
	},
	["_right_half" ]= {
		description = "Right Half Stair",
		node_box = {
			type = "fixed",
			fixed = {
				{0, -0.5, -0.5, 0.5, 0, 0.5},
				{0, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		light=3/8,
	},
	["_half_1"] = {
		description = "Left 1/16 Stair",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, -7/16, 0, 0.5},
				{-0.5, 0, 0, -7/16, 0.5, 0.5},
			},
		},
		light=1/8,
	},
	["_right_half_1" ]= {
		description = "Right 1/16 Stair",
		node_box = {
			type = "fixed",
			fixed = {
				{7/16, -0.5, -0.5, 0.5, 0, 0.5},
				{7/16, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		light=1/8,
	},
	["_inner"] = {
		description = "Inside Corner Stair",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
				{-0.5, 0, -0.5, 0, 0.5, 0},
			},
		},
		light=7/8,
	},
	["_outer"] = {
		description = "Outside Corner Stair #1",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0, 0.5, 0.5},
			},
		},
		light=5/8,
	},
	["_outer2"] = {
		description = "Outside Corner Stair #2",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, 0, 0, 0, 0.5, 0.5},
				{-0.5, -0.5, -0.5, 0, 0, 0.5},
				{0, -0.5, 0, 0.5, 0, 0.5},
			},
		},
		light=5/8,
	},
	["_alt"] = {
		description = "Half Open Step",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		light=1/2,
	},
	["_alt_1"] = {
		description = "1/16 Open Step",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.0625, -0.5, 0.5, 0, 0},
				{-0.5, 0.4375, 0, 0.5, 0.5, 0.5},
			},
		},
		light=1/16,
	},
	["_alt_5"] = {
		description = "Half Open Shelf",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.0625, 0.0, 0.5, 0, 0.5},
				{-0.5, 0.4375, 0, 0.5, 0.5, 0.5},
			},
		},
		light=1/16,
	},
	["_alt_6"] = {
		description = "Full Open Shelf",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.0625, -0.5, 0.5, 0, 0.5},
				{-0.5, 0.4375, -0.5, 0.5, 0.5, 0.5},
			},
		},
		light=1/16,
	},
	["_alt_2"] = {
		description = "1/8 Open Step",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.125, -0.5, 0.5, 0, 0},
				{-0.5, 0.375, 0, 0.5, 0.5, 0.5},
			},
		},
		light=2/16,
	},
	["_alt_4"] = {
		description = "Quarter Open Step",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.25, -0.5, 0.5, 0, 0},
				{-0.5, 0.25, 0, 0.5, 0.5, 0.5},
			},
		},
		light=4/16,
	},
}

function stairs.register_extra_stairs(subname, recipeitem, groups, images, description, sounds)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	local defs = table.copy(stairs_defs)
  
	-- Do not modify function argument.
	local groups = table.copy(groups)
	groups.not_in_craft_guide = 1
	groups.stairs_stair = 1
	groups.stairs_node = 1

	local ndef = minetest.registered_items[recipeitem]
	assert(ndef)

	for alternate, def in pairs(defs) do
		def.drawtype = "nodebox"
		def.paramtype = "light"
		def.paramtype2 = "facedir"
		def.on_place = function(...) return stairs.rotate_and_place(...) end
		def.groups = groups
		def.sounds = sounds
		def.description = description .. " " .. (def.description or "Stair")
		def.tiles = stair_images
		def.light_source = math.ceil(ndef.light_source*def.light)
		def.light = nil
		def._stairs_parent_material = recipeitem
    
		stairs.setup_nodedef_callbacks(subname, def)

		minetest.register_node(":stairs:stair_" ..subname..alternate, def)

		if recipeitem then
			if alternate == "_inner" then
				minetest.register_craft({
					output = "stairs:stair_" .. subname .. alternate .. ' 8',
					recipe = {
						{recipeitem, recipeitem, recipeitem},
						{recipeitem, recipeitem, ''},
						{recipeitem, '', recipeitem},
					},
				})
			elseif alternate == "_outer" then
				minetest.register_craft({
					output = "stairs:stair_" .. subname .. alternate .. ' 8',
					recipe = {
						{recipeitem, recipeitem, recipeitem},
						{recipeitem, '', ''},
						{recipeitem, '', ''},
					},
				})
			end
		end
	end
	--minetest.register_alias("stairs:stair_" ..subname.. "_bottom", "stairs:stair_" ..subname)

  if recipeitem then
		circular_saw.register_node(recipeitem, subname)
  end
end

local panels_defs = {
	[""] = {
		description = "Horizontal Double Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, 0, 0.5},
		},
		light=1/4,
	},
	["_1"] = {
		description = "1/16 Half Panel",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, -0.4375, 0.5},
		},
		light=1/32,
	},
	["_2"] = {
		description = "1/8 Half Panel",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, -0.375, 0.5},
		},
		light=2/32,
	},
	["_4"] = {
		description = "Quarter Half Panel",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, -0.25, 0.5},
		},
		light=4/32,
	},
	["_12"] = {
		description = "Three-Quarter Half Panel",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, 0.25, 0.5},
		},
		light=12/32,
	},
	["_14"] = {
		description = "7/8 Half Panel",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, 0.375, 0.5},
		},
		light=14/32,
	},
	["_15"] = {
		description = "15/16 Half Panel",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, 0.4375, 0.5},
		},
		light=15/32,
	},
	["_16"] = {
		description = "Vertical Half Slab",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0.5, 0.5, 0.5},
		},
		light=16/32,
	},

-- Nodeboxes for Columns inspired
-- (but not copied) from Artemis's design in Middle-Ages mod
-- Licensed: WTFPL
-- Integrated to circular saw by MustTest

	["_pillar"] = {
		_is_panel_pillar = true,
		description = "Column",
		node_box = {
			type = "fixed",
			fixed = {
				pixel_box(2, 0, 5, 14, 16, 11),
				pixel_box(3, 0, 3, 13, 16, 13),
				pixel_box(5, 0, 2, 11, 16, 14),
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				pixel_box(2, 0, 2, 14, 16, 14),
			},
		},
		light=1,
	},
	["_pcend"] = {
		_is_panel_pillar = true,
		description = "Column End",
		node_box = {
			type = "fixed",
			fixed = {
				pixel_box(2, 0, 5, 14, 16, 11),
				pixel_box(3, 0, 3, 13, 16, 13),
				pixel_box(5, 0, 2, 11, 16, 14),

				pixel_box(0, 0, 0, 16, 3, 16),
				pixel_box(1, 3, 1, 15, 5, 15),
				pixel_box(2, 5, 2, 14, 7, 14),
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				-- The 5.1 is intentional, it keeps the wireframe from being burried,
				-- which looks ugly.
				pixel_box(2, 5.1, 2, 14, 16, 14),
				pixel_box(0, 0, 0, 16, 5, 16),
			},
		},
		light=1,
	},
}

function stairs.register_panel(subname, recipeitem, groups, images, description, sounds, datatable)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	local defs = table.copy(panels_defs)
  
	-- Do not modify function argument.
	local groups = table.copy(groups)
	groups.not_in_craft_guide = 1
	groups.stairs_panel = 1
	groups.stairs_node = 1

	local ndef = minetest.registered_items[recipeitem]
	assert(ndef)

	for alternate, def in pairs(defs) do
		if not def._is_panel_pillar or (def._is_panel_pillar and not datatable.exclude_pillars) then
		def.drawtype = "nodebox"
		def.paramtype = "light"
		def.paramtype2 = "facedir"
		def.on_place = function(...) return stairs.rotate_and_place(...) end
		def.groups = groups
		def.sounds = sounds
		def.description = description .. " " .. (def.description or "Panel")
		def.tiles = stair_images
		def.light_source = math.ceil(ndef.light_source*def.light)
		def.light = nil
		def._stairs_parent_material = recipeitem
    
		stairs.setup_nodedef_callbacks(subname, def)

		minetest.register_node(":stairs:panel_" ..subname..alternate, def)
		end
	end
	--minetest.register_alias("stairs:panel_" ..subname.. "_bottom", "stairs:panel_" ..subname)

  if recipeitem then
		circular_saw.register_node(recipeitem, subname)
  end
end

local microblocks_defs = {
	[""] = {
		description = "Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, 0, 0.5},
		},
		light=8/64,
	},
	["_c"] = {
		description = "Microblock Centered",
		node_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25, 0.25, 0, 0.25},
		},
		light=8/64,
	},
	["_1c"] = {
		description = "1/16 Microblock Centered",
		node_box = {
			type = "fixed",
			fixed = {-0.25, -0.5, -0.25, 0.25, -0.4375, 0.25},
		},
		light=1/64,
	},
	["_1"] = {
		description = "1/16 Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, -0.4375, 0.5},
		},
		light=1/64,
	},
	["_2"] = {
		description = "1/8 Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, -0.375, 0.5},
		},
		light=2/64,
	},
	["_4"] = {
		description = "Quarter Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, -0.25, 0.5},
		},
		light=4/64,
	},
	["_12"] = {
		description = "Three-Quarter Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, 0.25, 0.5},
		},
		light=12/64,
	},
	["_14"] = {
		description = "7/8 Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, 0.375, 0.5},
		},
		light=14/64,
	},
	["_15"] = {
		description = "15/16 Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, 0.4375, 0.5},
		},
		light=15/64,
	},
	["_16"] = {
		description = "Vertical Double Microblock",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, 0, 0, 0.5, 0.5},
		},
		light=16/64,
	},
	["_1s"] = {
		description = "1/16 Double-Diag Microblock",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0, -0.4375, 0},
				{0, -0.5, 0, 0.5, -0.4375, 0.5},
			},
		},
		light=2/64,
	},
	["_16s"] = {
		description = "Half Double-Diag Microblock",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0, 0, 0},
				{0, -0.5, 0, 0.5, 0, 0.5},
			},
		},
		light=16/64,
	}
}

function stairs.register_micro(subname, recipeitem, groups, images, description, sounds)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	local defs = table.copy(microblocks_defs)
	
	-- Do not modify function argument.
	local groups = table.copy(groups)
	groups.not_in_craft_guide = 1
	groups.stairs_microblock = 1
	groups.stairs_node = 1

	local ndef = minetest.registered_items[recipeitem]
	assert(ndef)

	for alternate, def in pairs(defs) do
		def.drawtype = "nodebox"
		def.paramtype = "light"
		def.paramtype2 = "facedir"
		def.on_place = function(...) return stairs.rotate_and_place(...) end
		def.groups = groups
		def.sounds = sounds
		def.description = description .. " " .. (def.description or "Microblock")
		def.tiles = stair_images
		def.light_source = math.ceil(ndef.light_source*def.light)
		def.light = nil
		def._stairs_parent_material = recipeitem
		
		stairs.setup_nodedef_callbacks(subname, def)

		minetest.register_node(":stairs:micro_" .. subname .. alternate, def)
	end
  --minetest.register_alias("stairs:micro_" ..subname.. "_bottom", "stairs:micro_" ..subname)

  if recipeitem then
		circular_saw.register_node(recipeitem, subname)
  end
end

-- Register aliases for new pine node names

--minetest.register_alias("stairs:stair_pinewood", "stairs:stair_pine_wood")
--minetest.register_alias("stairs:slab_pinewood", "stairs:slab_pine_wood")



-- Register stairs.
-- Node will be called stairs:stair_<subname>

function stairs.register_stair(subname, recipeitem, groups, images, description, sounds)
	local stair_images = {}
	for i, image in ipairs(images) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then -- override using any other value
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end

	-- Do not modify function argument.
	groups = table.copy(groups)
	groups.stair = 1
	groups.stairs_stair = 1
	groups.not_in_craft_guide = 1
	groups.stairs_node = 1

	local ndef = minetest.registered_items[recipeitem]
	assert(ndef)

	local stair_def = {
		description = description .. " Stair",
		drawtype = "mesh",
		mesh = "stairs_stair.obj",
		tiles = stair_images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		sounds = sounds,
		move_speed_stair = recipeitem,
		_stairs_parent_material = recipeitem,
		light_source = math.ceil(ndef.light_source*0.75),
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:get_pos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y - 1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	}

	stairs.setup_nodedef_callbacks(subname, stair_def)

	minetest.register_node(":stairs:stair_" .. subname, stair_def)

	if recipeitem then
    assert(type(recipeitem) == "string")
		circular_saw.register_node(recipeitem, subname)

		-- Recipe matches appearence in inventory
		minetest.register_craft({
			output = 'stairs:stair_' .. subname .. ' 8',
			recipe = {
				{"", "", recipeitem},
				{"", recipeitem, recipeitem},
				{recipeitem, recipeitem, recipeitem},
			},
		})
	end
end


-- Slab facedir to placement 6d matching table
local slab_trans_dir = {[0] = 8, 0, 2, 1, 3, 4}
-- Slab facedir when placing initial slab against other surface
local slab_trans_dir_place = {[0] = 0, 20, 12, 16, 4, 8}

-- Register slabs.
-- Node will be called stairs:slab_<subname>

function stairs.register_slab(subname, recipeitem, groups, images, description, sounds)
	-- Do not modify function argument.
	groups = table.copy(groups)
	groups.slab = 1
	groups.stairs_slab = 1
	groups.not_in_craft_guide = 1
	groups.stairs_node = 1

	local ndef = minetest.registered_items[recipeitem]
	assert(ndef)

	local slab_def = {
		description = description .. " Horizontal Half Slab",
		drawtype = "nodebox",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		sounds = sounds,
		movement_speed_depends = recipeitem,
		_stairs_parent_material = recipeitem,
		light_source = math.ceil(ndef.light_source*0.5),
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
		on_place = function(itemstack, placer, pointed_thing)
			local under = minetest.get_node(pointed_thing.under)
			local wield_item = itemstack:get_name()

			if under and wield_item == under.name then
				-- place slab using under node orientation
				local dir = minetest.dir_to_facedir(vector.subtract(
					pointed_thing.above, pointed_thing.under), true)

				local p2 = under.param2

				-- combine two slabs if possible
				if slab_trans_dir[math_floor(p2 / 4)] == dir then
					if not recipeitem then
						return itemstack
					end
					local player_name = placer:get_player_name()
					if minetest.is_protected(pointed_thing.under, player_name) and not
							minetest.check_player_privs(placer, "protection_bypass") then
						minetest.record_protection_violation(pointed_thing.under,
							player_name)
						return
					end
					minetest.add_node(pointed_thing.under, {name = recipeitem, param2 = p2})
					itemstack:take_item()
					return itemstack
				end

				-- Placing a slab on an upside down slab should make it right-side up.
				if p2 >= 20 and dir == 8 then
					p2 = p2 - 20
				-- same for the opposite case: slab below normal slab
				elseif p2 <= 3 and dir == 4 then
					p2 = p2 + 20
				end

				-- else attempt to place node with proper param2
				minetest.item_place_node(ItemStack(wield_item), placer, pointed_thing, p2)

				itemstack:take_item()
				return itemstack
			else
				-- place slab using look direction of player
				local dir = minetest.dir_to_wallmounted(vector.subtract(
					pointed_thing.above, pointed_thing.under), true)

				local rot = slab_trans_dir_place[dir]
				if rot == 0 or rot == 20 then
					rot = rot + minetest.dir_to_facedir(placer:get_look_dir())
				end

				return minetest.item_place(itemstack, placer, pointed_thing, rot)
			end
		end,
	}

	stairs.setup_nodedef_callbacks(subname, slab_def)

	minetest.register_node(":stairs:slab_" .. subname, slab_def)

	if recipeitem then
		minetest.register_craft({
			output = 'stairs:slab_' .. subname .. ' 6',
			recipe = {
				{recipeitem, recipeitem, recipeitem},
			},
		})

		minetest.register_craft({
			output = recipeitem,
			recipe = {
				{'stairs:slab_' .. subname},
				{'stairs:slab_' .. subname},
			},
		})
	end
end



-- Stair/slab registration function.
-- Now includes all extra blocks.

function stairs.register_stair_and_slab(subname, recipeitem, groups, images, desc, sounds, datatable)
	datatable = datatable or {}

	if datatable.stair_and_slab_only then
		stairs.register_stair(subname, recipeitem, groups, images, desc, sounds, datatable)
		stairs.register_slab(subname, recipeitem, groups, images, desc, sounds, datatable)
		return
	end

  stairs.register_micro       (subname, recipeitem, groups, images, desc, sounds, datatable)
  stairs.register_panel       (subname, recipeitem, groups, images, desc, sounds, datatable)
  stairs.register_stair       (subname, recipeitem, groups, images, desc, sounds, datatable)
  stairs.register_extra_stairs(subname, recipeitem, groups, images, desc, sounds, datatable)
  stairs.register_slab        (subname, recipeitem, groups, images, desc, sounds, datatable)
  stairs.register_extra_slabs (subname, recipeitem, groups, images, desc, sounds, datatable)

  if not datatable.no_slopes then
		stairs.register_slopes(subname, recipeitem, groups, images, desc, sounds, datatable)
	end

  if datatable.include_new_slopes then
		stairs.register_new_slopes(subname, recipeitem, groups, images, desc, sounds, datatable)
	end
end



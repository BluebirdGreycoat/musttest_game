--[[
More Blocks: slope definitions

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
--]]

local S = function(str) return str end

local box_slope = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5, 0.5, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0.5,     0, 0.5},
		{-0.5,     0,     0, 0.5,  0.25, 0.5},
		{-0.5,  0.25,  0.25, 0.5,   0.5, 0.5}
	}
}

local box_slope_half = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5,   -0.5,  0.5, -0.375, 0.5},
		{-0.5, -0.375, -0.25, 0.5, -0.25,  0.5},
		{-0.5, -0.25,  0,    0.5, -0.125, 0.5},
		{-0.5, -0.125, 0.25, 0.5,  0,     0.5},
	}
}

local box_slope_half_raised = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5,   -0.5,  0.5, 0.125, 0.5},
		{-0.5, 0.125, -0.25, 0.5, 0.25,  0.5},
		{-0.5, 0.25,  0,    0.5, 0.375, 0.5},
		{-0.5, 0.375, 0.25, 0.5,  0.5,     0.5},
	}
}

local box_slope_lh = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5, 0, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0,     0, 0.5},
		{-0.5,     0,     0, 0,  0.25, 0.5},
		{-0.5,  0.25,  0.25, 0,   0.5, 0.5}
	}
}

local box_slope_half_lh = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5,   -0.5,  0, -0.375, 0.5},
		{-0.5, -0.375, -0.25, 0, -0.25,  0.5},
		{-0.5, -0.25,  0,     0, -0.125, 0.5},
		{-0.5, -0.125, 0.25,  0,  0,     0.5},
	}
}

local box_slope_half_raised_lh = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5,   -0.5,  0, 0.125, 0.5},
		{-0.5, 0.125, -0.25,  0, 0.25,  0.5},
		{-0.5, 0.25,  0,      0, 0.375, 0.5},
		{-0.5, 0.375, 0.25,   0,  0.5,     0.5},
	}
}

local box_slope_rh = {
	type = "fixed",
	fixed = {
		{0,  -0.5,  -0.5, 0.5, -0.25, 0.5},
		{0, -0.25, -0.25, 0.5,     0, 0.5},
		{0,     0,     0, 0.5,  0.25, 0.5},
		{0,  0.25,  0.25, 0.5,   0.5, 0.5}
	}
}

local box_slope_half_rh = {
	type = "fixed",
	fixed = {
		{0, -0.5,   -0.5,  0.5, -0.375, 0.5},
		{0, -0.375, -0.25, 0.5, -0.25,  0.5},
		{0, -0.25,  0,     0.5, -0.125, 0.5},
		{0, -0.125, 0.25,  0.5,  0,     0.5},
	}
}

local box_slope_half_raised_rh = {
	type = "fixed",
	fixed = {
		{0, -0.5,   -0.5,  0.5, 0.125, 0.5},
		{0, 0.125, -0.25,  0.5, 0.25,  0.5},
		{0, 0.25,  0,      0.5, 0.375, 0.5},
		{0, 0.375, 0.25,   0.5,  0.5,     0.5},
	}
}

--==============================================================

local box_slope_inner = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
		{-0.5, -0.5, -0.25, 0.5, 0, 0.5},
		{-0.5, -0.5, -0.5, 0.25, 0, 0.5},
		{-0.5, 0, -0.5, 0, 0.25, 0.5},
		{-0.5, 0, 0, 0.5, 0.25, 0.5},
		{-0.5, 0.25, 0.25, 0.5, 0.5, 0.5},
		{-0.5, 0.25, -0.5, -0.25, 0.5, 0.5},
	}
}

local box_slope_inner_half = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
		{-0.5, -0.375, -0.25, 0.5, -0.25, 0.5},
		{-0.5, -0.375, -0.5, 0.25, -0.25, 0.5},
		{-0.5, -0.25, -0.5, 0, -0.125, 0.5},
		{-0.5, -0.25, 0, 0.5, -0.125, 0.5},
		{-0.5, -0.125, 0.25, 0.5, 0, 0.5},
		{-0.5, -0.125, -0.5, -0.25, 0, 0.5},
	}
}

local box_slope_inner_half_raised = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0.125, 0.5},
		{-0.5, 0.125, -0.25, 0.5, 0.25, 0.5},
		{-0.5, 0.125, -0.5, 0.25, 0.25, 0.5},
		{-0.5, 0.25, -0.5, 0, 0.375, 0.5},
		{-0.5, 0.25, 0, 0.5, 0.375, 0.5},
		{-0.5, 0.375, 0.25, 0.5, 0.5, 0.5},
		{-0.5, 0.375, -0.5, -0.25, 0.5, 0.5},
	}
}

--==============================================================

local box_slope_outer = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5,   0.5, -0.25, 0.5},
		{-0.5, -0.25, -0.25,  0.25,     0, 0.5},
		{-0.5,     0,     0,     0,  0.25, 0.5},
		{-0.5,  0.25,  0.25, -0.25,   0.5, 0.5}
	}
}

local box_slope_outer_half = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5,   0.5, -0.375, 0.5},
		{-0.5, -0.375, -0.25,  0.25, -0.25, 0.5},
		{-0.5,  -0.25,     0,     0, -0.125, 0.5},
		{-0.5,  -0.125,  0.25, -0.25, 0, 0.5}
	}
}

local box_slope_outer_half_raised = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5,   0.5, 0.125, 0.5},
		{-0.5, 0.125, -0.25,  0.25, 0.25, 0.5},
		{-0.5,  0.25,     0,     0, 0.375, 0.5},
		{-0.5,  0.375,  0.25, -0.25, 0.5, 0.5}
	}
}

local xslope_quarter = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, 0.5, 0, 0, 0},
		{-0.25, -0.25, 0, -0.5, -0.5, -0.5},
	}
}
local xslope_three_quarter = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, 0.5, 0.5, 0.5, 0},
		{0.25, 0.25, 0, -0.5, -0.5, -0.5},
	}
}
local xslope_three_quarter_half = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, 0.5, 0.5, 0.5, 0},
	}
}
local xslope_cut = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, 0.5, 0.5, 0.5, 0},
	}
}
local xslope_slope = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, 0.5, 0.5, 0, 0},
	}
}
local xslope_peak = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, -0.25, 0.5, 0.5, 0.25},
	}
}
local xslope_peak_half = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0.5, 0, 0.25},
	}
}
local xslope_slope_lh = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, 0.5, 0, 0, 0},
	}
}
local xslope_slope_rh = {
	type = "fixed",
	fixed = {
		{0, -0.5, 0.5, 0.5, 0, 0},
	}
}
local xslope_peak_lh = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0, 0, 0.5},
		{-0.5, 0, -0.25, 0, 0.5, 0.25},
	}
}
local xslope_peak_half_lh = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0, 0, 0.25},
	}
}

-- Node will be called <modname>:slope_<subname>

local slopes_defs = {
	[""] = {
		mesh = "moreblocks_slope.obj",
		collision_box = box_slope,
		selection_box = box_slope,
		light=1/2,
	},
	["_half"] = {
		mesh = "moreblocks_slope_half.obj",
		collision_box = box_slope_half,
		selection_box = box_slope_half,
		light=1/4,
	},
	["_half_raised"] = {
		mesh = "moreblocks_slope_half_raised.obj",
		collision_box = box_slope_half_raised,
		selection_box = box_slope_half_raised,
		light=3/4,
	},

	--==============================================================

	["_inner"] = {
		mesh = "moreblocks_slope_inner.obj",
		collision_box = box_slope_inner,
		selection_box = box_slope_inner,
		light=3/4,
	},
	["_inner_half"] = {
		mesh = "moreblocks_slope_inner_half.obj",
		collision_box = box_slope_inner_half,
		selection_box = box_slope_inner_half,
		light=2/5,
	},
	["_inner_half_raised"] = {
		mesh = "moreblocks_slope_inner_half_raised.obj",
		collision_box = box_slope_inner_half_raised,
		selection_box = box_slope_inner_half_raised,
		light=4/5,
	},

	--==============================================================

	["_inner_cut"] = {
		mesh = "moreblocks_slope_inner_cut.obj",
		collision_box = box_slope_inner,
		selection_box = box_slope_inner,
		light=4/5,
	},
	["_inner_cut_half"] = {
		mesh = "moreblocks_slope_inner_cut_half.obj",
		collision_box = box_slope_inner_half,
		selection_box = box_slope_inner_half,
		light=2/5,
	},
	["_inner_cut_half_raised"] = {
		mesh = "moreblocks_slope_inner_cut_half_raised.obj",
		collision_box = box_slope_inner_half_raised,
		selection_box = box_slope_inner_half_raised,
		light=4/5,
	},

	--==============================================================

	["_outer"] = {
		mesh = "moreblocks_slope_outer.obj",
		collision_box = box_slope_outer,
		selection_box = box_slope_outer,
		light=2/5,
	},
	["_outer_half"] = {
		mesh = "moreblocks_slope_outer_half.obj",
		collision_box = box_slope_outer_half,
		selection_box = box_slope_outer_half,
		light=1/5,
	},
	["_outer_half_raised"] = {
		mesh = "moreblocks_slope_outer_half_raised.obj",
		collision_box = box_slope_outer_half_raised,
		selection_box = box_slope_outer_half_raised,
		light=4/5,
	},

	--==============================================================

	["_outer_cut"] = {
		mesh = "moreblocks_slope_outer_cut.obj",
		collision_box = box_slope_outer,
		selection_box = box_slope_outer,
		light=1/4,
	},
	["_outer_cut_half"] = {
		mesh = "moreblocks_slope_outer_cut_half.obj",
		collision_box = box_slope_outer_half,
		selection_box = box_slope_outer_half,
		light=1/8,
	},
	["_outer_cut_half_raised"] = {
		mesh = "moreblocks_slope_outer_cut_half_raised.obj",
		collision_box = box_slope_outer_half_raised,
		selection_box = box_slope_outer_half_raised,
		light=3/8,
	},
	["_cut"] = {
		mesh = "moreblocks_slope_cut.obj",
		collision_box = box_slope_outer,
		selection_box = box_slope_outer,
		light=1/2,
	},


	-- Additional custom slopes.
	["_xslope_quarter"] = {
		mesh = "xslopes_quarter.obj",
		collision_box = xslope_quarter,
		selection_box = xslope_quarter,
		light=1/5,
	},
	["_xslope_three_quarter"] = {
		mesh = "xslopes_three_quarter.obj",
		collision_box = xslope_three_quarter,
		selection_box = xslope_three_quarter,
		light=3/5,
	},
	["_xslope_three_quarter_half"] = {
		mesh = "xslopes_three_quarter_half.obj",
		collision_box = xslope_three_quarter_half,
		selection_box = xslope_three_quarter_half,
		light=2/5,
	},
	["_xslope_cut"] = {
		mesh = "xslopes_cut.obj",
		collision_box = xslope_cut,
		selection_box = xslope_cut,
		light=1/2,
	},
	["_xslope_slope"] = {
		mesh = "xslopes_slope.obj",
		collision_box = xslope_slope,
		selection_box = xslope_slope,
		light=1/4,
	},
	["_xslope_peak"] = {
		mesh = "xslopes_peak.obj",
		collision_box = xslope_peak,
		selection_box = xslope_peak,
		light=2/4,
	},
	["_xslope_peak_half"] = {
		mesh = "xslopes_peak_half.obj",
		collision_box = xslope_peak_half,
		selection_box = xslope_peak_half,
		light=1/4,
	},

	["_lh"] = {
		mesh = "moreblocks_slope_lh.obj",
		collision_box = box_slope_lh,
		selection_box = box_slope_lh,
		light=1/4,
	},
	["_half_lh"] = {
		mesh = "moreblocks_slope_half_lh.obj",
		collision_box = box_slope_half_lh,
		selection_box = box_slope_half_lh,
		light=1/8,
	},
	["_half_raised_lh"] = {
		mesh = "moreblocks_slope_half_raised_lh.obj",
		collision_box = box_slope_half_raised_lh,
		selection_box = box_slope_half_raised_lh,
		light=3/8,
	},

	["_xslope_slope_lh"] = {
		mesh = "xslopes_slope_lh.obj",
		collision_box = xslope_slope_lh,
		selection_box = xslope_slope_lh,
		light=1/8,
	},
	["_xslope_peak_lh"] = {
		mesh = "xslopes_peak_lh.obj",
		collision_box = xslope_peak_lh,
		selection_box = xslope_peak_lh,
		light=2/8,
	},
	["_xslope_peak_half_lh"] = {
		mesh = "xslopes_peak_half_lh.obj",
		collision_box = xslope_peak_half_lh,
		selection_box = xslope_peak_half_lh,
		light=1/8,
	},

	["_rh"] = {
		mesh = "moreblocks_slope_rh.obj",
		collision_box = box_slope_rh,
		selection_box = box_slope_rh,
		light=1/4,
	},
	["_half_rh"] = {
		mesh = "moreblocks_slope_half_rh.obj",
		collision_box = box_slope_half_rh,
		selection_box = box_slope_half_rh,
		light=1/8,
	},
	["_half_raised_rh"] = {
		mesh = "moreblocks_slope_half_raised_rh.obj",
		collision_box = box_slope_half_raised_rh,
		selection_box = box_slope_half_raised_rh,
		light=3/8,
	},

	["_xslope_slope_rh"] = {
		mesh = "xslopes_slope_rh.obj",
		collision_box = xslope_slope_rh,
		selection_box = xslope_slope_rh,
		light=1/8,
	},
}

function stairs.register_slopes(subname, recipeitem, groups, images, description, sounds)
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
	local defs = table.copy(slopes_defs)

  -- Do not modify function argument.
  local groups = table.copy(groups)
	groups.stairs_slope = 1
  groups.not_in_craft_guide = 1
	groups.stairs_node = 1

  local ndef = minetest.registered_items[recipeitem]
  assert(ndef)
  
	for alternate, def in pairs(defs) do
		--if not alternate:find("_xslope_") or minetest.settings:get("port") == "30001" then
			def.drawtype = "mesh"
			def.paramtype = "light"
			def.paramtype2 = "facedir"
			def.on_place = function(...) return stairs.rotate_and_place(...) end
			def.groups = groups
			def.sounds = sounds
			def.description = description
			def.tiles = stair_images
			def.light_source = math.ceil(ndef.light_source*(def.light or 0))
			def.light = nil

			stairs.setup_nodedef_callbacks(subname, def)
			
			minetest.register_node(":stairs:slope_" ..subname..alternate, def)
		--end
	end

  if recipeitem then
    circular_saw.known_nodes[recipeitem] = {"stairs", subname}
  end
end

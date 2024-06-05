--[[
More Blocks: slope definitions

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
--]]

local S = function(str) return str end

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

local box_regular = {
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5, 0.5, 0.5, 0.5},
	}
}

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

local box_slope_inner_cut4 = {
	type = "fixed",
	fixed = {
		pixel_box(0, 0, 8, 16, 8, 16),
		pixel_box(0, 0, 8, 8, 8, 0),
		pixel_box(0, 8, 0, 4, 16, 16),
		pixel_box(4, 8, 12, 16, 16, 16),
	}
}

local box_slope_01 = {
	type = "fixed",
	fixed = {
		pixel_box(0, 0, 8, 4, 8, 0),
		pixel_box(8, 0, 16, 16, 8, 12),
		pixel_box(0, 0, 16, 8, 8, 8),
		pixel_box(0, 8, 16, 4, 16, 12),
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
local xslope_quarter2 = {
	type = "fixed",
	fixed = {
		{0.0, -0.5, 0.5, 0.5, 0, 0},
		{0.5, -0.25, 0, 0.25, -0.5, -0.5},
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

local astair_1 = {
	type = "fixed",
	fixed = {
		-- Big angle.
		{-0.5, -0.5, 0.5, 0.5, 0, 0.25},
		{-0.5, -0.5, 0.25, 0.25, 0, 0},
		{-0.5, -0.5, 0, 0, 0, -0.25},
		{-0.5, -0.5, -0.25, -0.25, 0, -0.5},

		-- Corner angle.
		{-0.5, 0, 0.5, 0, 0.5, 0.25},
		{-0.5, 0, 0.25, -0.25, 0.5, 0},
	}
}

local astair_2 = {
	type = "fixed",
	fixed = {
		-- Box.
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

		-- Angle.
		{-0.5, 0, 0.5, 0.5, 0.5, 0.25},
		{-0.5, 0, 0.25, 0.25, 0.5, 0},
		{-0.5, 0, 0, 0, 0.5, -0.25},
		{-0.5, 0, -0.25, -0.25, 0.5, -0.5},
	}
}

local astair_3 = {
	type = "fixed",
	fixed = {
		-- Box.
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

		-- Corner angle.
		{-0.5, 0, 0.5, 0, 0.5, 0.25},
		{-0.5, 0, 0.25, -0.25, 0.5, 0},
	}
}

local astair_4 = {
	type = "fixed",
	fixed = {
		-- Box.
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

		-- Corner angle.
		{-0.5, 0, 0.5, 0, 0.5, 0.25},
		{-0.5, 0, 0.25, -0.25, 0.5, 0},
	}
}

-- Node will be called <modname>:slope_<subname>

local slopes_defs = {
	[""] = {
		description = "45 Slope Full",
		mesh = "moreblocks_slope.obj",
		collision_box = box_slope,
		selection_box = box_slope,
		light=1/2,
	},
	["_half"] = {
		description = "22 Slope Full",
		mesh = "moreblocks_slope_half.obj",
		collision_box = box_slope_half,
		selection_box = box_slope_half,
		light=1/4,
	},
	["_half_raised"] = {
		description = "22 Slope Raised Full",
		mesh = "moreblocks_slope_half_raised.obj",
		collision_box = box_slope_half_raised,
		selection_box = box_slope_half_raised,
		light=3/4,
	},

	--==============================================================

	["_inner"] = {
		description = "45 Inner Corner Slope #1",
		mesh = "moreblocks_slope_inner.obj",
		collision_box = box_slope_inner,
		selection_box = box_slope_inner,
		light=3/4,
	},
	["_inner_half"] = {
		description = "22 Inner Corner Slope",
		mesh = "moreblocks_slope_inner_half.obj",
		collision_box = box_slope_inner_half,
		selection_box = box_slope_inner_half,
		light=2/5,
	},
	["_inner_half_raised"] = {
		description = "22 Inner Corner Raised Slope",
		mesh = "moreblocks_slope_inner_half_raised.obj",
		collision_box = box_slope_inner_half_raised,
		selection_box = box_slope_inner_half_raised,
		light=4/5,
	},

	--==============================================================

	["_inner_cut"] = {
		description = "Beveled Corner Slope #4",
		mesh = "moreblocks_slope_inner_cut.obj",
		collision_box = box_slope_inner,
		selection_box = box_slope_inner,
		light=4/5,
	},
	["_inner_cut2"] = {
		description = "Beveled Corner Slope #5",
		mesh = "moreblocks_slope_inner_cut2.obj",
		collision_box = box_regular,
		selection_box = box_regular,
		light=4/5,
	},
	["_inner_cut3"] = {
		description = "Beveled Corner Slope #1",
		mesh = "moreblocks_slope_inner_cut3.obj",
		collision_box = box_regular,
		selection_box = box_regular,
		light=4/5,
	},
	["_inner_cut4"] = {
		description = "Inner Corner Beveled Slope",
		mesh = "moreblocks_slope_inner_cut4.obj",
		collision_box = box_slope_inner_cut4,
		selection_box = box_slope_inner_cut4,
		light=4/5,
	},
	["_inner_cut5"] = {
		description = "Inner Corner Slope #1",
		mesh = "moreblocks_slope_inner_cut5.obj",
		collision_box = box_slope_inner_cut4,
		selection_box = box_slope_inner_cut4,
		light=4/5,
	},
	["_inner_cut6"] = {
		description = "Inner Corner Slope #2",
		mesh = "moreblocks_slope_inner_cut6.obj",
		collision_box = box_slope_inner,
		selection_box = box_slope_inner,
		light=4/5,
	},
	["_inner_cut7"] = {
		description = "Inner Corner Slope #3",
		mesh = "moreblocks_slope_inner_cut7.obj",
		collision_box = box_regular,
		selection_box = box_regular,
		light=4/5,
	},
	["_inner_cut_half"] = {
		description = "Beveled Corner Slope #3",
		mesh = "moreblocks_slope_inner_cut_half.obj",
		collision_box = box_slope_inner_half,
		selection_box = box_slope_inner_half,
		light=2/5,
	},
	["_inner_cut_half_raised"] = {
		description = "Beveled Corner Slope #2",
		mesh = "moreblocks_slope_inner_cut_half_raised.obj",
		collision_box = box_slope_inner_half_raised,
		selection_box = box_slope_inner_half_raised,
		light=4/5,
	},

	--==============================================================

	["_outer"] = {
		description = "45 Outer Corner Slope",
		mesh = "moreblocks_slope_outer.obj",
		collision_box = box_slope_outer,
		selection_box = box_slope_outer,
		light=2/5,
	},
	["_outer_half"] = {
		description = "22 Outer Corner Slope",
		mesh = "moreblocks_slope_outer_half.obj",
		collision_box = box_slope_outer_half,
		selection_box = box_slope_outer_half,
		light=1/5,
	},
	["_outer_half_raised"] = {
		description = "22 Outer Corner Raised Slope",
		mesh = "moreblocks_slope_outer_half_raised.obj",
		collision_box = box_slope_outer_half_raised,
		selection_box = box_slope_outer_half_raised,
		light=4/5,
	},

	--==============================================================

	["_outer_cut"] = {
		description = "Beveled Corner Slope #7",
		mesh = "moreblocks_slope_outer_cut.obj",
		collision_box = box_slope_01,
		selection_box = box_slope_01,
		light=1/4,
	},
	["_outer_cut_half"] = {
		description = "Beveled Corner Slope #8",
		mesh = "moreblocks_slope_outer_cut_half.obj",
		collision_box = box_slope_outer_half,
		selection_box = box_slope_outer_half,
		light=1/8,
	},
	["_outer_cut_half_raised"] = {
		description = "Beveled Corner Slope #9",
		mesh = "moreblocks_slope_outer_cut_half_raised.obj",
		collision_box = box_slope_outer_half_raised,
		selection_box = box_slope_outer_half_raised,
		light=3/8,
	},
	["_cut"] = {
		description = "Beveled Corner Slope #6",
		mesh = "moreblocks_slope_cut.obj",
		collision_box = box_slope_outer,
		selection_box = box_slope_outer,
		light=1/2,
	},


	-- Additional custom slopes.
	["_xslope_quarter"] = {
		description = "Microspike Left",
		mesh = "xslopes_quarter.obj",
		collision_box = xslope_quarter,
		selection_box = xslope_quarter,
		light=1/5,
	},
	["_xslope_quarter2"] = {
		description = "Microspike Right",
		mesh = "xslopes_quarter2.obj",
		collision_box = xslope_quarter2,
		selection_box = xslope_quarter2,
		light=1/5,
	},
	["_xslope_three_quarter"] = {
		description = "Corner Trapezoid Full",
		mesh = "xslopes_three_quarter.obj",
		collision_box = xslope_three_quarter,
		selection_box = xslope_three_quarter,
		light=3/5,
	},
	["_xslope_three_quarter_half"] = {
		description = "Corner Trapezoid Half",
		mesh = "xslopes_three_quarter_half.obj",
		collision_box = xslope_three_quarter_half,
		selection_box = xslope_three_quarter_half,
		light=2/5,
	},
	["_xslope_cut"] = {
		description = "Edge Trapezoid Half",
		mesh = "xslopes_cut.obj",
		collision_box = xslope_cut,
		selection_box = xslope_cut,
		light=1/2,
	},
	["_xslope_slope"] = {
		description = "45 Doubled Microblock",
		mesh = "xslopes_slope.obj",
		collision_box = xslope_slope,
		selection_box = xslope_slope,
		light=1/4,
	},
	["_xslope_peak"] = {
		description = "Tall Peak Full-Width",
		mesh = "xslopes_peak.obj",
		collision_box = xslope_peak,
		selection_box = xslope_peak,
		light=2/4,
	},
	["_xslope_peak_half"] = {
		description = "Short Peak Full-Width",
		mesh = "xslopes_peak_half.obj",
		collision_box = xslope_peak_half,
		selection_box = xslope_peak_half,
		light=1/4,
	},

	["_lh"] = {
		description = "45 Slope Left",
		mesh = "moreblocks_slope_lh.obj",
		collision_box = box_slope_lh,
		selection_box = box_slope_lh,
		light=1/4,
	},
	["_half_lh"] = {
		description = "22 Slope Left",
		mesh = "moreblocks_slope_half_lh.obj",
		collision_box = box_slope_half_lh,
		selection_box = box_slope_half_lh,
		light=1/8,
	},
	["_half_raised_lh"] = {
		description = "22 Slope Raised Left",
		mesh = "moreblocks_slope_half_raised_lh.obj",
		collision_box = box_slope_half_raised_lh,
		selection_box = box_slope_half_raised_lh,
		light=3/8,
	},

	["_xslope_slope_lh"] = {
		description = "45 Microblock Slope Left",
		mesh = "xslopes_slope_lh.obj",
		collision_box = xslope_slope_lh,
		selection_box = xslope_slope_lh,
		light=1/8,
	},
	["_xslope_peak_lh"] = {
		description = "Tall Peak Half-Width",
		mesh = "xslopes_peak_lh.obj",
		collision_box = xslope_peak_lh,
		selection_box = xslope_peak_lh,
		light=2/8,
	},
	["_xslope_peak_half_lh"] = {
		description = "Short Peak Half-Width",
		mesh = "xslopes_peak_half_lh.obj",
		collision_box = xslope_peak_half_lh,
		selection_box = xslope_peak_half_lh,
		light=1/8,
	},

	["_rh"] = {
		description = "45 Slope Right",
		mesh = "moreblocks_slope_rh.obj",
		collision_box = box_slope_rh,
		selection_box = box_slope_rh,
		light=1/4,
	},
	["_half_rh"] = {
		description = "22 Slope Right",
		mesh = "moreblocks_slope_half_rh.obj",
		collision_box = box_slope_half_rh,
		selection_box = box_slope_half_rh,
		light=1/8,
	},
	["_half_raised_rh"] = {
		description = "22 Slope Raised Right",
		mesh = "moreblocks_slope_half_raised_rh.obj",
		collision_box = box_slope_half_raised_rh,
		selection_box = box_slope_half_raised_rh,
		light=3/8,
	},

	["_xslope_slope_rh"] = {
		description = "45 Microblock Slope Right",
		mesh = "xslopes_slope_rh.obj",
		collision_box = xslope_slope_rh,
		selection_box = xslope_slope_rh,
		light=1/8,
	},

	["_astair_1"] = {
		description = "Beveled Corner-Stair #1",
		mesh = "astair_1.obj",
		collision_box = astair_1,
		selection_box = astair_1,
		light=1/3,
	},

	["_astair_2"] = {
		description = "Beveled Corner-Stair #2",
		mesh = "astair_2.obj",
		collision_box = astair_2,
		selection_box = astair_2,
		light=1/3,
	},

	["_astair_3"] = {
		description = "Beveled Corner-Stair #3",
		mesh = "astair_3.obj",
		collision_box = astair_3,
		selection_box = astair_3,
		light=1/3,
	},

	["_astair_4"] = {
		description = "Beveled Corner-Stair #4",
		mesh = "astair_4.obj",
		collision_box = astair_4,
		selection_box = astair_4,
		light=1/3,
	},
	["_astair_5"] = {
		description = "Beveled Corner-Stair #5",
		mesh = "moreblocks_slope_inner_cut8.obj",
		collision_box = box_regular,
		selection_box = box_regular,
		light=4/5,
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
			def.description = description .. " " .. (def.description or "Slope")
			def.tiles = stair_images
			def.light_source = math.ceil(ndef.light_source*(def.light or 0))
			def.light = nil
			def._stairs_parent_material = recipeitem

			stairs.setup_nodedef_callbacks(subname, def)
			
			minetest.register_node(":stairs:slope_" ..subname..alternate, def)
		--end
	end

  if recipeitem then
		circular_saw.register_node(recipeitem, subname)
  end
end



local newslope_box01 = {
	type = "fixed",
	fixed = {
		pixel_box(0, 0, 16, 16, 8, 8),
		pixel_box(0, 0, 8, 8, 8, 0),
	},
}

local newslope_box02 = {
	type = "fixed",
	fixed = {
		pixel_box(0, 0, 16, 8, 8, 8),
	},
}

-- Note: names must NOT conflict with 'slopes_defs'!
-- This table shall only contain shapes suitable for use with default, basic materials:
-- stone, stone brick, desert stone and brick, sandstone and brick, and MAYBE a few others.
-- Strive hard to keep the node count down, and DO NOT register these shapes for every
-- possible material just because you *think* you can get away with it! This game is
-- already very close to the maximum allowed number of content IDs.
local new_slopes_defs = {
	["_01"] = {
		description = "45 Inner Corner Slope #2",
		mesh = "musttest_newslopes_01.obj",
		collision_box = newslope_box01,
		selection_box = newslope_box01,
		light=1/4,
	},
	["_02"] = {
		description = "Half Microspike",
		mesh = "musttest_newslopes_02.obj",
		collision_box = newslope_box02,
		selection_box = newslope_box02,
		light=1/8,
	},
}

function stairs.register_new_slopes(subname, recipeitem, groups, images, description, sounds, datatable)
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

	local defs = table.copy(new_slopes_defs)

	if datatable.blacklist then
		for k, v in pairs(datatable.blacklist) do
			defs[k] = nil
		end
	end

	if datatable.whitelist then
		local newdefs = {}
		for k, v in pairs(defs) do
			if datatable.whitelist[k] then
				newdefs[k] = v
			end
		end
		defs = newdefs
	end

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
			def.description = description .. " " .. (def.description or "Slope")
			def.tiles = stair_images
			def.light_source = math.ceil(ndef.light_source*(def.light or 0))
			def.light = nil
			def._stairs_parent_material = recipeitem

			stairs.setup_nodedef_callbacks(subname, def)

			minetest.register_node(":newslopes:" ..subname..alternate, def)
		--end
	end

  if recipeitem then
		circular_saw.register_node(recipeitem, subname)
  end
end

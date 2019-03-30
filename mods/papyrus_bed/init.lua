
local top_tiles = {
	"papyrus_bed_top_above.png",
	"papyrus_bed_top_below.png",
	"papyrus_bed_top_side_right.png",
	"papyrus_bed_top_side_left.png",
	"papyrus_bed_top_top.png",
	"papyrus_bed_brackets.png",
}

local bottom_tiles = {
	"papyrus_bed_bottom_above.png",
	"papyrus_bed_bottom_below.png",
	"papyrus_bed_bottom_side_right.png",
	"papyrus_bed_bottom_side_left.png",
	"papyrus_bed_brackets.png",
	"papyrus_bed_bottom_bottom.png",
}

local nodebox = {
	bottom = {
		-- bedspread
		{-0.5, 0.3125, -0.5, 0.5, 0.4375, 0.5},
		-- frame and mattress
		{-0.5, -0.3125, -0.5, 0.5, 0.3125, 0.5},
		-- brackets
		{-0.5, -0.5, -0.5, -0.3125, -0.3125, -0.3125},
		{0.3125, -0.5, -0.5, 0.5, -0.3125, -0.3125},
	},
	top = {
		-- headboard
		{-0.5, 0.3125, 0.4375, 0.5, 0.5, 0.5},
		-- pillow
		{-0.34375, 0.3125, 0.0, 0.34375, 0.375, 0.375},
		-- bedspread
		{-0.5, 0.3125, -0.5, 0.5, 0.4375, 0.0},
		-- frame and mattress
		{-0.5, -0.3125, -0.5, 0.5, 0.3125, 0.5},
		-- brackets
		{-0.5, -0.5, 0.3125, -0.3125, -0.3125, 0.5},
		{0.3125, -0.5, 0.3125, 0.5, -0.3125, 0.5},
	}
}

local selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 1.5}

beds.register_bed("papyrus_bed:bed", {
	description = "Bed (Papyrus)\n\nSleep once to set or refresh your home position.\nHold 'E' when placing to make public.",
	inventory_image = "papyrus_bed_wieldimage.png",
	wield_image = "papyrus_bed_wieldimage.png",
	tiles = {
		bottom = bottom_tiles,
		top = top_tiles,
	},
	nodebox = nodebox,
	selectionbox = selectionbox,
	recipe = {
		{"default:paper", "default:papyrus", "default:papyrus"},
		{"default:wood", "default:wood", "default:wood"},
		{"group:stick", "", "group:stick"},
	},
})

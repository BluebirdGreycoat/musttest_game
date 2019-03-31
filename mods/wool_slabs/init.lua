
--[[
	{"white",      "White",      "basecolor_white"},
	{"grey",       "Grey",       "basecolor_grey"},
	{"black",      "Black",      "basecolor_black"},
	{"red",        "Red",        "basecolor_red"},
	{"yellow",     "Yellow",     "basecolor_yellow"},
	{"green",      "Green",      "basecolor_green"},
	{"cyan",       "Cyan",       "basecolor_cyan"},
	{"blue",       "Blue",       "basecolor_blue"},
	{"magenta",    "Magenta",    "basecolor_magenta"},
	{"orange",     "Orange",     "excolor_orange"},
	{"violet",     "Violet",     "excolor_violet"},
	{"brown",      "Brown",      "unicolor_dark_orange"},
	{"pink",       "Pink",       "unicolor_light_red"},
	{"dark_grey",  "Dark Grey",  "unicolor_darkgrey"},
	{"dark_green", "Dark Green", "unicolor_dark_green"},
--]]

local dyes =
{
	"white",
	"grey",
	"black",
	"red",
	"yellow",
	"green",
	"cyan",
	"blue",
	"magenta",
	"orange",
	"violet",
	"brown",
	"pink",
	"dark_grey",
	"dark_green",
}

for i = 1, #dyes, 1 do
	local n = dyes[i]
	
	stairs.register_stair_and_slab(
		"wool"..n,
		"wool:"..n,
		{snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, flammable = 3},
		{"wool_"..n..".png"},
		"Wool",
		default.node_sound_defaults()
	)
end


-- Must match the list in the "dye" mod.
local dyes = {
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
		"wool" .. n,
		"wool:" .. n,
		{snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, flammable = 3},
		{"wool_" .. n .. ".png"},
		"Wool",
		default.node_sound_defaults()
	)
end

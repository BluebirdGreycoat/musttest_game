
-- Saravinca Realm Begin & End.

local REALM_BEGIN = 21150
local REALM_END = 23450

-- Decorations for Saravinca.

minetest.register_decoration({
	deco_type = "schematic",
	place_on = {"rackstone:cobble"},
	sidelen = 8,
	fill_ratio = 0.001,
	y_min = REALM_BEGIN,
	y_max = REALM_END,
	schematic = "schems/sara_tea.mts",
	flags = "all_floors,force_placement,place_center_x,place_center_z",
	rotation = "random",
})


-- Saravinca Realm Begin & End.

local REALM_BEGIN = 21150
local REALM_END = 23450
local REALM_MID = 22800

-- Wild Saravinca Tea Bushes.

minetest.register_decoration({
	deco_type = "schematic",
	place_on = {"rackstone:cobble"},
	sidelen = 8,
	fill_ratio = 0.0001,
	y_min = REALM_MID,
	y_max = REALM_END,
	schematic = "schems/sara_tea.mts",
	flags = "all_floors,force_placement,place_center_x,place_center_z",
	rotation = "random",
})

-- Wild Saravinca Wheat.

minetest.register_decoration({
	deco_type = "schematic",
	place_on = {"rackstone:cobble"},
	sidelen = 8,
	fill_ratio = 0.0001,
	y_min = REALM_MID,
	y_max = REALM_END,
	schematic = "schems/sara_wheat8.mts",
	flags = "all_floors,force_placement,place_center_x,place_center_z",
	rotation = "random",
})

minetest.register_decoration({
	deco_type = "schematic",
	place_on = {"rackstone:cobble"},
	sidelen = 8,
	fill_ratio = 0.0001,
	y_min = REALM_MID,
	y_max = REALM_END,
	schematic = "schems/sara_wheat7.mts",
	flags = "all_floors,force_placement,place_center_x,place_center_z",
	rotation = "random",
})

-- Wild Saravinca Cotton.

minetest.register_decoration({
	deco_type = "schematic",
	place_on = {"rackstone:cobble"},
	sidelen = 8,
	fill_ratio = 0.0001,
	y_min = REALM_MID,
	y_max = REALM_END,
	schematic = "schems/sara_cotton.mts",
	flags = "all_floors,force_placement,place_center_x,place_center_z",
	rotation = "random",
})

-- Mese crystal spikes to light up the *very* dark caverns?



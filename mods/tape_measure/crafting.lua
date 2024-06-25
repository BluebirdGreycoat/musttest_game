
local extra_mat = "default:steel_ingot"
local shell_mat = "rubber:rubber_fiber"
local case_mat = "plastic:plastic_sheeting"
local dye_mat = "dye:yellow"

minetest.register_craft({
	output = "tape_measure:tape_measure",
	recipe = {
		{shell_mat, dye_mat, ""},
		{shell_mat, case_mat, extra_mat},
		{"", "", ""},
	}
})


minetest.register_craft({
	output = "sumpf:junglestonebrick",
	recipe = {
		{"sumpf:junglestone", "sumpf:junglestone"},
		{"sumpf:junglestone", "sumpf:junglestone"},
	}
})

minetest.register_craft({
	output = "sumpf:junglestone 4",
	recipe = {
		{"sumpf:junglestonebrick"},
	}
})

minetest.register_craft({
	output = "sumpf:roofing",
	recipe = {
		{"sumpf:gras", "default:junglegrass", "sumpf:gras"},
		{"default:junglegrass", "sumpf:gras", "default:junglegrass"},
		{"sumpf:gras", "default:junglegrass", "sumpf:gras"},
	}
})

minetest.register_craft({
	type = "cooking",
	output = "sumpf:junglestone",
	recipe = "sumpf:cobble",
})


doors.register_fencegate("doors:gate_wood", {
	description = "Wooden Fence Gate",
	texture = "default_wood.png",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_acacia_wood", {
	description = "Acacia Wood Fence Gate",
	texture = "default_acacia_wood.png",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_junglewood", {
	description = "Jungle Wood Fence Gate",
	texture = "default_junglewood.png",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_pine_wood", {
	description = "Pine Wood Fence Gate",
	texture = "default_pine_wood.png",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_aspen_wood", {
	description = "Aspen Wood Fence Gate",
	texture = "default_aspen_wood.png",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_iron", {
	description = "Wrought Iron Fence Gate",
	texture = "default_fence_iron.png",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal"),
})

doors.register_fencegate("doors:gate_bronze", {
	description = "Bronze Fence Gate",
	texture = "default_fence_bronze.png",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal"),
})

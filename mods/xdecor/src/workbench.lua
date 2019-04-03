
xdecor.register("workbench", {
	description = "Woodworking Bench (Decorative)",
	groups = utility.dig_groups("furniture"),
	sounds = default.node_sound_wood_defaults(),
	tiles = {"xdecor_workbench_top.png",   "xdecor_workbench_top.png",
		 "xdecor_workbench_sides.png", "xdecor_workbench_sides.png",
		 "xdecor_workbench_front.png", "xdecor_workbench_front.png"},
	on_rotate = screwdriver.rotate_simple,
	nostairs = true,
})

-- Craft items

minetest.register_tool("xdecor:hammer", {
	description = "Woodworking Hammer",
	groups = {not_repaired_by_anvil = 1},
	sound = {breaks = "default_tool_breaks"},
	inventory_image = "xdecor_hammer.png",
	wield_image = "xdecor_hammer.png",
	tool_capabilities = tooldata["hammer_hammer"],
})

-- Recipes

minetest.register_craft({
	output = "xdecor:hammer",
	recipe = {
		{"default:steel_ingot", "group:stick", "default:steel_ingot"},
		{"", "group:stick", ""},
		{"", "group:stick", ""}
	}
})

minetest.register_craft({
	output = "xdecor:workbench",
	recipe = {
		{"basictrees:tree_wood", "basictrees:tree_wood"},
		{"basictrees:tree_wood", "basictrees:tree_wood"},
		{"", "xdecor:hammer"}
	}
})

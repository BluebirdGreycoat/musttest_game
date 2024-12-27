
-- Nodes

xdecor.register("workbench", {
	description = "Workbench",
	groups = utility.dig_groups("furniture"),
	sounds = default.node_sound_wood_defaults(),
	tiles = {
		"xdecor_workbench_top.png",
		"xdecor_workbench_top.png",
		"xdecor_workbench_sides.png",
		"xdecor_workbench_sides.png",
		"xdecor_workbench_front.png",
		"xdecor_workbench_front.png",
	},
	on_rotate = screwdriver.rotate_simple,
	nostairs = true,

	-- Behave like tool, not a building node.
	stack_max = 1,

	after_place_node = function(...)
		return workbench.after_place_node(...)
	end,

	on_rightclick = function(...)
		return workbench.on_rightclick(...)
	end,

	can_dig = function(...)
		return workbench.can_dig(...)
	end,

	on_blast = function(...)
		return workbench.on_blast(...)
	end,

	allow_metadata_inventory_move = function(...)
		return workbench.allow_metadata_inventory_move(...)
	end,

	allow_metadata_inventory_put = function(...)
		return workbench.allow_metadata_inventory_put(...)
	end,

	allow_metadata_inventory_take = function(...)
		return workbench.allow_metadata_inventory_take(...)
	end,

	on_metadata_inventory_move = function(...)
		return workbench.on_metadata_inventory_move(...)
	end,

	on_metadata_inventory_put = function(...)
		return workbench.on_metadata_inventory_put(...)
	end,

	on_metadata_inventory_take = function(...)
		return workbench.on_metadata_inventory_take(...)
	end,
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

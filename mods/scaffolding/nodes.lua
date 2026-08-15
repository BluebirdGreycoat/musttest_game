
minetest.register_node("scaffolding:scaffolding", {
	description = "Wooden Scaffolding",
	drawtype = "nodebox",
	tiles = {"scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding.png",
	"scaffolding_wooden_scaffolding.png", "scaffolding_wooden_scaffolding.png", "scaffolding_wooden_scaffolding.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = true,
	walkable = false,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_wood_defaults(),

	_scaffolding_alternate_name = "scaffolding:reinforced_scaffolding",
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	_falling_remove = function(pos)
		scaffolding.on_falling_trigger(pos)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
	_no_collapse_on_walkover = true,
	after_dig_node = function(pos, node, metadata, digger)
		default.dig_up(pos, node, digger)
	end,
})

minetest.register_node("scaffolding:reinforced_scaffolding", {
	description = "Wooden Scaffolding",
	drawtype = "nodebox",
	tiles = {"scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png", "scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png",
	"scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png"},
	drop = "scaffolding:scaffolding",
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = false,
	walkable = true,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_wood_defaults(),
	_no_collapse_on_walkover = true,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	_scaffolding_alternate_name = "scaffolding:scaffolding",
	_scaffolding_is_reinforced = true,
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
})

minetest.register_node("scaffolding:platform", {
	description = "Wooden Platform",
	drawtype = "nodebox",
	tiles = {"scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding.png^scaffolding_platform.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = false,
	walkable = true,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_wood_defaults(),
	_no_collapse_on_walkover = true,

	_scaffolding_alternate_name = "scaffolding:reinforced_platform",
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},

	after_dig_node = function(pos, node, metadata, digger)
		scaffolding.dig_horx(pos, node, digger)
		scaffolding.dig_horx2(pos, node, digger)
		scaffolding.dig_horz(pos, node, digger)
		scaffolding.dig_horz2(pos, node, digger)
	end,
})

minetest.register_node("scaffolding:reinforced_platform", {
	description = "Wooden Platform",
	drawtype = "nodebox",
	tiles = {"scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png", "scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png", "scaffolding_wooden_scaffolding.png^scaffolding_platform.png"},
	drop = "scaffolding:platform",
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = false,
	walkable = true,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_wood_defaults(),
	_no_collapse_on_walkover = true,

	_scaffolding_alternate_name = "scaffolding:platform",
	_scaffolding_is_reinforced = true,
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},
})

minetest.register_node("scaffolding:iron_scaffolding", {
	description = "Iron Scaffolding",
	drawtype = "nodebox",
	tiles = {"scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding.png",
	"scaffolding_iron_scaffolding.png", "scaffolding_iron_scaffolding.png", "scaffolding_iron_scaffolding.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = true,
	walkable = false,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_stone_defaults(),
	_no_collapse_on_walkover = true,
	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},

	_falling_remove = function(pos)
		scaffolding.on_falling_trigger(pos)
	end,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	_scaffolding_alternate_name = "scaffolding:reinforced_iron_scaffolding",
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	after_dig_node = function(pos, node, metadata, digger)
		default.dig_up(pos, node, digger)
	end,
})

minetest.register_node("scaffolding:reinforced_iron_scaffolding", {
	description = "Iron Scaffolding",
	drawtype = "nodebox",
	tiles = {"scaffolding_iron_scaffolding.png^scaffolding_reinforced.png", "scaffolding_iron_scaffolding.png^scaffolding_reinforced.png",
	"scaffolding_iron_scaffolding.png^scaffolding_reinforced.png"},
	drop = "scaffolding:iron_scaffolding",
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = false,
	walkable = true,
	_no_collapse_on_walkover = true,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_stone_defaults(),

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	_scaffolding_alternate_name = "scaffolding:iron_scaffolding",
	_scaffolding_is_reinforced = true,
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
	},
})

minetest.register_node("scaffolding:iron_platform", {
	description = "Iron Platform",
	drawtype = "nodebox",
	tiles = {"scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding.png^scaffolding_platform.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = false,
	walkable = true,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_stone_defaults(),
	_no_collapse_on_walkover = true,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	_scaffolding_alternate_name = "scaffolding:reinforced_iron_platform",
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},

	after_dig_node = function(pos, node, metadata, digger)
		scaffolding.dig_horx(pos, node, digger)
		scaffolding.dig_horx2(pos, node, digger)
		scaffolding.dig_horz(pos, node, digger)
		scaffolding.dig_horz2(pos, node, digger)
	end,
})

minetest.register_node("scaffolding:reinforced_iron_platform", {
	description = "Iron Platform",
	drawtype = "nodebox",
	tiles = {"scaffolding_iron_scaffolding.png^scaffolding_reinforced.png", "scaffolding_iron_scaffolding.png^scaffolding_reinforced.png", "scaffolding_iron_scaffolding.png^scaffolding_platform.png"},
	drop = "scaffolding:iron_platform",
	paramtype = "light",
	paramtype2 = "facedir",
	climbable = false,
	walkable = true,
	groups = utility.dig_groups("scaffolding", {scaffolding=1}),
	sounds = default.node_sound_stone_defaults(),
	_no_collapse_on_walkover = true,

	on_place = function(...)
		return scaffolding.on_place(...)
	end,

	_scaffolding_alternate_name = "scaffolding:iron_platform",
	_scaffolding_is_reinforced = true,
	on_punch = function(...)
		return scaffolding.on_punch(...)
	end,

	node_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},
	selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
			},
	},
})

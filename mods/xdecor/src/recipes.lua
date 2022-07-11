minetest.register_craft({
	output = "xdecor:baricade",
	recipe = {
		{"group:stick", "", "group:stick"},
		{"", "default:steel_ingot", ""},
		{"group:stick", "", "group:stick"}
	}
})

minetest.register_craft({
	output = "xdecor:barrel",
	recipe = {
		{"group:wood_light", "group:wood_light", "group:wood_light"},
		{"default:iron_lump", "", "default:iron_lump"},
		{"group:wood_light", "group:wood_light", "group:wood_light"}
	}
})

minetest.register_craft({
	output = "xdecor:candle",
	recipe = {
		{"torches:torch_floor"},
		{"default:paper"},
	},
})

minetest.register_craft({
	output = "xdecor:cabinet",
	recipe = {
		{"group:wood_light", "group:wood_light", "group:wood_light"},
		{"doors:trapdoor", "", "doors:trapdoor"},
		{"group:wood_light", "group:wood_light", "group:wood_light"}
	}
})

minetest.register_craft({
	output = "xdecor:cabinet_half 2",
	recipe = {
		{"xdecor:cabinet"}
	}
})

minetest.register_craft({
	output = "xdecor:cactusbrick",
	recipe = {
		{"default:brick", "default:cactus"}
	}
})

minetest.register_craft({
	output = "xdecor:chair",
	recipe = {
		{"group:stick", "", ""},
		{"group:stick", "group:stick", "group:stick"},
		{"group:stick", "", "group:stick"}
	}
})

minetest.register_craft({
	output = "xdecor:coalstone_tile 4",
	recipe = {
		{"default:coalblock", "default:stone"},
		{"default:stone", "default:coalblock"}
	}
})

minetest.register_craft({
	output = "xdecor:cobweb",
	recipe = {
		{"farming:cotton", "", "farming:cotton"},
		{"", "farming:cotton", ""},
		{"farming:cotton", "", "farming:cotton"}
	}
})

minetest.register_craft({
	output = "xdecor:cushion 3",
	recipe = {
		{"farming:cloth", "farming:cloth", "farming:cloth"},
		{"farming:cloth", "wool:red", "farming:cloth"},
		{"farming:cloth", "farming:cloth", "farming:cloth"},
	}
})

minetest.register_craft({
	output = "xdecor:cushion_block",
	recipe = {
		{"xdecor:cushion"},
		{"xdecor:cushion"}
	}
})

minetest.register_craft({
	output = "xdecor:desertstone_tile",
	recipe = {
		{"default:desert_cobble2", "default:desert_cobble2"},
		{"default:desert_cobble2", "default:desert_cobble2"}
	}
})

minetest.register_craft({
	output = "xdecor:empty_shelf",
	recipe = {
		{"group:wood_light", "group:wood_light", "group:wood_light"},
		{"", "", ""},
		{"group:wood_light", "group:wood_light", "group:wood_light"}
	}
})

-- Note: recipe must take more material than it takes to build an obsidian
-- gate. Otherwise it will be possible to "farm" obsidian gates for their gold
-- and their additional obsidian. This exploit was reported by a player.
minetest.register_craft({
	output = "xdecor:xchest",
	recipe = {
		{"default:obsidian", "default:obsidian", "default:obsidian"},
		{"griefer:grieferstone", "default:chest", "griefer:grieferstone"},
		{"default:obsidian", "default:obsidian", "default:obsidian"},
	}
})

minetest.register_craft({
	output = "xdecor:hard_clay",
	recipe = {
		{"default:clay", "default:clay"},
		{"default:clay", "default:clay"}
	}
})

minetest.register_craft({
	output = "xdecor:iron_lightbox",
	recipe = {
		{"xpanes:bar_flat", "default:glass", "xpanes:bar_flat"},
		{"xpanes:bar_flat", "xdecor:lantern", "xpanes:bar_flat"},
		{"xpanes:bar_flat", "default:glass", "xpanes:bar_flat"}
	}
})

minetest.register_craft({
	output = "xdecor:ivy 4",
	recipe = {
		{"group:leaves"},
		{"group:leaves"}
	}
})

minetest.register_craft({
	output = "xdecor:lantern",
	recipe = {
		{"default:iron_lump"},
		{"torches:torch_floor"},
		{"default:iron_lump"}
	}
})

minetest.register_craft({
	output = "xdecor:lantern",
	recipe = {
		{"default:iron_lump"},
		{"torches:kalite_torch_floor"},
		{"default:iron_lump"}
	}
})

minetest.register_craft({
	output = "xdecor:moonbrick",
	recipe = {
		{"default:brick", "default:stone"}
	}
})

minetest.register_craft({
	output = "xdecor:multishelf",
	recipe = {
		{"group:wood_light", "group:wood_light", "group:wood_light"},
		{"group:vessel", "group:book", "group:vessel"},
		{"group:wood_light", "group:wood_light", "group:wood_light"}
	}
})

minetest.register_craft({
	output = "xdecor:multishelf2",
	recipe = {
		{"group:wood_light", "group:wood_light", "group:wood_light"},
		{"default:paper", "group:book", "group:book"},
		{"group:wood_light", "group:wood_light", "group:wood_light"}
	}
})

minetest.register_craft({
	output = "xdecor:multishelf3",
	recipe = {
		{"group:wood_light", "group:wood_light", "group:wood_light"},
		{"default:paper", "group:book", "group:vessel"},
		{"group:wood_light", "group:wood_light", "group:wood_light"}
	}
})

minetest.register_craft({
	output = "xdecor:packed_ice",
	recipe = {
		{"default:ice", "default:ice", ""},
		{"default:ice", "default:ice", "default:ice"},
		{"default:ice", "default:ice", "default:ice"},
	}
})

minetest.register_craft({
	output = "xdecor:painting_1",
	recipe = {
		{"default:sign_wall_wood", "dye:blue"}
	}
})

minetest.register_craft({
	output = "xdecor:stone_tile 4",
	recipe = {
		{"default:cobble", "default:cobble"},
		{"default:cobble", "default:stone"},
	}
})

minetest.register_craft({
	output = "xdecor:stone_rune 4",
	recipe = {
		{"moreblocks:stone_tile", "moreblocks:stone_tile", "moreblocks:stone_tile"},
		{"moreblocks:stone_tile", "", "moreblocks:stone_tile"},
		{"moreblocks:stone_tile", "moreblocks:stone_tile", "moreblocks:stone_tile"}
	}
})

minetest.register_craft({
	output = "xdecor:stonepath 16",
	recipe = {
		{"stairs:slab_cobble", "", "stairs:slab_cobble"},
		{"", "stairs:slab_cobble", ""},
		{"stairs:slab_cobble", "", "stairs:slab_cobble"}
	}
})

minetest.register_craft({
	output = "xdecor:table",
	recipe = {
		{"stairs:slab_wood", "stairs:slab_wood", "stairs:slab_wood"},
		{"", "group:stick", ""},
		{"", "group:stick", ""}
	}
})

minetest.register_craft({
	output = "xdecor:tatami",
	recipe = {
		{"farming:wheat", "farming:wheat", "farming:wheat"}
	}
})

minetest.register_craft({
	output = "xdecor:trampoline",
	recipe = {
		{"farming:cloth", "farming:string", "farming:cloth"},
		{"default:steel_ingot", "farming:cloth", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "xdecor:tv",
	recipe = {
		{"default:steel_ingot", "plastic:plastic_sheeting", "default:steel_ingot"},
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
		{"transformer:lv", "techcrafts:copper_coil", "techcrafts:control_logic_unit"}
	}
})

minetest.register_craft({
	output = "xdecor:woodframed_glass",
	recipe = {
		{"group:stick", "group:stick", "group:stick"},
		{"group:stick", "default:glass", "group:stick"},
		{"group:stick", "group:stick", "group:stick"}
	}
})

minetest.register_craft({
	output = "xdecor:wood_tile 2",
	recipe = {
		{"", "group:wood_light", ""},
		{"group:wood_light", "", "group:wood_light"},
		{"", "group:wood_light", ""}
	}
})

minetest.register_craft({
	output = "xdecor:wooden_lightbox",
	recipe = {
		{"group:stick", "default:glass", "group:stick"},
		{"basictrees:tree_wood", "xdecor:lantern", "basictrees:tree_wood"},
		{"group:stick", "default:glass", "group:stick"}
	}
})


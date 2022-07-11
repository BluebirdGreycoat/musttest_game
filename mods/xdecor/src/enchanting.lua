
xdecor.register("booktable", {
	description = "Fancy Book Table (Obsidian, Decorative)",
	tiles = {"xdecor_enchantment_top.png",  "xdecor_enchantment_bottom.png",
		 "xdecor_enchantment_side.png", "xdecor_enchantment_side.png",
		 "xdecor_enchantment_side.png", "xdecor_enchantment_side.png"},
	groups = utility.dig_groups("furniture"),
	sounds = default.node_sound_stone_defaults(),
	on_rotate = screwdriver.rotate_simple,
	nostairs = true,
})

-- Recipes

minetest.register_craft({
	output = "xdecor:booktable",
	recipe = {
		{"wool:red", "farming:cloth", "xdecor:curtain_yellow"},
		{"default:diamond", "default:obsidian", "default:diamond"},
	}
})

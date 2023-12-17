
xdecor.register("booktable", {
	description = "Book Table",
	tiles = {"xdecor_enchantment_top.png",  "xdecor_enchantment_bottom.png",
		 "xdecor_enchantment_side.png", "xdecor_enchantment_side.png",
		 "xdecor_enchantment_side.png", "xdecor_enchantment_side.png"},
	groups = utility.dig_groups("furniture"),
	sounds = default.node_sound_stone_defaults(),
	on_rotate = screwdriver.rotate_simple,
	nostairs = true,

	on_timer = function(...)
		return books.book_table_on_timer(...)
	end,
})

-- Recipes

minetest.register_craft({
	output = "xdecor:booktable",
	recipe = {
		{"wool:red", "farming:cloth", "xdecor:curtain_yellow"},
		{"default:diamond", "default:obsidian", "default:diamond"},
	}
})

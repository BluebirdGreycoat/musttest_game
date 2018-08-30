
-- Cost-in-mese calculation for these recipes is carefully considered!

minetest.register_craft({
	output = "protector:protect",
	recipe = {
		{"default:stone", "default:mese_crystal", "default:stone"},
		{"default:stone", "default:mese", "default:stone"},
		{"default:mese_crystal", "default:stone", "default:mese_crystal"},
	}
})

minetest.register_craft({
	output = "default:mese_crystal 12",
	type = "shapeless",
	recipe = {"protector:protect"}
})

minetest.register_craft({
	output = "protector:protect2",
	recipe = {
		{"moreores:tin_ingot", "default:mese_crystal", "moreores:tin_ingot"},
		{"moreores:tin_ingot", "default:mese", "moreores:tin_ingot"},
		{"default:mese_crystal", "moreores:tin_ingot", "default:mese_crystal"},
	}
})

minetest.register_craft({
    output = "default:mese_crystal 12",
    type = "shapeless",
    recipe = {"protector:protect2"}
})

minetest.register_craft({
	output = "protector:protect3",
	recipe = {
		{"default:stone", "default:mese_crystal", "default:stone"},
		{"default:stone", "default:mese_crystal", "default:stone"},
		{"default:mese_crystal", "default:stone", "default:mese_crystal"},
	}
})

minetest.register_craft({
	output = "default:mese_crystal 4",
	type = "shapeless",
	recipe = {"protector:protect3"}
})

minetest.register_craft({
	output = "protector:protect4",
	recipe = {
		{"moreores:tin_ingot", "default:mese_crystal", "moreores:tin_ingot"},
		{"moreores:tin_ingot", "default:mese_crystal", "moreores:tin_ingot"},
		{"default:mese_crystal", "moreores:tin_ingot", "default:mese_crystal"},
	}
})

minetest.register_craft({
	output = "default:mese_crystal 4",
	type = "shapeless",
	recipe = {"protector:protect4"}
})

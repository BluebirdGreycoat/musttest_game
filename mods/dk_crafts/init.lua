

-- Cooking recipes.
minetest.register_craft({
	type = "cooking",
	output = "darkage:gneiss",
	recipe = "darkage:schist",
})

minetest.register_craft({
	type = "cooking",
	output = "default:glass",
	recipe = "darkage:wood_frame",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:rhyolitic_tuff",
	recipe = "darkage:rhyolitic_tuff_rubble",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:tuff",
	recipe = "darkage:tuff_rubble",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:old_tuff_bricks",
	recipe = "darkage:tuff_bricks",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:tuff",
	recipe = "darkage:old_tuff_bricks",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:gneiss",
	recipe = "darkage:gneiss_rubble",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:slate",
	recipe = "darkage:slate_rubble",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:ors",
	recipe = "darkage:ors_rubble",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:slate",
	recipe = "darkage:slate_rubble",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:schist",
	recipe = "darkage:slate",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:shale",
	recipe = "darkage:mud",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:slate",
	recipe = "darkage:shale",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:ors_brick",
	recipe = "default:desert_stone",
})

minetest.register_craft({
	type = "cooking",
	output = "darkage:basaltic",
	recipe = "darkage:basaltic_rubble",
})

-- Craft recipes.
minetest.register_craft({
	output = "darkage:straw_bale 9",
	recipe = {
		{"farming:straw", "farming:straw", "farming:straw"},
		{"farming:straw", "farming:straw", "farming:straw"},
		{"farming:straw", "farming:straw", "farming:straw"},
	}
})

minetest.register_craft({
	output = "darkage:ors 3",
	recipe = {
		{"default:sandstone", "default:sandstone"},
		{"default:iron_lump", "default:sandstone"},
	}
})
minetest.register_craft({
	output = "darkage:ors_brick 4",
	recipe = {
		{"darkage:ors", "darkage:ors"},
		{"darkage:ors", "darkage:ors"},
	}
})

minetest.register_craft({
	output = "darkage:ors_block 9",
	recipe = {
		{"darkage:ors", "darkage:ors", "darkage:ors"},
		{"darkage:ors", "darkage:ors", "darkage:ors"},
		{"darkage:ors", "darkage:ors", "darkage:ors"},
	}
})

minetest.register_craft({
	output = "darkage:stone_brick 2",
	recipe = {
		{"default:stonebrick", "default:stonebrick"},
	}
})

minetest.register_craft({
	output = "darkage:silt 2",
	recipe = {
		{"default:clay_lump",	"default:sand"},
		{"default:sand",			"default:clay_lump"},
	}
})

minetest.register_craft({
	output = "darkage:silt",
	recipe = {
		{"darkage:silt_lump", "darkage:silt_lump"},
		{"darkage:silt_lump", "darkage:silt_lump"},
	}
})

minetest.register_craft({
	output = "darkage:marble_tile 4",
	recipe = {
		{"darkage:marble", "darkage:marble"},
		{"darkage:marble", "darkage:marble"},
	}
})

minetest.register_craft({
	output = "darkage:gneiss_brick 4",
	recipe = {
		{"darkage:gneiss", "darkage:gneiss"},
		{"darkage:gneiss", "darkage:gneiss"},
	}
})

minetest.register_craft({
	output = "darkage:gneiss_block 9",
	recipe = {
		{"darkage:gneiss", "darkage:gneiss", "darkage:gneiss"},
		{"darkage:gneiss", "darkage:gneiss", "darkage:gneiss"},
		{"darkage:gneiss", "darkage:gneiss", "darkage:gneiss"},
	}
})

minetest.register_craft({
	output = "darkage:chalked_bricks_with_plaster 2",
	recipe = {
		{"darkage:chalked_bricks", "darkage:chalk_powder"},
		{"darkage:chalk_powder", "darkage:chalked_bricks"},
	}
})

minetest.register_craft({
	output = "darkage:cobble_with_plaster 2",
	recipe = {
		{"default:cobble", "darkage:chalk_powder"},
		{"darkage:chalk_powder", "default:cobble"},
	}
})

minetest.register_craft({
	type = "compressing",
	output = "darkage:chalk",
	recipe = "darkage:chalk_powder 4",
	time = 4,
})

minetest.register_craft({
	output = "darkage:chalked_bricks 4",
	recipe = {
		{"default:stone", 				"default:stone",				"darkage:chalk_powder"},
		{"darkage:chalk_powder",	"darkage:chalk_powder", "darkage:chalk_powder"},
		{"default:stone",					"darkage:chalk_powder", "default:stone"},
	}
})

minetest.register_craft({
	output = "darkage:adobe 2",
	recipe = {
		{"default:sand",			"default:sand"},
		{"default:clay_lump",	"farming:straw"},
	}
})

minetest.register_craft({
	output = "darkage:darkdirt 4",
	recipe = {
		{"default:dirt",	"default:gravel"},
		{"default:gravel",	"default:dirt"},
	}
})

minetest.register_craft({
	output = "darkage:mud 2",
	recipe = {
		{"default:dirt",			"default:dirt"},
		{"default:clay_lump",	"darkage:silt_lump"},
	}
})

minetest.register_craft({
	output = "darkage:mud",
	recipe = {
		{"darkage:mud_lump", "darkage:mud_lump"},
		{"darkage:mud_lump", "darkage:mud_lump"},
	}
})

minetest.register_craft({
	output = "darkage:iron_stick 6",
	recipe = {
		{"default:steel_ingot", "", ""},
		{"", "default:steel_ingot", ""},
		{"", "", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "darkage:slate_brick 4",
	recipe = {
		{"darkage:slate", "darkage:slate"},
		{"darkage:slate", "darkage:slate"},
	}
})

minetest.register_craft({
	output = "darkage:slate_block 9",
	recipe = {
		{"darkage:slate", "darkage:slate", "darkage:slate"},
		{"darkage:slate", "darkage:slate", "darkage:slate"},
		{"darkage:slate", "darkage:slate", "darkage:slate"},
	}
})

minetest.register_craft({
	output = "darkage:slate_tile 4",
	recipe = {
		{"darkage:slate_brick", "darkage:slate_brick"},
		{"darkage:slate_brick", "darkage:slate_brick"},
	}
})

minetest.register_craft({
	output = "darkage:tuff 4",
	recipe = {
		{"darkage:gneiss", "default:stone"},
		{"default:stone", "darkage:gneiss"},
	}
})

minetest.register_craft({
	output = "darkage:tuff_bricks 4",
	recipe = {
		{"darkage:tuff", "darkage:tuff"},
		{"darkage:tuff", "darkage:tuff"},
	}
})

minetest.register_craft({
	output = "darkage:rhyolitic_tuff 4",
	recipe = {
		{"darkage:gneiss", "default:desert_stone"},
		{"default:desert_stone", "darkage:gneiss"},
	}
})

minetest.register_craft({
	output = "darkage:rhyolitic_tuff_bricks 4",
	recipe = {
		{"darkage:rhyolitic_tuff", "darkage:rhyolitic_tuff"},
		{"darkage:rhyolitic_tuff", "darkage:rhyolitic_tuff"},
	}
})

minetest.register_craft({
	output = "darkage:basaltic_rubble 4",
	recipe = {
		{"default:cobble",		"default:coal_lump"},
		{"default:coal_lump",	"default:cobble"},
	}
})

minetest.register_craft({
	output = "darkage:basaltic_brick 4",
	recipe = {
		{"darkage:basaltic", "darkage:basaltic"},
		{"darkage:basaltic", "darkage:basaltic"},
	}
})

minetest.register_craft({
	output = "darkage:basaltic_block 9",
	recipe = {
		{"darkage:basaltic", "darkage:basaltic", "darkage:basaltic"},
		{"darkage:basaltic", "darkage:basaltic", "darkage:basaltic"},
		{"darkage:basaltic", "darkage:basaltic", "darkage:basaltic"},
	}
})

minetest.register_craft({
	output = "darkage:glass 5",
	recipe = {
		{"default:glass", "default:steel_ingot", "default:glass"},
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
		{"default:glass", "default:steel_ingot", "default:glass"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:milk_glass",
	recipe = {"darkage:glass", "dye:white"},
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:glass",
	recipe = {"darkage:milk_glass"},
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:glass",
	recipe = {"darkage:glow_glass"},
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:glow_glass 1",
	recipe = {"darkage:glass", "xdecor:lantern"},
})

minetest.register_craft({
	output = "darkage:glass_round 5",
	recipe = {
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
		{"default:glass", "default:glass", "default:glass"},
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:milk_glass_round",
	recipe = {"darkage:glass_round", "dye:white"},
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:glass_round",
	recipe = {"darkage:milk_glass_round"},
})

minetest.register_craft({
	output = "darkage:glass_square 4",
	recipe = {
		{"default:glass", "default:steel_ingot", "default:glass"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:glass", "default:steel_ingot", "default:glass"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:milk_glass_square",
	recipe = {"darkage:glass_square", "dye:white"},
})

minetest.register_craft({
	type = "shapeless",
	output = "darkage:glass_square",
	recipe = {"darkage:milk_glass_square"},
})

minetest.register_craft({
	output = "darkage:wood_frame",
	recipe = {
		{"group:stick", "group:stick", "group:stick"},
		{"", "default:glass", ""},
		{"group:stick", "group:stick", "group:stick"},
	}
})

minetest.register_craft({
	output = "darkage:lamp",
	recipe = {
		{"group:stick", "default:paper", "group:stick"},
		{"default:paper", "xdecor:lantern", "default:paper"},
		{"group:stick", "default:paper", "group:stick"},
	}
})

minetest.register_craft({
	output = "darkage:box",
	recipe = {
		{"default:wood", "group:stick", "default:wood"},
		{"group:stick", "", "group:stick"},
		{"default:wood", "group:stick", "default:wood"},
	}
})

minetest.register_craft({
	output = "darkage:wood_shelves 2",
	recipe = {
		{"darkage:box"},
		{"darkage:box"},
	}
})


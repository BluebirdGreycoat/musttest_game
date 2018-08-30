-- Minetest 0.4 mod: bone_collector
-- Bones can be crafted to clay, sand or coal to motivate players clear the playground.
-- 
-- See README.txt for licensing and other information.

minetest.register_craft({
	output = 'default:clay_lump 8',
	type = 'shapeless',
	recipe = {"group:bones", "bucket:bucket_water"},
	replacements = {{"bucket:bucket_water", "bucket:bucket_empty"}},
})
minetest.register_craft({
	output = 'default:clay_lump',
	type = 'shapeless',
	recipe = {"group:bones"},
})
minetest.register_craft({
	output = 'default:gravel',
	recipe = {
		{"group:bones", "group:bones", "group:bones"},
	},
})
minetest.register_craft({
	output = 'default:sand',
	recipe = {
		{"group:bones", "", "group:bones"},
		{"", "default:cobble", ""},
		{"group:bones", "", "group:bones"},
	},
})
minetest.register_craft({
	output = 'default:coal_lump',
	recipe = {
		{"", "group:bones", ""},
		{"group:bones", "default:clay_lump", "group:bones"},
		{"", "group:bones", ""},
	},
})
minetest.register_craft({
	output = 'default:dirt',
	recipe = {
		{"group:bones", "group:bones", "group:bones"},
		{"group:bones", "group:bones", "group:bones"},
		{"group:bones", "group:bones", "group:bones"},
	},
})

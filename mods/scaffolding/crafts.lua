
----------------------
-- wood scaffolding --
----------------------

minetest.register_craft({
	output = 'scaffolding:scaffolding 12',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'group:stick', '', 'group:stick'},
		{'group:wood', 'group:wood', 'group:wood'},
	}
})

minetest.register_craft({
	output = 'scaffolding:scaffolding 4',
	recipe = {
		{'group:wood'},
		{'group:stick'},
		{'group:wood'},
	}
})

-- back to scaffolding --

minetest.register_craft({
	output = 'scaffolding:scaffolding',
	recipe = {
		{'scaffolding:platform'},
		{'scaffolding:platform'},
	}
})

-- wood platforms --

minetest.register_craft({
	output = 'scaffolding:platform 2',
	recipe = {
		{'scaffolding:scaffolding'},
	}
})

minetest.register_craft({
	output = 'scaffolding:platform 6',
	recipe = {
		{'scaffolding:scaffolding', 'scaffolding:scaffolding', 'scaffolding:scaffolding'},
	}
})

----------------------
-- iron scaffolding --
----------------------

minetest.register_craft({
	output = 'scaffolding:iron_scaffolding 12',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'group:stick', '', 'group:stick'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'scaffolding:iron_scaffolding 4',
	recipe = {
		{'default:steel_ingot'},
		{'group:stick'},
		{'default:steel_ingot'},
	}
})
-- back to scaffolding --

minetest.register_craft({
	output = 'scaffolding:iron_scaffolding',
	recipe = {
		{'scaffolding:iron_platform'},
		{'scaffolding:iron_platform'},
	}
})

-- iron platforms --

minetest.register_craft({
	output = 'scaffolding:iron_platform 2',
	recipe = {
		{'scaffolding:iron_scaffolding'},
	}
})

minetest.register_craft({
	output = 'scaffolding:iron_platform 6',
	recipe = {
		{'scaffolding:iron_scaffolding', 'scaffolding:iron_scaffolding', 'scaffolding:iron_scaffolding'},
	}
})


------------
-- wrench --
------------

minetest.register_craft({
	output = 'scaffolding:scaffolding_wrench',
	recipe = {
		{'', 'default:steel_ingot', ''},
		{'', 'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', '', ''},
	}
})

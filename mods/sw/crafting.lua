
minetest.register_craft({
    type = "cooking",
	cooktime = 10,
	output = "sw:teststone1",
	recipe = "sw:teststone2",
})

minetest.register_craft({
	output = "sw:teststone1brick 4",
	recipe = {
		{"sw:teststone1",   "sw:teststone1",         "",},
		{"sw:teststone1",   "sw:teststone1",         "",},
		{"",                "",                      "",},
   },
})

minetest.register_craft({
	output = "sw:teststone1block 9",
	recipe = {
		{"sw:teststone1",   "sw:teststone1",        "sw:teststone1", },
		{"sw:teststone1",   "sw:teststone1",        "sw:teststone1", },
		{"sw:teststone1",   "sw:teststone1",        "sw:teststone1", },
   },
})


local path = minetest.get_modpath("barter_table")
dofile(path .. "/barter.lua")


minetest.register_craft({
	output = 'barter_table:barter',
	recipe = {
		{'default:sign_wall_wood'},
		{'chests:chest_public_closed'},
	}
})

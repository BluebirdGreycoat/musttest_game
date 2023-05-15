
minetest.register_craftitem("currency:minegeld", {
	description = "Minegeld Banknote",
	inventory_image = "minegeld.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_2", {
	description = "Two Minegeld Banknote",
	inventory_image = "minegeld_2.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_5", {
	description = "Five Minegeld Banknote",
	inventory_image = "minegeld_5.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_10", {
	description = "Ten Minegeld Banknote",
	inventory_image = "minegeld_10.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_20", {
	description = "Twenty Minegeld Banknote",
	inventory_image = "minegeld_20.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_50", {
	description = "Fifty Minegeld Banknote",
	inventory_image = "minegeld_50.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_100", {
	description = "Hundred Minegeld Banknote",
	inventory_image = "minegeld_100.png",
	stack_max = currency.stackmax,
	groups = {minegeld = 1, flammable = 3},
})

minetest.register_craftitem("currency:minegeld_bundle", {
	description = "Bundle of Random Minegeld Notes",
	inventory_image = "minegeld_bundle.png",
	groups = {flammable = 3},
})

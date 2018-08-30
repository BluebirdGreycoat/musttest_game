
minetest.register_craftitem("fine_wire:copper", {
  description = "Fine Copper Wire",
  inventory_image = "technic_fine_copper_wire.png",
})

minetest.register_craftitem("fine_wire:gold", {
  description = "Fine Gold Wire",
  inventory_image = "technic_fine_gold_wire.png",
})

minetest.register_craftitem("fine_wire:silver", {
  description = "Fine Silver Wire",
  inventory_image = "technic_fine_silver_wire.png",
})

minetest.register_craft({
  output = 'fine_wire:copper 3',
  recipe = {
    {'', 'default:copper_ingot', ''},
    {'', 'default:copper_ingot', ''},
    {'', 'default:copper_ingot', ''},
  }
})

minetest.register_craft({
	type = "cooking",
	output = "default:copper_ingot",
	recipe = "fine_wire:copper",
})

minetest.register_craft({
  output = 'fine_wire:gold 3',
  recipe = {
    {'', 'default:gold_ingot', ''},
    {'', 'default:gold_ingot', ''},
    {'', 'default:gold_ingot', ''},
  }
})

minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "fine_wire:gold",
})

minetest.register_craft({
  output = 'fine_wire:silver 3',
  recipe = {
    {'', 'moreores:silver_ingot', ''},
    {'', 'moreores:silver_ingot', ''},
    {'', 'moreores:silver_ingot', ''},
  }
})

minetest.register_craft({
	type = "cooking",
	output = "moreores:silver_ingot",
	recipe = "fine_wire:silver",
})

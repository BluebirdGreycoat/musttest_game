
minetest.register_craftitem("charcoal:charcoal", {
  description = "Charcoal Lump",
  inventory_image = "charcoal_charcoal.png",

	-- punching unlit torch with coal powder relights
	on_use = function(...)
		return real_torch.relight(...)
	end,
})

minetest.register_craft({
  type = "fuel",
  recipe = "charcoal:charcoal",
  burntime = 4,
})

minetest.register_craft({
  type = "coalfuel",
  recipe = "charcoal:charcoal",
  burntime = 4,
})

minetest.register_craft({
  output = 'torches:torch_floor 4',
  recipe = {
    {'charcoal:charcoal'},
    {'group:stick'},
  }
})

minetest.register_craft({
  type = "cooking",
  output = "charcoal:charcoal 6",
  recipe = "group:tree",
})

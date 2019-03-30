
--[[
	Original textures from DocFarming mod
	https://forum.minetest.net/viewtopic.php?id=3948
]]

minetest.register_craftitem(":farming:potato_salad", {
	description = "Cucumber And Potato Salad",
	inventory_image = "farming_potato_salad.png",
	on_use = minetest.item_eat(10, "xdecor:bowl"),
})

minetest.register_craft({
	output = "farming:potato_salad",
	recipe = {
		{"cucumber:cucumber"},
		{"potatoes:baked_potato"},
		{"xdecor:bowl"},
	}
})

minetest.register_node("cucumber:seed", {
  description = "Cucumber Seed",
  tiles = {"farming_cucumber_seed.png"},
  wield_image = "farming_cucumber_seed.png",
  inventory_image = "farming_cucumber_seed.png",
  drawtype = "signlike",
  paramtype = "light",
  paramtype2 = "wallmounted",
  walkable = false,
  sunlight_propagates = true,
	selection_box = farming.select,
  groups = {level = 1, seed = 1, snappy = 3, attached_node = 1, flammable = 2, notify_destruct = 1},
  on_place = function(itemstack, placer, pointed_thing)
    return farming.place_seed(itemstack, placer, pointed_thing, "cucumber:seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = default.LIGHT_MAX,
  next_plant = "cucumber:cucumber_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})

-- cucumber
minetest.register_craftitem("cucumber:cucumber", {
	description = "Cucumber",
	inventory_image = "farming_cucumber.png",
	groups = {food_cucumber = 1, flammable = 2},
	on_use = minetest.item_eat(4),
	flowerpot_insert = {"cucumber:cucumber_1", "cucumber:cucumber_2", "cucumber:cucumber_3", "cucumber:cucumber_4"},
})

-- cucumber definition
local crop_def = {
	drawtype = "plantlike",
	tiles = {"farming_cucumber_1.png"},
	paramtype = "light",
  sunlight_propagates = true,
  waving = 1,
	walkable = false,
	buildable_to = true,
	drop = "",
	selection_box = farming.select,
	groups = {
		snappy = 3, flammable = 2, plant = 1, attached_node = 1,
		not_in_creative_inventory = 1,
	},
	sounds = default.node_sound_leaves_defaults(),
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = default.LIGHT_MAX,
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	flowerpot_drop = "cucumber:cucumber",
}

-- stage 1
crop_def.next_plant = "cucumber:cucumber_2"
minetest.register_node("cucumber:cucumber_1", table.copy(crop_def))

-- stage 2
crop_def.next_plant = "cucumber:cucumber_3"
crop_def.tiles = {"farming_cucumber_2.png"}
minetest.register_node("cucumber:cucumber_2", table.copy(crop_def))

-- stage 3
crop_def.next_plant = "cucumber:cucumber_4"
crop_def.tiles = {"farming_cucumber_3.png"}
minetest.register_node("cucumber:cucumber_3", table.copy(crop_def))

-- stage 4 (final)
crop_def.tiles = {"farming_cucumber_4.png"}
crop_def.drop = {
	items = {
		{items = {'cucumber:seed 1'}, rarity = 1},
		{items = {'cucumber:seed 1'}, rarity = 3},
		{items = {'cucumber:cucumber'}, rarity = 1},
		{items = {'cucumber:cucumber'}, rarity = 3},
	}
}
crop_def.next_plant = nil
minetest.register_node("cucumber:cucumber_4", table.copy(crop_def))

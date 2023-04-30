
--[[
	Original textures from DocFarming mod
	https://forum.minetest.net/viewtopic.php?id=3948
]]

local S = function(s)
	return s
end

minetest.register_node("potatoes:seed", {
  description = "Potato Eyes",
  tiles = {"farming_potato_seed.png"},
  wield_image = "farming_potato_seed.png",
  inventory_image = "farming_potato_seed.png",
  drawtype = "signlike",
  paramtype = "light",
  paramtype2 = "wallmounted",
  walkable = false,
  sunlight_propagates = true,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5}
  },
  groups = utility.dig_groups("seeds", {seed = 1, seed_oil = 1, attached_node = 1, flammable = 2, notify_destruct = 1}),
  on_place = function(itemstack, placer, pointed_thing)
    return farming.place_seed(itemstack, placer, pointed_thing, "potatoes:seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  _farming_next_plant = "potatoes:potato_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



-- potato
minetest.register_craftitem("potatoes:potato", {
	description = S("Potato"),
	inventory_image = "farming_potato.png",
	on_use = minetest.item_eat(1),
	groups = {foodrot=1},
	flowerpot_insert = {"potatoes:potato_1", "potatoes:potato_2", "potatoes:potato_3", "potatoes:potato_4"},
})

-- baked potato
minetest.register_craftitem("potatoes:baked_potato", {
	description = S("Baked Potato"),
	inventory_image = "farming_baked_potato.png",
	on_use = minetest.item_eat(4),
	groups = {foodrot=1},
})

minetest.register_craft({
	type = "cooking",
	cooktime = 7,
	output = "potatoes:baked_potato",
	recipe = "potatoes:potato"
})

-- potato definition
local crop_def = {
	drawtype = "plantlike",
	tiles = {"farming_potato_1.png"},
	paramtype = "light",
	sunlight_propagates = true,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = "",
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5}
	},
	groups = utility.dig_groups("crop", {
		flammable = 2, plant = 1, attached_node = 1,
		not_in_creative_inventory = 1, growing = 1, notify_destruct = 1,
	}),
	sounds = default.node_sound_leaves_defaults(),
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = default.LIGHT_MAX,
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	flowerpot_drop = "potatoes:potato",
}

-- stage 1
crop_def._farming_next_plant = "potatoes:potato_2"
minetest.register_node("potatoes:potato_1", table.copy(crop_def))

-- stage 2
crop_def._farming_next_plant = "potatoes:potato_3"
crop_def.tiles = {"farming_potato_2.png"}
minetest.register_node("potatoes:potato_2", table.copy(crop_def))

-- stage 3
crop_def._farming_next_plant = "potatoes:potato_4"
crop_def.tiles = {"farming_potato_3.png"}
crop_def.drop = {
	items = {
		{items = {'potatoes:potato'}, rarity = 1},
		{items = {'potatoes:potato'}, rarity = 3},
	}
}
minetest.register_node("potatoes:potato_3", table.copy(crop_def))

-- stage 4
crop_def._farming_next_plant = nil
crop_def.tiles = {"farming_potato_4.png"}
crop_def.groups.growing = 0
crop_def.drop = {
	items = {
		{items = {'potatoes:potato'}, rarity = 1},
		{items = {'potatoes:potato 3'}, rarity = 3},
		{items = {'potatoes:seed'}, rarity = 1},
		{items = {'potatoes:seed'}, rarity = 2},
	}
}
minetest.register_node("potatoes:potato_4", table.copy(crop_def))

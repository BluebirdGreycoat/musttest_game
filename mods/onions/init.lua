


local S = function(s)
	return s
end

minetest.register_node("onions:seed", {
  description = "Allium Seeds",
  tiles = {"allium_seeds.png"},
  wield_image = "allium_seeds.png",
  inventory_image = "allium_seeds.png",
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
    return farming.place_seed(itemstack, placer, pointed_thing, "onions:seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  _farming_next_plant = "onions:allium_sprouts_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



-- onion 
minetest.register_craftitem("onions:onion", {
	description = S("Wild Onion"),
	inventory_image = "wild_onion.png",
	on_use = minetest.item_eat(2),
	groups = {foodrot=1},
	flowerpot_insert = {
		"onions:allium_sprouts_1", "onions:allium_sprouts_2", "onions:allium_sprouts_3", "onions:allium_sprouts_4",},
	_xp_zerocost_drop = true,
	_xdecor_soup_ingredient = true,
})

-- sauteed onions
minetest.register_craftitem("onions:sauteed_onions", {
	description = S("Sauteed Onions"),
	inventory_image = "sauteed_onions.png",
	on_use = minetest.item_eat(4),
	groups = {foodrot=1},
	_xp_zerocost_drop = true,
	_xdecor_soup_ingredient = true,
})

minetest.register_craft({
	type = "cooking",
	cooktime = 10,
	output = "onions:sauteed_onions",
	recipe = "onions:onion"
})

-- onion_potato salad recipe
local eat_function = minetest.item_eat(10, "xdecor:bowl")
minetest.register_craftitem("onions:onion_potato_salad", {
	description = "Potato And Wild Onion Salad\n\nBoosts current and max HP beyond normal for a short time.",
	inventory_image = "onion_potato_salad.png",
  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
		hunger.apply_health_boost(user:get_player_name(), "onions", {health=30*500, time=30})
    return eat_function(itemstack, user, pointed_thing)
  end,
	_xp_zerocost_drop = true,
})

minetest.register_craft({
	output = "onions:onion_potato_salad",
	recipe = {
		{"onions:onion"},
		{"potatoes:baked_potato"},
		{"xdecor:bowl"},
	}
})

-- onion definition
local crop_def = {
	drawtype = "plantlike",
	tiles = {"allium_sprouts1.png"},
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
	flowerpot_drop = "onions:onion",
}

-- stage 1
crop_def._farming_next_plant = "onions:allium_sprouts_2"
crop_def._farming_prev_seed = "onions:seed"
minetest.register_node("onions:allium_sprouts_1", table.copy(crop_def))

-- stage 2
crop_def._farming_next_plant = "onions:allium_sprouts_3"
crop_def._farming_prev_plant = "onions:allium_sprouts_1"
crop_def.tiles = {"allium_sprouts2.png"}
minetest.register_node("onions:allium_sprouts_2", table.copy(crop_def))

-- stage 3
crop_def._farming_next_plant = "onions:allium_sprouts_4"
crop_def._farming_prev_plant = "onions:allium_sprouts_2"
crop_def.tiles = {"allium_sprouts3.png"}
crop_def.drop = {
	items = {
		{items = {'onions:onion'}, rarity = 1},
		{items = {'onions:onion'}, rarity = 3},
	}
}
minetest.register_node("onions:allium_sprouts_3", table.copy(crop_def))

-- stage 4
crop_def._farming_next_plant = nil
crop_def._farming_prev_plant = "onions:allium_sprouts_3"
crop_def.tiles = {"allium_sprouts4.png"}
crop_def.groups.growing = 0
crop_def.drop = {
	items = {
		{items = {'onions:onion'}, rarity = 1},
		{items = {'onions:onion 3'}, rarity = 3},
		{items = {'onions:seed'}, rarity = 1},
		{items = {'onions:seed'}, rarity = 2},
	}
}
minetest.register_node("onions:allium_sprouts_4", table.copy(crop_def))

-- Some aliases for old item names.
minetest.register_alias("farming:onion_potato_salad", "onions:onion_potato_salad")
minetest.register_alias("onions:suateed_onions", "onions:sauteed_onions")



--aloevera init.lua
--all textures by Nakilashiva

local S = function(s)
	return s
end

minetest.register_node("aloevera:aloe_seed", {
  description = "Aloe Vera Seeds",
  tiles = {"aloe_seeds.png"},
  wield_image = "aloe_seeds.png",
  inventory_image = "aloe_seeds.png",
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
    return farming.place_seed(itemstack, placer, pointed_thing, "aloevera:aloe_seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  _farming_next_plant = "aloevera:aloe_plant_01",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



-- aloe_slice
minetest.register_craftitem("aloevera:aloe_slice", {
	description = S("Aloe Vera Slice"),
	inventory_image = "aloe_vera_slice.png",
	on_use = minetest.item_eat(3),
	groups = {foodrot=1},
	flowerpot_insert = {"aloevera:aloe_plant_01", "aloevera:aloe_plant_02", "aloevera:aloe_plant_03", "aloevera:aloe_plant_04"},
})

-- aloe gel
minetest.register_craftitem("aloevera:aloe_gel", {
	description = S("Aloe Vera Gel"),
	inventory_image = "aloe_vera_gel.png",
})

minetest.register_craft({
  type = "extracting",
  output = 'aloevera:aloe_gel 5',
  recipe = 'aloevera:aloe_slice',
  time = 3,
})

minetest.register_craft({
  type = "shapeless",
  output = 'aloevera:aloe_gel',
  recipe = {'aloevera:aloe_slice', 'farming:mortar_pestle'},
	replacements = {{'farming:mortar_pestle', 'farming:mortar_pestle'}},
})

-- aloe_slice definition
local crop_def = {
	drawtype = "plantlike",
	tiles = {"aloe_plant_01.png"},
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
	flowerpot_drop = "aloevera:aloe_slice",
}

-- stage 1
crop_def._farming_next_plant = "aloevera:aloe_plant_02"
crop_def._farming_prev_seed = "aloevera:aloe_seed"
minetest.register_node("aloevera:aloe_plant_01", table.copy(crop_def))

-- stage 2
crop_def._farming_next_plant = "aloevera:aloe_plant_03"
crop_def._farming_prev_plant = "aloevera:aloe_plant_01"
crop_def.tiles = {"aloe_plant_02.png"}
minetest.register_node("aloevera:aloe_plant_02", table.copy(crop_def))

-- stage 3
crop_def._farming_next_plant = "aloevera:aloe_plant_04"
crop_def._farming_prev_plant = "aloevera:aloe_plant_02"
crop_def.tiles = {"aloe_plant_03.png"}
crop_def.drop = {
	items = {
		{items = {'aloevera:aloe_slice'}, rarity = 1},
		{items = {'aloevera:aloe_slice'}, rarity = 3},
	}
}
minetest.register_node("aloevera:aloe_plant_03", table.copy(crop_def))

-- stage 4
crop_def._farming_next_plant = nil
crop_def._farming_prev_plant = "aloevera:aloe_plant_03"
crop_def.tiles = {"aloe_plant_04.png"}
crop_def.groups.growing = 0
crop_def.drop = {
	items = {
		{items = {'aloevera:aloe_slice'}, rarity = 1},
		{items = {'aloevera:aloe_slice 3'}, rarity = 3},
		{items = {'aloevera:aloe_seed'}, rarity = 1},
		{items = {'aloevera:aloe_seed'}, rarity = 3},
	}
}
minetest.register_node("aloevera:aloe_plant_04", table.copy(crop_def))

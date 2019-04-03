
minetest.register_node("carrot:seed", {
  description = "Carrot Seed",
  tiles = {"carrot_seed.png"},
  wield_image = "carrot_seed.png",
  inventory_image = "carrot_seed.png",
  drawtype = "signlike",
  paramtype = "light",
  paramtype2 = "wallmounted",
  walkable = false,
  sunlight_propagates = true,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5}
  },
  groups = utility.dig_groups("seeds", {seed = 1, attached_node = 1, flammable = 2, notify_destruct = 1}),
  on_place = function(itemstack, placer, pointed_thing)
    return farming.place_seed(itemstack, placer, pointed_thing, "carrot:seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  next_plant = "carrot:plant_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



-- Edible!
minetest.register_craftitem("carrot:regular", {
  description = "Carrot",
  inventory_image = "carrot_regular.png",
  on_use = minetest.item_eat(2),
	flowerpot_insert = {"carrot:plant_1", "carrot:plant_2", "carrot:plant_3", "carrot:plant_4", "carrot:plant_5", "carrot:plant_6", "carrot:plant_7", "carrot:plant_8"},
})



-- Edible!
local eat_function = minetest.item_eat(6)
minetest.register_craftitem("carrot:gold", {
  description = "Golden Carrot",
  inventory_image = "carrot_gold.png",
  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
    --ambiance.sound_play("hunger_eat", user:getpos(), 0.7, 10)
    user:set_hp(20)
		sprint.set_stamina(user, SPRINT_STAMINA)
    return eat_function(itemstack, user, pointed_thing)
  end,
})

minetest.register_craft({
  output = "carrot:gold",
  recipe = {
		{"", "default:gold_lump", ""},
		{"default:gold_lump", "carrot:regular", "default:gold_lump"},
		{"", "default:gold_lump", ""},
	},
})



local crop_def = {
  drawtype = "plantlike",
  tiles = {"carrot_plant_1.png"},
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
    not_in_creative_inventory = 1, notify_destruct = 1,
  }),
  sounds = default.node_sound_leaves_defaults(),
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = default.LIGHT_MAX,
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
	flowerpot_drop = "carrot:regular",
}

crop_def.next_plant = "carrot:plant_2"
minetest.register_node("carrot:plant_1", table.copy(crop_def))

crop_def.next_plant = "carrot:plant_3"
crop_def.tiles = {"carrot_plant_2.png"}
minetest.register_node("carrot:plant_2", table.copy(crop_def))

crop_def.next_plant = "carrot:plant_4"
crop_def.tiles = {"carrot_plant_3.png"}
minetest.register_node("carrot:plant_3", table.copy(crop_def))

crop_def.next_plant = "carrot:plant_5"
crop_def.tiles = {"carrot_plant_4.png"}
minetest.register_node("carrot:plant_4", table.copy(crop_def))

crop_def.next_plant = "carrot:plant_6"
crop_def.tiles = {"carrot_plant_5.png"}
minetest.register_node("carrot:plant_5", table.copy(crop_def))

crop_def.next_plant = "carrot:plant_7"
crop_def.tiles = {"carrot_plant_6.png"}
minetest.register_node("carrot:plant_6", table.copy(crop_def))

crop_def.next_plant = "carrot:plant_8"
crop_def.tiles = {"carrot_plant_7.png"}
minetest.register_node("carrot:plant_7", table.copy(crop_def))

crop_def.tiles = {"carrot_plant_8.png"}
crop_def.drop = {
  items = {
    {items = {"carrot:regular"}, rarity = 1},
    {items = {"carrot:gold"}, rarity = 100},
    {items = {"carrot:seed"}, rarity = 1},
    {items = {"carrot:seed"}, rarity = 2},
    {items = {"carrot:seed 2"}, rarity = 3},
  }
}
crop_def.next_plant = nil
minetest.register_node("carrot:plant_8", table.copy(crop_def))


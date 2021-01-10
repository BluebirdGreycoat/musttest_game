
minetest.register_node("tomato:seed", {
  description = "Tomato Seed",
  tiles = {"tomato_seed.png"},
  wield_image = "tomato_seed.png",
  inventory_image = "tomato_seed.png",
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
    return farming.place_seed(itemstack, placer, pointed_thing, "tomato:seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  next_plant = "tomato:plant_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



-- Edible!
minetest.register_craftitem("tomato:tomato", {
  description = "Ripe Tomato",
  inventory_image = "tomato_tomato.png",
  on_use = minetest.item_eat(2),
	groups = {foodrot=1},
	flowerpot_insert = {"tomato:plant_1", "tomato:plant_2", "tomato:plant_3", "tomato:plant_4", "tomato:plant_5", "tomato:plant_6", "tomato:plant_7", "tomato:plant_8"},
})



local crop_def = {
  drawtype = "plantlike",
  tiles = {"tomato_plant_1.png"},
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
	flowerpot_drop = "tomato:tomato",
}

crop_def.next_plant = "tomato:plant_2"
minetest.register_node("tomato:plant_1", table.copy(crop_def))

crop_def.next_plant = "tomato:plant_3"
crop_def.tiles = {"tomato_plant_2.png"}
minetest.register_node("tomato:plant_2", table.copy(crop_def))

crop_def.next_plant = "tomato:plant_4"
crop_def.tiles = {"tomato_plant_3.png"}
minetest.register_node("tomato:plant_3", table.copy(crop_def))

crop_def.next_plant = "tomato:plant_5"
crop_def.tiles = {"tomato_plant_4.png"}
minetest.register_node("tomato:plant_4", table.copy(crop_def))

crop_def.next_plant = "tomato:plant_6"
crop_def.tiles = {"tomato_plant_5.png"}
minetest.register_node("tomato:plant_5", table.copy(crop_def))

crop_def.next_plant = "tomato:plant_7"
crop_def.tiles = {"tomato_plant_6.png"}
minetest.register_node("tomato:plant_6", table.copy(crop_def))

crop_def.next_plant = "tomato:plant_8"
crop_def.tiles = {"tomato_plant_7.png"}
-- Not ready yet. Wait longer for best harvest.
-- Note: this is the plant level placed by the mapgen.
-- So we need to give seeds sometimes.
crop_def.drop = {
  items = {
    {items = {"tomato:tomato"}, rarity = 1},
    {items = {"tomato:seed"}, rarity = 2},
    {items = {"tomato:seed"}, rarity = 2},
  }
}
minetest.register_node("tomato:plant_7", table.copy(crop_def))

crop_def.tiles = {"tomato_plant_8.png"}
crop_def.drop = {
  items = {
    {items = {"tomato:tomato"}, rarity = 1},
    {items = {"tomato:tomato"}, rarity = 2},
    {items = {"tomato:tomato"}, rarity = 2},
    {items = {"tomato:tomato"}, rarity = 2},
    {items = {"tomato:seed"}, rarity = 1},
    {items = {"tomato:seed"}, rarity = 2},
    {items = {"tomato:seed"}, rarity = 2},
    {items = {"tomato:seed"}, rarity = 3},
  }
}
crop_def.next_plant = nil
minetest.register_node("tomato:plant_8", table.copy(crop_def))


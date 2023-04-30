
--[[
	Big thanks to PainterlyPack.net for allowing me to use these textures
]]

-- Pumpkin Seed
minetest.register_node("pumpkin:seed", {
  description = "Pumpkin Seed",
  tiles = {"farming_pumpkin_seed.png"},
  wield_image = "farming_pumpkin_seed.png",
  inventory_image = "farming_pumpkin_seed.png",
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
    return farming.place_seed(itemstack, placer, pointed_thing, "pumpkin:seed")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  _farming_next_plant = "pumpkin:plant_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



-- Pumpkin
minetest.register_node("pumpkin:pumpkin", {
  description = "Pumpkin",
  tiles = {
    "farming_pumpkin_top.png",
    "farming_pumpkin_top.png",
    "farming_pumpkin_side.png"
  },
  paramtype2 = "facedir",
  groups = utility.dig_groups("bigitem", {
    flammable = 2, plant = 1
  }),
  sounds = default.node_sound_wood_defaults(),
})



-- Pumpkin Slice
minetest.register_craftitem("pumpkin:slice", {
  description = "Pumpkin Slice",
  inventory_image = "farming_pumpkin_slice.png",
  on_use = minetest.item_eat(2),
	groups = {foodrot=1},
})



-- One pumpkin makes slightly more than enough to make 1 loaf of bread.
minetest.register_craft({
  type = "shapeless",
  output = "pumpkin:slice 3",
  recipe = {"pumpkin:pumpkin"},
})

minetest.register_craft({
	type = "shapeless",
	output = "pumpkin:slice 4", -- use a cutting board to get slightly more
	recipe = {"pumpkin:pumpkin", "farming:cutting_board"},
	replacements = {{"farming:cutting_board", "farming:cutting_board"}},
})



-- Jack 'O Lantern
minetest.register_node("pumpkin:lantern", {
  description = "Jack 'O Lantern",
  tiles = {
    "farming_pumpkin_top.png",
    "farming_pumpkin_top.png",
    "farming_pumpkin_side.png",
    "farming_pumpkin_side.png",
    "farming_pumpkin_side.png",
    "farming_pumpkin_face_off.png"
  },
  paramtype2 = "facedir",
  groups = utility.dig_groups("bigitem", {flammable = 2}),
  sounds = default.node_sound_wood_defaults(),
  
  on_punch = function(pos, node, puncher)
    node.name = "pumpkin:lantern_on"
    minetest.swap_node(pos, node)
  end,
})



minetest.register_node("pumpkin:lantern_on", {
  tiles = {
    "farming_pumpkin_top.png",
    "farming_pumpkin_top.png",
    "farming_pumpkin_side.png",
    "farming_pumpkin_side.png",
    "farming_pumpkin_side.png",
    "farming_pumpkin_face_on.png"
  },
  light_source = 12,
  paramtype2 = "facedir",
  groups = utility.dig_groups("bigitem", {
    flammable = 2,
    not_in_creative_inventory = 1
  }),
  sounds = default.node_sound_wood_defaults(),
  drop = "pumpkin:lantern",
  
  on_punch = function(pos, node, puncher)
    node.name = "pumpkin:lantern"
    minetest.swap_node(pos, node)
  end,
})



minetest.register_craft({
  type = "shapeless",
  output = "pumpkin:lantern",
  recipe = {"xdecor:candle", "pumpkin:pumpkin"},
})



-- Pumpkin Bread
minetest.register_craftitem("pumpkin:bread", {
  description = "Pumpkin Bread",
  inventory_image = "farming_pumpkin_bread.png",
  on_use = minetest.item_eat(6),
	groups = {foodrot=1},
})



minetest.register_craftitem("pumpkin:dough", {
  description = "Pumpkin Dough",
  inventory_image = "farming_pumpkin_dough.png",
	groups = {foodrot=1},
})



minetest.register_craft({
  type = "shapeless",
  output = "pumpkin:dough",
  recipe = {"farming:flour", "pumpkin:slice", "pumpkin:slice"}
})



minetest.register_craft({
  type = "cooking",
  output = "pumpkin:bread",
  recipe = "pumpkin:dough",
  cooktime = 10,
})



-- Pumpkin plant definition.
local crop_def = {
  drawtype = "plantlike",
  tiles = {"farming_pumpkin_1.png"},
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
}

-- Stage 1.
crop_def._farming_next_plant = "pumpkin:plant_2"
crop_def._farming_prev_seed = "pumpkin:seed"
minetest.register_node("pumpkin:plant_1", table.copy(crop_def))

-- Stage 2.
crop_def._farming_next_plant = "pumpkin:plant_3"
crop_def._farming_prev_plant = "pumpkin:plant_1"
crop_def.tiles = {"farming_pumpkin_2.png"}
minetest.register_node("pumpkin:plant_2", table.copy(crop_def))

-- Stage 3.
crop_def._farming_next_plant = "pumpkin:plant_4"
crop_def._farming_prev_plant = "pumpkin:plant_2"
crop_def.tiles = {"farming_pumpkin_3.png"}
minetest.register_node("pumpkin:plant_3", table.copy(crop_def))

-- Stage 4.
crop_def._farming_next_plant = "pumpkin:plant_5"
crop_def._farming_prev_plant = "pumpkin:plant_3"
crop_def.tiles = {"farming_pumpkin_4.png"}
minetest.register_node("pumpkin:plant_4", table.copy(crop_def))

-- Stage 5.
crop_def._farming_next_plant = "pumpkin:plant_6"
crop_def._farming_prev_plant = "pumpkin:plant_4"
crop_def.tiles = {"farming_pumpkin_5.png"}
minetest.register_node("pumpkin:plant_5", table.copy(crop_def))

-- Stage 6.
crop_def._farming_next_plant = "pumpkin:plant_7"
crop_def._farming_prev_plant = "pumpkin:plant_5"
crop_def.tiles = {"farming_pumpkin_6.png"}
minetest.register_node("pumpkin:plant_6", table.copy(crop_def))

-- Stage 7.
crop_def._farming_next_plant = "pumpkin:plant_8"
crop_def._farming_prev_plant = "pumpkin:plant_6"
crop_def.tiles = {"farming_pumpkin_7.png"}
minetest.register_node("pumpkin:plant_7", table.copy(crop_def))

-- Stage 8 (final).
crop_def.tiles = {"farming_pumpkin_8.png"}
crop_def.drop = {
  items = {
    {items = {"pumpkin:pumpkin"}, rarity = 1},
    {items = {"pumpkin:seed"}, rarity = 2},
    {items = {"pumpkin:seed"}, rarity = 2},
    {items = {"pumpkin:seed"}, rarity = 2},
  }
}
crop_def._farming_next_plant = nil
crop_def._farming_prev_plant = "pumpkin:plant_7"
minetest.register_node("pumpkin:plant_8", table.copy(crop_def))


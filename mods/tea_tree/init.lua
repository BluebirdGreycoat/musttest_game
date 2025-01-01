-- Shamelessly stealing this code for a similar Tea Plant. Nakilashiva wrote that, right? She won't mind...

local math_random = math.random

-- Tea Tree Seeds

minetest.register_node("tea_tree:seeds", {
  description = "Tree Tea Seeds",
  tiles = {"teatreeseeds.png"},
  wield_image = "teatreeseeds.png",
  inventory_image = "teatreeseeds.png",
  drawtype = "signlike",
  paramtype = "light",
  paramtype2 = "wallmounted",
  walkable = false,
  sunlight_propagates = true,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5}
  },
  groups = utility.dig_groups("seeds", {seed = 1, seed_oil = 1, attached_node = 1, flammable = 2, foodrot = 1, notify_destruct = 1}),
  on_place = function(itemstack, placer, pointed_thing)
    return farming.place_seed(itemstack, placer, pointed_thing, "tea_tree:seeds")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  _farming_next_plant = "tea_tree:plant_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})

-- Is this the bush? 
local crop_def = {
  drawtype = "plantlike",
  paramtype = "light",
  paramtype2 = "meshoptions",
  place_param2 = 2,
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

-- Tea Tree Bush?
crop_def._farming_next_plant = "tea_tree:plant_2"
crop_def._farming_prev_seed = "tea_tree:seeds"
crop_def.tiles = {"tea_tree1.png"}
minetest.register_node("tea_tree:plant_1", table.copy(crop_def))

crop_def.description = "Tea Tree"
crop_def.inventory_image = "tea_tree2.png"
crop_def._farming_next_plant = "tea_tree:plant_3"
crop_def._farming_prev_plant = "tea_tree:plant_1"
crop_def.tiles = {"tea_tree2.png"}
crop_def.after_dig_node =
function(pos, oldnode, oldmetadata, digger)
  if digger and digger:is_player() then
    local wielditem = digger:get_wielded_item()
    if string.find(wielditem:get_name(), "shovel") then
      -- If player digs with a shovel, then the tree is removed.
      -- The player gets 1 tree, which can be used for decoration.
      local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack(oldnode.name))
      minetest.add_item(pos, leftover)
    else
      -- Restore tree. Player did not actually dig it up yet.
      minetest.after(0, function()
        minetest.set_node(pos, {name="tea_tree:plant_2", param2=2})
        local timer = minetest.get_node_timer(pos)
        timer:start(math_random(300, 700))
      end)
    end
  end
end
minetest.register_node("tea_tree:plant_2", table.copy(crop_def))

crop_def.description = "Tea Tree"
crop_def.inventory_image = "tea_tree3.png"
crop_def._farming_next_plant = "tea_tree:plant_4"
crop_def._farming_prev_plant = "tea_tree:plant_2"
crop_def.tiles = {"tea_tree3.png"}
minetest.register_node("tea_tree:plant_3", table.copy(crop_def))

crop_def.description = "Mature Tea Tree"
crop_def.inventory_image = "tea_tree4.png"
crop_def._farming_next_plant = nil
crop_def._farming_prev_plant = "tea_tree:plant_3"
crop_def.tiles = {"tea_tree4.png"}
crop_def.after_dig_node =
function(pos, oldnode, oldmetadata, digger)
  if digger and digger:is_player() then
    local wielditem = digger:get_wielded_item()
    if string.find(wielditem:get_name(), "shovel") then
      -- If player digs with a shovel, then the tree is removed.
      -- The player gets 1 tree, which can be used for decoration.
      local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack("tea_tree:plant_4"))
      minetest.add_item(pos, leftover)
    else
      local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack("tea_tree:seeds " .. math_random(1, 3)))
      minetest.add_item(pos, leftover)
	  
	  -- Attempting to add tea tree leaves to the player's inventory here.
	  local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack("tea_tree:leaves " .. math_random(1, 3)))
      minetest.add_item(pos, leftover)
      
      -- Restore tree. Player did not actually dig it up.
      minetest.after(0, function()
        minetest.set_node(pos, {name="tea_tree:plant_2", param2=2})
        local timer = minetest.get_node_timer(pos)
        timer:start(math_random(300, 700))
      end)
    end
  end
end
minetest.register_node("tea_tree:plant_4", table.copy(crop_def))

minetest.register_craftitem(":tea_tree:leaves", {
    description = "Tea Leaves",
	inventory_image = "teatreeleaves.png",
})

-- Register tea leaves as a craft item in farming_redo?

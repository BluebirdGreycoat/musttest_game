
-- Localize for performance.
local math_random = math.random

-- This is both seed and edible fruit.
minetest.register_node("raspberries:fruit", {
  description = "Raspberries",
  tiles = {"raspberries_raspberries.png"},
  wield_image = "raspberries_raspberries.png",
  inventory_image = "raspberries_raspberries.png",
  drawtype = "signlike",
  paramtype = "light",
  paramtype2 = "wallmounted",
  walkable = false,
  sunlight_propagates = true,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5}
  },
  groups = utility.dig_groups("seeds", {seed = 1, attached_node = 1, flammable = 2, foodrot = 1, notify_destruct = 1}),
  on_place = function(itemstack, placer, pointed_thing)
    return farming.place_seed(itemstack, placer, pointed_thing, "raspberries:fruit")
  end,
  on_timer = farming.grow_plant,
  minlight = 13,
  maxlight = 15,
  _farming_next_plant = "raspberries:plant_1",
  fertility = {"grassland"},
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
  on_use = minetest.item_eat(1),
})



minetest.register_craftitem("raspberries:smoothie", {
  description = "Raspberry Smoothie\n\nEnergy drink. Quaff to improve stamina.",
  inventory_image = "raspberries_smoothie.png",
	on_use = function(itemstack, user, pointed_thing)
		sprint.add_stamina(user, 4)
		user:get_inventory():add_item("main", ItemStack("vessels:drinking_glass"))
		local func = minetest.item_eat(1)
		return func(itemstack, user, pointed_thing)
	end,
	-- Stored in glass, so does not rot.
})



minetest.register_craft({
  output = "raspberries:smoothie",
  recipe = {
    {"default:snow"},
    {"raspberries:fruit"},
    {"vessels:drinking_glass"},
  }
})



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

crop_def._farming_next_plant = "raspberries:plant_2"
crop_def.tiles = {"raspberries_plant_1.png"}
minetest.register_node("raspberries:plant_1", table.copy(crop_def))

crop_def._farming_next_plant = "raspberries:plant_3"
crop_def.tiles = {"raspberries_plant_2.png"}
crop_def.description = "Raspberry Bush"
crop_def.inventory_image = "raspberries_plant_2.png"
crop_def.after_dig_node =
function(pos, oldnode, oldmetadata, digger)
  if digger and digger:is_player() then
    local wielditem = digger:get_wielded_item()
    if string.find(wielditem:get_name(), "shovel") then
      -- If player digs with a shovel, then the bush is removed.
      -- The player gets 1 bush, which can be used for decoration.
      local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack(oldnode.name))
      minetest.add_item(pos, leftover)
    else
      -- Restore bush. Player did not actually dig it up.
      minetest.after(0, function()
        minetest.set_node(pos, {name="raspberries:plant_2", param2=2})
        local timer = minetest.get_node_timer(pos)
        timer:start(math_random(300, 700))
      end)
    end
  end
end
minetest.register_node("raspberries:plant_2", table.copy(crop_def))

crop_def.description = "Raspberry Bush with Blossoms"
crop_def.inventory_image = "raspberries_plant_3.png"
crop_def._farming_next_plant = "raspberries:plant_4"
crop_def.tiles = {"raspberries_plant_3.png"}
minetest.register_node("raspberries:plant_3", table.copy(crop_def))

crop_def.description = "Raspberry Bush with Raspberries"
crop_def.inventory_image = "raspberries_plant_4.png"
crop_def._farming_next_plant = nil
crop_def.tiles = {"raspberries_plant_4.png"}
crop_def.after_dig_node =
function(pos, oldnode, oldmetadata, digger)
  if digger and digger:is_player() then
    local wielditem = digger:get_wielded_item()
    if string.find(wielditem:get_name(), "shovel") then
      -- If player digs with a shovel, then the bush is removed.
      -- The player gets 1 bush, which can be used for decoration.
      local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack("raspberries:plant_4"))
      minetest.add_item(pos, leftover)
    else
      local inv = digger:get_inventory()
      local leftover = inv:add_item("main", ItemStack("raspberries:fruit " .. math_random(1, 5)))
      minetest.add_item(pos, leftover)
      
      -- Restore bush. Player did not actually dig it up.
      minetest.after(0, function()
        minetest.set_node(pos, {name="raspberries:plant_2", param2=2})
        local timer = minetest.get_node_timer(pos)
        timer:start(math_random(300, 700))
      end)
    end
  end
end
minetest.register_node("raspberries:plant_4", table.copy(crop_def))



if not minetest.global_exists("bluegrass") then bluegrass = {} end
bluegrass.modpath = minetest.get_modpath("bluegrass")

-- Localize for performance.
local math_random = math.random



-- How often node timers for plants will tick, +/- some random value.
local function tick(pos, data)
  if data then
    minetest.get_node_timer(pos):start(math_random(data.min_time, data.max_time))
  else
    minetest.get_node_timer(pos):start(math_random(166, 286))
    --minetest.get_node_timer(pos):start(1.0) -- Debug
  end
end



-- How often a growth failure tick is retried.
local function tick_again(pos)
  minetest.get_node_timer(pos):start(math_random(40, 80))
  --minetest.get_node_timer(pos):start(1.0) -- Debug
end



-- Seed placement.
bluegrass.place_seed = function(itemstack, placer, pointed_thing, plantname)
  local pt = pointed_thing
  -- check if pointing at a node
  if not pt then
    return itemstack
  end
  if pt.type ~= "node" then
    return itemstack
  end

  local under = minetest.get_node(pt.under)
  
  -- Pass through interactions to nodes that define them (like chests).
  do
    local pdef = minetest.reg_ns_nodes[under.name]
    if pdef and pdef.on_rightclick and not placer:get_player_control().sneak then
      return pdef.on_rightclick(pt.under, under, placer, itemstack, pt)
    end
  end

  local above = minetest.get_node(pt.above)

  if minetest.is_protected(pt.under, placer:get_player_name()) then
    minetest.record_protection_violation(pt.under, placer:get_player_name())
    return
  end
  if minetest.is_protected(pt.above, placer:get_player_name()) then
    minetest.record_protection_violation(pt.above, placer:get_player_name())
    return
  end

  -- return if any of the nodes is not registered
  if not minetest.reg_ns_nodes[under.name] then
    return itemstack
  end
  if not minetest.reg_ns_nodes[above.name] then
    return itemstack
  end

  -- check if pointing at the bottom of the node
  if pt.above.y ~= pt.under.y-1 then
    return itemstack
  end

  -- check if you can replace the node above the pointed node
	local ndef_above = minetest.reg_ns_nodes[above.name]
  if not ndef_above or not ndef_above.buildable_to then
    return itemstack
  end

  -- check if pointing at soil
  if under.name ~= "rackstone:dauthsand_stable" then
    return itemstack
  end

  -- add the node and remove 1 item from the itemstack
	-- note: use of `add_node` causes additional callbacks to run (droplift, dirtspread).
  minetest.add_node(pt.above, {name=plantname})
  tick(pt.above)
  itemstack:take_item()
  return itemstack
end



bluegrass.grow_plant = function(pos, elapsed)
  local node = minetest.get_node(pos)
  local name = node.name
  local def = minetest.reg_ns_nodes[name]

  if not def.next_plant then
    -- disable timer for fully grown plant
    return
  end

  -- grow seed
  if minetest.get_item_group(node.name, "seed") and def.fertility then
    local soil_node = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
    if not soil_node then
      tick_again(pos)
      return
    end
    -- omitted is a check for light, we assume seeds can germinate in the dark.
    for _, v in pairs(def.fertility) do
      if minetest.get_item_group(soil_node.name, v) ~= 0 then
        local placenode = {name = def.next_plant}
        if def.place_param2 then
          placenode.param2 = def.place_param2
        end
        minetest.swap_node(pos, placenode)
        if minetest.reg_ns_nodes[def.next_plant].next_plant then
          tick(pos)
          return
        end
      end
    end

    return
  end
  
  -- check if below soil
  local above = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
  if above.name ~= "rackstone:dauthsand_stable" then
    -- We really shouldn't be able to get here, but we should still handle it just in case.
    tick_again(pos)
    return
  end
  
  local tick_data = {
    min_time = 300,
    max_time = 400,
  }
  
  local can_grow = false
  do
    if minetest.find_node_near(pos, 4, "group:lava") then
      can_grow = true
    end
    if minetest.find_node_near(pos, 2, "group:flame") then
      can_grow = true
    end
  end
  if not can_grow then
    tick_again(pos)
    return
  end
  
  -- Minerals nearby make bluegrass grow faster.
  local lava_near = minetest.find_node_near(pos, 2, "glowstone:minerals")
  if lava_near then
    tick_data.min_time = 200
    tick_data.max_time = 300
  end

  -- grow
  local placenode = {name = def.next_plant}
  if def.place_param2 then
    placenode.param2 = def.place_param2
  end
  minetest.swap_node(pos, placenode)
  
  -- new timer needed?
  if minetest.reg_ns_nodes[def.next_plant].next_plant then
    tick(pos, tick_data)
  end
  
  return
end



minetest.register_craftitem("bluegrass:bluegrass", {
  description = "Bluegrass Stalk (Completely Inedible)",
  inventory_image = "bluegrass_bluegrass.png",
	-- Does not rot.
})



minetest.register_craftitem("bluegrass:cooked", {
  description = "Cooked Bluegrass (Unappetizing)",
  inventory_image = "bluegrass_cooked.png",
  on_use = minetest.item_eat(1),
	groups = {foodrot=1},
})



minetest.register_craft({
  type = "cooking",
  output = "bluegrass:cooked 3",
  recipe = "bluegrass:bluegrass",
  cooktime = 2,
})



minetest.register_node("bluegrass:seed", {
  description = "Bluegrass Seed",
  tiles = {"bluegrass_seed.png"},
  wield_image = "bluegrass_seed.png",
  inventory_image = "bluegrass_seed.png",
  drawtype = "signlike",
  paramtype = "light",
  paramtype2 = "wallmounted",
  walkable = false,
  sunlight_propagates = true,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
  },
  groups = utility.dig_groups("seeds", {seed = 1, seed_oil = 1, hanging_node = 1, flammable = 2}),
  on_place = function(itemstack, placer, pointed_thing)
    return bluegrass.place_seed(itemstack, placer, pointed_thing, "bluegrass:seed")
  end,
  on_timer = bluegrass.grow_plant,
  next_plant = "bluegrass:plant_1",
  sounds = default.node_sound_dirt_defaults({
    dug = {name = "default_grass_footstep", gain = 0.2},
    place = {name = "default_place_node", gain = 0.25},
  }),
})



local crop_def = {
  drawtype = "plantlike",
  tiles = {"bluegrass_plant_1.png"},
  paramtype = "light",
  paramtype2 = "meshoptions",
  place_param2 = 2,
  sunlight_propagates = true,
  --waving = 1,
  walkable = false,
  buildable_to = true,
  drop = "",
  selection_box = {
    type = "fixed",
    fixed = {-0.5, 5/16, -0.5, 0.5, 0.5, 0.5},
  },
  groups = utility.dig_groups("crop", {
    flammable = 2, plant = 1, hanging_node = 1,
    not_in_creative_inventory = 1,
  }),
  sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
  on_timer = bluegrass.grow_plant,
}

  
  
-- Stage 1.
crop_def.next_plant = "bluegrass:plant_2"
minetest.register_node("bluegrass:plant_1", table.copy(crop_def))

-- Stage 2.
crop_def.next_plant = "bluegrass:plant_3"
crop_def.tiles = {"bluegrass_plant_2.png"}
minetest.register_node("bluegrass:plant_2", table.copy(crop_def))

-- Stage 3.
crop_def.next_plant = "bluegrass:plant_4"
crop_def.tiles = {"bluegrass_plant_3.png"}
minetest.register_node("bluegrass:plant_3", table.copy(crop_def))

-- Stage 4.
crop_def.next_plant = "bluegrass:plant_5"
crop_def.tiles = {"bluegrass_plant_4.png"}
minetest.register_node("bluegrass:plant_4", table.copy(crop_def))

-- Stage 5.
crop_def.next_plant = "bluegrass:plant_6"
crop_def.tiles = {"bluegrass_plant_5.png"}
minetest.register_node("bluegrass:plant_5", table.copy(crop_def))

-- Stage 6.
crop_def.next_plant = "bluegrass:plant_7"
crop_def.tiles = {"bluegrass_plant_6.png"}
minetest.register_node("bluegrass:plant_6", table.copy(crop_def))

-- Stage 7.
crop_def.next_plant = nil
crop_def.tiles = {"bluegrass_plant_7.png"}
crop_def.drop = {
  items = {
    {items = {"bluegrass:bluegrass"}, rarity = 1},
    {items = {"bluegrass:bluegrass 2"}, rarity = 2},
    {items = {"bluegrass:seed"}, rarity = 2},
    {items = {"bluegrass:seed"}, rarity = 2},
    {items = {"bluegrass:seed"}, rarity = 3},
  }
}
minetest.register_node("bluegrass:plant_7", table.copy(crop_def))

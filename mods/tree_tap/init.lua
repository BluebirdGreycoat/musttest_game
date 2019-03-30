
minetest.register_tool("tree_tap:tree_tap", {
  description = "Tree Tap",
  inventory_image = "technic_tree_tap.png",
  
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then return end
    local pos = pointed_thing.under
    if minetest.is_protected(pos, user:get_player_name()) then
      minetest.record_protection_violation(pos, user:get_player_name())
      return
    end
    local node = minetest.get_node(pos)
    local node_name = node.name
    if node_name ~= "moretrees:rubber_tree_tree" then return end
    node.name = "moretrees:rubber_tree_trunk_empty"
    minetest.swap_node(pos, node)
    
    minetest.handle_node_drops(pointed_thing.above, {"rubber:raw_latex"}, user)
    
    local item_wear = tonumber(itemstack:get_wear())
    item_wear = item_wear + 819
    if item_wear > 65535 then
      ambiance.sound_play("default_tool_breaks", user:get_pos(), 0.7, 10)
      itemstack:clear()
      return itemstack
    end
    itemstack:set_wear(item_wear)
    return itemstack
  end,
})



minetest.register_craft({
  output = "tree_tap:tree_tap",
  recipe = {
    {"stainless_steel:ingot", "group:wood",    "group:stick"},
    {"",               "group:stick", "group:stick"}
  },
})



minetest.register_abm({
  nodenames = {"moretrees:rubber_tree_trunk_empty"},
  interval = 60 * default.ABM_TIMER_MULTIPLIER,
  chance = 30 * default.ABM_CHANCE_MULTIPLIER,
  
  action = function(pos, node)
    local t = minetest.find_node_near(pos, 2, "moretrees:rubber_tree_leaves")
    local w = minetest.find_node_near(pos, 5, "group:water")
    if t and w then
      node.name = "moretrees:rubber_tree_tree"
      minetest.swap_node(pos, node)
    end
  end
})


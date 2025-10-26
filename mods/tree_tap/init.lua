
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
    
    itemstack = utility.wear_tool_with_feedback({
      item = itemstack,
      wear = 819,
      user = user,
    })
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



local REALM_LIST = {
	"channelwood",
	"jarkati",
	"midfeld",
	"waterworld",
	"ariba",
}

for _, realm in ipairs(REALM_LIST) do
  minetest.register_abm({
    nodenames = {"moretrees:rubber_tree_trunk_empty"},
    interval = 60 * default.ABM_TIMER_MULTIPLIER,
    chance = 30 * default.ABM_CHANCE_MULTIPLIER,

		min_y = rc.get_realm_data(realm).minp.y,
		max_y = rc.get_realm_data(realm).maxp.y,

    action = function(pos, node)
      local t = minetest.find_node_near(pos, 2, "moretrees:rubber_tree_leaves")
      local w = minetest.find_node_near(pos, 5, "group:water")
      local m = minetest.find_node_near(pos, 5,
        {"group:dirt_type", "group:soil"})

      if t and w and m then
        node.name = "moretrees:rubber_tree_tree"
        minetest.swap_node(pos, node)
      end
    end
  })
end


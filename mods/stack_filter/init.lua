
stack_filter = stack_filter or {}
stack_filter.modpath = minetest.get_modpath("stack_filter")



stack_filter.on_punch = 
function(pos, node, puncher, pointed_thing)
end



stack_filter.can_dig = function(pos, player)
  return true
end



stack_filter.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  return stack:get_count()
end



stack_filter.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return stack_filter.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



stack_filter.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  return stack:get_count()
end



stack_filter.on_timer = 
function(pos, elapsed)
end



stack_filter.on_construct = 
function(pos)
end



stack_filter.on_metadata_inventory_move = 
function(pos)
end



stack_filter.on_metadata_inventory_put = 
function(pos)
end



stack_filter.on_blast = 
function(pos)
  local drops = {}
  drops[#drops+1] = "stack_filter:filter"
  minetest.remove_node(pos)
  return drops
end



if not stack_filter.run_once then
  minetest.register_node("stack_filter:filter", {
    description = "Stack Filter",
    tiles = {
      "pipeworks_mese_filter_top.png",
      "pipeworks_mese_filter_top.png",
      "pipeworks_mese_filter_output.png",
      "pipeworks_mese_filter_input.png",
      "pipeworks_mese_filter_side.png",
      "pipeworks_mese_filter_top.png",
    },
    
    groups = utility.dig_groups("machine", {
      immovable = 1,
    }),
    
    paramtype2 = "facedir",
    on_rotate = function(...) return screwdriver.rotate_simple(...) end,
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    
    on_punch = function(...)
      return stack_filter.on_punch(...) end,
    can_dig = function(...)
      return stack_filter.can_dig(...) end,
    on_timer = function(...)
      return stack_filter.on_timer(...) end,
    on_construct = function(...)
      return stack_filter.on_construct(...) end,
    on_blast = function(...)
      return stack_filter.on_blast(...) end,

    on_metadata_inventory_move = function(...)
      return stack_filter.on_metadata_inventory_move(...) end,
    on_metadata_inventory_put = function(...)
      return stack_filter.on_metadata_inventory_put(...) end,
    on_metadata_inventory_take = function(...)
      return stack_filter.on_metadata_inventory_take(...) end,

    allow_metadata_inventory_put = function(...)
      return stack_filter.allow_metadata_inventory_put(...) end,
    allow_metadata_inventory_move = function(...)
      return stack_filter.allow_metadata_inventory_move(...) end,
    allow_metadata_inventory_take = function(...)
      return stack_filter.allow_metadata_inventory_take(...) end,
  })

  minetest.register_craft( {
    output = "stack_filter:filter",
    recipe = {
      { "default:steel_ingot", "default:steel_ingot", "plastic:plastic_sheeting" },
      { "default:mese", "techcrafts:machine_casing", "plastic:plastic_sheeting" },
      { "default:steel_ingot", "default:steel_ingot", "plastic:plastic_sheeting" }
    },
  })
  
  local c = "stack_filter:core"
  local f = stack_filter.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  stack_filter.run_once = true
end

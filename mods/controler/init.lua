
controler = controler or {}
controler.modpath = minetest.get_modpath("controler")



controler.compose_formspec =
function(pos)
  local meta = minetest.get_meta(pos)
  
  local formspec =
    "size[8,8.5]" ..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors() ..
    "label[0,0.5;Controler Configuration]" ..
    "list[context;cfg;0,1;8,2;]" ..
    
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    
    "listring[context;cfg]" ..
    "listring[current_player;main]" ..
    default.get_hotbar_bg(0, 4.25)
  
  meta:set_string("formspec", formspec)
end

controler.compose_infotext =
function(pos)
  local meta = minetest.get_meta(pos)
  local infotext = "Machine Controler"
  meta:set_string("infotext", infotext)
end

controler.can_dig = 
function(pos, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty('cfg')
end

controler.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  if stack:get_name() == "cfg:dev" then
    return stack:get_count()
  end
  return 0
end

controler.allow_metadata_inventory_move = 
function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return controler.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

controler.allow_metadata_inventory_take = 
function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  return stack:get_count()
end

controler.on_timer = 
function(pos, elapsed)
  machines.log_update(pos, "Machine Controler")
  
  local table_in = {
    purpose = "autostart_trigger",
  }
  local table_out = {}
  local traversal = {}
         
  -- Do not process self.
  local hash = minetest.hash_node_position(pos)
  traversal[hash] = 0
  
  -- Update all machines on adjacent networks of any tier.
  local hubs = machines.get_adjacent_network_hubs(pos)
  if hubs then
    for k, v in ipairs(hubs) do
      local node = minetest.get_node(v)
      local def = minetest.reg_ns_nodes[node.name]
      if def and def.on_machine_execute then
        def.on_machine_execute(v, table_in, table_out, traversal)
      end
    end
  end
  
  controler.compose_formspec(pos)
  controler.compose_infotext(pos)
end

controler.on_blast = 
function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "cfg", drops)
  drops[#drops+1] = "controler:controler"
  minetest.remove_node(pos)
  return drops
end

controler.on_construct = 
function(pos)
  controler.initialize_typedata(pos)

  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  
  inv:set_size('cfg', 16)
  
  controler.compose_formspec(pos)
  controler.compose_infotext(pos)
end

controler.after_place_node =
function(pos, placer, itemstack, pointed_thing)
end

controler.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end

controler.on_metadata_inventory_move = 
function(pos)
  controler.trigger_update(pos)
end

controler.on_metadata_inventory_put = 
function(pos)
  controler.trigger_update(pos)
end

controler.on_metadata_inventory_take = 
function(pos)
  controler.trigger_update(pos)
end

controler.on_machine_execute =
function(pos, table_in, table_out, traversal)
  -- No recursion check, because controlers do not take part in chains.
  -- This also allows them to function at the very end of a switching chain.

  -- Do not process this node more than once.
  local hash = minetest.hash_node_position(pos)
  if traversal[hash] then return end
  traversal[hash] = 0
  
  local purpose = table_in.purpose
  if purpose == "controler_update" then
    controler.trigger_update(pos)
  end
end

-- Typedata is used when traversing the network, without touching the node.
-- It must contain as much data as needed to get the node even if unloaded.
-- This must be done after node construction.
-- This should also be done when punched, to allow old nodes to be upgraded.
controler.initialize_typedata =
function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("technic_machine", "yes")
  meta:set_string("technic_type", "utility")
  meta:set_string("technic_tier", "lv|mv|hv")
  meta:set_string("technic_name", "controler:controler")
end

controler.on_punch =
function(pos, node, puncher, pointed_thing)
  controler.initialize_typedata(pos)
  controler.trigger_update(pos)
end



if not controler.run_once then
  minetest.register_node("controler:controler", {
    description = "Machine Controler",
    tiles = {
      "controler_top.png", "controler_bottom.png",
      "controler_side.png", "controler_side.png",
      "controler_side.png", "controler_front.png"
    },
    
    groups = utility.dig_groups("machine", {
      immovable = 1,
      tier_lv = 1, tier_mv = 1, tier_hv = 1,
    }),
    
    paramtype2 = "facedir",
    on_rotate = function(...) return screwdriver.rotate_simple(...) end,
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),

    on_punch = function(...)
      return controler.on_punch(...) end,
    can_dig = function(...)
      return controler.can_dig(...) end,
    on_timer = function(...)
      return controler.on_timer(...) end,
    on_construct = function(...)
      return controler.on_construct(...) end,
    after_place_node = function(...)
      return controler.after_place_node(...) end,

    on_metadata_inventory_move = function(...)
      return controler.on_metadata_inventory_move(...) end,
    on_metadata_inventory_put = function(...)
      return controler.on_metadata_inventory_put(...) end,
    on_metadata_inventory_take = function(...)
      return controler.on_metadata_inventory_take(...) end,
    on_blast = function(...)
      return controler.on_blast(...) end,

    allow_metadata_inventory_put = function(...)
      return controler.allow_metadata_inventory_put(...) end,
    allow_metadata_inventory_move = function(...)
      return controler.allow_metadata_inventory_move(...) end,
    allow_metadata_inventory_take = function(...)
      return controler.allow_metadata_inventory_take(...) end,
      
    on_machine_execute = function(...)
      return controler.on_machine_execute(...) end,
  })

	-- Not used anymore. Ready for repurposing.
	--[[
  minetest.register_craft({
    output = 'controler:controler',
    recipe = {
      {'fine_wire:silver', 'default:glass', 'fine_wire:gold'},
      {'techcrafts:control_logic_unit', 'techcrafts:machine_casing', 'techcrafts:control_logic_unit'},
      {'carbon_steel:ingot', 'battery:battery', 'carbon_steel:ingot'},
    },
  })
	--]]
  
  local c = "controler:core"
  local f = controler.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  controler.run_once = true
end

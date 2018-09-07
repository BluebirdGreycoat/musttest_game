
centrifuge = centrifuge or {}
centrifuge.modpath = minetest.get_modpath("centrifuge")



centrifuge.get_formspec_defaults = function()
  local str =
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  return str
end

centrifuge.formspec_active = function(fuel_percent, item_percent)
  local formspec =
    "size[8,8.5]" ..
    centrifuge.get_formspec_defaults() ..
    
    "label[3.5,0;Fuel & Input]" ..
    "list[context;src;3.5,0.5;1,1;]" ..
    "list[context;fuel;3.5,2.5;1,1;]" ..
    
    "image[3.5,1.5;1,1;machine_progress_bg.png^[lowpart:" ..
    (100-fuel_percent) .. ":machine_progress_fg.png]" ..
    "image[4.5,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:" ..
    (item_percent) .. ":gui_furnace_arrow_fg.png^[transformR270]" ..
    
    "label[5.5,0.46;Destination]" ..
    "list[context;dst;5.5,0.96;2,2;]" ..
    
    "list[current_player;main;0,4.25;8,1;]" ..
    "list[current_player;main;0,5.5;8,3;8]" ..
    
    "label[0.75,0;Configuration]" ..
    "list[context;cfg;0.75,0.5;2,1;]" ..
    "label[0.75,2;Upgrades]" ..
    "list[context;upg;0.75,2.5;2,1;]" ..
    
    "listring[context;dst]" ..
    "listring[current_player;main]" ..
    "listring[context;src]" ..
    "listring[current_player;main]" ..
    "listring[context;fuel]" ..
    "listring[current_player;main]" ..
    default.get_hotbar_bg(0, 4.25)
  return formspec
end

centrifuge.formspec_inactive = function()
  return centrifuge.formspec_active(100, 0)
end

centrifuge.on_punch = 
function(pos, node, puncher, pointed_thing)
  machines.initialize_typedata(pos, "centrifuge:inactive", "mv")
  centrifuge.trigger_update(pos)
end

centrifuge.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



centrifuge.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("dst") and
    inv:is_empty("src") and
    inv:is_empty("cfg") and
    inv:is_empty("upg")
end



centrifuge.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    "mesefuel", "fuel", "src", "dst", "cfg", "upg")
end



centrifuge.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return centrifuge.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



centrifuge.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  return stack:get_count()
end



local MACHINE_DATA = {
  name = "Centrifuge",
  method = "separating",
  demand = 200,
  swap = {
    inactive = "centrifuge:inactive",
    active = "centrifuge:active",
  },
  form = {
    inactive = centrifuge.formspec_inactive,
    active = centrifuge.formspec_active,
  },
  fuel = "mesefuel",
  processable = "Separable",
}

centrifuge.on_timer = function(pos, elapsed)
  machines.log_update(pos, "Centrifuge")
  return machines.on_machine_timer(pos, elapsed, MACHINE_DATA)
end



centrifuge.on_construct = 
function(pos)
end

centrifuge.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  machines.initialize_typedata(pos, "centrifuge:inactive", "mv")
  machines.after_place_machine(pos, placer, "Centrifuge", 1, centrifuge.formspec_inactive)
end



centrifuge.on_metadata_inventory_move = function(pos)
  centrifuge.trigger_update(pos)
end



centrifuge.on_metadata_inventory_put = function(pos)
  centrifuge.trigger_update(pos)
end



centrifuge.on_metadata_inventory_take = function(pos)
  centrifuge.trigger_update(pos)
end



centrifuge.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  default.get_inventory_drops(pos, "upg", drops)
  drops[#drops+1] = "centrifuge:inactive"
  minetest.remove_node(pos)
  return drops
end



if not centrifuge.run_once then
  local SIDE_ANIMATED = {
    name = "centrifuge_side.png",
    animation = {
      type = "vertical_frames",
      aspect_w = 16,
      aspect_h = 16,
      length = 0.5,
    },
  }
  local FRONT_ANIMATED = {
    image = "centrifuge_front_active.png",
    backface_culling = false,
    animation = {
      type = "vertical_frames",
      aspect_w = 16,
      aspect_h = 16,
      length = 0.5,
    },
  }
  
  for k, v in ipairs({
    {name="inactive", light=0, tile_side="centrifuge_side_no_anim.png", tile_front="centrifuge_front.png"},
    {name="active", light=4, tile_side=SIDE_ANIMATED, tile_front=FRONT_ANIMATED},
  }) do
    minetest.register_node("centrifuge:" .. v.name, {
      description = "Centrifuge",
      tiles = {
        "centrifuge_top.png", "centrifuge_bottom.png",
        v.tile_side, v.tile_side,
        v.tile_side, v.tile_front,
      },

      light_source = v.light,
      paramtype2 = "facedir",
      groups = {
        level=1, cracky=3,
        tubedevice = 1, tubedevice_receiver = 1,
        immovable = 1,
        tier_mv = 1,
      },
      
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "cent2:mv_inactive",

      can_dig = function(...)       
        return centrifuge.can_dig(...) end,
      on_timer = function(...)      
        return centrifuge.on_timer(...) end,
      on_construct = function(...)  
        return centrifuge.on_construct(...) end,
      on_blast = function(...)      
        return centrifuge.on_blast(...) end,
      on_punch = function(...)      
        return centrifuge.on_punch(...) end,
      after_place_node = function(...)
        return centrifuge.after_place_node(...) end,
      on_metadata_inventory_move = function(...)
        return centrifuge.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return centrifuge.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return centrifuge.on_metadata_inventory_take(...) end,
      allow_metadata_inventory_put = function(...)
        return centrifuge.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return centrifuge.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return centrifuge.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end

  

  minetest.register_craft({
    output = 'cent2:mv_inactive',
    recipe = {
      {"techcrafts:electric_motor", "techcrafts:copper_plate", "techcrafts:control_logic_unit"},
      {"techcrafts:copper_plate", "techcrafts:machine_casing", "techcrafts:copper_plate"},
      {"stack_filter:filter", "gem_cutter:blade", "stack_filter:filter"},
    }
  })

  local c = "centrifuge:core"
  local f = centrifuge.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(centrifuge.modpath .. "/v2.lua")
  centrifuge.run_once = true
end



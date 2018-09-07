
extractor = extractor or {}
extractor.modpath = minetest.get_modpath("extractor")



extractor.get_formspec_defaults = function()
  local str =
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  return str
end

extractor.formspec_active = function(fuel_percent, item_percent)
  local formspec =
    "size[8,8.5]" ..
    extractor.get_formspec_defaults() ..
    
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

extractor.formspec_inactive = function()
  return extractor.formspec_active(100, 0)
end

extractor.on_punch = 
function(pos, node, puncher, pointed_thing)
  machines.initialize_typedata(pos, "extractor:inactive", "mv")
  extractor.trigger_update(pos)
end

extractor.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



extractor.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("dst") and
    inv:is_empty("src") and
    inv:is_empty("cfg") and
    inv:is_empty("upg")
end



extractor.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    "mesefuel", "fuel", "src", "dst", "cfg", "upg")
end



extractor.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return extractor.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



extractor.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  return stack:get_count()
end



local MACHINE_DATA = {
  name = "Extractor",
  method = "extracting",
  demand = 100,
  swap = {
    inactive = "extractor:inactive",
    active = "extractor:active",
  },
  form = {
    inactive = extractor.formspec_inactive,
    active = extractor.formspec_active,
  },
  fuel = "mesefuel",
  processable = "Extractable",
}

extractor.on_timer = function(pos, elapsed)
  machines.log_update(pos, "Extractor")
  return machines.on_machine_timer(pos, elapsed, MACHINE_DATA)
end



extractor.on_construct = 
function(pos)
end

extractor.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  machines.initialize_typedata(pos, "extractor:inactive", "mv")
  machines.after_place_machine(pos, placer, "Extractor", 1, extractor.formspec_inactive)
end



extractor.on_metadata_inventory_move = function(pos)
  extractor.trigger_update(pos)
end



extractor.on_metadata_inventory_put = function(pos)
  extractor.trigger_update(pos)
end



extractor.on_metadata_inventory_take = function(pos)
  extractor.trigger_update(pos)
end



extractor.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  default.get_inventory_drops(pos, "upg", drops)
  drops[#drops+1] = "extractor:inactive"
  minetest.remove_node(pos)
  return drops
end



if not extractor.run_once then
  for k, v in ipairs({
    {name="inactive", light=0, tile="technic_lv_extractor_front.png"},
    {name="active", light=8, tile="technic_lv_extractor_front_active.png"},
  }) do
    minetest.register_node("extractor:" .. v.name, {
      description = "Extractor",
      tiles = {
        "technic_lv_extractor_top.png", "technic_lv_extractor_bottom.png",
        "technic_lv_extractor_side.png", "technic_lv_extractor_side.png",
        "technic_lv_extractor_side.png", v.tile,
      },

      paramtype2 = "facedir",
      groups = {
        level=1, cracky=3,
        tubedevice = 1, tubedevice_receiver = 1,
        immovable = 1,
        tier_mv = 1,
      },
      
      light_source = v.light,
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "extract2:mv_inactive",

      can_dig = function(...)       
        return extractor.can_dig(...) end,
      on_timer = function(...)      
        return extractor.on_timer(...) end,
      on_construct = function(...)  
        return extractor.on_construct(...) end,
      on_blast = function(...)      
        return extractor.on_blast(...) end,
      on_punch = function(...)      
        return extractor.on_punch(...) end,
      after_place_node = function(...)
        return extractor.after_place_node(...) end,
      on_metadata_inventory_move = function(...)
        return extractor.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return extractor.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return extractor.on_metadata_inventory_take(...) end,
      allow_metadata_inventory_put = function(...)
        return extractor.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return extractor.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return extractor.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end

  minetest.register_alias("extractor:extractor", "extractor:inactive")
  minetest.register_alias("extractor:extractor_active", "extractor:active")
  


  minetest.register_craft({
    output = 'extract2:lv_inactive',
    recipe = {
      {'tree_tap:tree_tap', 'techcrafts:electric_motor', 'tree_tap:tree_tap'},
      {'tree_tap:tree_tap', 'techcrafts:machine_casing', 'tree_tap:tree_tap'},
      {'default:stonebrick','techcrafts:control_logic_unit','default:stonebrick'},
    }
  })

	minetest.register_craft({
		output = 'extract2:mv_inactive',
		recipe = {
			{'stainless_steel:ingot', 'extract2:lv_inactive',   'stainless_steel:ingot'},
			{'stack_filter:filter',              'transformer:mv', 'stack_filter:filter'},
			{'stainless_steel:ingot', 'cb2:mv',       'stainless_steel:ingot'},
		}
	})

  minetest.register_craft({
    type = "extracting",
    output = "dye:green",
    recipe = "group:leaves",
    time = 4,
  })
  
  local c = "extractor:core"
  local f = extractor.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(extractor.modpath .. "/v2.lua")
  extractor.run_once = true
end



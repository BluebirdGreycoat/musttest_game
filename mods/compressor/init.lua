
compressor = compressor or {}
compressor.modpath = minetest.get_modpath("compressor")



compressor.get_formspec_defaults = function()
  local str =
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots
  return str
end



-- Get active formspec.
compressor.get_active_formspec = function(fuel_percent, item_percent)
  local formspec = 
    "size[8,8.5]" ..
    compressor.get_formspec_defaults() ..
    
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



compressor.get_inactive_formspec = function()
  return compressor.get_active_formspec(100, 0)
end



compressor.on_punch =
function(pos, node, puncher, pointed_thing)
  machines.initialize_typedata(pos, "compressor:inactive", "mv")
  compressor.trigger_update(pos)
end



compressor.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("dst") and
    inv:is_empty("src") and
    inv:is_empty("cfg") and
    inv:is_empty("upg")
end



compressor.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    "mesefuel", "fuel", "src", "dst", "cfg", "upg")
end



compressor.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return compressor.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



compressor.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  return stack:get_count()
end



local MACHINE_DATA = {
  name = "Compressor",
  method = "compressing",
  demand = 200,
  swap = {
    inactive = "compressor:inactive",
    active = "compressor:active",
  },
  form = {
    inactive = compressor.get_inactive_formspec,
    active = compressor.get_active_formspec,
  },
  fuel = "mesefuel",
  processable = "Compressable",
}

compressor.on_timer = function(pos, elapsed)
  machines.log_update(pos, "Compressor")
  return machines.on_machine_timer(pos, elapsed, MACHINE_DATA)
end



compressor.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  default.get_inventory_drops(pos, "upg", drops)
  drops[#drops+1] = "compressor:inactive"
  minetest.remove_node(pos)
  return drops
end



compressor.on_construct = 
function(pos)
end

compressor.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  machines.initialize_typedata(pos, "compressor:inactive", "mv")
  machines.after_place_machine(pos, placer, "Compressor", 1, compressor.get_inactive_formspec)
end



compressor.on_metadata_inventory_move = function(pos)
  compressor.trigger_update(pos)
end



compressor.on_metadata_inventory_put = 
function(pos)
  compressor.trigger_update(pos)
end



compressor.on_metadata_inventory_take = 
function(pos)
  compressor.trigger_update(pos)
end



compressor.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



if not compressor.run_once then
  for k, v in ipairs({
    {name="inactive", light=0, tile="compressor_front.png"},
    {name="active", light=8, tile="compressor_front_active.png"},
  }) do
    minetest.register_node("compressor:" .. v.name, {
      description = "Compressor",
      tiles = {
        "compressor_top.png", "compressor_top.png",
        "compressor_side.png", "compressor_side.png",
        "compressor_side.png", v.tile,
      },
      
      groups = utility.dig_groups("machine", {
        tubedevice = 1, tubedevice_receiver = 1,
        immovable = 1,
        tier_mv = 1,
      }),
      
      light_source = v.light,
      paramtype2 = "facedir",
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "comp2:mv_inactive",

      can_dig = function(...)
        return compressor.can_dig(...) end,
      on_timer = function(...)
        return compressor.on_timer(...) end,
      on_construct = function(...)
        return compressor.on_construct(...) end,
      after_place_node = function(...)
        return compressor.after_place_node(...) end,
      on_punch = function(...)
        return compressor.on_punch(...) end,
      on_metadata_inventory_move = function(...)
        return compressor.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return compressor.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return compressor.on_metadata_inventory_take(...) end,
      on_blast = function(...)
        return compressor.on_blast(...) end,
      allow_metadata_inventory_put = function(...)
        return compressor.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return compressor.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return compressor.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end



  minetest.register_craft({
    output = 'comp2:lv_inactive',
    recipe = {
      {'cast_iron:ingot', 'techcrafts:electric_motor', 'cast_iron:ingot'},
      {'default:obsidian_block', 'techcrafts:machine_casing', 'default:obsidian_block'},
      {'fine_wire:silver', 'techcrafts:electric_motor', 'fine_wire:silver'},
    }
  })

	minetest.register_craft({
		output = 'comp2:mv_inactive',
		recipe = {
			{'stainless_steel:ingot', 'comp2:lv_inactive',  'stainless_steel:ingot'},
			{'techcrafts:copper_plate',              'transformer:mv', 'techcrafts:carbon_plate'},
			{'stainless_steel:ingot', 'cb2:mv',       'stainless_steel:ingot'},
		}
	})



  minetest.register_craft({
    type = "compressing",
    output = "default:ice",
    recipe = "default:snowblock",
    time = 4,
  })

  minetest.register_craft({
    type = "compressing",
    output = "default:desert_stone",
    recipe = "default:desert_sandstone 2",
    time = 16,
  })

  minetest.register_craft({
    type = "compressing",
    output = "default:stone",
    recipe = "default:sandstone 2",
    time = 16,
  })

  minetest.register_craft({
    type = "compressing",
    output = "default:sandstone",
    recipe = "default:sand 2",
    time = 16,
  })

  minetest.register_craft({
    type = "compressing",
    output = "default:desert_sandstone",
    recipe = "default:desert_sand 2",
    time = 16,
  })

  minetest.register_craft({
    type = "compressing",
    output = "default:silver_sandstone",
    recipe = "default:silver_sand 2",
    time = 16,
  })

  local c = "compressor:core"
  local f = compressor.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(compressor.modpath .. "/v2.lua")
  compressor.run_once = true
end

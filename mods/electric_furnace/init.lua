
electric_furnace = electric_furnace or {}
electric_furnace.modpath = minetest.get_modpath("electric_furnace")



-- Get active formspec.
electric_furnace.get_active_formspec = function(fuel_percent, item_percent)
  local formspec = 
    "size[8,8.5]"..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors() ..
    
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
    
    "listring[context;dst]"..
    "listring[current_player;main]"..
    "listring[context;src]"..
    "listring[current_player;main]"..
    "listring[context;fuel]"..
    "listring[current_player;main]"..
    default.get_hotbar_bg(0, 4.25)
  return formspec
end



electric_furnace.get_inactive_formspec = function()
  return electric_furnace.get_active_formspec(100, 0)
end

electric_furnace.on_punch = 
function(pos, node, puncher, pointed_thing)
  machines.initialize_typedata(pos, "electric_furnace:inactive", "mv")
  electric_furnace.trigger_update(pos)
end

electric_furnace.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(1.0)
  end
end



electric_furnace.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and
    inv:is_empty("dst") and
    inv:is_empty("src") and
    inv:is_empty("cfg") and
    inv:is_empty("upg")
end



electric_furnace.allow_metadata_inventory_put = 
function(pos, listname, index, stack, player)
  return machines.allow_metadata_inventory_put(
    pos, listname, index, stack, player,
    "mesefuel", "fuel", "src", "dst", "cfg", "upg")
end



electric_furnace.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return electric_furnace.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



electric_furnace.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  if minetest.test_protection(pos, pname) then
    return 0
  end
  return stack:get_count()
end



local MACHINE_DATA = {
  name = "Electric Furnace",
  method = "cooking",
  demand = 300,
  swap = {
    inactive = "electric_furnace:inactive",
    active = "electric_furnace:active",
  },
  form = {
    inactive = electric_furnace.get_inactive_formspec,
    active = electric_furnace.get_active_formspec,
  },
  fuel = "mesefuel",
  processable = "Smeltable",
}

electric_furnace.on_timer = function(pos, elapsed)
  machines.log_update(pos, "Furnace")
  return machines.on_machine_timer(pos, elapsed, MACHINE_DATA)
end



electric_furnace.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  default.get_inventory_drops(pos, "cfg", drops)
  default.get_inventory_drops(pos, "upg", drops)
  drops[#drops+1] = "electric_furnace:inactive"
  minetest.remove_node(pos)
  return drops
end



electric_furnace.on_construct = 
function(pos)
end

electric_furnace.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  machines.initialize_typedata(pos, "electric_furnace:inactive", "mv")
  machines.after_place_machine(pos, placer, "Electric Furnace", 1, electric_furnace.get_inactive_formspec)
end



electric_furnace.on_metadata_inventory_move = function(pos)
  electric_furnace.trigger_update(pos)
end



electric_furnace.on_metadata_inventory_put = function(pos)
  electric_furnace.trigger_update(pos)
end



electric_furnace.on_metadata_inventory_take = function(pos)
  electric_furnace.trigger_update(pos)
end



if not electric_furnace.run_once then
  for k, v in ipairs({
    {name="inactive", light=0, tile="electric_furnace_front.png"},
    {name="active", light=8, tile="electric_furnace_front_active.png"},
  }) do
    minetest.register_node("electric_furnace:" .. v.name, {
      description = "Electric Furnace",
      tiles = {
        "electric_furnace_top.png", "electric_furnace_bottom.png",
        "electric_furnace_side.png", "electric_furnace_side.png",
        "electric_furnace_side.png", v.tile,
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
      drop = "ecfurn2:mv_inactive",

      can_dig = function(...)
        return electric_furnace.can_dig(...) end,
      on_timer = function(...)
        return electric_furnace.on_timer(...) end,
      on_construct = function(...)
        return electric_furnace.on_construct(...) end,
      after_place_node = function(...)
        return electric_furnace.after_place_node(...) end,
      on_punch = function(...)
        return electric_furnace.on_punch(...) end,
      on_metadata_inventory_move = function(...)
        return electric_furnace.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return electric_furnace.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return electric_furnace.on_metadata_inventory_take(...) end,
      on_blast = function(...)
        return electric_furnace.on_blast(...) end,
      allow_metadata_inventory_put = function(...)
        return electric_furnace.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return electric_furnace.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return electric_furnace.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end

  minetest.register_craft({
    output = 'ecfurn2:lv_inactive',
    recipe = {
      {'stainless_steel:ingot', 'cobble_furnace:inactive', 'stainless_steel:ingot'},
      {'default:stone', 'techcrafts:machine_casing','default:stone'},
      {'stainless_steel:ingot', 'transformer:lv', 'stainless_steel:ingot'},
    }
  })
  
	minetest.register_craft({
		output = 'ecfurn2:mv_inactive',
		recipe = {
			{'stainless_steel:ingot', 'ecfurn2:lv_inactive', 'stainless_steel:ingot'},
			{'techcrafts:composite_plate',              'transformer:mv',      'techcrafts:machine_casing'},
			{'stainless_steel:ingot', 'cb2:mv',            'stainless_steel:ingot'},
		}
	})

	minetest.register_craft({
		output = 'ecfurn2:hv_inactive',
		recipe = {
			{'stainless_steel:ingot', 'ecfurn2:mv_inactive', 'stainless_steel:ingot'},
			{'techcrafts:composite_plate',              'transformer:hv',      'techcrafts:composite_plate'},
			{'stainless_steel:ingot', 'cb2:hv',            'stainless_steel:ingot'},
		}
	})

  local c = "electric_furnace:core"
  local f = electric_furnace.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(electric_furnace.modpath .. "/v2.lua")
  electric_furnace.run_once = true
end

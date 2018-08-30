
converter = converter or {}
converter.modpath = minetest.get_modpath("converter")

dofile(converter.modpath .. "/functions.lua")



if not converter.run_once then
  minetest.register_node("converter:converter", {
    description = "Supply Converter",
    tiles = {
      "converter_top.png", "converter_top.png",
      "converter_side.png", "converter_side.png",
      "converter_side.png", "converter_side.png",
    },
    
    groups = {
      level=1, cracky=3,
      immovable = 1,
      tier_lv = 1, tier_mv = 1, tier_hv = 1,
    },
		drop = "conv2:converter",
    
    paramtype2 = "facedir",
    on_rotate = function(...) return screwdriver.rotate_simple(...) end,
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    
    on_punch = function(...)
      return converter.on_punch(...) end,
    can_dig = function(...)
      return converter.can_dig(...) end,
    on_timer = function(...)
      return converter.on_timer(...) end,
    on_construct = function(...)
      return converter.on_construct(...) end,
    after_place_node = function(...)
      return converter.after_place_node(...) end,
    on_metadata_inventory_move = function(...)
      return converter.on_metadata_inventory_move(...) end,
    on_metadata_inventory_put = function(...)
      return converter.on_metadata_inventory_put(...) end,
    on_metadata_inventory_take = function(...)
      return converter.on_metadata_inventory_take(...) end,
    on_blast = function(...)
      return converter.on_blast(...) end,
    on_destruct = function(...)
      return converter.on_destruct(...) end,
    allow_metadata_inventory_put = function(...)
      return converter.allow_metadata_inventory_put(...) end,
    allow_metadata_inventory_move = function(...)
      return converter.allow_metadata_inventory_move(...) end,
    allow_metadata_inventory_take = function(...)
      return converter.allow_metadata_inventory_take(...) end,
    on_machine_execute = function(...)
      return converter.on_machine_execute(...) end,
  })
  
  minetest.register_craft({
    output = 'conv2:converter',
    recipe = {
      {'rubber:rubber_fiber', 'transformer:hv', 'rubber:rubber_fiber'},
      {'transformer:mv', 'techcrafts:machine_casing', 'transformer:lv'},
      {'cb2:mv', 'cb2:hv', 'cb2:lv'},
    }
  })

  local c = "converter:core"
  local f = converter.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(converter.modpath .. "/conv2.lua")
  converter.run_once = true
end

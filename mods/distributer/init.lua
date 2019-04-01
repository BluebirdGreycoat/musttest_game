
distributer = distributer or {}
distributer.modpath = minetest.get_modpath("distributer")

dofile(distributer.modpath .. "/functions.lua")
dofile(distributer.modpath .. "/v2.lua")



-- Currently this just tells the network operator how much power is in the network.
-- It also signals machine controlers when a change happens.
minetest.register_node("distributer:distributer", {
  description = "Network EU Observer",
  tiles = {
    "technic_supply_converter_top.png", "technic_supply_converter_top.png",
    "technic_supply_converter_side.png", "technic_supply_converter_side.png",
    "technic_supply_converter_side.png", "technic_supply_converter_side.png"
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
    return distributer.on_punch(...) end,
  can_dig = function(...)
    return distributer.can_dig(...) end,
  on_timer = function(...)
    return distributer.on_timer(...) end,
  on_construct = function(...)
    return distributer.on_construct(...) end,
  after_place_node = function(...)
    return distributer.after_place_node(...) end,

  on_metadata_inventory_move = function(...)
    return distributer.on_metadata_inventory_move(...) end,
  on_metadata_inventory_put = function(...)
    return distributer.on_metadata_inventory_put(...) end,
  on_metadata_inventory_take = function(...)
    return distributer.on_metadata_inventory_take(...) end,
  on_blast = function(...)
    return distributer.on_blast(...) end,

  allow_metadata_inventory_put = function(...)
    return distributer.allow_metadata_inventory_put(...) end,
  allow_metadata_inventory_move = function(...)
    return distributer.allow_metadata_inventory_move(...) end,
  allow_metadata_inventory_take = function(...)
    return distributer.allow_metadata_inventory_take(...) end,
  
  on_machine_execute = function(...)
    return distributer.on_machine_execute(...) end,
})



-- Remove from craft-guide. Needs repurposing.
--[[
minetest.register_craft({
  output = 'distributer:distributer',
  recipe = {
    {'fine_wire:gold', 'rubber:rubber_fiber', 'silicon:doped_wafer'},
    {'cb2:lv', 'techcrafts:machine_casing', 'cb2:lv'},
    {'techcrafts:control_logic_unit', 'rubber:rubber_fiber', 'fine_wire:silver'},
  }
})
--]]

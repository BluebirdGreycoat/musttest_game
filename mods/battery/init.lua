
battery = battery or {}
battery.modpath = minetest.get_modpath("battery")

dofile(battery.modpath .. "/functions.lua")
dofile(battery.modpath .. "/battery.lua")
dofile(battery.modpath .. "/bat2.lua")



-- The battery array is basically a box with slots in which batteries
-- can be placed, thus giving it the ability to store energy. The box
-- provides the wiring so all the batteries can be accessed as a unit.
for k, v in ipairs({
  {tier="lv", title="Low-Voltage"},
  {tier="mv", title="Medium-Voltage"},
  {tier="hv", title="High-Voltage"},
}) do
  -- Register 13 nodes for each tier; each node has a different texture set to show the charge level.
  for i = 0, 12, 1 do
    -- Which function table are we operating on?
    local functable = _G["battery_" .. v.tier]
  
    minetest.register_node("battery:array" .. i .. "_" .. v.tier, {
      description = v.title .. " Battery Array",
      tiles = {
        "technic_" .. v.tier .. "_battery_box_top.png",
        "technic_" .. v.tier .. "_battery_box_bottom.png",
        "technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
        "technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
        "technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
        "technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
      },
      
      groups = {
        level=1, cracky=3,
        immovable = 1,
        ["tier_" .. v.tier] = 1,
      },
      
      paramtype2 = "facedir",
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "bat2:bt0_" .. v.tier,
      
      on_punch = function(...)
        return functable.on_punch(...) end,
      can_dig = function(...)
        return functable.can_dig(...) end,
      on_timer = function(...)
        return functable.on_timer(...) end,
      on_construct = function(...)
        return functable.on_construct(...) end,
      after_place_node = function(...)
        return functable.after_place_node(...) end,

      on_metadata_inventory_move = function(...)
        return functable.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return functable.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return functable.on_metadata_inventory_take(...) end,
        
      on_blast = function(...)
        return functable.on_blast(...) end,

      allow_metadata_inventory_put = function(...)
        return functable.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return functable.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return functable.allow_metadata_inventory_take(...) end,
        
      on_machine_execute = function(...)
        return functable.on_machine_execute(...) end,
    })
    -- Alias old non-tiered nodes to tiered nodes.
    if v.tier == "lv" then
      minetest.register_alias("battery:array" .. i, "battery:array" .. i .. "_lv")
    end
  end
end

minetest.register_alias("battery:lv_battery", "battery:array0_lv")
minetest.register_alias("battery:array", "battery:array0_lv")



minetest.register_craft({
  output = 'bat2:bt0_lv',
  recipe = {
    {'group:wood', 'transformer:lv', 'group:wood'},
    {'rubber:rubber_fiber', 'techcrafts:machine_casing', 'rubber:rubber_fiber'},
    {'fine_wire:copper', 'cb2:lv', 'fine_wire:copper'},
  }
})

minetest.register_craft({
  output = 'bat2:bt0_mv',
  recipe = {
    {'bat2:bt0_lv', 'transformer:mv', 'bat2:bt0_lv'},
    {'rubber:rubber_fiber', 'techcrafts:machine_casing', 'rubber:rubber_fiber'},
    {'fine_wire:silver', 'cb2:mv', 'fine_wire:silver'},
  }
})

minetest.register_craft({
  output = 'bat2:bt0_hv',
  recipe = {
    {'bat2:bt0_mv', 'transformer:hv', 'bat2:bt0_mv'},
    {'rubber:rubber_fiber', 'techcrafts:machine_casing', 'rubber:rubber_fiber'},
    {'fine_wire:gold', 'cb2:hv', 'fine_wire:gold'},
  }
})

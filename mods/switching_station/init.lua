
switching_station = switching_station or {}
switching_station.modpath = minetest.get_modpath("switching_station")

dofile(switching_station.modpath .. "/shared.lua")

if not switching_station.run_once then
  for k, v in ipairs({
    {tier="hv", name="High-Voltage"},
    {tier="mv", name="Medium-Voltage"},
    {tier="lv", name="Low-Voltage"},
  }) do
    -- Which function table are we operating on?
    local functable = _G["switching_station_" .. v.tier]
    
    minetest.register_node("switching_station:" .. v.tier, {
      description = v.name .. " Cable Box",
      tiles = {"switching_station_" .. v.tier .. ".png"},
      
      groups = {
        level=1, cracky=3,
        immovable = 1,
        ["tier_" .. v.tier] = 1,
      },
			drop = "stat2:" .. v.tier,
      
      paramtype2 = "facedir",
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      
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
      on_destruct = function(...)
        return functable.on_destruct(...) end,
      allow_metadata_inventory_put = function(...)
        return functable.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return functable.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return functable.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return functable.on_machine_execute(...) end,
    })
  end
  
  minetest.register_alias("switching_station:switching_station", "switching_station:hv")
  
  for k, v in ipairs({
    {chest="chests:chest_public_closed"},
    {chest="morechests:woodchest_public_closed"},
  }) do
    minetest.register_craft({
      output = "stat2:lv",
      recipe = {
        {'plastic:plastic_sheeting', 'cb2:lv', 'plastic:plastic_sheeting'},
        {'plastic:plastic_sheeting', v.chest, 'plastic:plastic_sheeting'},
        {'plastic:plastic_sheeting', 'cb2:lv', 'plastic:plastic_sheeting'},
      },
    })
  end

    minetest.register_craft({
      output = "stat2:mv",
      recipe = {
        {'plastic:plastic_sheeting', 'cb2:mv', 'plastic:plastic_sheeting'},
        {'plastic:plastic_sheeting', 'stat2:lv', 'plastic:plastic_sheeting'},
        {'plastic:plastic_sheeting', 'cb2:mv', 'plastic:plastic_sheeting'},
      },
    })

    minetest.register_craft({
      output = "stat2:hv",
      recipe = {
        {'plastic:plastic_sheeting', 'cb2:hv', 'plastic:plastic_sheeting'},
        {'plastic:plastic_sheeting', 'stat2:mv', 'plastic:plastic_sheeting'},
        {'plastic:plastic_sheeting', 'cb2:hv', 'plastic:plastic_sheeting'},
      },
    })

  local c = "switching_station:core"
  local f = switching_station.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
	dofile(switching_station.modpath .. "/stat2.lua")
  switching_station.run_once = true
end

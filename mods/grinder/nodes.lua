
if not minetest.global_exists("grinder") then grinder = {} end

if not grinder.nodes_registered then
  for k, v in ipairs({
    {name="inactive", light=0, tile="grinder_front.png"},
    {name="active", light=8, tile="grinder_front_active.png"},
  }) do
    minetest.register_node("grinder:" .. v.name, {
      description = "Electric Grinder",
      tiles = {
        "grinder_top.png",  "grinder_bottom.png",
        "grinder_side.png", "grinder_side.png",
        "grinder_side.png", v.tile,
      },

      paramtype2 = "facedir",
      groups = utility.dig_groups("machine", {
        tubedevice = 1, tubedevice_receiver = 1,
        immovable = 1,
        tier_mv = 1,
      }),
      
      light_source = v.light,
      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "grind2:mv_inactive",

      can_dig = function(...)       
        return grinder.can_dig(...) end,
      on_timer = function(...)      
        return grinder.on_timer(...) end,
      on_construct = function(...)  
        return grinder.on_construct(...) end,
      on_blast = function(...)      
        return grinder.on_blast(...) end,
      on_punch = function(...)      
        return grinder.on_punch(...) end,
      after_place_node = function(...)
        return grinder.after_place_node(...) end,
      on_metadata_inventory_move = function(...)
        return grinder.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return grinder.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return grinder.on_metadata_inventory_take(...) end,
      allow_metadata_inventory_put = function(...)
        return grinder.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return grinder.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return grinder.allow_metadata_inventory_take(...) end,
      on_machine_execute = function(...)
        return machines.on_machine_execute(...) end,
    })
  end

  minetest.register_alias("grinder:grinder", "grinder:inactive")
  minetest.register_alias("grinder:grinder_active", "grinder:active")
  grinder.nodes_registered = true
end


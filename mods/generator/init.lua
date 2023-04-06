
if not minetest.global_exists("generator") then generator = {} end
generator.modpath = minetest.get_modpath("generator")

dofile(generator.modpath .. "/functions.lua")
dofile(generator.modpath .. "/generator.lua")


for k, v in ipairs({
  {name="inactive", tile="generator_mv_front.png", light=0},
  {name="active", tile="generator_mv_front_active.png", light=8},
}) do
  minetest.register_node("generator:" .. v.name, {
    description = "LV/MV Power Generator",
    tiles = {
      "generator_mv_top.png", "generator_mv_bottom.png",
      "generator_mv_side.png", "generator_mv_side.png",
      "generator_mv_side.png", v.tile,
    },
    
    groups = utility.dig_groups("machine", {
      immovable = 1,
      tier_lv = 1, tier_mv = 1,
    }),
    
    paramtype2 = "facedir",
    on_rotate = function(...) return screwdriver.rotate_simple(...) end,
    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),
    drop = "gen2:mv_inactive",
    light_source = v.light,
    
    on_punch = function(...)
      return generator.on_punch(...) end,
    can_dig = function(...)
      return generator.can_dig(...) end,
    on_timer = function(...)
      return generator.on_timer(...) end,
    on_construct = function(...)
      return generator.on_construct(...) end,
    after_place_node = function(...)
      return generator.after_place_node(...) end,

    on_metadata_inventory_move = function(...)
      return generator.on_metadata_inventory_move(...) end,
    on_metadata_inventory_put = function(...)
      return generator.on_metadata_inventory_put(...) end,
    on_metadata_inventory_take = function(...)
      return generator.on_metadata_inventory_take(...) end,
    on_blast = function(...)
      return generator.on_blast(...) end,

    allow_metadata_inventory_put = function(...)
      return generator.allow_metadata_inventory_put(...) end,
    allow_metadata_inventory_move = function(...)
      return generator.allow_metadata_inventory_move(...) end,
    allow_metadata_inventory_take = function(...)
      return generator.allow_metadata_inventory_take(...) end,
      
    on_machine_execute = function(...)
      return machines.on_machine_execute(...) end,
  })
end



minetest.register_craft({
  output = 'gen2:lv_inactive',
  recipe = {
    {'default:steel_ingot', 'cobble_furnace:inactive', 'default:steel_ingot'},
    {'techcrafts:copper_coil', 'techcrafts:machine_casing', 'techcrafts:copper_coil'},
    {'default:steel_ingot', 'techcrafts:electric_motor', 'default:steel_ingot'},
  },
})

minetest.register_craft({
	output = 'gen2:mv_inactive',
	recipe = {
		{'stainless_steel:ingot', 'gen2:lv_inactive',   'stainless_steel:ingot'},
		{'default:stonebrick',              'transformer:mv', 'default:stonebrick'},
		{'stainless_steel:ingot', 'cb2:mv',       'stainless_steel:ingot'},
	}
})

minetest.register_craft({
	output = 'gen2:hv_inactive',
	recipe = {
		{'techcrafts:carbon_plate',          'gen2:mv_inactive',   'techcrafts:composite_plate'},
		{'default:stonebrick',              'transformer:hv', 'default:stonebrick'},
		{'stainless_steel:ingot', 'cb2:hv',       'stainless_steel:ingot'},
	}
})

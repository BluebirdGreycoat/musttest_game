
-- Kalite: a coal substitute.

minetest.register_node("kalite:ore", {
  description = "Kalite Ore",
  tiles = {"default_stone.png^gloopores_mineral_kalite.png"},
  groups = utility.dig_groups("mineral"),
  drop = {
    max_items = 4,
    items = {
      {
        items = {'kalite:lump'},
        rarity = 5,
      },
      {
        items = {'kalite:lump'},
        rarity = 2,
      },
      {
        items = {'kalite:lump 2'},
      },
    }
  },
  sounds = default.node_sound_stone_defaults(),

	-- Digging kalite has a chance to release poison gas.
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if pos.y < -1024 then
			if math.random(1, 300) == 1 then
				breath.spawn_gas(pos)
			end
		end
	end,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "kalite:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -25000,
  y_max       = 300,
})

minetest.register_craftitem("kalite:lump", {
  description = "Kalite Lump",
  inventory_image = "gloopores_kalite_lump.png",
})

minetest.register_craftitem("kalite:dust", {
  description = "Kalite Dust",
  inventory_image = "technic_kalite_dust.png"
})

minetest.register_craft({
  type = "grinding",
  output = 'kalite:dust 2',
  recipe = 'kalite:lump',
  time = 10,
})

minetest.register_craftitem("kalite:ingot", {
  description = "Compressed Kalite",
  inventory_image = "glooptest_compressed_kalite.png",
  -- Intentionally NOT in `ingot` group, because it's not metalic.
})

minetest.register_craft({
  type = "compressing",
  output = "kalite:ingot",
  recipe = "kalite:lump 4",
  time = 10,
})

minetest.register_craft({
  type = "compressing",
  output = "kalite:ingot",
  recipe = "kalite:dust 8",
  time = 10,
})

minetest.register_craft({
  type = "grinding",
  output = 'kalite:dust 8',
  recipe = 'kalite:ingot',
  time = 10,
})

minetest.register_craft({
  type = "shapeless",
  output = 'kalite:dust',
  recipe = {'kalite:lump', 'kalite:lump'}
})

minetest.register_craft({
  type = "fuel",
  recipe = "kalite:lump",
  burntime = 40,
})

minetest.register_craft({
  type = "coalfuel",
  recipe = "kalite:lump",
  burntime = 40,
})

minetest.register_craft({
  type = "fuel",
  recipe = "kalite:ingot",
  burntime = 220, -- A bit more than 40*4, and more than burning dusts.
})

minetest.register_craft({
  type = "coalfuel",
  recipe = "kalite:ingot",
  burntime = 220, -- A bit more than 40*4, and more than burning dusts.
})

minetest.register_craft({
  type = "fuel",
  recipe = "kalite:dust",
  burntime = 25, -- A bit more than 1/2 of lump's burntime.
  -- This makes it better to burn kalite dust than kalite lumps.
})
  
minetest.register_craft({
  type = "coalfuel",
  recipe = "kalite:dust",
  burntime = 25, -- A bit more than 1/2 of lump's burntime.
  -- This makes it better to burn kalite dust than kalite lumps.
})

minetest.register_craft({
  type = "shapeless",
  output = "dye:red",
  recipe = {"kalite:dust"},
})

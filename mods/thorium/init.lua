minetest.register_node("thorium:ore", {
  description = "Thorium Ore",
  tiles = {"default_stone.png^technic_thorium_mineral.png"},
  groups = utility.dig_groups("mineral", {melts = 1, ore = 1}),
  drop = "thorium:lump",
  sounds = default.node_sound_stone_defaults(),
	silverpick_drop = true,
	
	-- thorium ore reacts like uranium ore with respect to lava, only less violently.
	on_melt = function(pos, other)
		minetest.after(0, function()
      tnt.boom(pos, {
        radius = 2,
        ignore_protection = false,
        ignore_on_blast = false,
        damage_radius = 3,
        disable_drops = true,
      })
		end)
	end,
})

minetest.register_node("thorium:block", {
  description = "Thorium Block",
  tiles = {"technic_thorium_block.png"},
  groups = utility.dig_groups("block"),
  sounds = default.node_sound_metal_defaults(),
})

minetest.register_craftitem("thorium:lump", {
  description = "Thorium Ore Lump",
  inventory_image = "technic_thorium_lump.png",
})

minetest.register_craftitem("thorium:ingot", {
	description = "Thorium Ingot",
	inventory_image = "technic_thorium_ingot.png",
	groups = {ingot = 1},
})

minetest.register_craftitem("thorium:dust", {
	description = "Thorium Dust",
	inventory_image = "technic_thorium_dust.png",
})



minetest.register_craft({
  type = "cooking",
  output = "thorium:ingot",
  recipe = "thorium:lump",
})

minetest.register_craft({
  type = "cooking",
  output = "thorium:ingot",
  recipe = "thorium:dust",
})

minetest.register_craft({
  type = "grinding",
  output = 'thorium:dust 2',
  recipe = 'thorium:lump',
  time = 6,
})

minetest.register_craft({
  type = "grinding",
  output = 'thorium:dust',
  recipe = 'thorium:ingot',
  time = 20,
})


minetest.register_craft({
	output = "thorium:block",
	recipe = {
		{"thorium:ingot", "thorium:ingot", "thorium:ingot"},
		{"thorium:ingot", "thorium:ingot", "thorium:ingot"},
		{"thorium:ingot", "thorium:ingot", "thorium:ingot"},
	},
})

minetest.register_craft({
	type = "shapeless",
	output = "thorium:ingot 9",
	recipe = {"thorium:block"},
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "thorium:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -700,
  y_max       = -400,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "thorium:ore",
  wherein          = "default:stone",
  clust_scarcity   = 6*6*6,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -800,
  y_max       = -600,
})


minetest.register_craftitem("thorium:rod", {
  description = "Fission Reactor Thorium Fuel Rod",
  inventory_image = "technic_thorium_fuel.png",
	stack_max = 1,
})

minetest.register_craft({
  type = "compressing",
  output = "thorium:rod",
  recipe = "thorium:ingot 16",
  time = 80,
})


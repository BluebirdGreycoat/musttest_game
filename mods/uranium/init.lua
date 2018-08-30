
minetest.register_node("uranium:ore", {
  description = "Uranium Ore",
  tiles = {"default_stone.png^technic_uranium_mineral.png"},
  groups = {level = 1, cracky = 3, melts = 1},
  drop = "uranium:lump",
  sounds = default.node_sound_stone_defaults(),
	
	-- Uranium in stone reacts badly to lava.
	on_melt = function(pos, other)
		minetest.after(0, function()
      tnt.boom(pos, {
        radius = 4,
        ignore_protection = false,
        ignore_on_blast = false,
        damage_radius = 6,
        disable_drops = true,
      })
		end)
	end,
})

minetest.register_node("uranium:block", {
  description = "Uranium Block (Not Radioactive)",
  tiles = {"technic_uranium_block.png"},
  groups = {level = 1, cracky = 3},
  sounds = default.node_sound_stone_defaults(),
})

minetest.register_craftitem("uranium:lump", {
  description = "Uranium Lump",
  inventory_image = "technic_uranium_lump.png",
})

minetest.register_craftitem("uranium:ingot", {
	description = "Uranium Ingot",
	inventory_image = "technic_uranium_ingot.png",
	groups = {ingot = 1},
})

minetest.register_craftitem("uranium:ingot_enriched", {
	description = "Enriched Uranium Ingot",
	inventory_image = "technic_uranium_ingot.png",
	groups = {ingot = 1},
})

minetest.register_craftitem("uranium:ingot_waste", {
	description = "Uranium Ingot (Waste)",
	inventory_image = "technic_uranium_ingot.png",
	groups = {ingot = 1},
})

minetest.register_craftitem("uranium:dust", {
	description = "Uranium Dust",
	inventory_image = "technic_uranium_dust.png",
})

minetest.register_craftitem("uranium:dust_enriched", {
	description = "Enriched Uranium Dust",
	inventory_image = "technic_uranium_dust.png",
})

minetest.register_craftitem("uranium:dust_waste", {
	description = "Uranium Dust (Waste)",
	inventory_image = "technic_uranium_dust.png",
})

minetest.register_craft({
  type = "cooking",
  output = "uranium:ingot",
  recipe = "uranium:lump",
})

minetest.register_craft({
  type = "cooking",
  output = "uranium:ingot",
  recipe = "uranium:dust",
})

minetest.register_craft({
  type = "cooking",
  output = "uranium:ingot_waste",
  recipe = "uranium:dust_waste",
})

minetest.register_craft({
  type = "cooking",
  output = "uranium:ingot_enriched",
  recipe = "uranium:dust_enriched",
})

minetest.register_craft({
  type = "grinding",
  output = 'uranium:dust 2',
  recipe = 'uranium:lump',
  time = 6,
})

minetest.register_craft({
  type = "grinding",
  output = 'uranium:dust',
  recipe = 'uranium:ingot',
  time = 20,
})

minetest.register_craft({
  type = "grinding",
  output = 'uranium:dust_waste',
  recipe = 'uranium:ingot_waste',
  time = 20,
})

minetest.register_craft({
  type = "grinding",
  output = 'uranium:dust_enriched',
  recipe = 'uranium:ingot_enriched',
  time = 20,
})

minetest.register_craft({
	output = "uranium:block",
	recipe = {
		{"uranium:ingot_waste", "uranium:ingot_waste", "uranium:ingot_waste"},
		{"uranium:ingot_waste", "uranium:ingot_waste", "uranium:ingot_waste"},
		{"uranium:ingot_waste", "uranium:ingot_waste", "uranium:ingot_waste"},
	},
})

minetest.register_craft({
	type = "shapeless",
	output = "uranium:ingot_waste 9",
	recipe = {"uranium:block"},
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "uranium:ore",
  wherein          = "default:stone",
  clust_scarcity   = 8*8*8,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -800,
  y_max       = -500,
})

oregen.register_ore({
  ore_type         = "scatter",
  ore              = "uranium:ore",
  wherein          = "default:stone",
  clust_scarcity   = 6*6*6,
  clust_num_ores   = 2,
  clust_size       = 3,
  y_min       = -900,
  y_max       = -700,
})

-- Refining uranium takes a lot of material and produces mostly waste.
minetest.register_craft({
	type = "separating",
	output = {"uranium:dust_waste 7", "uranium:dust_enriched"},
	recipe = "uranium:dust 8",
})

minetest.register_craftitem("uranium:rod", {
  description = "Fission Reactor Fuel Rod",
  inventory_image = "technic_uranium_fuel.png",
	stack_max = 1,
})

minetest.register_craft({
  type = "compressing",
  output = "uranium:rod",
  recipe = "uranium:ingot_enriched 12",
  time = 60,
})

-- Get rid of uranium blocks.
-- Having uranium blocks in the world means the heat-damage code has to worry about them,
-- which increases CPU demand.
for i = 0, 35, 1 do
	local newname = "default:stone"
	local oldname = "uranium:block_" .. i
	minetest.register_alias(oldname, newname)
end

-- Get rid of those multiple fissile levels. Players say it feels like punishment.
for i = 0, 35, 1 do
	local ingotname = "uranium:ingot_" .. i
	local dustname = "uranium:dust_" .. i

	minetest.register_alias(ingotname, "uranium:ingot")
	minetest.register_alias(dustname, "uranium:dust")
end

-- Remove corium.
minetest.register_alias("corium:chernobylite", "default:stone")
minetest.register_alias("corium:flowing", "default:lava_flowing")
minetest.register_alias("corium:source", "default:lava_source")


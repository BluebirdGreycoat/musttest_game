
minetest.register_craftitem("dusts:iron", {
  description = "Wrought Iron Shavings",
  inventory_image = "grinder_iron_dust.png"
})

minetest.register_craftitem("dusts:copper", {
  description = "Copper Shavings",
  inventory_image = "grinder_copper_dust.png"
})

minetest.register_craftitem("dusts:gold", {
  description = "Gold Dust",
  inventory_image = "grinder_gold_dust.png"
})

minetest.register_craftitem("dusts:coal", {
  description = "Coal Powder",
  inventory_image = "grinder_coal_dust.png"
})

minetest.register_craftitem("dusts:diamond_shard", {
  description = "Diamond Shard",
  inventory_image = "grinder_diamond_shard.png"
})

minetest.register_craftitem("dusts:diamond", {
  description = "Diamond Fragments",
  inventory_image = "grinder_diamond_dust.png"
})

minetest.register_craftitem("dusts:tin", {
  description = "Tin Shavings",
  inventory_image = "grinder_tin_dust.png"
})

minetest.register_craftitem("dusts:silver", {
  description = "Silver Dust",
  inventory_image = "grinder_silver_dust.png"
})

minetest.register_craftitem("dusts:mithril", {
  description = "Mithril Dust",
  inventory_image = "grinder_mithril_dust.png"
})



-- Compatibility.
minetest.register_alias("grinder:diamond_shard", "dusts:diamond_shard")
minetest.register_alias("grinder:diamond_dust",  "dusts:diamond")
minetest.register_alias("grinder:coal_dust",     "dusts:coal")
minetest.register_alias("grinder:gold_dust",     "dusts:gold")
minetest.register_alias("grinder:copper_dust",   "dusts:copper")
minetest.register_alias("grinder:iron_dust",     "dusts:iron")
minetest.register_alias("grinder:tin_dust",      "dusts:tin")
minetest.register_alias("grinder:silver_dust",   "dusts:silver")
minetest.register_alias("grinder:mithril_dust",  "dusts:mithril")



minetest.register_craft({
  type = "grinding",
  output = 'dusts:iron 2',
  recipe = 'default:iron_lump',
  time = 8,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:iron',
  recipe = 'default:steel_ingot',
  time = 8,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:copper 2',
  recipe = 'default:copper_lump',
  time = 8,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:copper',
  recipe = 'default:copper_ingot',
  time = 8,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:gold 2',
  recipe = 'default:gold_lump',
  time = 7,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:gold',
  recipe = 'default:gold_ingot',
  time = 7,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:coal 2',
  recipe = 'default:coal_lump',
  time = 7,
})

-- It needs to be possible to obtain coal dust by hand,
-- otherwise whole branches of the tech tree are unreachable
-- due to circular dependencies.
minetest.register_craft({
  type = "shapeless",
  output = 'dusts:coal 2',
  -- Coal dust is obtainable by grinding lumps together in the hands.
  recipe = {'default:coal_lump', 'default:coal_lump'},
})

minetest.register_craft({
  type = "anvil",
  output = 'dusts:coal 2',
  recipe = 'default:coal_lump',
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:diamond 2',
  recipe = 'dusts:diamond_shard',
  time = 15,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:diamond_shard 9',
  recipe = 'default:diamond',
  time = 15,
})

minetest.register_craft({
  type = "anvil",
  output = 'dusts:diamond_shard 9',
  recipe = 'default:diamond',
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:silver 2',
  recipe = 'moreores:silver_lump',
  time = 7,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:silver',
  recipe = 'moreores:silver_ingot',
  time = 7,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:tin 2',
  recipe = 'moreores:tin_lump',
  time = 8,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:tin',
  recipe = 'moreores:tin_ingot',
  time = 8,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:mithril 2',
  recipe = 'moreores:mithril_lump',
  time = 7,
})

minetest.register_craft({
  type = "grinding",
  output = 'dusts:mithril',
  recipe = 'moreores:mithril_ingot',
  time = 7,
})



minetest.register_craft({
  type = "cooking",
  output = "default:steel_ingot",
  recipe = "dusts:iron",
})

minetest.register_craft({
  type = "cooking",
  output = "default:copper_ingot",
  recipe = "dusts:copper",
})

minetest.register_craft({
  type = "cooking",
  output = "default:gold_ingot",
  recipe = "dusts:gold",
})

minetest.register_craft({
  type = "cooking",
  output = "moreores:silver_ingot",
  recipe = "dusts:silver",
})

minetest.register_craft({
  type = "cooking",
  output = "moreores:tin_ingot",
  recipe = "dusts:tin",
})

minetest.register_craft({
  type = "cooking",
  output = "moreores:mithril_ingot",
  recipe = "dusts:mithril",
})


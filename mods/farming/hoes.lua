
-- No wooden hoes! By MustTest
--[[
farming.register_hoe(":farming:hoe_wood", {
	description = "Wooden Hoe",
	inventory_image = "farming_tool_woodhoe.png",
	max_uses = 30,
	material = "group:wood"
})
--]]

farming.register_hoe(":farming:hoe_stone", {
	description = "Stone Hoe",
	inventory_image = "farming_tool_stonehoe.png",
	max_uses = 90,
	material = "default:stone",
  groups = {not_repaired_by_anvil = 1},
})

farming.register_hoe(":farming:hoe_steel", {
	description = "Iron Hoe",
	inventory_image = "farming_tool_steelhoe.png",
	max_uses = 200,
	material = "default:steel_ingot"
})

farming.register_hoe(":farming:hoe_bronze", {
	description = "Copper Hoe",
	inventory_image = "farming_tool_bronzehoe.png",
	max_uses = 220,
	material = "default:copper_ingot"
})

farming.register_hoe(":farming:hoe_mese", {
	description = "Mese Hoe",
	inventory_image = "farming_tool_mesehoe.png",
	max_uses = 350,
	material = "default:mese_crystal"
})

farming.register_hoe(":farming:hoe_diamond", {
	description = "Diamond Hoe",
	inventory_image = "farming_tool_diamondhoe.png",
	max_uses = 500,
	material = "default:diamond"
})

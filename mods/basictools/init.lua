
basictools = basictools or {}
basictools.modpath = minetest.get_modpath("basictools")



minetest.register_tool(":default:pick_wood", {
	description = "Wooden Pickaxe",
	inventory_image = "default_tool_woodpick.png",
	tool_capabilities = tooldata["pick_wood"],
  sound = {breaks = "basictools_tool_breaks"},
  groups = {flammable = 2, not_repaired_by_anvil = 1},
})

minetest.register_tool(":default:pick_stone", {
	description = "Stone Pickaxe",
	inventory_image = "default_tool_stonepick.png",
	tool_capabilities = tooldata["pick_stone"],
  sound = {breaks = "basictools_tool_breaks"},
  groups = {not_repaired_by_anvil = 1},
})

minetest.register_tool(":default:pick_steel", {
	description = "Iron Pickaxe",
	inventory_image = "default_tool_steelpick.png",
	tool_capabilities = tooldata["pick_steel"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:pick_bronze", {
	description = "Copper Pickaxe",
	inventory_image = "default_tool_bronzepick.png",
	tool_capabilities = tooldata["pick_bronze"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:pick_bronze2", {
	description = "Bronze Pickaxe",
	inventory_image = "default_tool_bronzepick2.png",
	tool_capabilities = tooldata["pick_bronze2"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:pick_mese", {
	description = "Mese Pickaxe",
	inventory_image = "default_tool_mesepick.png",
	tool_capabilities = tooldata["pick_mese"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:pick_diamond", {
	description = "Diamond Pickaxe",
	inventory_image = "default_tool_diamondpick.png",
	tool_capabilities = tooldata["pick_diamond"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:shovel_stone", {
	description = "Stone Shovel",
	inventory_image = "default_tool_stoneshovel.png",
	wield_image = "default_tool_stoneshovel.png^[transformR90",
	tool_capabilities = tooldata["shovel_stone"],
  sound = {breaks = "basictools_tool_breaks"},
  groups = {not_repaired_by_anvil = 1},
})

minetest.register_tool(":default:shovel_steel", {
	description = "Iron Shovel",
	inventory_image = "default_tool_steelshovel.png",
	wield_image = "default_tool_steelshovel.png^[transformR90",
	tool_capabilities = tooldata["shovel_steel"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:shovel_bronze", {
	description = "Copper Shovel",
	inventory_image = "default_tool_bronzeshovel.png",
	wield_image = "default_tool_bronzeshovel.png^[transformR90",
	tool_capabilities = tooldata["shovel_bronze"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:shovel_bronze2", {
	description = "Bronze Shovel",
	inventory_image = "default_tool_bronzeshovel2.png",
	wield_image = "default_tool_bronzeshovel2.png^[transformR90",
	tool_capabilities = tooldata["shovel_bronze2"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:shovel_mese", {
	description = "Mese Shovel",
	inventory_image = "default_tool_meseshovel.png",
	wield_image = "default_tool_meseshovel.png^[transformR90",
	tool_capabilities = tooldata["shovel_mese"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:shovel_diamond", {
	description = "Diamond Shovel",
	inventory_image = "default_tool_diamondshovel.png",
	wield_image = "default_tool_diamondshovel.png^[transformR90",
	tool_capabilities = tooldata["shovel_diamond"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:axe_stone", {
	description = "Stone Axe",
	inventory_image = "default_tool_stoneaxe.png",
	tool_capabilities = tooldata["axe_stone"],
  sound = {breaks = "basictools_tool_breaks"},
  groups = {not_repaired_by_anvil = 1},
})

minetest.register_tool(":default:axe_steel", {
	description = "Iron Axe",
	inventory_image = "default_tool_steelaxe.png",
	tool_capabilities = tooldata["axe_steel"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:axe_bronze", {
	description = "Copper Axe",
	inventory_image = "default_tool_bronzeaxe.png",
	tool_capabilities = tooldata["axe_bronze"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:axe_bronze2", {
	description = "Bronze Axe",
	inventory_image = "default_tool_bronzeaxe2.png",
	tool_capabilities = tooldata["axe_bronze2"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:axe_mese", {
	description = "Mese Axe",
	inventory_image = "default_tool_meseaxe.png",
	tool_capabilities = tooldata["axe_mese"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:axe_diamond", {
	description = "Diamond Axe",
	inventory_image = "default_tool_diamondaxe.png",
	tool_capabilities = tooldata["axe_diamond"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:sword_stone", {
	description = "Stone Sword",
	inventory_image = "default_tool_stonesword.png",
	tool_capabilities = tooldata["sword_stone"],
  sound = {breaks = "basictools_tool_breaks"},
  groups = {not_repaired_by_anvil = 1},
})

minetest.register_tool(":default:sword_steel", {
	description = "Iron Sword",
	inventory_image = "default_tool_steelsword.png",
	tool_capabilities = tooldata["sword_steel"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:sword_bronze", {
	description = "Copper Sword",
	inventory_image = "default_tool_bronzesword.png",
	tool_capabilities = tooldata["sword_bronze"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:sword_bronze2", {
	description = "Bronze Sword",
	inventory_image = "default_tool_bronzesword2.png",
	tool_capabilities = tooldata["sword_bronze2"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:sword_mese", {
	description = "Mese Sword",
	inventory_image = "default_tool_mesesword.png",
	tool_capabilities = tooldata["sword_mese"],
    sound = {breaks = "basictools_tool_breaks"},
})

minetest.register_tool(":default:sword_diamond", {
	description = "Diamond Sword",
	inventory_image = "default_tool_diamondsword.png",
	tool_capabilities = tooldata["sword_diamond"],
    sound = {breaks = "basictools_tool_breaks"},
})



minetest.register_craft({
	output = 'default:pick_wood',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	},
})

minetest.register_craft({
	output = 'default:pick_stone',
	recipe = {
		{'group:native_stone', 'group:native_stone', 'group:native_stone'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:pick_steel',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:pick_bronze',
	recipe = {
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:pick_bronze2',
	recipe = {
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:pick_mese',
	recipe = {
		{'default:mese_crystal', 'default:mese_crystal', 'default:mese_crystal'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:pick_diamond',
	recipe = {
		{'default:diamond', 'default:diamond', 'default:diamond'},
		{'', 'group:stick', ''},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:shovel_stone',
	recipe = {
		{'group:native_stone'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:shovel_steel',
	recipe = {
		{'default:steel_ingot'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:shovel_bronze',
	recipe = {
		{'default:copper_ingot'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:shovel_bronze2',
	recipe = {
		{'default:bronze_ingot'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:shovel_mese',
	recipe = {
		{'default:mese_crystal'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:shovel_diamond',
	recipe = {
		{'default:diamond'},
		{'group:stick'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_stone',
	recipe = {
		{'group:native_stone', 'group:native_stone'},
		{'group:native_stone', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_steel',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_bronze',
	recipe = {
		{'default:copper_ingot', 'default:copper_ingot'},
		{'default:copper_ingot', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_bronze2',
	recipe = {
		{'default:bronze_ingot', 'default:bronze_ingot'},
		{'default:bronze_ingot', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_mese',
	recipe = {
		{'default:mese_crystal', 'default:mese_crystal'},
		{'default:mese_crystal', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_diamond',
	recipe = {
		{'default:diamond', 'default:diamond'},
		{'default:diamond', 'group:stick'},
		{'', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:axe_stone',
	recipe = {
		{'group:native_stone', 'group:native_stone'},
		{'group:stick', 'group:native_stone'},
		{'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:axe_steel',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot'},
		{'group:stick', 'default:steel_ingot'},
		{'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:axe_bronze',
	recipe = {
		{'default:copper_ingot', 'default:copper_ingot'},
		{'group:stick', 'default:copper_ingot'},
		{'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:axe_bronze2',
	recipe = {
		{'default:bronze_ingot', 'default:bronze_ingot'},
		{'group:stick', 'default:bronze_ingot'},
		{'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:axe_mese',
	recipe = {
		{'default:mese_crystal', 'default:mese_crystal'},
		{'group:stick', 'default:mese_crystal'},
		{'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:axe_diamond',
	recipe = {
		{'default:diamond', 'default:diamond'},
		{'group:stick', 'default:diamond'},
		{'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'default:sword_stone',
	recipe = {
		{'group:native_stone'},
		{'group:native_stone'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:sword_steel',
	recipe = {
		{'default:steel_ingot'},
		{'default:steel_ingot'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:sword_bronze',
	recipe = {
		{'default:copper_ingot'},
		{'default:copper_ingot'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:sword_bronze2',
	recipe = {
		{'default:bronze_ingot'},
		{'default:bronze_ingot'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:sword_mese',
	recipe = {
		{'default:mese_crystal'},
		{'default:mese_crystal'},
		{'group:stick'},
	}
})

minetest.register_craft({
	output = 'default:sword_diamond',
	recipe = {
		{'default:diamond'},
		{'default:diamond'},
		{'default:sword_steel'},
	}
})

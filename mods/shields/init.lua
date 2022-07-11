local use_moreores = minetest.get_modpath("moreores")

-- Regisiter Shields

if ARMOR_MATERIALS.wood then
	minetest.register_tool("shields:shield_wood", {
		description = "Wooden Shield",
		inventory_image = "shields_inv_shield_wood.png",
		groups = {armor_shield=5, armor_heal=0, armor_use=2000},
		wear = 0,
	})
	minetest.register_tool("shields:shield_enhanced_wood", {
		description = "Enhanced Wood Shield",
		inventory_image = "shields_inv_shield_enhanced_wood.png",
		groups = {armor_shield=8, armor_heal=0, armor_use=1000},
		wear = 0,
	})
	minetest.register_craft({
		output = "shields:shield_enhanced_wood",
		recipe = {
			{"default:steel_ingot"},
			{"shields:shield_wood"},
			{"default:steel_ingot"},
		},
	})
	minetest.register_craft({
		type = "cooking",
		output = "default:steel_ingot 2",
		recipe = "shields:shield_enhanced_wood",
	})
end
--[[
if ARMOR_MATERIALS.cactus then
	minetest.register_tool("shields:shield_cactus", {
		description = "Cactus Shield",
		inventory_image = "shields_inv_shield_cactus.png",
		groups = {armor_shield=5, armor_heal=0, armor_use=2000},
		wear = 0,
	})
	minetest.register_tool("shields:shield_enhanced_cactus", {
		description = "Enhanced Cactus Shield",
		inventory_image = "shields_inv_shield_enhanced_cactus.png",
		groups = {armor_shield=8, armor_heal=0, armor_use=1000},
		wear = 0,
	})
	minetest.register_craft({
		output = "shields:shield_enhanced_cactus",
		recipe = {
			{"default:steel_ingot"},
			{"shields:shield_cactus"},
			{"default:steel_ingot"},
		},
	})
end
--]]
if ARMOR_MATERIALS.steel then
	minetest.register_tool("shields:shield_steel", {
		description = "Wrought Iron Shield",
		inventory_image = "shields_inv_shield_steel.png",
		groups = {armor_shield=10, armor_heal=0, armor_use=500},
		wear = 0,
	})
end

if ARMOR_MATERIALS.carbon then
	minetest.register_tool("shields:shield_carbon", {
		description = "Carbon Steel Shield",
		inventory_image = "shields_inv_shield_carbon.png",
		groups = {armor_shield=12, armor_heal=0, armor_use=200},
		wear = 0,
	})
end

if ARMOR_MATERIALS.bronze then
	minetest.register_tool("shields:shield_bronze", {
		description = "Bronze Shield",
		inventory_image = "shields_inv_shield_bronze.png",
		groups = {armor_shield=10, armor_heal=6, armor_use=250},
		wear = 0,
	})
end

if ARMOR_MATERIALS.diamond then
	minetest.register_tool("shields:shield_diamond", {
		description = "Diamond Shield",
		inventory_image = "shields_inv_shield_diamond.png",
		groups = {armor_shield=15, armor_heal=12, armor_use=100},
		wear = 0,
	})
end

if ARMOR_MATERIALS.gold then
	minetest.register_tool("shields:shield_gold", {
		description = "Gold Shield",
		inventory_image = "shields_inv_shield_gold.png",
		groups = {armor_shield=10, armor_heal=6, armor_use=250},
		wear = 0,
	})
end

if ARMOR_MATERIALS.mithril then
	minetest.register_tool("shields:shield_mithril", {
		description = "Mithril Shield",
		inventory_image = "shields_inv_shield_mithril.png",
		groups = {armor_shield=15, armor_heal=12, armor_use=50},
		wear = 0,
	})
end

for k, v in pairs(ARMOR_MATERIALS) do
	minetest.register_craft({
		output = "shields:shield_"..k,
		recipe = {
			{v, "mobs:leather_padding", v},
			{v, "techcrafts:composite_plate", v},
			{"", v, ""},
		},
	})
	-- Reverse cooking recipes for all shields except wood and diamond.
	if not string.find(v, "wood") and not string.find(v, "diamond") and string.find(v, "ingot") then
		minetest.register_craft({
			type = "cooking",
			output = v .. " 7",
			recipe = "shields:shield_" .. k,
			cooktime = 15,
		})
	end
	if string.find(v, "wood") then
		minetest.register_craft({
			type = "fuel",
			recipe = "shields:shield_" .. k,
			burntime = 5,
		})
	end
end

minetest.after(0, function()
	table.insert(armor.elements, "shield")
end)


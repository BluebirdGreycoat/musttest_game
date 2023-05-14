local use_moreores = minetest.get_modpath("moreores")

-- Register Shields
local function register_shield(name, data)
	data._armor_resist_groups = sysdmg.get_armor_resist_for(name)
	data._armor_wear_groups = sysdmg.get_armor_wear_for(name)
	if not data.groups then
		data.groups = {armor_shield=1}
	else
		data.groups.armor_shield = 1
	end
	data.groups = sysdmg.get_armor_groups_for(name, data.groups)
	minetest.register_tool(name, data)
end

if ARMOR_MATERIALS.wood then
	register_shield("shields:shield_wood", {
		description = "Wooden Shield",
		inventory_image = "shields_inv_shield_wood.png",
	})

	register_shield("shields:shield_enhanced_wood", {
		description = "Enhanced Wood Shield",
		inventory_image = "shields_inv_shield_enhanced_wood.png",
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

if ARMOR_MATERIALS.steel then
	register_shield("shields:shield_steel", {
		description = "Wrought Iron Shield",
		inventory_image = "shields_inv_shield_steel.png",
	})
end

if ARMOR_MATERIALS.carbon then
	register_shield("shields:shield_carbon", {
		description = "Carbon Steel Shield",
		inventory_image = "shields_inv_shield_carbon.png",
	})
end

if ARMOR_MATERIALS.bronze then
	register_shield("shields:shield_bronze", {
		description = "Bronze Shield",
		inventory_image = "shields_inv_shield_bronze.png",
	})
end

if ARMOR_MATERIALS.diamond then
	register_shield("shields:shield_diamond", {
		description = "Diamond Shield",
		inventory_image = "shields_inv_shield_diamond.png",
	})
end

if ARMOR_MATERIALS.gold then
	register_shield("shields:shield_gold", {
		description = "Golden Shield",
		inventory_image = "shields_inv_shield_gold.png",
	})
end

if ARMOR_MATERIALS.mithril then
	register_shield("shields:shield_mithril", {
		description = "Mithril Shield",
		inventory_image = "shields_inv_shield_mithril.png",
	})
end



for k, v in pairs(ARMOR_MATERIALS) do
	local center = "techcrafts:composite_plate"
	if string.find(v, "wood") then
		center = "default:steel_ingot"
	end

	minetest.register_craft({
		output = "shields:shield_"..k,
		recipe = {
			{v, "mobs:leather_padding", v},
			{v, center, v},
			{"", v, ""},
		},
	})

	-- Reverse cooking recipes for all shields except wood and diamond.
	if not string.find(v, "wood") and not string.find(v, "diamond") and string.find(v, "ingot") then
		minetest.register_craft({
			type = "cooking",
			output = v .. " 5",
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


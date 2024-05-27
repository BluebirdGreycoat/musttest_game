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



-- Enhanced wooden shield. -----------------------------------------------------
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
--------------------------------------------------------------------------------



for key, data in pairs(ARMOR_MATERIALS) do
	register_shield("shields:shield_" .. key, {
		description = data.name .. " Shield",
		inventory_image = "shields_inv_shield_" .. key .. ".png",
	})
end



for key, data in pairs(ARMOR_MATERIALS) do
	local k = key
	local v = data.item
	local fueltime = data.fuel or 0
	local cooktime = data.cook or 0

	if data.shield then
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
		if cooktime > 0 then
			minetest.register_craft({
				type = "cooking",
				output = v .. " 5",
				recipe = "shields:shield_" .. k,
				cooktime = cooktime,
			})
		end

		if fueltime > 0 then
			minetest.register_craft({
				type = "fuel",
				recipe = "shields:shield_" .. k,
				burntime = fueltime,
			})
		end
	end
end

minetest.after(0, function()
	table.insert(armor.elements, "shield")
end)


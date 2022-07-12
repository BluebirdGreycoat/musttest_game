
-- The armor craft registrations are in their own directory in order to break up
-- circular dependency issues.

for k, v in pairs(ARMOR_MATERIALS) do
	local padding = "group:leather_padding"
	if v == "group:wood" then
		padding = "farming:cotton"
	elseif minetest.get_item_group(v, "gem") ~= 0 then
		padding = "farming:cloth"
	end

	minetest.register_craft({
		output = "3d_armor:helmet_"..k,
		recipe = {
			{v, v, v},
			{v, padding, v},
			{padding, "farming:string", padding},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..k,
		recipe = {
			{v, padding, v},
			{v, padding, v},
			{v, v, v},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..k,
		recipe = {
			{v, "farming:string", v},
			{v, padding, v},
			{v, padding, v},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..k,
		recipe = {
			{padding, "", padding},
			{v, "farming:string", v},
			{v, "farming:string", v},
		},
	})

	if not string.find(v, "wood") and not string.find(v, "diamond") and string.find(v, "ingot") then
		minetest.register_craft({
			type = "cooking",
			output = v .. " 5",
			recipe = "3d_armor:helmet_"..k,
			cooktime = 15,
		})

		minetest.register_craft({
			type = "cooking",
			output = v .. " 8",
			recipe = "3d_armor:chestplate_"..k,
			cooktime = 15,
		})

		minetest.register_craft({
			type = "cooking",
			output = v .. " 7",
			recipe = "3d_armor:leggings_"..k,
			cooktime = 15,
		})

		minetest.register_craft({
			type = "cooking",
			output = v .. " 4",
			recipe = "3d_armor:boots_"..k,
			cooktime = 15,
		})
	end

	-- Wooden armor can be used as fuel.
	if string.find(v, "wood") then
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:helmet_" .. k,
			burntime = 4,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:chestplate_" .. k,
			burntime = 4,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:leggings_" .. k,
			burntime = 4,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:boots_" .. k,
			burntime = 4,
		})
	end
end

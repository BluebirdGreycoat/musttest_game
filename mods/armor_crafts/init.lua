
-- The armor craft registrations are in their own directory in order to break up
-- circular dependency issues.

for key, data in pairs(ARMOR_MATERIALS) do
	local k = key
	local v = data.item
	local padding = data.padding
	local fueltime = data.fuel or 0
	local cooktime = data.cook or 0

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

	if cooktime > 0 then
		minetest.register_craft({
			type = "cooking",
			output = v .. " 5",
			recipe = "3d_armor:helmet_"..k,
			cooktime = cooktime,
		})

		minetest.register_craft({
			type = "cooking",
			output = v .. " 7",
			recipe = "3d_armor:chestplate_"..k,
			cooktime = cooktime,
		})

		minetest.register_craft({
			type = "cooking",
			output = v .. " 6",
			recipe = "3d_armor:leggings_"..k,
			cooktime = cooktime,
		})

		minetest.register_craft({
			type = "cooking",
			output = v .. " 4",
			recipe = "3d_armor:boots_"..k,
			cooktime = cooktime,
		})
	end

	if fueltime > 0 then
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:helmet_" .. k,
			burntime = fueltime,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:chestplate_" .. k,
			burntime = fueltime,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:leggings_" .. k,
			burntime = fueltime,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:boots_" .. k,
			burntime = fueltime,
		})
	end
end

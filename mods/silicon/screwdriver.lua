
electric_screwdriver = electric_screwdriver or {}
electric_screwdriver.modpath = minetest.get_modpath("silicon")

electric_screwdriver.image = "technic_sonic_screwdriver.png"
electric_screwdriver.sound = "technic_sonic_screwdriver"
electric_screwdriver.name = "electric_screwdriver:electric_screwdriver"
electric_screwdriver.description = "Electric Screwdriver\n\nAn electrical, reusable screwdriver.\nMust be charged to use."

-- This is how many nodes the electric screwdriver can spin.
electric_screwdriver.uses = math.floor(65535/2500)

function electric_screwdriver.on_use(itemstack, user, pt)
	if pt.type ~= "node" then
		return
	end
	local wear = itemstack:get_wear()
	if wear == 0 then
		-- Tool isn't charged!
		-- Once it is charged the first time, wear should never be 0 again.
		return
	end
	if wear > math.floor(65535-electric_screwdriver.uses) then
		-- Tool has no charge left.
		return
	end

	-- We handle stack ourselves.
	local fakestack = ItemStack(itemstack:get_name())

	ambiance.sound_play(electric_screwdriver.sound, pt.under, 0.4, 30)
	screwdriver.handler(fakestack, user, pt, screwdriver.ROTATE_FACE, 200)

	wear = wear + electric_screwdriver.uses
	-- Don't let wear reach max or tool will be destroyed.
	if wear >= 65535 then
		wear = 65534
	end
	itemstack:set_wear(wear)
	return itemstack
end

function electric_screwdriver.on_place(itemstack, user, pt)
	if pt.type ~= "node" then
		return
	end
	local wear = itemstack:get_wear()
	if wear == 0 then
		-- Tool isn't charged!
		-- Once it is charged the first time, wear should never be 0 again.
		return
	end
	if wear > math.floor(65535-electric_screwdriver.uses) then
		-- Tool has no charge left.
		return
	end

	-- We handle stack ourselves.
	local fakestack = ItemStack(itemstack:get_name())

	ambiance.sound_play(electric_screwdriver.sound, pt.under, 0.5, 40)
	screwdriver.handler(fakestack, user, pt, screwdriver.ROTATE_AXIS, 200)

	wear = wear + electric_screwdriver.uses
	-- Don't let wear reach max or tool will be destroyed.
	if wear >= 65535 then
		wear = 65534
	end
	itemstack:set_wear(wear)
	return itemstack
end

if not electric_screwdriver.run_once then
	minetest.register_tool(":" .. electric_screwdriver.name, {
		description = electric_screwdriver.description,
		inventory_image = electric_screwdriver.image,
		wear_represents = "eu_charge",
		groups = {not_repaired_by_anvil = 1, disable_repair = 1},

		on_use = function(...)
			return electric_screwdriver.on_use(...)
		end,

		on_place = function(...)
			return electric_screwdriver.on_place(...)
		end,
	})

	---[[
	minetest.register_craft({
		output = electric_screwdriver.name,
		recipe = {
		{"",                         "default:diamond",        ""},
		{"plastic:plastic_sheeting", "battery:battery",        "plastic:plastic_sheeting"},
		{"plastic:plastic_sheeting", "moreores:mithril_ingot", "plastic:plastic_sheeting"},
		}
	})
	--]]

	local c = "electric_screwdriver:core"
	local f = electric_screwdriver.modpath .. "/screwdriver.lua"
	reload.register_file(c, f, false)

	electric_screwdriver.run_once = true
end

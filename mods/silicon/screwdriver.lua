
electric_screwdriver = electric_screwdriver or {}
electric_screwdriver.modpath = minetest.get_modpath("silicon")

electric_screwdriver.image = "technic_sonic_screwdriver.png"
electric_screwdriver.sound = "technic_sonic_screwdriver"
electric_screwdriver.name = "electric_screwdriver:electric_screwdriver"
electric_screwdriver.description = "Electric Screwdriver\n\nAn electrical, reusable screwdriver.\nMust be charged to use.\nLeft-click + 'E' copies rotation, right-click + 'E' applies rotation."
electric_screwdriver.sound_gain = 0.3
electric_screwdriver.sound_dist = 25

-- This is how many nodes the electric screwdriver can spin.
electric_screwdriver.uses = math.floor(65535/2500)

function electric_screwdriver.on_use(itemstack, user, pt)
	if not user or not user:is_player() then
		return
	end

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

	local control = user:get_player_control()

	if control.aux1 then
		local meta = itemstack:get_meta()
		local node = minetest.get_node(pt.under)
		local ndef = minetest.registered_nodes[node.name]
		if ndef and ndef.paramtype2 == "facedir" then
			if node.param2 >= 0 and node.param2 <= 23 then
				meta:set_int("screwdriver_rotation", node.param2)

				minetest.chat_send_player(user:get_player_name(),
					"# Server: copied facedir (" .. node.param2 .. ")!")
			end
		end
	else
		-- We handle stack ourselves.
		local fakestack = ItemStack(itemstack:get_name())
		screwdriver.handler(fakestack, user, pt, screwdriver.ROTATE_FACE, 200)
	end

	ambiance.sound_play(electric_screwdriver.sound, pt.under, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)

	wear = wear + electric_screwdriver.uses
	-- Don't let wear reach max or tool will be destroyed.
	if wear >= 65535 then
		wear = 65534
	end
	itemstack:set_wear(wear)
	return itemstack
end

function electric_screwdriver.on_place(itemstack, user, pt)
	if not user or not user:is_player() then
		return
	end

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

	local control = user:get_player_control()

	if control.aux1 then
		if not minetest.is_protected(pt.under, user:get_player_name()) then
			local meta = itemstack:get_meta()
			local param2 = meta:get_int("screwdriver_rotation")
			local node = minetest.get_node(pt.under)
			local ndef = minetest.registered_nodes[node.name]
			if ndef and ndef.paramtype2 == "facedir" then
				if param2 >= 0 and param2 <= 23 then
					node.param2 = param2
					minetest.swap_node(pt.under, node)
					ambiance.sound_play("default_dug_metal", pt.under, 1, 30)
				end
			end
		end
	else
		-- We handle stack ourselves.
		local fakestack = ItemStack(itemstack:get_name())
		screwdriver.handler(fakestack, user, pt, screwdriver.ROTATE_AXIS, 200)
	end

	ambiance.sound_play(electric_screwdriver.sound, pt.under, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)

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

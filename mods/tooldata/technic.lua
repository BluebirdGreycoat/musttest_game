
-- Balancing table.
tech = {
	-- Solar energy is scaled by altitude.
	solar_panel={power=10, buffer=100},
	solar_lv={power=30, buffer=500},
	solar_mv={power=50, buffer=1000},
	solar_hv={power=100, buffer=6000},

	windy={power=60, buffer=1000},
	tidal={power=50, buffer=1000},

	breeder={power=10000, time=10, totaltime=60*60*24*10, buffer=30000},
    reactor={power=10000, time=5, totaltime=60*60*24*7, buffer=60000},
	converter={power=1000, buffer=50000},

	leecher={power=800, buffer=60000},
	charger={power=100, buffer=5000},
	workshop={power=160, buffer=5000, repair=70},

	distributer_lv={power=50, buffer=1000},
	distributer_mv={power=100, buffer=5000},
	distributer_hv={power=1000, buffer=10000},

	-- Buffer size is scaled by number of battery units in the array.
	battery_lv={buffer=10000},
	battery_mv={buffer=50000},
	battery_hv={buffer=120000},

	-- Power is scaled by number of lava/water nodes adjacent to machine.
	geothermal={power=3, buffer=500},
	hydroturbine={power=1, buffer=300},

	-- Time determines how many seconds to produce power.
	-- Mesepower is how much power to produce if fuel is mese.
	generator_lv={power=100, mesepower=450, time=3, buffer=5000},
	generator_mv={power=200, mesepower=500, time=2, buffer=10000},
	generator_hv={power=300, mesepower=550, time=1, buffer=20000},

	-- Tool machines. Timecut multiplies the machine clock; higher is longer.
	centrifuge_mv={demand=300, buffer=6000, timecut=1.0},
	gemcutter_lv={demand=100, buffer=1000, timecut=1.0},
	alloyer_mv={demand=300, buffer=6000, timecut=0.8},

	compressor_lv={demand=100, buffer=1000, timecut=2.0},
	compressor_mv={demand=300, buffer=6000, timecut=1.0},

	furnace_lv={demand=100, buffer=1000, timecut=2.0},
	furnace_mv={demand=300, buffer=6000, timecut=1.0},
	furnace_hv={demand=600, buffer=10000, timecut=0.5},

	extractor_lv={demand=100, buffer=1000, timecut=2.0},
	extractor_mv={demand=300, buffer=6000, timecut=1.0},

	grinder_lv={demand=200, buffer=2000, timecut=2.0},
	grinder_mv={demand=300, buffer=6000, timecut=0.6},
}


minetest.register_chatcommand("recharge", {
	params = "",
	description = "Recharges the machine tool held in hand.",
	privs = {server=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player and player:is_player() then
			local tool = player:get_wielded_item()
			local def = minetest.registered_items[tool:get_name()]
			if def and def.wear_represents and def.wear_represents == "eu_charge" then
				-- The wear format says that 1 means fully charged.
				-- 0 would mean 'never yet charged'.
				-- The value increases toward 65534 as charge is drained,
				-- but should never go past that.
				-- A value greater than 1 means some energy has been drained.
				tool:set_wear(1)
				player:set_wielded_item(tool)

				if map.is_mapping_kit(tool:get_name()) then
					map.update_inventory_info(name)
				end
			else
				minetest.chat_send_player(name, "# Server: Wielded item is not rechargeable.")
			end
		end
		return true
	end,
})

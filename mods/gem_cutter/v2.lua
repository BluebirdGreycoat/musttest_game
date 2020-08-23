
gemcut2 = gemcut2 or {}
gemcut2.modpath = minetest.get_modpath("gem_cutter")

local MACHINE_NAME = "Gem Cutter"
local MACHINE_DESC = "This cuts and shapes gems into a useable form.\nCan burn mese for fuel when off-grid.\nAlternatively, connect to a power-network."
local MACHINE_FUEL_EU_PER_SEC = 80
local RECIPE_TYPE = "cutting"

gemcut2_lv = gemcut2_lv or {}
--gemcut2_mv = gemcut2_mv or {}
--gemcut2_hv = gemcut2_hv or {}

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random



for j, t in ipairs({
	-- Only the LV version is available.
	-- MustTest.
	{tier="lv", up="LV", speed=1.0, level=1, buffer=1000, demand=100},
	--{tier="mv", up="MV", speed=1.0, level=2, buffer=6000, demand=300},
	--{tier="hv", up="HV", speed=0.5, level=3, buffer=10000, demand=600},
}) do
	-- Which function table are we operating on?
	local func = _G["gemcut2_" .. t.tier]

	-- Read values from balancing table.
	local techname = "gemcutter_" .. t.tier
	t.speed = tech[techname].timecut
	t.buffer = tech[techname].buffer
	t.demand = tech[techname].demand

	func.get_formspec_defaults = function()
		local str =
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots
		return str
	end



	func.formspec_active = function(fuel_percent, item_percent)
		local x1 = 3.5
		local x2 = 4.5
		local x3 = 5.5
		local x4 = 0.5
		if t.level <= 1 then
			x1 = 3
			x2 = 4
			x3 = 5
			x4 = 1
		end

		local formspec =
			"size[8,8.5]" ..
			func.get_formspec_defaults() ..

			"label[" .. x1 .. ",0;Fuel & Input]" ..
			"list[context;src;" .. x1 .. ",0.5;1,1;]" ..
			"list[context;fuel;" .. x1 .. ",2.5;1,1;]" ..
			"image[" .. x1 .. ",1.5;1,1;machine_progress_bg.png^[lowpart:" ..
			(fuel_percent) .. ":machine_progress_fg.png]" ..

			"image[" .. x2 .. ",1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:" ..
			(item_percent) .. ":gui_furnace_arrow_fg.png^[transformR270]" ..
			"label[" .. x3 .. ",0.46;Destination]" ..
			"list[context;dst;" .. x3 .. ",0.96;2,2;]" ..

			"list[current_player;main;0,4.25;8,1;]" ..
			"list[current_player;main;0,5.5;8,3;8]"

		if t.level > 1 then
			formspec = formspec ..
				"label[0.5,0;Upgrades]" ..
				"list[context;upg;0.5,0.5;2,1;]"
		else
			formspec = formspec ..
				"label[1,0;Upgrade]" ..
				"list[context;upg;1,0.5;1,1;]"
		end

		formspec = formspec ..
			"label[" .. x4 .. ",2;Buffer]" ..
			"list[context;buffer;" .. x4 .. ",2.5;1,1;]" ..

			"listring[context;dst]" ..
			"listring[current_player;main]" ..
			"listring[context;src]" ..
			"listring[current_player;main]" ..
			"listring[context;fuel]"..
			"listring[current_player;main]"..
			default.get_hotbar_bg(0, 4.25)
		return formspec
	end



	func.formspec_inactive = function()
		return func.formspec_active(0, 0)
	end



	func.on_punch =
	function(pos, node, puncher, pointed_thing)
		func.trigger_update(pos)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if t.level > 1 then
			inv:set_size('upg', 2)
		else
			inv:set_size('upg', 1)
		end
	end



	func.trigger_update =
	function(pos)
		local timer = minetest.get_node_timer(pos)
		-- Start timer even if already running.
		timer:start(1.0)
	end



	func.can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("fuel") and
			inv:is_empty("dst") and
			inv:is_empty("src") and
			inv:is_empty("upg")
	end



	func.get_speed =
	function(pos, meta, inv)
		if t.level <= 1 then
			return t.speed
		end

		local clus = utility.inventory_count_items(inv, "upg", "techcrafts:control_logic_unit")
		if clus == 1 then
			return (t.speed*0.8)
		elseif clus == 2 then
			return (t.speed*0.7)
		end

		return t.speed
	end



	func.get_demand =
	function(pos, meta, inv)
		if t.level <= 1 then
			return t.demand
		end

		local bats = utility.inventory_count_items(inv, "upg", "battery:battery")
		if bats == 1 then
			return math_floor(t.demand*0.8)
		elseif bats == 2 then
			return math_floor(t.demand*0.7)
		end

		return t.demand
	end



	func.has_public_access =
	function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		local s1 = inv:get_stack("upg", 1)
		if s1:get_count() > 0 then
			if minetest.get_item_group(s1:get_name(), "chest") > 0 then
				return true
			end
		end

		-- Second upgrad slot for level 2 and 3 machines.
		if t.level > 1 then
			local s2 = inv:get_stack("upg", 2)
			if s2:get_count() > 0 then
				if minetest.get_item_group(s2:get_name(), "chest") > 0 then
					return true
				end
			end
		end
	end



	func.allow_metadata_inventory_put =
	function(pos, listname, index, stack, player)
		local pname = player:get_player_name()
		local public = func.has_public_access(pos)
		local protected = false
		if minetest.test_protection(pos, pname) then
			protected = true
		end
		if listname == "fuel" and (not protected or public) then
			if minetest.get_craft_result({method="mesefuel", width=1, items={stack}}).time ~= 0 then
				return stack:get_count()
			end
		elseif listname == "src"  and (not protected or public)then
			return stack:get_count()
		elseif listname == "upg" and not protected then
			-- Level 1 has 1 slot, level 2 & 3 have 2 slots.
			if minetest.get_item_group(stack:get_name(), "chest") > 0 then
				return stack:get_count()
			elseif stack:get_name() == "battery:battery" then
				return stack:get_count()
			elseif stack:get_name() == "techcrafts:control_logic_unit" then
				return stack:get_count()
			end
		end
		return 0
	end



	func.allow_metadata_inventory_move =
	function(pos, from_list, from_index, to_list, to_index, count, player)
		local pname = player:get_player_name()
		local public = func.has_public_access(pos)
		local protected = false
		if minetest.test_protection(pos, pname) then
			protected = true
		end
		if (from_list == "upg" or to_list == "upg") and protected then
			-- Level 1 has 1 slot, level 2 & 3 have 2 slots.
			return 0
		end
		if not protected or public then
			if from_list == "buffer" or to_list == "buffer" then
				return 0
			end
			if from_list == to_list then
				return count
			end
		end
		return 0
	end



	func.allow_metadata_inventory_take =
	function(pos, listname, index, stack, player)
		local pname = player:get_player_name()
		local public = func.has_public_access(pos)
		local protected = false
		if minetest.test_protection(pos, pname) then
			protected = true
		end
		if listname == "fuel" and (not protected or public) then
			return stack:get_count()
		elseif listname == "dst" and (not protected or public) then
			return stack:get_count()
		elseif listname == "upg" and not protected then
			-- Level 1 has 1 slot, level 2 & 3 have 2 slots.
			return stack:get_count()
		elseif listname == "src" and (not protected or public) then
			return stack:get_count()
		end
		return 0
	end



	func.on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local wantedenergy = 0
		local keeprunning = false

		local demand = func.get_demand(pos, meta, inv)
		local speed = func.get_speed(pos, meta, inv)

		-- Check if we have cookable content.
		local srclist = inv:get_list("src")
		local cookable = true
		local cooked, aftercooked = minetest.get_craft_result({
			method = RECIPE_TYPE, width = 1, items = srclist})
		if cooked.time == 0 then
			cookable = false
		end

		-- If we have cookable content, goto 'on cook content'.
		if cookable then
			-- If total energy time wasn't recorded yet, record it.
			if meta:get_int("fueltotaltime") == 0 then
				local energy = inv:get_stack("buffer", 1):get_count()
				meta:set_int("fueltotaltime", math_floor(energy/demand))
			end

			goto on_cook
		else
			-- Stop machine.
			keeprunning = false
			goto end_func
		end

		-- On cook content.
		::on_cook::
		do
			-- Check if item is fully cooked.
			if meta:get_float("srctime") >= cooked.time then
				-- Place result in dst list if possible
				if inv:room_for_item("dst", cooked.item) then
					inv:add_item("dst", cooked.item)
					inv:set_stack("src", 1, aftercooked.items[1])
					meta:set_float("srctime", 0)

					-- Check if there are still items in the source slot.
					local srclist = inv:get_list("src")
					local cooked, aftercooked = minetest.get_craft_result({
						method = RECIPE_TYPE, width = 1, items = srclist})
					if cooked.time == 0 then
						-- No more items? Stop machine.
						meta:set_int("fueltotaltime", 0)
						keeprunning = false
						goto end_func
					else
						-- Set machine active.
						keeprunning = true
						goto end_func
					end
				else
					-- Stop machine, no room!
					meta:set_int("fueltotaltime", 0)
					keeprunning = false
					goto end_func
				end
			else
				-- Check if we have buffered energy.
				goto check_buffered_energy
			end
		end

		-- Check if we have buffered energy.
		::check_buffered_energy::
		do
			local energy = inv:get_stack("buffer", 1)
			if energy:get_count() >= demand then
				-- Increment cooktime.
				meta:set_float("srctime", meta:get_float("srctime") + 1/speed)
				energy:take_item(math_floor(demand/speed))
				inv:set_stack("buffer", 1, energy)
				-- Set machine active.
				keeprunning = true
				goto end_func
			else
				-- Goto 'on get energy'. Send wanted amount of energy.
				wantedenergy = demand
				goto on_get_energy
			end
		end

		-- On get energy.
		::on_get_energy::
		do
			-- Check if we can get energy from fuel.
			local fuellist = inv:get_list("fuel")
			local fuel, afterfuel = minetest.get_craft_result({
				method = "mesefuel", width = 1, items = fuellist})
			if fuel.time > 0 then
				local old = inv:get_stack("buffer", 1):get_count()
				local energy = old + math_floor(fuel.time * MACHINE_FUEL_EU_PER_SEC)
				meta:set_int("fueltotaltime", math_floor(energy/demand))
				inv:set_stack("buffer", 1, "atomic:energy " .. energy)
				inv:set_stack("fuel", 1, afterfuel.items[1])
				goto check_got_enough_energy
			else
				goto get_energy_from_network
			end
		end

		-- Check if we can get energy from network.
		::get_energy_from_network::
		do
			local current = inv:get_stack("buffer", 1)
			if current:get_count() < t.buffer then
				local owner = meta:get_string("owner")
				local get_amount = t.buffer
				local energy = net2.get_energy(pos, owner, get_amount, t.tier)
				if energy > 0 then
					local old = inv:get_stack("buffer", 1):get_count()
					energy = energy + old
					meta:set_int("fueltotaltime", math_floor(energy/demand))
					inv:set_stack("buffer", 1, "atomic:energy " .. energy)
					goto check_got_enough_energy
				else
					-- Stop machine (network exhausted).
					keeprunning = false
					goto end_func
				end
			else
				-- Stop machine (buffer full).
				keeprunning = false
				goto end_func
			end
		end

		-- Check if we got enough energy.
		::check_got_enough_energy::
		do
			local energy = inv:get_stack("buffer", 1)
			if energy:get_count() >= wantedenergy then
				keeprunning = true
				goto end_func
			else
				-- Keep trying to get energy.
				goto on_get_energy
			end
		end

		-- End func.
		::end_func::
		do
			if keeprunning then
				local itempercent = 0
				if cookable then
					itempercent = math_floor(meta:get_float("srctime") / cooked.time * 100)
				end
				local fueltime = math_floor(inv:get_stack("buffer", 1):get_count()/demand)
				local fueltotaltime = meta:get_int("fueltotaltime")
				local fuelpercent = math_floor(fueltime / fueltotaltime * 100)

				local eu_demand = math_floor(demand/speed)
				local infotext = t.up .. " " .. MACHINE_NAME .. " (Active)\n" ..
					"Demand: " .. eu_demand .. " EU Per/Sec"
				local formspec = func.formspec_active(fuelpercent, itempercent)
				meta:set_string("infotext", infotext)
				meta:set_string("formspec", formspec)
				machines.swap_node(pos, "gemcut2:" .. t.tier .. "_active")
				minetest.get_node_timer(pos):start(1.0)
			else
				local infotext = t.up .. " " .. MACHINE_NAME .. " (Standby)\n" ..
					"Demand: 0 EU Per/Sec"
				local formspec = func.formspec_inactive()
				meta:set_string("infotext", infotext)
				meta:set_string("formspec", formspec)
				meta:set_int("fueltotaltime", 0)
				meta:set_float("srctime", 0)
				machines.swap_node(pos, "gemcut2:" .. t.tier .. "_inactive")
				minetest.get_node_timer(pos):start(math_random(1, 3*60))
			end
		end
	end



	func.on_construct =
	function(pos)
	end



	func.on_destruct =
	function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		net2.clear_caches(pos, owner, t.tier)
		nodestore.del_node(pos)
	end



	func.after_place_node =
	function(pos, placer, itemstack, pointed_thing)
		local owner = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		local inv = meta:get_inventory()

		meta:set_string("owner", owner)
		meta:set_string("nodename", node.name)

		inv:set_size('src', 1)
		inv:set_size('fuel', 1)
		inv:set_size('dst', 4)
		if t.level > 1 then
			inv:set_size('upg', 2)
		else
			inv:set_size('upg', 1)
		end
		inv:set_size('buffer', 1)

		meta:set_string("formspec", func.formspec_inactive())
		meta:set_string("infotext", t.up .. " " .. MACHINE_NAME .. " (Standby)\n" ..
			"Demand: 0 EU Per/Sec")
		nodestore.add_node(pos)

		net2.clear_caches(pos, owner, t.tier)
		local timer = minetest.get_node_timer(pos)
		timer:start(1.0)
	end



	func.on_metadata_inventory_move =
	function(pos)
		func.trigger_update(pos)
	end



	func.on_metadata_inventory_put =
	function(pos)
		func.trigger_update(pos)
	end



	func.on_metadata_inventory_take =
	function(pos)
		func.trigger_update(pos)
	end



	func.on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "src", drops)
		default.get_inventory_drops(pos, "fuel", drops)
		default.get_inventory_drops(pos, "dst", drops)
		if t.level > 1 then
			default.get_inventory_drops(pos, "upg", drops)
		end
		drops[#drops+1] = "gemcut2:" .. t.tier .. "_inactive"
		minetest.remove_node(pos)
		return drops
	end
end



if not gemcut2.run_once then
	for j, t in ipairs({
		{tier="lv", up="LV"},
		--{tier="mv", up="MV"},
		--{tier="hv", up="HV"},
	}) do
		-- Which function table are we operating on?
		local func = _G["gemcut2_" .. t.tier]

		for k, v in ipairs({
			{name="inactive", light=0, tile="gem_cutter_" .. t.tier .. "_front.png"},
			{name="active", light=8, tile="gem_cutter_" .. t.tier .. "_front_active.png"},
		}) do
			minetest.register_node(":gemcut2:" .. t.tier .. "_" .. v.name, {
				description = t.up .. " " .. MACHINE_NAME .. "\n\n" .. MACHINE_DESC,
				tiles = {
					"gem_cutter_" .. t.tier .. "_top.png",  "gem_cutter_" .. t.tier .. "_bottom.png",
					"gem_cutter_" .. t.tier .. "_side.png", "gem_cutter_" .. t.tier .. "_side.png",
					"gem_cutter_" .. t.tier .. "_side.png", v.tile,
				},

				paramtype2 = "facedir",
				groups = utility.dig_groups("machine"),

				light_source = v.light,
				is_ground_content = false,
				sounds = default.node_sound_metal_defaults(),
				drop = "gemcut2:" .. t.tier .. "_inactive",

				on_rotate = function(...)
					return screwdriver.rotate_simple(...) end,
				can_dig = function(...)
					return func.can_dig(...) end,
				on_timer = function(...)
					return func.on_timer(...) end,
				on_construct = function(...)
					return func.on_construct(...) end,
				on_destruct = function(...)
					return func.on_destruct(...) end,
				on_blast = function(...)
					return func.on_blast(...) end,
				on_punch = function(...)
					return func.on_punch(...) end,
				after_place_node = function(...)
					return func.after_place_node(...) end,
				on_metadata_inventory_move = function(...)
					return func.on_metadata_inventory_move(...) end,
				on_metadata_inventory_put = function(...)
					return func.on_metadata_inventory_put(...) end,
				on_metadata_inventory_take = function(...)
					return func.on_metadata_inventory_take(...) end,
				allow_metadata_inventory_put = function(...)
					return func.allow_metadata_inventory_put(...) end,
				allow_metadata_inventory_move = function(...)
					return func.allow_metadata_inventory_move(...) end,
				allow_metadata_inventory_take = function(...)
					return func.allow_metadata_inventory_take(...) end,
			})
		end
	end

	local c = "gemcut2:core"
	local f = gemcut2.modpath .. "/v2.lua"
	reload.register_file(c, f, false)

	gemcut2.run_once = true
end

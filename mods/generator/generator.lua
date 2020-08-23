
-- Functions for the generator nodes.
gen2 = gen2 or {}
gen2_lv = gen2_lv or {}
gen2_mv = gen2_mv or {}
gen2_hv = gen2_hv or {}

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random



for k, v in ipairs({
	{tier="lv", up="LV", eups=tech.generator_lv.power, bt=tech.generator_lv.time, buf=tech.generator_lv.buffer, mese=tech.generator_lv.mesepower},
	{tier="mv", up="MV", eups=tech.generator_mv.power, bt=tech.generator_mv.time, buf=tech.generator_mv.buffer, mese=tech.generator_mv.mesepower},
	{tier="hv", up="HV", eups=tech.generator_hv.power, bt=tech.generator_hv.time, buf=tech.generator_hv.buffer, mese=tech.generator_hv.mesepower},
}) do
  -- Which function table are we operating on?
  local func = _G["gen2_" .. v.tier]

	func.trigger_update =
	function(pos)
		local timer = minetest.get_node_timer(pos)
		-- Restart timer even if already running.
		timer:start(1.0)
	end

	func.on_energy_get =
	function(pos, energy)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local have = inv:get_stack("out", 1):get_count()
		if have < energy then
			inv:set_stack("out", 1, ItemStack(""))
			func.trigger_update(pos)
			return have
		end
		have = have - energy
		inv:set_stack("out", 1, ItemStack("atomic:energy " .. have))
		func.trigger_update(pos)
		return energy
	end



	func.on_punch =
	function(pos, node, puncher, pointed_thing)
		func.trigger_update(pos)

		-- Upgrade old machines.
		if v.tier == "mv" or v.tier == "hv" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_size("upg", 2)
		end
	end



	func.compose_formspec =
	function(fuel_percent, item_percent)
		local formspec
		if v.tier == "lv" then
			-- Formspec without upgrade slots.
			formspec =
				"size[8,8.5]" ..
				default.formspec.get_form_colors() ..
				default.formspec.get_form_image() ..
				default.formspec.get_slot_colors() ..

				"label[2,0.5;Fuel Supply]" ..
				"list[context;fuel;2,1;1,1;]" ..

				"image[3,1;1,1;default_furnace_fire_bg.png^[lowpart:" ..
				(fuel_percent) .. ":default_furnace_fire_fg.png]" ..

				"image[4,1;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
				(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..

				"label[5,0.5;Charge Buffer]" ..
				"list[context;out;5,1;1,1;]" ..

				"list[current_player;main;0,4.25;8,1;]" ..
				"list[current_player;main;0,5.5;8,3;8]" ..
				"listring[context;fuel]" ..
				"listring[current_player;main]" ..
				default.get_hotbar_bg(0, 4.25)
		else
			-- Formspec *with* upgrade slots.
			formspec =
				"size[8,8.5]" ..
				default.formspec.get_form_colors() ..
				default.formspec.get_form_image() ..
				default.formspec.get_slot_colors() ..

				"label[1,0.5;Upgrades]" ..
				"list[context;upg;1,1;1,2;]" ..

				"label[3,0.5;Fuel Supply]" ..
				"list[context;fuel;3,1;1,1;]" ..

				"image[4,1;1,1;default_furnace_fire_bg.png^[lowpart:" ..
				(fuel_percent) .. ":default_furnace_fire_fg.png]" ..

				"image[5,1;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
				(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..

				"label[6,0.5;Charge Buffer]" ..
				"list[context;out;6,1;1,1;]" ..

				"list[current_player;main;0,4.25;8,1;]" ..
				"list[current_player;main;0,5.5;8,3;8]" ..
				"listring[context;fuel]" ..
				"listring[current_player;main]" ..
				default.get_hotbar_bg(0, 4.25)
		end
		return formspec
	end

	func.compose_infotext =
	function(pos, keeprunning)
		local meta = minetest.get_meta(pos)
		local eups = meta:get_int("eups")
		local machine_state = "Standby"
		if keeprunning then machine_state = "Active" end
		local output = math_floor(eups / v.bt)
		if not keeprunning then
			output = 0
		end
		local infotext = v.up .. " Fuel Generator (" .. machine_state .. ")\n" ..
			"Output: " .. output .. " EU Per/Sec"
		return infotext
	end



	func.can_dig =
	function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		-- The energy output inventory does not count.
		return inv:is_empty("fuel") and inv:is_empty("upg")
	end



  func.has_public_access =
  function(pos)
    if v.tier == "lv" then
      return
    end

    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    local s1 = inv:get_stack("upg", 1)
    if s1 and s1:get_count() > 0 then
      if minetest.get_item_group(s1:get_name(), "chest") > 0 then
        return true
      end
    end

    local s2 = inv:get_stack("upg", 2)
    if s2 and s2:get_count() > 0 then
      if minetest.get_item_group(s2:get_name(), "chest") > 0 then
        return true
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
			if minetest.get_craft_result({method="coalfuel", width=1, items={stack}}).time ~= 0 then
				func.trigger_update(pos)
				return stack:get_count()
			end
			if minetest.get_craft_result({method="mesefuel", width=1, items={stack}}).time ~= 0 then
				func.trigger_update(pos)
				return stack:get_count()
			end
		elseif listname == "upg" and not protected and (v.tier == "mv" or v.tier == "hv") then
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
    if (from_list == "upg" or to_list == "upg") and protected and (v.tier == "mv" or v.tier == "hv") then
			-- Don't permit public users to mess with the upgrades.
      return 0
    end
    if not protected or public then
			-- Can't touch the output energy buffer.
      if from_list == "out" or to_list == "out" then
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
			func.trigger_update(pos)
      return stack:get_count()
    elseif listname == "upg" and not protected and (v.tier == "mv" or v.tier == "hv") then
			func.trigger_update(pos)
      return stack:get_count()
    end
    return 0
	end



	func.on_timer =
	function(pos, elapsed)
		--minetest.chat_send_all("# Server: On Timer! " .. minetest.get_gametime())

		local keeprunning = false
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local inv = meta:get_inventory()

		local fuellist = inv:get_list("fuel")
		local time = meta:get_float("time")
		local time2 = meta:get_float("time2")
		local maxtime = meta:get_float("maxtime")
		local maxtime2 = v.bt
		local eups = meta:get_int("eups")
		local fuel_percent = 0
		local item_percent = 0
		local need_discharge = false

		do
			local stack = inv:get_stack("out", 1)
			if stack:get_count() >= v.buf then
				need_discharge = true
			end
		end

		-- Manage fuel.
		if time > 0 then
			-- Keep burning current fuel item.
			time = time - 1

			-- Restart timer.
			keeprunning = true

			-- Generate energy.
			time2 = time2 + 1
			if time2 >= maxtime2 then
				if not need_discharge then
					local energy = "atomic:energy " .. eups
					if inv:room_for_item("out", energy) then
						inv:add_item("out", energy)
					end
				end

				time2 = 0
			end
		else
			-- Burntime has run out, get new fuel item.
			if fuellist[1]:get_count() > 0 and not need_discharge then
				local fuel, afterfuel
				local is_mese = false
				meta:set_int("eups", 0)

				-- Try to get fuel.
				fuel, afterfuel = minetest.get_craft_result({
					method="coalfuel", width=1, items=fuellist,
				})
				if fuel.time == 0 then
					fuel, afterfuel = minetest.get_craft_result({
						method="mesefuel", width=1, items=fuellist,
					})
					is_mese = true
				end

				if fuel.time > 0 then
					-- We got a valid fuel item, consume it.
					inv:set_stack("fuel", 1, afterfuel.items[1])

					time = fuel.time
					meta:set_float("maxtime", fuel.time)
					machines.swap_node(pos, "gen2:" .. v.tier .. "_active")
					fuel_percent = 100
					keeprunning = true -- Restart timer.

					if is_mese then
						meta:set_int("eups", math_floor(v.mese))
					else
						meta:set_int("eups", v.eups)
					end
				else
					-- No valid fuel in fuel slot.
					machines.swap_node(pos, "gen2:" .. v.tier .. "_inactive")
					--minetest.get_node_timer(pos):stop()
					time2 = 0
				end
			else
				-- No more fuel, shutdown generator.
				machines.swap_node(pos, "gen2:" .. v.tier .. "_inactive")
				--minetest.get_node_timer(pos):stop()
				meta:set_int("eups", 0)
				time2 = 0
			end
		end

		-- Discharge energy into the network.
		if need_discharge then
			local energy = inv:get_stack("out", 1)
			local old = energy:get_count()
			energy:set_count(net2.put_energy(pos, owner, old, v.tier))
			inv:set_stack("out", 1, energy)
			if energy:get_count() < old then
				-- If we succeeded in discharging energy, keep doing so.
				-- Otherwise, batteries are full.
				keeprunning = true
			end
		end

		-- If generator is no longer producing energy,
		-- unload the buffered energy.
		if not keeprunning then
			local energy = inv:get_stack("out", 1)
			energy:set_count(net2.put_energy(pos, owner, energy:get_count(), v.tier))
			inv:set_stack("out", 1, energy)
		end

		-- Update infotext & formspec.
		meta:set_float("time", time)
		meta:set_float("time2", time2)

		fuel_percent = math_floor(time / maxtime * 100)
		item_percent = math_floor(time2 / maxtime2 * 100)

		meta:set_string("infotext", func.compose_infotext(pos, keeprunning))
		meta:set_string("formspec", func.compose_formspec(fuel_percent, item_percent))

		-- Determine mode (active or sleep) and set timer accordingly.
		if keeprunning then
			minetest.get_node_timer(pos):start(1.0)
		else
			-- Slow down timer during sleep periods to reduce load.
			minetest.get_node_timer(pos):start(math_random(1, 3*60))
		end
	end



	func.on_blast =
	function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "fuel", drops)
		drops[#drops+1] = "gen2:" .. v.tier .. "_inactive"
		minetest.remove_node(pos)
		return drops
	end



	func.on_construct =
	function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		meta:set_string("infotext", func.compose_infotext(pos, false))
		meta:set_string("formspec", func.compose_formspec(0, 0))

		inv:set_size("fuel", 1)
		inv:set_size("out", 1)

		-- MV and HV generators have upgrade slots.
		if v.tier == "mv" or v.tier == "hv" then
			inv:set_size("upg", 2)
		end
	end



	func.on_destruct =
	function(pos)
		local meta = minetest.get_meta(pos)
		net2.clear_caches(pos, meta:get_string("owner"), v.tier)
		nodestore.del_node(pos)
	end



	func.after_place_node =
	function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		local owner = placer:get_player_name()
		meta:set_string("nodename", node.name)
		meta:set_string("owner", owner)
		net2.clear_caches(pos, owner, v.tier)
		nodestore.add_node(pos)
	end



	func.on_metadata_inventory_move =
	function(pos)
	end



	func.on_metadata_inventory_put =
	function(pos)
	end



	func.on_metadata_inventory_take =
	function(pos, listname, index, stack, player)
	end

	func.burn_feet = function(pos, player)
		if not heatdamage.is_immune(player:get_player_name()) then
			player:set_hp(player:get_hp() - 1)
		end
	end
end



if not generator.gen2_loaded then
	-- Register active & inactive generator nodes.
	-- Generates atomic energy from coal.
	for m, n in ipairs({
		{tier="lv", up="LV"},
		{tier="mv", up="MV"},
		{tier="hv", up="HV"},
	}) do
		for k, v in ipairs({
			{name="inactive", tile="generator_" .. n.tier .. "_front.png", light=0},
			{name="active", tile="generator_" .. n.tier .. "_front_active.png", light=8},
		}) do
			-- Which function table are we operating on?
			local func = _G["gen2_" .. n.tier]

			local feet_burning_func = nil
			if v.name == "active" then
				feet_burning_func = function(...)
					return func.burn_feet(...)
				end
			end

			minetest.register_node(":gen2:" .. n.tier .. "_" .. v.name, {
				description = n.up .. " Fuel-Activated Generator\n\nCan burn coal, kalite or mese and convert it to energy.",
				tiles = {
					"generator_" .. n.tier .. "_top.png", "generator_" .. n.tier .. "_bottom.png",
					"generator_" .. n.tier .. "_side.png", "generator_" .. n.tier .. "_side.png",
					"generator_" .. n.tier .. "_side.png", v.tile,
				},

				groups = utility.dig_groups("machine"),

				paramtype2 = "facedir",
				is_ground_content = false,
				sounds = default.node_sound_metal_defaults(),
				drop = "gen2:" .. n.tier .. "_inactive",
				light_source = v.light,

				on_energy_get = function(...)
					return func.on_energy_get(...) end,
				on_rotate = function(...)
					return screwdriver.rotate_simple(...) end,
				on_punch = function(...)
					return func.on_punch(...) end,
				can_dig = function(...)
					return func.can_dig(...) end,
				on_timer = function(...)
					return func.on_timer(...) end,
				on_construct = function(...)
					return func.on_construct(...) end,
				on_destruct = function(...)
					return func.on_destruct(...) end,
				after_place_node = function(...)
					return func.after_place_node(...) end,
				on_blast = function(...)
					return func.on_blast(...) end,

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
				on_player_walk_over = feet_burning_func,
			})
		end
	end

  local c = "gen2:core"
  local f = generator.modpath .. "/generator.lua"
  reload.register_file(c, f, false)

  generator.gen2_loaded = true
end


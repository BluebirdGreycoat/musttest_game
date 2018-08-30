
bat2 = bat2 or {}
bat2_lv = bat2_lv or {}
bat2_mv = bat2_mv or {}
bat2_hv = bat2_hv or {}

for k, v in ipairs({
  {tier="lv", up="LV", name="LV", buffer=tech.battery_lv.buffer},
  {tier="mv", up="MV", name="MV", buffer=tech.battery_mv.buffer},
  {tier="hv", up="HV", name="HV", buffer=tech.battery_hv.buffer},
}) do
  -- Which function table are we operating on?
  local functable = _G["bat2_" .. v.tier]

	functable.on_energy_put =
	function(pos, energy)
		--minetest.chat_send_all("# Server: Got " .. energy .. " energy!")
		local meta = minetest.get_meta(pos)
		local chg, max = functable.get_energy_status(meta)

		local canfit = max - chg
		local toput = energy
		if toput > canfit then
			toput = canfit
		end
		local total = chg + toput
		meta:set_int("energy", total)
		energy = energy - toput

		functable.trigger_update(pos)
		return energy
	end

	functable.on_energy_get =
	function(pos, energy)
		local meta = minetest.get_meta(pos)
		local have = meta:get_int("energy")
		if have < energy then
			meta:set_int("energy", 0)
			functable.trigger_update(pos)
			return have
		end
		have = have - energy
		meta:set_int("energy", have)
		functable.trigger_update(pos)
		return energy
	end

  functable.compose_infotext =
  function(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local chg, max = functable.get_energy_status(meta)
    local size = inv:get_size("batteries")
    local cnt = functable.get_battery_count(inv)

    local infotext = v.up .. " Battery Array\n" ..
      "Internal Battery Units: " .. cnt .. "/" .. size .. "\n" ..
      "Energy: " .. chg .. "/" .. max .. " EUs\n"

    if max > 0 then
      local percent = math.floor(chg / max * 100)
      infotext = infotext .. "Charge: " .. percent .. "%"
    else
      infotext = infotext .. "Charge: 0%"
    end

    meta:set_string("infotext", infotext)
  end

  functable.compose_formspec =
  function(pos)
    local meta = minetest.get_meta(pos)
    local chg, max = functable.get_energy_status(meta)

    local charge_desc = v.name .. " Charge Status: " ..
      chg .. "/" .. max .. " EUs"

    local formspec =
      "size[8,8.5]" ..
      default.formspec.get_form_colors() ..
      default.formspec.get_form_image() ..
      default.formspec.get_slot_colors() ..

      "label[0,0;" .. minetest.formspec_escape(charge_desc) .. "]" ..

      "label[0,0.5;NRAIB (Non-Redundant Array of Independant Batteries)]" ..
			"item_image[7,0;1,1;battery:battery]" ..
      "list[context;batteries;0,1;8,2;]" ..

      "list[current_player;main;0,4.25;8,1;]" ..
      "list[current_player;main;0,5.5;8,3;8]" ..
			"listring[context;batteries]"..
			"listring[current_player;main]"..
      default.get_hotbar_bg(0, 4.25)
    meta:set_string("formspec", formspec)
  end

  functable.update_charge_visual =
  function(pos)
    local meta = minetest.get_meta(pos)
    local chg, max = functable.get_energy_status(meta)

    local name = "bat2:bt0_" .. v.tier

    if max > 0 then -- Avoid divide-by-zero.
      local percent = math.floor((chg / max) * 100)
      local sz = math.ceil(100 / 12)
      for i = 0, 12, 1 do
        if percent <= sz*i then
          name = "bat2:bt" .. i .. "_" .. v.tier
          break
        end
      end
    end

    machines.swap_node(pos, name)
  end

  functable.on_punch =
  function(pos, node, puncher, pointed_thing)
    functable.trigger_update(pos)
		functable.privatize(minetest.get_meta(pos))
  end

  functable.can_dig =
  function(pos, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    return inv:is_empty("batteries")
  end

  functable.allow_metadata_inventory_put =
  function(pos, listname, index, stack, player)
    local NBATT = "battery:battery"

    local pname = player:get_player_name()
    if minetest.test_protection(pos, pname) then
      return 0
    end

    if stack:get_name() == NBATT then
      return stack:get_count()
    end

    return 0
  end

  functable.allow_metadata_inventory_move =
  function(pos, from_list, from_index, to_list, to_index, count, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = inv:get_stack(from_list, from_index)
    return functable.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
  end

  functable.allow_metadata_inventory_take =
  function(pos, listname, index, stack, player)
    local pname = player:get_player_name()
    if minetest.test_protection(pos, pname) then
      return 0
    end

    return stack:get_count()
  end

  functable.get_battery_count =
  function(inv)
    local batteries = inv:get_list("batteries")

    local count = 0
    for k, v in ipairs(batteries) do
      if v:get_name() == "battery:battery" then
        -- Only 1 battery allowed per stack.
        count = count + 1
      end
    end
    return count
  end

  functable.update_maximum_charge =
  function(meta)
    local count = functable.get_battery_count(meta:get_inventory())

    local max
    if v.tier == "lv" then
      max = count * v.buffer
    elseif v.tier == "mv" then
      max = count * v.buffer
    elseif v.tier == "hv" then
      max = count * v.buffer
    end

    local chg = meta:get_int("energy")

    -- Ensure charge isn't over max. This can happen if user removed a battery.
    if chg > max then
      meta:set_int("energy", max)
    end
    meta:set_int("max", max)
  end

  functable.on_timer =
  function(pos, elapsed)
    local meta = minetest.get_meta(pos)

    local current_amount = meta:get_int("energy")
    local old_eu_amount = meta:get_int("old_eu")

    -- Todo: here, we can respond to changes in EU amount since last update.

    meta:set_int("old_eu", current_amount)

    -- Needed in case the operator removes or adds a battery.
    -- Also, EUs can be added/drained from batteries without going through a distributer.
    functable.update_maximum_charge(meta)

    functable.update_charge_visual(pos)
    functable.compose_infotext(pos)
    functable.compose_formspec(pos)
  end

  functable.on_blast =
  function(pos)
    local drops = {}
    default.get_inventory_drops(pos, "batteries", drops)
    drops[#drops+1] = "bat2:bt0_" .. v.tier
    minetest.remove_node(pos)
    return drops
  end

  functable.on_construct =
  function(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    inv:set_size("batteries", 8*2)

    functable.update_maximum_charge(meta)
    functable.compose_infotext(pos)
    functable.compose_formspec(pos)

		meta:set_string("nodename", "DUMMY")
		meta:set_string("owner", "DUMMY")
		meta:set_int("energy", 0)
		meta:set_int("old_eu", 0)
		meta:set_int("max", 0)

		functable.privatize(meta)
  end

	functable.privatize =
	function(meta)
		meta:mark_as_private({
			"nodename",
			"owner",
			"energy",
			"old_eu",
			"max",
		})
	end

  functable.on_destruct =
  function(pos)
		local meta = minetest.get_meta(pos)
		net2.clear_caches(pos, meta:get_string("owner"), v.tier)
		nodestore.del_node(pos)
  end

  functable.after_place_node =
  function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("nodename", minetest.get_node(pos).name)
		meta:set_string("owner", owner)
		net2.clear_caches(pos, owner, v.tier)
		nodestore.add_node(pos)
  end

  functable.on_metadata_inventory_move =
  function(pos)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_put =
  function(pos)
    functable.trigger_update(pos)
  end

  functable.on_metadata_inventory_take =
  function(pos)
    functable.trigger_update(pos)
  end

  functable.trigger_update =
  function(pos)
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
      timer:start(1.0)
    end
  end

  -- Read the current & max charge of the battery, but do not trigger any update.
  -- Function shall be used internally ONLY.
  functable.get_energy_status =
  function(meta)
    local chg = meta:get_int("energy")
    local max = meta:get_int("max")
    return chg, max
  end
end



if not bat2.run_once then
	local nodebox = {
		{0, 0, 0, 5, 16, 5},
		{11, 0, 0, 16, 16, 5},
		{0, 0, 11, 5, 16, 16},
		{11, 0, 11, 16, 16, 16},
		{1, 1, 1, 15, 15, 15},
		{0, 0, 0, 16, 1, 16},
		{0, 15, 0, 16, 16, 16},
	}
	local selectbox = {
		{0, 0, 0, 16, 16, 16},
	}
	utility.transform_nodebox(nodebox)
	utility.transform_nodebox(selectbox)

	for k, v in ipairs({
		{tier="lv", title="LV"},
		{tier="mv", title="MV"},
		{tier="hv", title="HV"},
	}) do
		-- Register 13 nodes for each tier; each node has a different texture set to show the charge level.
		for i = 0, 12, 1 do
			-- Which function table are we operating on?
			local functable = _G["bat2_" .. v.tier]

			minetest.register_node(":bat2:bt" .. i .. "_" .. v.tier, {
				drawtype = "nodebox",
				description = v.title .. " Battery Box",
				tiles = {
					"technic_" .. v.tier .. "_battery_box_top.png",
					"technic_" .. v.tier .. "_battery_box_bottom.png",
					"technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
					"technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
					"technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
					"technic_" .. v.tier .. "_battery_box_side.png^battery_meter" .. i .. ".png",
				},

				groups = {level=1, cracky=3},

				paramtype = "light",
				paramtype2 = "facedir",
				is_ground_content = false,
				sounds = default.node_sound_metal_defaults(),
				drop = "bat2:bt0_" .. v.tier,

				node_box = {
					type = "fixed",
					fixed = nodebox,
				},

				selection_box = {
					type = "fixed",
					fixed = selectbox,
				},

				on_energy_put = function(...)
					return functable.on_energy_put(...) end,
				on_energy_get = function(...)
					return functable.on_energy_get(...) end,
				on_punch = function(...)
					return functable.on_punch(...) end,
				can_dig = function(...)
					return functable.can_dig(...) end,
				on_timer = function(...)
					return functable.on_timer(...) end,
				on_construct = function(...)
					return functable.on_construct(...) end,
				on_destruct = function(...)
					return functable.on_destruct(...) end,
				after_place_node = function(...)
					return functable.after_place_node(...) end,
				on_metadata_inventory_move = function(...)
					return functable.on_metadata_inventory_move(...) end,
				on_metadata_inventory_put = function(...)
					return functable.on_metadata_inventory_put(...) end,
				on_metadata_inventory_take = function(...)
					return functable.on_metadata_inventory_take(...) end,
				on_blast = function(...)
					return functable.on_blast(...) end,
				on_rotate = function(...)
					return screwdriver.rotate_simple(...) end,
				allow_metadata_inventory_put = function(...)
					return functable.allow_metadata_inventory_put(...) end,
				allow_metadata_inventory_move = function(...)
					return functable.allow_metadata_inventory_move(...) end,
				allow_metadata_inventory_take = function(...)
					return functable.allow_metadata_inventory_take(...) end,
			})
		end
	end

	local c = "bat2:core"
	local f = battery.modpath .. "/bat2.lua"
	reload.register_file(c, f, false)

	bat2.run_once = true
end

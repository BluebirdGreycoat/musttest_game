
charger = charger or {}
charger.modpath = minetest.get_modpath("machines")

local BUFFER_SIZE = tech.charger.buffer
local ENERGY_AMOUNT = tech.charger.power



charger.compose_formspec =
function(pos)
	local formspec =
		"size[8,4.5]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..

		"label[1.0,0.5;Upgrade]" ..
		"list[context;upg;1.0,1;1,1]" ..

		"label[3.5,0.5;Energy Buffer]" ..
		"list[context;buffer;3.5,1;1,1]" ..

		"label[6.0,0.5;Tool Recharge]" ..
		"list[context;main;6.0,1;1,1]" ..

		"list[current_player;main;0,3.5;8,1;]" ..
		"listring[context;main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 3.5)

	return formspec
end

charger.on_receive_fields =
function(pos, formname, fields, sender)
end

charger.compose_infotext =
function(pos)
	local meta = minetest.get_meta(pos)
	local state = "Standby"
	local eups = 0
	if meta:get_int("active") == 1 then
		state = "Active"
		eups = ENERGY_AMOUNT
	end
	local infotext = "LV Charging Device (" .. state .. ")\n" ..
		"Demand: " .. eups .. " EU Per/Sec"
	return infotext
end

charger.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
	-- Restart timer even if already running.
	timer:start(1.0)
end

charger.on_punch =
function(pos, node, puncher, pointed_thing)
  charger.trigger_update(pos)

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("upg", 1)
end

charger.can_dig =
function(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("main") and inv:is_empty("upg")
end

charger.on_timer =
function(pos, elapsed)
	--minetest.chat_send_all("# Server: Elapsed time is " .. elapsed .. "!")

	local keeprunning = false
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local the_tool -- Set to tool's itemstack if we have one.
	local got_energy = false
	local energy_gotten = 0

	-- Assuming we can keep running unless someone says otherwise.
	keeprunning = true
	do
		local tool = inv:get_stack("main", 1)
		if tool:get_count() == 1 then
			local name = tool:get_name()
			local def = minetest.registered_items[name]
			if def and def.wear_represents and def.wear_represents == "eu_charge" then
				local wear = tool:get_wear()
				if wear == 1 then
					-- Tool fully charged.
					keeprunning = false
					goto cancel
				elseif wear > 1 then
					-- We got a tool and it needs recharging.
					the_tool = tool
				else
					-- Tool has never been charged before (wear is 0).
					assert(wear == 0)
					wear = 65534
					tool:set_wear(wear)
					inv:set_stack("main", 1, tool)

					-- Wait for next iteration before beginning charge.
					goto cancel
				end
			else
				-- Unknown item.
				keeprunning = false
				goto cancel
			end
		else
			-- No tool.
			keeprunning = false
			goto cancel
		end
	end

	-- Consume energy (but only if there is a tool to charge).
	if the_tool then
		local energy = inv:get_stack("buffer", 1)
		if energy:get_count() >= ENERGY_AMOUNT then
			energy:set_count(energy:get_count() - ENERGY_AMOUNT)
			inv:set_stack("buffer", 1, energy)
			-- We have enough energy.
			energy_gotten = ENERGY_AMOUNT
			got_energy = true
		else
			-- Try to get energy from network.
			local owner = meta:get_string("owner")
			local gotten = net2.get_energy(pos, owner, BUFFER_SIZE, "lv")
			if gotten >= ENERGY_AMOUNT then
				energy = ItemStack("atomic:energy " .. (energy:get_count() + gotten))
				inv:set_stack("buffer", 1, energy)
				-- Wait for next iteration before producing again.
				goto cancel
			end

			-- Not enough energy!
			keeprunning = false
			goto cancel
		end
	end

	-- Charge the tool.
	if the_tool and got_energy then
		local wear = the_tool:get_wear()
		wear = wear - energy_gotten
		if wear < 1 then
			wear = 1
		end
		the_tool:set_wear(wear)
		inv:set_stack("main", 1, the_tool)
	end

	-- Jump here if something prevents machine from working.
	::cancel::

	-- Determine mode (active or sleep) and set timer accordingly.
	if keeprunning then
		minetest.get_node_timer(pos):start(1.0)
		meta:set_int("active", 1)
	else
		-- Slow down timer during sleep periods to reduce load.
		minetest.get_node_timer(pos):start(math.random(1, 3*60))
		meta:set_int("active", nil)
	end

	-- Update infotext.
  meta:set_string("formspec", charger.compose_formspec(pos))
	meta:set_string("infotext", charger.compose_infotext(pos))
end

charger.on_construct =
function(pos)
end

charger.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
  local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
  inv:set_size("buffer", 1)
	inv:set_size("main", 1)
	inv:set_size("upg", 1)

	net2.clear_caches(pos, owner, "lv")
  meta:set_string("formspec", charger.compose_formspec(pos))
  meta:set_string("infotext", charger.compose_infotext(pos))
	nodestore.add_node(pos)

	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end

charger.on_blast =
function(pos)
  local drops = {}
  drops[#drops+1] = "charger:charger"
	default.get_inventory_drops(pos, "main", drops)
  minetest.remove_node(pos)
  return drops
end

charger.has_public_access =
function(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- There is only 1 upgrade slot.
	local s1 = inv:get_stack("upg", 1)
	if s1 and s1:get_count() > 0 then
		if minetest.get_item_group(s1:get_name(), "chest") > 0 then
			return true
		end
	end
end

charger.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	local public = charger.has_public_access(pos)
	local protected = false

	if minetest.test_protection(pos, pname) then
		protected = true
	end

	if listname == "main" and (not protected or public) then
		local def = minetest.registered_items[stack:get_name()]
		if def and def.wear_represents and def.wear_represents == "eu_charge" then
			return 1
		end
	elseif listname == "upg" and not protected then
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

charger.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
	local pname = player:get_player_name()
	local public = charger.has_public_access(pos)
	local protected = false

	if minetest.test_protection(pos, pname) then
		protected = true
	end

	if (from_list == "upg" or to_list == "upg") and protected then
		-- Don't permit public users to mess with the upgrades.
		return 0
	end
	if not protected or public then
		-- Can't touch the output energy buffer.
		if from_list == "buffer" or to_list == "buffer" then
			return 0
		end
		if from_list == to_list then
			return count
		end
	end
	return 0
end

charger.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	local public = charger.has_public_access(pos)
	local protected = false

	if minetest.test_protection(pos, pname) then
		protected = true
	end

	if listname == "main" and (not protected or public) then
		return stack:get_count()
	elseif listname == "upg" and not protected then
		return stack:get_count()
	end

	return 0
end

charger.on_metadata_inventory_move =
function(pos)
  charger.trigger_update(pos)
end

charger.on_metadata_inventory_put =
function(pos)
  charger.trigger_update(pos)
end

charger.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  charger.trigger_update(pos)
end

charger.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	net2.clear_caches(pos, meta:get_string("owner"), "lv")
	nodestore.del_node(pos)
end



if not charger.run_once then
	minetest.register_node(":charger:charger", {
		description = "LV Charging Device\n\nA machine for recharging energy tools.\nConnects to a power-network.",
		tiles = {
			"charger_top.png",
			"charger_top.png",
			"charger_side.png",
			"charger_side.png",
			"charger_side.png",
			"charger_side.png",
		},

		groups = {level=1, cracky=3},

		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),

		drop = "charger:charger",

		on_rotate = function(...)
			return screwdriver.rotate_simple(...) end,
		allow_metadata_inventory_put = function(...)
			return charger.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_move = function(...)
			return charger.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_take = function(...)
			return charger.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...)
			return charger.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...)
			return charger.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...)
			return charger.on_metadata_inventory_take(...) end,
		on_punch = function(...)
			return charger.on_punch(...) end,
		can_dig = function(...)
			return charger.can_dig(...) end,
		on_timer = function(...)
			return charger.on_timer(...) end,
		on_construct = function(...)
			return charger.on_construct(...) end,
		on_destruct = function(...)
			return charger.on_destruct(...) end,
		on_blast = function(...)
			return charger.on_blast(...) end,
		after_place_node = function(...)
			return charger.after_place_node(...) end,
		on_receive_fields = function(...)
			return charger.on_receive_fields(...) end,
	})

	---[[
	minetest.register_craft({
		output = "charger:charger",
		recipe = {
			{"techcrafts:control_logic_unit"},
			{"fine_wire:silver"},
			{"bat2:bt0_lv"},
		},
	})
	--]]

  local c = "charger:core"
  local f = charger.modpath .. "/charger.lua"
  reload.register_file(c, f, false)

	charger.run_once = true
end

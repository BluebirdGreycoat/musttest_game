
conv2 = conv2 or {}
conv2.modpath = minetest.get_modpath("converter")

local BUFFER_SIZE = tech.converter.buffer
local ENERGY_AMOUNT = tech.converter.power

-- First key is voltage from. Second key is voltage to.
-- Note that we never have 'from' and 'to' be the same voltage tier.
local efficiency = {
	lv = {
		lv = 1.0,
		mv = 0.7,
		hv = 0.1,
	},
	mv = {
		lv = 0.9,
		mv = 1.0,
		hv = 0.7,
	},
	hv = {
		lv = 0.7,
		mv = 0.9,
		hv = 1.0,
	},
}



conv2.get_config_data =
function(pos, side) -- side should be p1 or p2.
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local inv = meta:get_inventory()
	local cfg = inv:get_stack("config", 1)

	if cfg:get_count() == 1 and cfg:get_name() == "cfg:dev" then
		local meta1 = cfg:get_meta()
		local pos1 = minetest.string_to_pos(meta1:get_string(side))

		if pos1 then
			if vector.distance(pos, pos1) < 1.01 then
				local node = minetest.get_node(pos1)
				local nmeta = minetest.get_meta(pos1)
				local nowner = nmeta:get_string("owner")

				if string.find(node.name, "^stat2:") and owner == nowner then
					local tier = string.sub(node.name, 7)
					-- Return success, pos, tier, owner.
					return true, pos1, tier, nowner
				end
			end
		end
	end

	return false
end



conv2.on_energy_put =
function(pos, energy, tier)
	-- Can only put energy into machine if it comes from the input side.
	local gooda, posa, tiera, owna = conv2.get_config_data(pos, "p1")
	if not gooda then
		return energy
	end
	if tier ~= tiera then
		return energy
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local stack = inv:get_stack("buffer", 1)
	local chg, max = stack:get_count(), BUFFER_SIZE

	local canfit = max - chg
	if canfit < 0 then canfit = 0 end
	local toput = energy
	if toput > canfit then
		toput = canfit
	end
	local total = chg + toput
	inv:set_stack("buffer", 1, "atomic:energy " .. total)
	energy = energy - toput

	conv2.trigger_update(pos)
	return energy
end

conv2.compose_formspec =
function(pos)
	local formspec =
		"size[8,4]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..

		"label[2,0.5;Config]" ..
		"list[context;config;2,1;1,1]" ..

		"label[5,0.5;Energy]" ..
		"list[context;buffer;5,1;1,1]" ..

		"list[current_player;main;0,3;8,1;]" ..
		"listring[context;config]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 3)
	return formspec
end

conv2.compose_infotext =
function(pos, tiera, tierb, invalidconfig, keeprunning)
	local active = "Standby"
	if keeprunning then
		active = "Active"
	end
	local infotext = "Voltage Transformer (" .. active .. ")\n" ..
		"Configuration: "
	if invalidconfig then
		infotext = infotext .. "Invalid/Unknown"
	else
		--print(tiera)
		--print(tierb)
		infotext = infotext .. string.upper(tiera) .. " -> " .. string.upper(tierb) .. "\n" ..
			"Efficiency: " .. math.floor(efficiency[tiera][tierb] * 100) .. "%"
	end
	return infotext
end

conv2.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
	-- Restart timer even if already running.
	timer:start(1.0)
end

conv2.on_punch =
function(pos, node, puncher, pointed_thing)
  conv2.trigger_update(pos)
end

conv2.can_dig =
function(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("config")
end

conv2.on_timer =
function(pos, elapsed)
	--minetest.chat_send_player("MustTest", "# Server: On Timer! " .. minetest.get_gametime())

	local keeprunning = false
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")
	local needflush = false
	local invalidconfig = false
	local putgood = false
	local getgood = false

	local gooda, posa, tiera, owna = conv2.get_config_data(pos, "p1")
	local goodb, posb, tierb, ownb = conv2.get_config_data(pos, "p2")

	if not gooda or not goodb then
		invalidconfig = true
		goto the_end
	end

	-- Tiers cannot be same.
	if tiera == tierb then
		invalidconfig = true
		goto the_end
	end

	-- Check if we need to discharge energy.
	do -- Scoped local variable to prevent problems with goto.
		local curstack = inv:get_stack("buffer", 1)
		if curstack:get_count() >= BUFFER_SIZE then
			needflush = true
		end
	end

	-- Draw energy from network above only if not needing a flush.
	if not needflush then
		local toget = ENERGY_AMOUNT
		local energy = net2.get_energy(posa, owna, toget, tiera)
		local estack = ItemStack("atomic:energy " .. energy)
		inv:add_item("buffer", estack)
		if energy >= toget then
			getgood = true -- We were able to get wanted amount of energy.
		end
	end

	-- Discharge energy into network below.
	if needflush then
		-- There should be at least BUFFER_SIZE energy in inventory.
		local total_energy = inv:get_stack("buffer", 1)
		local eff = efficiency[tiera][tierb]
		local amount_to_send = math.floor(total_energy:get_count() * eff)
		local amount_not_sent = net2.put_energy(posb, ownb, amount_to_send, tierb)

		-- 3 possible cases.
		if amount_not_sent == amount_to_send then
			-- No energy could be stored in the network.
			-- Don't change energy buffered.
		elseif amount_not_sent == 0 then
			-- All energy sent was stored in the network.
			inv:set_stack("buffer", 1, ItemStack(""))
			putgood = true
		else
			-- Energy was only partially stored.
			assert(amount_not_sent < amount_to_send)
			assert(amount_not_sent > 0)
			local amount_sent = (amount_to_send - amount_not_sent)
			-- print((7000*100)/(0.7*100))
			local full_cost = math.floor((amount_sent*100)/(eff*100))
			assert(total_energy:get_count() > full_cost)
			local energy_remaining = total_energy:take_item(full_cost)
			inv:set_stack("buffer", 1, energy_remaining)
		end
	end

	::the_end::

	-- Determine if we should enter sleep mode, or keep running.
	if getgood or putgood then
		keeprunning = true
	end
	if invalidconfig then
		keeprunning = false
	end

	meta:set_string("infotext", conv2.compose_infotext(pos, tiera, tierb, invalidconfig, keeprunning))
	if keeprunning then
		minetest.get_node_timer(pos):start(1.0)
	else
		minetest.get_node_timer(pos):start(math.random(1, 60*3))
	end
end

conv2.on_construct =
function(pos)
end

conv2.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
  local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
  inv:set_size("buffer", 1)
	inv:set_size("config", 1)

	net2.clear_caches(pos, owner, "lv")
	net2.clear_caches(pos, owner, "mv")
	net2.clear_caches(pos, owner, "hv")

  meta:set_string("formspec", conv2.compose_formspec(pos))
  meta:set_string("infotext", conv2.compose_infotext(pos, "", "", true, false))
	nodestore.add_node(pos)

	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end

conv2.on_blast =
function(pos)
  local drops = {}
	default.get_inventory_drops(pos, "config", drops)
  drops[#drops+1] = "conv2:converter"
  minetest.remove_node(pos)
  return drops
end

conv2.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
	if minetest.test_protection(pos, player:get_player_name()) then
		return 0
	end
	if listname == "config" and stack:get_name() == "cfg:dev" then
		return stack:get_count()
	end
  return 0
end

conv2.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

conv2.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
	if minetest.test_protection(pos, player:get_player_name()) then
		return 0
	end
	if listname == "config" then
		return stack:get_count()
	end
  return 0
end

conv2.on_metadata_inventory_move =
function(pos)
  conv2.trigger_update(pos)
end

conv2.on_metadata_inventory_put =
function(pos)
  conv2.trigger_update(pos)
end

conv2.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  conv2.trigger_update(pos)
end

conv2.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	net2.clear_caches(pos, owner, "lv")
	net2.clear_caches(pos, owner, "mv")
	net2.clear_caches(pos, owner, "hv")
	nodestore.del_node(pos)
end



if not conv2.run_once then
	minetest.register_node(":conv2:converter", {
		description = "Voltage Transformer\n\nThis machine requires a WR Config Device to configure it.\nThe configurator should point to adjacent cable boxes.",
    tiles = {
      "converter_top.png", "converter_top.png",
      "converter_side.png", "converter_side.png",
      "converter_side.png", "converter_side.png",
    },

		groups = utility.dig_groups("machine"),

		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
		drop = "conv2:converter",

		on_energy_put = function(...)
			return conv2.on_energy_put(...) end,
		on_rotate = function(...)
			return screwdriver.rotate_simple(...) end,
		allow_metadata_inventory_put = function(...)
			return conv2.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_move = function(...)
			return conv2.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_take = function(...)
			return conv2.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...)
			return conv2.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...)
			return conv2.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...)
			return conv2.on_metadata_inventory_take(...) end,
		on_punch = function(...)
			return conv2.on_punch(...) end,
		can_dig = function(...)
			return conv2.can_dig(...) end,
		on_timer = function(...)
			return conv2.on_timer(...) end,
		on_construct = function(...)
			return conv2.on_construct(...) end,
		on_destruct = function(...)
			return conv2.on_destruct(...) end,
		on_blast = function(...)
			return conv2.on_blast(...) end,
		after_place_node = function(...)
			return conv2.after_place_node(...) end,
	})

	local c = "conv2:core"
	local f = conv2.modpath .. "/conv2.lua"
	reload.register_file(c, f, false)

	conv2.run_once = true
end

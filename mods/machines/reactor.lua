
-- Functions for the generator nodes.
reactor = reactor or {}
reactor_inactive = reactor_inactive or {}
reactor_active = reactor_active or {}
reactor.siren = reactor.siren or {}

local BUFFER_SIZE = tech.reactor.buffer
local ENERGY_TIME = tech.reactor.time
local TOTAL_COOK_TIME = tech.reactor.totaltime
local ENERGY_AMOUNT = tech.reactor.power
local REACTOR_TIER = "hv"



local SS_OFF = 0
local SS_DANGER = 1
local SS_CLEAR = 2

local reactor_siren = reactor.siren
local function siren_set_state(pos, state)
	local hpos = minetest.hash_node_position(pos)
	local siren = reactor_siren[hpos]
	if not siren then
		if state == SS_OFF then return end
		siren = {state=SS_OFF}
		reactor_siren[hpos] = siren
	end
	if state == SS_DANGER and siren.state ~= SS_DANGER then
		if siren.handle then minetest.sound_stop(siren.handle) end
		siren.handle = minetest.sound_play("technic_hv_nuclear_reactor_siren_danger_loop",
				{pos=pos, gain=1.5, loop=true, max_hear_distance=48})
		siren.state = SS_DANGER
	elseif state == SS_CLEAR then
		if siren.handle then minetest.sound_stop(siren.handle) end
		local clear_handle = minetest.sound_play("technic_hv_nuclear_reactor_siren_clear",
				{pos=pos, gain=1.5, loop=false, max_hear_distance=48})
		siren.handle = clear_handle
		siren.state = SS_CLEAR
		minetest.after(10, function()
			if siren.handle ~= clear_handle then return end
			minetest.sound_stop(clear_handle)
			if reactor_siren[hpos] == siren then
				reactor_siren[hpos] = nil
			end
		end)
	elseif state == SS_OFF and siren.state ~= SS_OFF then
		if siren.handle then minetest.sound_stop(siren.handle) end
		reactor_siren[hpos] = nil
	end
end

local function siren_danger(pos, meta)
	meta:set_int("siren", 1)
	siren_set_state(pos, SS_DANGER)
end

local function siren_clear(pos, meta)
	if meta:get_int("siren") ~= 0 then
		siren_set_state(pos, SS_CLEAR)
		meta:set_int("siren", 0)
	end
end



local function get_reactor_damage(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local vm = VoxelManip()
	local pos1 = vector.subtract(pos, 4)
	local pos2 = vector.add(pos, 4)
	local MinEdge, MaxEdge = vm:read_from_map(pos1, pos2)
	local data = vm:get_data()
	local area = VoxelArea:new({MinEdge=MinEdge, MaxEdge=MaxEdge})

	local c_blast_concrete = minetest.get_content_id("concrete:brc")
	local c_lead = minetest.get_content_id("lead:block")
	local c_steel = minetest.get_content_id("stainless_steel:block")
	local c_water_source = minetest.get_content_id("default:water_source")
	local c_water_flowing = minetest.get_content_id("default:water_flowing")
	local c_river_source = minetest.get_content_id("default:river_water_source")
	local c_river_flowing = minetest.get_content_id("default:river_water_flowing")
	local c_concrete = minetest.get_content_id("concrete:concrete")

	local concrete_layer, blast_layer, lead_layer, water_layer = 0, 0, 0, 0

	for z = pos1.z, pos2.z do
	for y = pos1.y, pos2.y do
	for x = pos1.x, pos2.x do
		local cid = data[area:index(x, y, z)]
		if x == pos1.x+0 or x == pos2.x-0 or
		   y == pos1.y+0 or y == pos2.y-0 or
		   z == pos1.z+0 or z == pos2.z-0 then
			if cid == c_concrete then
				concrete_layer = concrete_layer + 1
			end
		elseif x == pos1.x+1 or x == pos2.x-1 or
					 y == pos1.y+1 or y == pos2.y-1 or
		       z == pos1.z+1 or z == pos2.z-1 then
			if cid == c_blast_concrete then
				blast_layer = blast_layer + 1
			end
		elseif x == pos1.x+2 or x == pos2.x-2 or
		       y == pos1.y+2 or y == pos2.y-2 or
		       z == pos1.z+2 or z == pos2.z-2 then
			if cid == c_lead or cid == c_steel then
				lead_layer = lead_layer + 1
			end
		elseif x == pos1.x+3 or x == pos2.x-3 or
		       y == pos1.y+3 or y == pos2.y-3 or
		       z == pos1.z+3 or z == pos2.z-3 then
			if cid == c_water_source or cid == c_water_flowing or cid == c_river_source or cid == c_river_flowing then
				water_layer = water_layer + 1
			end
		end
	end
	end
	end

	--minetest.chat_send_player("MustTest", "Checking reactor!")

	-- Debug!
	--if minetest.is_singleplayer() or gdac.player_is_admin(owner) then
	--	return 0
	--end

	if water_layer > 25 then water_layer = 25 end
	if lead_layer > 96 then lead_layer = 96 end
	if blast_layer > 216 then blast_layer = 216 end
	if concrete_layer > 384 then concrete_layer = 384 end
	return (25 - water_layer) +
		(96 - lead_layer) +
		(216 - blast_layer) +
		(384 - concrete_layer)
end



local function check_environment(pos, meta)
	--minetest.chat_send_player("MustTest", "Check env!")

  local timer = meta:get_int("chktmr")
  --local active = meta:get_int("active")
  if timer <= 0 then
		local result = false
		local good = false

		local damage = get_reactor_damage(pos)
		if damage == 0 then
			good = true
		end

		--minetest.chat_send_player("MustTest", "Reactor damage: " .. damage .. "!")

    if good then
			meta:set_string("error", "DUMMY")
      result = false
    else
			meta:set_string("error", "INSUFFICIENT REACTOR SHIELDING!")
      result = true -- Bad
    end

		-- Randomize time to next nodecheck.
		meta:set_int("chktmr", math.random(1*60, 3*60))
		return result
  end

  -- Decrement check timer.
  timer = timer - 1
  meta:set_int("chktmr", timer)

  -- No check performed.
  return nil
end



for k, v in ipairs({
	{name="inactive"},
	{name="active"},
}) do
  -- Which function table are we operating on?
  local func = _G["reactor_" .. v.name]

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

	func.reactor_destroy =
	function(pos)
		minetest.after(0, function()
			tnt.boom(pos, {
				radius = 20,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 30,
				disable_drops = true,
			})

			local minp = vector.subtract(pos, 1)
			local maxp = vector.add(pos, 1)

			-- Transform reactor and all water around it into lava.
			-- Must be done *after* explosion runs.
			for x=minp.x, maxp.x do
			for y=minp.y, maxp.y do
			for z=minp.z, maxp.z do
				local p = {x=x, y=y, z=z}
				if p.y < -14 then
					minetest.set_node(p, {name="default:lava_source"})
					minetest.transforming_liquid_add(p)
				else
					minetest.set_node(p, {name="fire:basic_flame"})
				end
			end
			end
			end
		end)
	end

	func.trigger_update =
	function(pos)
		local timer = minetest.get_node_timer(pos)
		-- Restart timer even if already running.
		timer:start(1.0)
	end



	func.on_punch =
	function(pos, node, puncher, pointed_thing)
		--minetest.chat_send_player("MustTest", "Punched!")
		func.trigger_update(pos)

		-- Check reactor integrity.
		local meta = minetest.get_meta(pos)
		meta:set_int("chktmr", 0)

		func.privatize(meta)
	end



	func.compose_formspec =
	function(fuel_percent, item_percent)
		local formspec =
			"size[8,8.5]" ..
			default.formspec.get_form_colors() ..
			default.formspec.get_form_image() ..
			default.formspec.get_slot_colors() ..

			"label[1,0.5;Uranium Rod Compartment]" ..
			"list[context;fuel;1,1;3,2;]" ..

			"image[4,1.5;1,1;default_furnace_fire_bg.png^[lowpart:" ..
			(fuel_percent) .. ":default_furnace_fire_fg.png]" ..

			"image[5,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
			(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..

			"label[6,1.0;Charge Buffer]" ..
			"list[context;out;6,1.5;1,1;]" ..

			"list[current_player;main;0,4.25;8,1;]" ..
			"list[current_player;main;0,5.5;8,3;8]" ..
			"listring[context;fuel]" ..
			"listring[current_player;main]" ..
			default.get_hotbar_bg(0, 4.25)
		return formspec
	end

	func.compose_infotext =
	function(pos, keeprunning)
		local meta = minetest.get_meta(pos)
		local eups = meta:get_int("eups")
		local machine_state = "Standby"
		if keeprunning then machine_state = "Active" end
		local output = math.floor(eups / ENERGY_TIME)
		if not keeprunning then
			output = 0
		end
		local infotext = "Fission Reactor (" .. machine_state .. ")\n" ..
			"Output: " .. output .. " EU Per/Sec"
		local err = meta:get_string("error") or "DUMMY"
		if err ~= "" and err ~= "DUMMY" then
			infotext = infotext .. "\n" .. err
		end
		local damage = meta:get_int("damage")
		if damage > 0 then
			infotext = infotext .. "\nReactor damage: " .. damage .. "!"
		end
		return infotext
	end



	func.can_dig =
	function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		-- The energy output inventory does not count.
		return inv:is_empty("fuel")
	end



	func.allow_metadata_inventory_put =
	function(pos, listname, index, stack, player)
		if minetest.test_protection(pos, player:get_player_name()) then
			return 0
		end

		if listname == "fuel" then
			local node = minetest.get_node(pos)
			-- Cannot put rods in an active reactor.
			if node.name == "reactor:inactive" and stack:get_name() == "uranium:rod" then
				return stack:get_count()
			end
		end
		return 0
	end



	func.allow_metadata_inventory_move =
	function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end



	func.allow_metadata_inventory_take =
	function(pos, listname, index, stack, player)
		if minetest.test_protection(pos, player:get_player_name()) then
			return 0
		end

		if listname == "fuel" then
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
		local time = meta:get_int("time")
		local time2 = meta:get_float("time2")
		local maxtime = meta:get_int("maxtime")
		local maxtime2 = ENERGY_TIME
		local eups = meta:get_int("eups")
		local fuel_percent = 0
		local item_percent = 0
		local need_discharge = false

		-- This sets infotext, so must always call this.
		local bad = check_environment(pos, meta)

		if v.name == "active" then
			if bad ~= nil then
				if bad then
					meta:set_int("bad", 1)
					siren_danger(pos, meta)
				else
					if meta:get_int("bad") == 1 then
						siren_clear(pos, meta)
					end
					meta:set_int("bad", 0)
				end
			end

			-- Damage reactor over time if bad.
			if meta:get_int("bad") == 1 then
				local damage = meta:get_int("damage")
				damage = damage + 1
				meta:set_int("damage", damage)

				-- Destroy reactor after 10 minutes of continous damage.
				if damage > 60*10 then
					func.reactor_destroy(pos)
					return
				end
			else
				-- Slowly decrease damage if not bad.
				local damage = meta:get_int("damage")
				if damage > 0 then
					damage = damage - 1
					meta:set_int("damage", damage)
				end
			end
		else
			-- Slowly decrease damage when inactive.
			local damage = meta:get_int("damage")
			if damage > 0 then
				damage = damage - 1
				meta:set_int("damage", damage)
			end
		end

		-- Radiation damage to nearby players.
		if v.name == "active" then
			local entities = minetest.get_objects_inside_radius(pos, 4.5)
			for k, v in ipairs(entities) do
				if v:is_player() then
					v:set_hp(v:get_hp() - 1)
					-- Radiation exhausts player.
					sprint.set_stamina(v, 0)
				end
			end
		end

		do
			local stack = inv:get_stack("out", 1)
			--minetest.chat_send_player("MustTest", "# Server: " .. stack:get_count() .. " charge!")
			if stack:get_count() >= BUFFER_SIZE then
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
					else
						-- No room? Huh. Discharge reactor!
						-- Note: this can happen because charge to be added would be
						-- greater than stack_max. This bug was actually observed.
						-- It is only likely to affect high-output machines.
						need_discharge = true
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

				-- Check if we have enough fuel.
				local rods = 0
				for i = 1, 6, 1 do
					local stack = inv:get_stack("fuel", i)
					if stack:get_name() == "uranium:rod" and stack:get_count() > 0 then
						rods = rods + 1
					end
				end

				-- Try to get fuel.
				fuel, afterfuel = minetest.get_craft_result({
					method="coalfuel", width=1, items=fuellist,
				})

				if rods == 6 then
					-- We got uranium rods, consume them.
					for i = 1, 6, 1 do
						inv:set_stack("fuel", i, ItemStack(""))
					end

					time = TOTAL_COOK_TIME
					meta:set_int("maxtime", TOTAL_COOK_TIME)
					machines.swap_node(pos, "reactor:active")
					fuel_percent = 100
					keeprunning = true -- Restart timer.
					meta:set_int("eups", ENERGY_AMOUNT)
				else
					-- No valid fuel in fuel slot.
					machines.swap_node(pos, "reactor:inactive")
					--minetest.get_node_timer(pos):stop()
					time2 = 0
				end
			else
				-- No more fuel, shutdown generator.
				machines.swap_node(pos, "reactor:inactive")
				--minetest.get_node_timer(pos):stop()
				meta:set_int("eups", 0)
				time2 = 0
			end
		end

		-- Discharge energy into the network.
		if need_discharge then
			--minetest.chat_send_player("MustTest", "# Server: Discharging reactor!")

			local energy = inv:get_stack("out", 1)
			local old = energy:get_count()
			energy:set_count(net2.put_energy(pos, owner, old, REACTOR_TIER))
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
			energy:set_count(net2.put_energy(pos, owner, energy:get_count(), REACTOR_TIER))
			inv:set_stack("out", 1, energy)
		end

		-- Update infotext & formspec.
		meta:set_int("time", time)
		meta:set_float("time2", time2)

		fuel_percent = math.floor(time / maxtime * 100)
		item_percent = math.floor(time2 / maxtime2 * 100)

		meta:set_string("infotext", func.compose_infotext(pos, keeprunning))
		meta:set_string("formspec", func.compose_formspec(fuel_percent, item_percent))

		-- Determine mode (active or sleep) and set timer accordingly.
		if keeprunning then
			minetest.get_node_timer(pos):start(1.0)

			-- Change water to salt water sometimes.
			if math.random(1, 60) == 1 then
				local minp = {x=pos.x-1, y=pos.y-1, z=pos.z-1}
				local maxp = {x=pos.x+1, y=pos.y+1, z=pos.z+1}
				local nodes = minetest.find_nodes_in_area(minp, maxp, {
					"default:water_source",
					"default:water_flowing",
					"default:river_water_flowing",
				})
				if nodes and #nodes > 0 then
					minetest.set_node(nodes[math.random(1, #nodes)], {name="default:river_water_source"})
				end
			end
		else
			-- Slow down timer during sleep periods to reduce load.
			minetest.get_node_timer(pos):start(math.random(1, 3*60))
		end
	end



	func.on_blast =
	function(pos)
		local drops = {}
		-- Ignore contents of fuel inventory.
		minetest.remove_node(pos)
		if v.name == "active" then
			func.reactor_destroy(pos)
		else
			-- Only save reactor if it wasn't active.
			drops[#drops+1] = "reactor:inactive"
		end
		return drops
	end



	func.on_construct =
	function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		meta:set_string("infotext", func.compose_infotext(pos, false))
		meta:set_string("formspec", func.compose_formspec(0, 0))

		--minetest.chat_send_player("MustTest", "Constructed!")

		inv:set_size("fuel", 6)
		inv:set_size("out", 1)

		meta:set_string("owner", "DUMMY")
		meta:set_string("error", "DUMMY")
		meta:set_string("nodename", "DUMMY")
		meta:set_int("siren", 0)
		meta:set_int("chktmr", 0)
		meta:set_int("eups", 0)
		meta:set_int("damage", 0)
		meta:set_int("time", 0)
		meta:set_int("maxtime", 0)
		meta:set_int("bad", 0)
		meta:set_float("time2", 0.0)

		func.privatize(meta)
	end

	func.privatize =
	function(meta)
		meta:mark_as_private({
			"nodename", "bad", "time2", "maxtime", "siren", "owner",
			"chktmr", "error", "eups", "damage", "time",
		})
	end



	func.on_destruct =
	function(pos)
		local meta = minetest.get_meta(pos)
		siren_set_state(pos, SS_OFF)
		net2.clear_caches(pos, meta:get_string("owner"), REACTOR_TIER)
		nodestore.del_node(pos)
		if v.name == "active" then
			func.reactor_destroy(pos)
		end
	end



	func.after_place_node =
	function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		local owner = placer:get_player_name()
		meta:set_string("nodename", node.name)
		meta:set_string("owner", owner)
		net2.clear_caches(pos, owner, REACTOR_TIER)
		nodestore.add_node(pos)
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
	function(pos, listname, index, stack, player)
		func.trigger_update(pos)
	end
end



if not reactor.run_once then
	for k, v in ipairs({
		{name="inactive", light=0},
		{name="active", light=14},
	}) do
		-- Which function table are we operating on?
		local func = _G["reactor_" .. v.name]

		minetest.register_node(":reactor:" .. v.name, {
			description = "Fission Reactor Core\n\nConnects to an HV power-network.\nGenerates huge amounts of power.\nExplosion danger, requires shielding!",
			tiles = {"reactor_core.png"},

			groups = {level=1, cracky=3},

			paramtype2 = "facedir",
			is_ground_content = false,
			sounds = default.node_sound_metal_defaults(),
			drop = "reactor:inactive",
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
		})
	end

	minetest.register_craft({
		output = 'reactor:inactive',
		recipe = {
			{'techcrafts:carbon_plate',          'default:obsidian_glass', 'techcrafts:carbon_plate'},
			{'techcrafts:composite_plate',       'gen2:hv_inactive', 'techcrafts:composite_plate'},
			{'stainless_steel:ingot', 'geo2:lv_inactive',       'stainless_steel:ingot'},
		}
	})

  local c = "reactor:core"
  local f = machines.modpath .. "/reactor.lua"
  reload.register_file(c, f, false)

  reactor.run_once = true
end


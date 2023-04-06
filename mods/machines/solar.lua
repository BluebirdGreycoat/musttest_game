
if not minetest.global_exists("solar") then solar = {} end
solar.modpath = minetest.get_modpath("machines")

if not minetest.global_exists("solar_lv") then solar_lv = {} end
if not minetest.global_exists("solar_mv") then solar_mv = {} end
if not minetest.global_exists("solar_hv") then solar_hv = {} end

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random



function do_log(meta, str)
	local owner = meta:get_string("owner")
	if gdac.player_is_admin(owner) then
		minetest.chat_send_player(owner, str)
	end
end



for k, v in ipairs({
	{tier="lv", up2="LV", power=tech.solar_lv.power, buffer=tech.solar_lv.buffer},
	{tier="mv", up2="MV", power=tech.solar_mv.power, buffer=tech.solar_mv.buffer},
	{tier="hv", up2="HV", power=tech.solar_hv.power, buffer=tech.solar_hv.buffer},
}) do
	-- Which function table are we operating on?
	local func = _G["solar_" .. v.tier]

	func.on_energy_get =
	function(pos, energy)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local have = inv:get_stack("buffer", 1):get_count()
		if have < energy then
			inv:set_stack("buffer", 1, ItemStack(""))
			func.trigger_update(pos)
			return have
		end
		have = have - energy
		inv:set_stack("buffer", 1, ItemStack("atomic:energy " .. have))
		func.trigger_update(pos)
		return energy
	end

	func.compose_formspec =
	function(pos)
		local formspec =
			"size[2,2.5]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..

			"label[0,0.5;Energy Buffer]" ..
			"list[context;buffer;0,1;1,1]"
		return formspec
	end

	func.compose_infotext =
	function(pos)
		local meta = minetest.get_meta(pos)
		local eups = meta:get_int("eups")
		local state = "Standby"
		if meta:get_int("active") == 1 then
			state = "Active"
		end
		local infotext = v.up2 .. " Solar Array (" .. state .. ")\n" ..
			"Output: " .. eups .. " EU Per/Sec"
		return infotext
	end

	func.on_player_walk_over =
	function(pos, player)
		player:set_hp(player:get_hp() - 1)
	end

	func.trigger_update =
	function(pos)
		local timer = minetest.get_node_timer(pos)
		-- Start timer anew even if already running.
		timer:start(1.0)
	end

	func.on_punch =
	function(pos, node, puncher, pointed_thing)
		func.trigger_update(pos)
	end

	func.can_dig =
	function(pos, player)
		return true
	end

	func.check_environment =
	function(pos, meta)
		local timer = meta:get_int("chktmr")
		local active = meta:get_int("active")
		if timer <= 0 then
			-- Check environment.
			local goodenv = false
			local eu_rate = 0
			local result = false

			local above = {x=pos.x, y=pos.y+1, z=pos.z}
			local light = minetest.get_node_light(above, nil) or 0
			local tod = minetest.get_timeofday()
			--do_log(meta, "Light: " .. light)

			local success, groundlevel = rc.get_ground_level_at_pos(pos)

			if success then
				if light >= 15 and tod >= 0.24 and tod <= 0.76 and pos.y >= -10 then
					--do_log(meta, "Has goodenv!")
					goodenv = true
					local h = (pos.y - groundlevel)
					if h > 60 then h = 60 end
					if h < 0 then h = 0 end
					-- Normalize.
					h = h / 60
					-- Add scaling to power output.
					eu_rate = math_floor(v.power * h)
					-- Clamp.
					if eu_rate < 1 then eu_rate = 1 end
				end
			end

			if goodenv then
				--minetest.chat_send_all("# Server: Good env!")
				-- Randomize time to next nodecheck.
				meta:set_int("chktmr", math_random(3, 15))

				meta:set_int("active", 1)
				meta:set_int("eups", eu_rate)
				result = true
			else
				--minetest.chat_send_all("# Server: Bad env!")
				meta:set_int("chktmr", 0)
				meta:set_int("active", 0)
				meta:set_int("eups", 0)
				result = false
			end

			meta:set_string("infotext", func.compose_infotext(pos))
			return result
		end

		-- Decrement check timer.
		timer = timer - 1
		meta:set_int("chktmr", timer)

		-- No check performed; just return whatever the result of the last check was.
		return (active == 1)
	end

	func.on_timer =
	function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local inv = meta:get_inventory()
		local keeprunning = false

		-- Check if we can produce energy from environment.
		-- Note that this uses a caching algorithm.
		local canrun = func.check_environment(pos, meta)

		-- If environment is no longer producing energy,
		-- unload the buffered energy.
		if not canrun then
			local energy = inv:get_stack("buffer", 1)
			energy:set_count(net2.put_energy(pos, owner, energy:get_count(), v.tier))
			inv:set_stack("buffer", 1, "atomic:energy " .. energy:get_count())
		end

		-- Produce energy.
		local needdischarge = false
		if canrun then
			local eups = meta:get_int("eups")
			local energy = "atomic:energy " .. eups
			local stack = inv:get_stack("buffer", 1)
			if stack:get_count() >= v.buffer then
				needdischarge = true
			end
			if not needdischarge then
				if inv:room_for_item("buffer", energy) then
					inv:add_item("buffer", energy)
				end
			end
			keeprunning = true
		end

		-- Discharge energy.
		if needdischarge then
			local energy = inv:get_stack("buffer", 1)
			-- Unload energy onto the network.
			local old = energy:get_count()
			energy:set_count(net2.put_energy(pos, owner, old, v.tier))
			inv:set_stack("buffer", 1, "atomic:energy " .. energy:get_count())
			if energy:get_count() < old then
				keeprunning = true
			else
				-- Batteries full? Go to sleep.
				keeprunning = false
			end
		end

		-- Determine mode (active or sleep) and set timer accordingly.
		if keeprunning then
			minetest.get_node_timer(pos):start(1.0)
		else
			-- Slow down timer during sleep periods to reduce load.
			minetest.get_node_timer(pos):start(math_random(1, 3*60))
			meta:set_int("chktmr", 0)
			meta:set_int("active", 0)
			meta:set_int("eups", 0)
			meta:set_string("infotext", func.compose_infotext(pos))
		end
	end

	func.on_construct =
	function(pos)
	end

	func.after_place_node =
	function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		local owner = placer:get_player_name()
		local inv = meta:get_inventory()

		meta:set_string("owner", owner)
		meta:set_string("nodename", node.name)
		--meta:set_string("infotext", v.up2 .. " Solar Array")
		inv:set_size("buffer", 1)

		net2.clear_caches(pos, owner, v.tier)
		meta:set_string("formspec", func.compose_formspec(pos))
		meta:set_string("infotext", func.compose_infotext(pos))
		nodestore.add_node(pos)

		-- Start timer.
		local timer = minetest.get_node_timer(pos)
		timer:start(1.0)
	end

	func.on_blast =
	function(pos)
		local drops = {}
		drops[#drops+1] = "solar:" .. v.tier
		minetest.remove_node(pos)
		return drops
	end

	func.allow_metadata_inventory_put =
	function(pos, listname, index, stack, player)
		return 0
	end

	func.allow_metadata_inventory_move =
	function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end

	func.allow_metadata_inventory_take =
	function(pos, listname, index, stack, player)
		return 0
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

	func.on_destruct =
	function(pos)
		local meta = minetest.get_meta(pos)
		net2.clear_caches(pos, meta:get_string("owner"), v.tier)
		nodestore.del_node(pos)
	end
end



if not solar.run_once then
  for k, v in ipairs({
    {tier="lv", up="LV"},
    {tier="mv", up="MV"},
		{tier="hv", up="HV"},
  }) do
    -- Which function table are we operating on?
    local func = _G["solar_" .. v.tier]

    minetest.register_node(":solar:" .. v.tier, {
			drawtype = "nodebox",
      description = "Arrayed Solar " .. v.up .. " Generator",

			tiles = {
				"technic_" .. v.tier .. "_solar_array_top.png",
				"technic_" .. v.tier .. "_solar_array_bottom.png",
				"technic_" .. v.tier .. "_solar_array_side.png",
				"technic_" .. v.tier .. "_solar_array_side.png",
				"technic_" .. v.tier .. "_solar_array_side.png",
				"technic_" .. v.tier .. "_solar_array_side.png",
			},

			node_box = {
				type = "fixed",
				fixed = {
					{-0.5, -0.5, -0.5, 0.5, -((0.5/8)*4), 0.5},
					{-0.5, -((0.5/8)*6), -((0.5/8)*3), 0.5, -((0.5/8)*3), ((0.5/8)*3)},
					{-((0.5/8)*3), -((0.5/8)*6), -0.5, ((0.5/8)*3), -((0.5/8)*3), 0.5},
				},
			},

      groups = utility.dig_groups("machine"),

			paramtype = "light",
      paramtype2 = "facedir",
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "solar:" .. v.tier,

			on_energy_get = function(...)
				return func.on_energy_get(...) end,
      on_rotate = function(...)
				return screwdriver.rotate_simple(...) end,
      allow_metadata_inventory_put = function(...)
        return func.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return func.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return func.allow_metadata_inventory_take(...) end,
      on_metadata_inventory_move = function(...)
        return func.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return func.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return func.on_metadata_inventory_take(...) end,
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
      on_blast = function(...)
        return func.on_blast(...) end,
      after_place_node = function(...)
        return func.after_place_node(...) end,
			on_player_walk_over = function(...)
				return func.on_player_walk_over(...) end,
    })
  end

	minetest.register_craft({
		output = 'solar:lv',
		recipe = {
			{'solar:panel',        'solar:panel',    'solar:panel'},
			{'carbon_steel:ingot', 'transformer:lv', 'carbon_steel:ingot'},
			{'',                           'cb2:lv',       ''},
		}
	})

	minetest.register_craft({
		output = 'solar:mv',
		recipe = {
			{'solar:lv',     'solar:lv', 'solar:lv'},
			{'carbon_steel:ingot', 'transformer:mv', 'carbon_steel:ingot'},
			{'',                           'cb2:mv',       ''},
		}
	})

	minetest.register_craft({
		output = 'solar:hv',
		recipe = {
			{'solar:mv',     'solar:mv', 'solar:mv'},
			{'techcrafts:carbon_plate',       'transformer:hv', 'techcrafts:composite_plate'},
			{'',                           'cb2:hv',       ''},
		}
	})

	local c = "solar:core"
	local f = solar.modpath .. "/solar.lua"
	reload.register_file(c, f, false)

	solar.run_once = true
end


if not minetest.global_exists("panel") then panel = {} end
panel.modpath = minetest.get_modpath("machines")

local BUFFER_SIZE = tech.solar_panel.buffer
local POWER_OUTPUT = tech.solar_panel.power

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random



panel.on_energy_get =
function(pos, energy)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local have = inv:get_stack("buffer", 1):get_count()
	if have < energy then
		inv:set_stack("buffer", 1, ItemStack(""))
		panel.trigger_update(pos)
		return have
	end
	have = have - energy
	inv:set_stack("buffer", 1, ItemStack("atomic:energy " .. have))
	panel.trigger_update(pos)
	return energy
end



panel.on_player_walk_over =
function(pos, player)
	utility.damage_player(player, "electrocute", 1*500)
end



panel.compose_formspec =
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

panel.compose_infotext =
function(pos)
	local meta = minetest.get_meta(pos)
	local eups = meta:get_int("eups")
	local state = "Standby"
	if meta:get_int("active") == 1 then
		state = "Active"
	end
	local infotext = "LV Solar Panel (" .. state .. ")\n" ..
		"Output: " .. eups .. " EU Per/Sec"
	return infotext
end

panel.trigger_update =
function(pos)
	local timer = minetest.get_node_timer(pos)
	-- Start timer anew even if already running.
	timer:start(1.0)
end

panel.on_punch =
function(pos, node, puncher, pointed_thing)
	panel.trigger_update(pos)
end

panel.can_dig =
function(pos, player)
	return true
end

panel.check_environment =
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

		local success, groundlevel = rc.get_ground_level_at_pos(pos)

		if success then
			if light >= 15 and tod >= 0.24 and tod <= 0.76 and pos.y >= -10 then
				goodenv = true
				local h = (pos.y - groundlevel)
				if h > 60 then h = 60 end
				if h < 0 then h = 0 end
				-- Normalize.
				h = h / 60
				-- Add scaling to power output.
				eu_rate = math_floor(POWER_OUTPUT * h)
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

		meta:set_string("infotext", panel.compose_infotext(pos))
		return result
	end

	-- Decrement check timer.
	timer = timer - 1
	meta:set_int("chktmr", timer)

	-- No check performed; just return whatever the result of the last check was.
	return (active == 1)
end

panel.on_timer =
function(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local inv = meta:get_inventory()
	local keeprunning = false

	-- Check if we can produce energy from environment.
	-- Note that this uses a caching algorithm.
	local canrun = panel.check_environment(pos, meta)

	-- If environment is no longer producing energy,
	-- unload the buffered energy.
	if not canrun then
		local energy = inv:get_stack("buffer", 1)
		energy:set_count(net2.put_energy(pos, owner, energy:get_count(), "lv"))
		inv:set_stack("buffer", 1, energy)
	end

	-- Produce energy.
	local needdischarge = false
	if canrun then
		local eups = meta:get_int("eups")
		local energy = "atomic:energy " .. eups
		local stack = inv:get_stack("buffer", 1)
		if stack:get_count() >= BUFFER_SIZE then
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
		energy:set_count(net2.put_energy(pos, owner, old, "lv"))
		inv:set_stack("buffer", 1, energy)
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
		meta:set_string("infotext", panel.compose_infotext(pos))
	end
end

panel.on_construct =
function(pos)
end

panel.after_place_node =
function(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
	local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
	inv:set_size("buffer", 1)

	net2.clear_caches(pos, owner, "lv")
	meta:set_string("formspec", panel.compose_formspec(pos))
	meta:set_string("infotext", panel.compose_infotext(pos))
	nodestore.add_node(pos)

	-- Start timer.
	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end

panel.on_blast =
function(pos)
	local drops = {}
	drops[#drops+1] = "solar:panel"
	minetest.remove_node(pos)
	return drops
end

panel.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
	return 0
end

panel.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
	return 0
end

panel.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
	return 0
end

panel.on_metadata_inventory_move =
function(pos)
	panel.trigger_update(pos)
end

panel.on_metadata_inventory_put =
function(pos)
	panel.trigger_update(pos)
end

panel.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
	panel.trigger_update(pos)
end

panel.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	net2.clear_caches(pos, meta:get_string("owner"), "lv")
	nodestore.del_node(pos)
end



if not panel.run_once then
	local nodebox = {
		{0, 0, 0, 16, 2, 16},
	}
	for k, v in ipairs(nodebox) do
		for m, n in ipairs(v) do
			local p = nodebox[k][m]
			p = p / 16
			p = p - 0.5
			nodebox[k][m] = p
		end
	end

	minetest.register_node(":solar:panel", {
		drawtype = "nodebox",
		description = "LV Solar Panel",

		tiles = {
			"solar_panel_top.png",
			"solar_panel_side.png",
			"solar_panel_side.png",
			"solar_panel_side.png",
			"solar_panel_side.png",
			"solar_panel_side.png",
		},

		node_box = {
			type = "fixed",
			fixed = nodebox,
		},

		groups = utility.dig_groups("machine"),

		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
		drop = "solar:panel",

		on_energy_get = function(...)
			return panel.on_energy_get(...) end,
		on_rotate = function(...)
			return screwdriver.rotate_simple(...) end,
		allow_metadata_inventory_put = function(...)
			return panel.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_move = function(...)
			return panel.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_take = function(...)
			return panel.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...)
			return panel.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...)
			return panel.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...)
			return panel.on_metadata_inventory_take(...) end,
		on_punch = function(...)
			return panel.on_punch(...) end,
		can_dig = function(...)
			return panel.can_dig(...) end,
		on_timer = function(...)
			return panel.on_timer(...) end,
		on_construct = function(...)
			return panel.on_construct(...) end,
		on_destruct = function(...)
			return panel.on_destruct(...) end,
		on_blast = function(...)
			return panel.on_blast(...) end,
		after_place_node = function(...)
			return panel.after_place_node(...) end,
		on_player_walk_over = function(...)
			return panel.on_player_walk_over(...) end,
	})

	minetest.register_craft({
		output = 'solar:panel',
		recipe = {
			{'silicon:doped_wafer', 'silicon:doped_wafer', 'silicon:doped_wafer'},
			{'fine_wire:silver',    'cb2:lv',            'fine_wire:gold'},
		}
	})

	local c = "panel:core"
	local f = panel.modpath .. "/panel.lua"
	reload.register_file(c, f, false)

	panel.run_once = true
end

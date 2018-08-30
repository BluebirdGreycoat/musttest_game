
distrib2 = distrib2 or {}
distrib2.modpath = minetest.get_modpath("distributer")

distrib2_lv = distrib2_lv or {}
distrib2_mv = distrib2_mv or {}
distrib2_hv = distrib2_hv or {}



for k, v in ipairs({
	{tier="lv", up="LV", buffer=tech.distributer_lv.buffer, power=tech.distributer_lv.power},
	{tier="mv", up="MV", buffer=tech.distributer_mv.buffer, power=tech.distributer_mv.power},
	{tier="hv", up="HV", buffer=tech.distributer_hv.buffer, power=tech.distributer_hv.power},
}) do
  -- Which function table are we operating on?
  local func = _G["distrib2_" .. v.tier]

	func.compose_formspec =
	function(pos)
		local meta = minetest.get_meta(pos)
		local formspec =
			"size[5,2.5]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..

			"label[0,0.5;Energy Buffer]" ..
			"list[context;buffer;0,1;1,1]"

		local modename = "Mode: Obtaining EU"
		if meta:get_int("toggle") == 1 then
			modename = "Mode: Distributing EU"
		end

		formspec = formspec ..
			"label[2,0.5;" .. modename .. "]" ..
			"button[2,1;3,1;toggle;Toggle Mode]"

		return formspec
	end

	func.on_receive_fields =
	function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.toggle then
			if meta:get_int("toggle") == 1 then
				meta:set_int("toggle", 0)
			else
				meta:set_int("toggle", 1)
			end
			func.trigger_update(pos)

			-- Only need update if something changed.
			meta:set_string("formspec", func.compose_formspec(pos))
			meta:set_string("infotext", func.compose_infotext(pos, false))
		end
	end

	func.compose_infotext =
	function(pos, keeprunning)
		local active = "Standby"
		if keeprunning then
			active = "Active"
		end
		local demand = "Output"
		local meta = minetest.get_meta(pos)
		if meta:get_int("toggle") == 1 then
			demand = "Demand"
		end
		local amount = v.power
		if not keeprunning then
			amount = 0
		end
		local infotext = v.up .. " Grid Splicer (" .. active .. ")\n" ..
			demand .. ": " .. amount .. " Per/Sec"
		return infotext
	end

	func.trigger_update =
	function(pos)
		local timer = minetest.get_node_timer(pos)
		-- Restart timer even if already running.
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

	func.on_timer =
	function(pos, elapsed)
		local keeprunning = false
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local owner = meta:get_string("owner")

		if meta:get_int("toggle") == 1 then
			-- Distribute EU.
			-- Get EU from own network and store in buffer.
			-- When buffer full, deliver to adjacent consumers.
			local energy = inv:get_stack("buffer", 1)
			if energy:get_count() < v.buffer then
				local gotten = net2.get_energy(pos, owner, v.power, v.tier)
				if gotten >= v.power then
					keeprunning = true
				end
				gotten = energy:get_count() + gotten
				inv:set_stack("buffer", 1, "atomic:energy " .. gotten)
			else
				local adjacent = {
					{x=pos.x+1, y=pos.y, z=pos.z},
					{x=pos.x-1, y=pos.y, z=pos.z},
					{x=pos.x, y=pos.y+1, z=pos.z},
					{x=pos.x, y=pos.y-1, z=pos.z},
					{x=pos.x, y=pos.y, z=pos.z+1},
					{x=pos.x, y=pos.y, z=pos.z-1},
				}
				local targets = {}
				local machine = "distrib2:" .. v.tier .. "_machine"
				for i, j in ipairs(adjacent) do
					if minetest.get_node(j).name == machine then
						local m2 = minetest.get_meta(j)
						local i2 = m2:get_inventory()
						--if m2:get_string("owner") ~= owner then
							if i2:get_stack("buffer", 1):get_count() < v.buffer then
								targets[#targets+1] = j
							end
						--end
					end
				end
				if #targets > 0 then
					local energy = inv:get_stack("buffer", 1)
					local toeach = math.floor(energy:get_count() / (#targets))
					toeach = math.floor(toeach * 0.8) -- 80% efficiency.
					if toeach > 0 then
						for i, j in ipairs(targets) do
							local m2 = minetest.get_meta(j)
							local i2 = m2:get_inventory()
							local e2 = i2:get_stack("buffer", 1)
							i2:set_stack("buffer", 1, "atomic:energy " .. (e2:get_count() + toeach))
							if i2:get_stack("buffer", 1):get_count() >= v.buffer then
								func.trigger_update(j)
							end
						end
						keeprunning = true
					end
					inv:set_stack("buffer", 1, ItemStack(""))
				end
			end
		else
			-- Obtain EU.
			-- Deliver EU currently in buffer to own network.
			local energy = inv:get_stack("buffer", 1)
			if energy:get_count() > 0 then
				local give = energy:get_count()
				if give > v.power then give = v.power end
				local left = net2.put_energy(pos, owner, give, v.tier)
				if left == 0 then
					keeprunning = true
				end
				local sub = (give - left)
				inv:set_stack("buffer", 1, "atomic:energy " .. (energy:get_count() - sub))
			end
		end

		meta:set_string("infotext", func.compose_infotext(pos, keeprunning))
		if keeprunning then
			minetest.get_node_timer(pos):start(1.0)
		else
			minetest.get_node_timer(pos):start(math.random(1, 60*3))
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
		inv:set_size("buffer", 1)

		net2.clear_caches(pos, owner, v.tier)

		meta:set_string("formspec", func.compose_formspec(pos))
		meta:set_string("infotext", func.compose_infotext(pos, false))
		nodestore.add_node(pos)

		local timer = minetest.get_node_timer(pos)
		timer:start(1.0)
	end

	func.on_blast =
	function(pos)
		local drops = {}
		drops[#drops+1] = "distrib2:" .. v.tier .. "_machine"
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
		local owner = meta:get_string("owner")
		net2.clear_caches(pos, owner, v.tier)
		nodestore.del_node(pos)
	end
end



if not distrib2.run_once then
	for m, n in ipairs({
		{tier="lv", up="LV"},
		{tier="mv", up="MV"},
		{tier="hv", up="HV"},
	}) do
		-- Which function table are we operating on?
		local func = _G["distrib2_" .. n.tier]

		minetest.register_node(":distrib2:" .. n.tier .. "_machine", {
			description = n.up .. " Grid Splicer\n\nThis machine connects energy grids having different owners.\nNormally all machines and cables in a network must have the same owner.\nThis machine allows to share power between networks with different owners.",
			tiles = {
				"network_connector_" .. n.tier .. "_top.png", "network_connector_" .. n.tier .. "_top.png",
				"network_connector_" .. n.tier .. "_side.png", "network_connector_" .. n.tier .. "_side.png",
				"network_connector_" .. n.tier .. "_side.png", "network_connector_" .. n.tier .. "_side.png",
			},

			groups = {level=1, cracky=3},

			paramtype2 = "facedir",
			is_ground_content = false,
			sounds = default.node_sound_metal_defaults(),
			drop = "distrib2:" .. n.tier .. "_machine",

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
			on_receive_fields = function(...)
				return func.on_receive_fields(...) end,
		})
	end

	minetest.register_craft({
		output = 'distrib2:lv_machine',
		recipe = {
			{'fine_wire:gold', 'rubber:rubber_fiber', 'silicon:doped_wafer'},
			{'cb2:lv', 'techcrafts:machine_casing', 'cb2:lv'},
			{'techcrafts:control_logic_unit', 'rubber:rubber_fiber', 'fine_wire:silver'},
		}
	})

	minetest.register_craft({
		output = 'distrib2:mv_machine',
		recipe = {
			{'carbon_steel:ingot', 'rubber:rubber_fiber', 'carbon_steel:ingot'},
			{'cb2:mv', 'distrib2:lv_machine', 'cb2:mv'},
			{'carbon_steel:ingot', 'rubber:rubber_fiber', 'carbon_steel:ingot'},
		}
	})

	minetest.register_craft({
		output = 'distrib2:hv_machine',
		recipe = {
			{'stainless_steel:ingot', 'rubber:rubber_fiber', 'stainless_steel:ingot'},
			{'cb2:hv', 'distrib2:mv_machine', 'cb2:hv'},
			{'stainless_steel:ingot', 'rubber:rubber_fiber', 'stainless_steel:ingot'},
		}
	})

	local c = "distrib2:core"
	local f = distrib2.modpath .. "/v2.lua"
	reload.register_file(c, f, false)

	distrib2.run_once = true
end

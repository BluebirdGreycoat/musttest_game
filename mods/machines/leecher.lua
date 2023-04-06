
if not minetest.global_exists("leecher") then leecher = {} end
leecher.data = leecher.data or {}
leecher.modpath = minetest.get_modpath("machines")
leecher.liquid_range = 20

-- Localize for performance.
local math_random = math.random

local BUFFER_SIZE = tech.leecher.buffer
local ENERGY_AMOUNT = tech.leecher.power
local DISSOLVE_HEIGHT = 120



-- Per testing, this function will load a node from any position on the map as
-- long as it was previously generated.
local function safe_get_node(p)
	local n = minetest.get_node_or_nil(p)
	if not n then
		-- Load map and get node.
		-- This will still return "ignore" if the location was never generated.
		local v = VoxelManip(p, p)
		n = v:get_node_at(p)
	end
	return n
end



-- What results should machine give for these ore types?
-- Ores without an entry here will produce nothing!
local ore_conversion_data = {
	["akalin:ore"] = "akalin:dust",
	["alatro:ore"] = "alatro:dust",
	["arol:ore"] = "arol:dust",
	["chromium:ore"] = "chromium:dust",
	["kalite:ore"] = "kalite:dust",
	["lead:ore"] = "lead:dust",
	["default:stone_with_iron"] = "dusts:iron",
	["default:stone_with_coal"] = "dusts:coal",
	["default:stone_with_copper"] = "dusts:copper",
	["default:stone_with_gold"] = "dusts:gold",
	["default:stone_with_diamond"] = "dusts:diamond",
	["default:desert_stone_with_coal"] = "dusts:coal",
	["default:desert_stone_with_iron"] = "dusts:iron",
	["default:desert_stone_with_copper"] = "dusts:copper",
	["default:desert_stone_with_diamond"] = "dusts:diamond",
	["moreores:mineral_tin"] = "dusts:tin",
	["moreores:mineral_silver"] = "dusts:silver",
	["moreores:mineral_mithril"] = "dusts:mithril",
	["glowstone:glowstone"] = "glowstone:glowing_dust",
	["glowstone:minerals"] = "glowstone:glowing_dust",
	["glowstone:luxore"] = "glowstone:glowing_dust",
	["rackstone:redrack_with_coal"] = "dusts:coal",
	["rackstone:redrack_with_iron"] = "dusts:iron",
	["rackstone:redrack_with_copper"] = "dusts:copper",
	["rackstone:redrack_with_tin"] = "dusts:tin",
	["talinite:ore"] = "talinite:dust",
	["thorium:ore"] = "thorium:dust",
	["uranium:ore"] = "uranium:dust",
	["zinc:ore"] = "zinc:dust",
	["sulfur:ore"] = "sulfur:dust",
}

-- Nodes listed here are dissolved without any result.
local ore_dissolve_data = {
	["default:stone"] = true,
	["default:desert_stone"] = true,
	["rackstone:redrack"] = true,
	["rackstone:rackstone"] = true,
	["rackstone:mg_redrack"] = true,
	["rackstone:mg_rackstone"] = true,
}

-- Nodes listed here can only be obtained by dropping them via ceiling-cavitation.
local ore_drop_data = {
	["gems:ruby_ore"] = true,
	["gems:emerald_ore"] = true,
	["gems:sapphire_ore"] = true,
	["gems:amethyst_ore"] = true,
	["default:clay"] = true,
	["default:sand"] = true,
	["default:dirt"] = true,
	["default:gravel"] = true,
	["default:stone_with_mese"] = true,
	["default:mese"] = true,
	["rackstone:dauthsand"] = true,
	["rackstone:blackrack"] = true,
	["rackstone:bluerack"] = true,
	["quartz:quartz_ore"] = true,
	["titanium:ore"] = true,
	["morerocks:marble"] = true,
	["morerocks:marble_pink"] = true,
	["morerocks:marble_white"] = true,
	["morerocks:granite"] = true,
	["morerocks:serpentine"] = true,
	["luxore:luxore"] = true,
}



-- Queued algorithm.
local function get_water_surface(startpos)
	local traversal = {}
	local queue = {}
	local output = {}
	local curpos, hash, exists, name, found, depth, is_water, is_leecher
	local first = true
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
	local max_depth = leecher.liquid_range
	startpos.d = 1
	queue[#queue+1] = startpos

	::continue::
	curpos = queue[#queue]
	queue[#queue] = nil

	depth = curpos.d
	curpos.d = nil

	hash = get_node_hash(curpos)
	exists = false
	if traversal[hash] then
		exists = true
		if depth >= traversal[hash] then
			goto next
		end
	end

	if depth >= max_depth then
		goto next
	end

	name = get_node(curpos).name
	found = false
	is_water = false
	is_leecher = false

	if name == "default:water_source" or name == "default:river_water_source" then
		is_water = true
		found = true
	end

	if name == "leecher:leecher" then
		is_leecher = true
		found = true
	end

	-- Water must have air above.
	if found and is_water then
		if get_node(vector.add(curpos, {x=0, y=1, z=0})).name ~= "air" then
			found = false
		end
	end

	if not found then
		goto next
	end

	traversal[hash] = depth
	if not exists then
		if is_water or is_leecher then
			output[#output+1] = curpos
		end
	end

	-- Queue up adjacent locations.
	-- We only search horizontally.
	queue[#queue+1] = {x=curpos.x+1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x-1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z+1, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z-1, d=depth+1}

	::next::
	first = false
	if #queue > 0 then
		goto continue
	end

	-- Max water count is ~144.
	--minetest.chat_send_all("water: " .. #output)
	return output
end



local function do_water_boiling(pos)
	local nn = minetest.get_node(pos).name
	if nn == "default:water_source" or nn == "default:river_water_source" then
		local bubbles = {
			amount = math_random(3, 5),
			time = 1.0,
			minpos = vector.add(pos, {x=-1, y=0.5, z=-1}),
			maxpos = vector.add(pos, {x=1, y=0.5, z=1}),
			minvel = vector.new(-0.2, 1.0, -0.2),
			maxvel = vector.new(0.2, 5.0, 0.2),
			minacc = vector.new(0.0, -1, 0.0),
			maxacc = vector.new(0.0, -5, 0.0),
			minexptime = 0.5,
			maxexptime = 2,
			minsize = 0.5,
			maxsize = 1.5,
			collisiondetection = true,
			collision_removal = true,
			vertical = false,
			texture = "bubble.png",
		}
		minetest.add_particlespawner(bubbles)
	end
end



local function check_outsalting_done(heights)
	local reached_max = false
	local count = 0
	local size = 0
	for k, v in pairs(heights) do
		size = size + 1
		if v >= DISSOLVE_HEIGHT then
			count = count + 1
		end
	end
	if count == size and size > 0 then
		reached_max = true
	end
	return reached_max
end



-- Dig ceiling above position.
local function do_ceiling_dig(pos, heights)
	local hash = minetest.hash_node_position(pos)
	local yheight = heights[hash] or 0
	yheight = yheight + 1

	local p3 = vector.new(pos)
	p3.y = p3.y + yheight
	while safe_get_node(p3).name == "air" do
		p3.y = p3.y + 1
		yheight = yheight + 1
	end

	heights[hash] = yheight

	if yheight >= DISSOLVE_HEIGHT then
		return false, nil
	end

	if true then
		local p = {x=pos.x, y=pos.y+yheight, z=pos.z}
		local node = safe_get_node(p)
		if node.name == "air" then
			-- Keep going.
		elseif node.name == "ignore" then
			-- Stop on finding "ignore".
			return false, nil
		elseif ore_dissolve_data[node.name] then
			if not minetest.test_protection(p, "") then
				-- Dissolve node without giving any result.
				minetest.remove_node(p)
				minetest.check_for_falling(p)
				return true, nil
			else
				return false, nil
			end
		elseif ore_conversion_data[node.name] then
			-- If we encounter a dissolvable node, dissolve it.
			if not minetest.test_protection(p, "") then
				minetest.remove_node(p)
				minetest.check_for_falling(p)
				local count = math_random(4, 16)

				-- Any param2 value other than 0 indicates this node was NOT placed by
				-- the mapgen.
				if node.param2 ~= 0 then
					count = math_random(4, 8)
				end

				local stack = ItemStack(ore_conversion_data[node.name] .. " " .. count)
				if stack:is_known() then
					return true, stack
				else
					return false, nil
				end
			else
				return false, nil
			end
		elseif ore_drop_data[node.name] then
			if not minetest.test_protection(p, "") then
				-- Undissolvable node, just drop it.
				sfn.drop_node(p)
				minetest.check_for_falling(p)
				return true, nil
			else
				return false, nil
			end
		else
			-- If it's protected, we ran into a developed zone, the machine should go
			-- into standby mode.
			if minetest.test_protection(p, "") then
				return false, nil
			end

			-- Unrecognized node, drop it.
			sfn.drop_node(p)
			minetest.check_for_falling(p)
			return true, nil
		end
	end

	return true, nil
end



leecher.compose_formspec =
function(pos)
	local formspec =
		"size[8,4.5]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..

		"label[0.5,1.5;Energy Buffer]" ..
		"list[context;buffer;0.5,2;1,1]" ..

		"list[context;main;4.5,0;3,3]" ..

		"list[current_player;main;0,3.5;8,1;]" ..
		"listring[context;main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 3.5)

	local meta = minetest.get_meta(pos)
	if meta:get_int("enabled") == 1 then
		formspec = formspec ..
			"label[0.5,0;Outsalter Enabled]" ..
			"button[0.5,0.4;2.5,1;toggle;Disable Machine]"
	else
		formspec = formspec ..
			"label[0.5,0;Outsalter Disabled]" ..
			"button[0.5,0.4;2.5,1;toggle;Enable Machine]"
	end

	return formspec
end



leecher.on_receive_fields =
function(pos, formname, fields, sender)
	if minetest.test_protection(pos, sender:get_player_name()) then
		return
	end

	local meta = minetest.get_meta(pos)

	if fields.toggle then
		if meta:get_int("enabled") == 1 then
			meta:set_int("enabled", 0)
		else
			meta:set_int("enabled", 1)
		end
		leecher.trigger_update(pos)

		-- Only need update if something changed.
		meta:set_string("formspec", leecher.compose_formspec(pos))
	end
end



leecher.compose_infotext =
function(pos)
	local meta = minetest.get_meta(pos)
	local state = "Standby"
	local eups = 0
	if meta:get_int("active") == 1 then
		state = "Active"
		eups = meta:get_int("eups_usage")
	end
	local infotext = "HV Mineral Outsalter (" .. state .. ")\n" ..
		"Demand: " .. eups .. " EU Per/Sec"
	local errstr = meta:get_string("error")
	if errstr ~= "" and errstr ~= "DUMMY" then
		infotext = infotext .. "\nMessage: " .. errstr
	end
	return infotext
end



leecher.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
	-- Restart timer even if already running.
	timer:start(1.0)
end



leecher.on_punch =
function(pos, node, puncher, pointed_thing)
  leecher.trigger_update(pos)
end



leecher.can_dig =
function(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("main")
end



leecher.on_timer =
function(pos, elapsed)
	--minetest.chat_send_all("# Server: Elapsed time is " .. elapsed .. "!")

	local keeprunning = false
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local hash = minetest.hash_node_position(pos)
	local try_run = false

	-- If the machine is enabled, keep running.
	if meta:get_int("enabled") == 1 then
		try_run = true
		meta:set_string("error", "DUMMY")
	end

	if try_run then
		-- Assuming we can keep running unless someone says otherwise.
		keeprunning = true

		-- Ensure external datatable exists.
		if not leecher.data[hash] then
			leecher.data[hash] = {
				timer2 = 10,
				timer3 = math_random(1, 60),
				water = {},
				heights = {},
			}
		end

		-- Bring datatable local.
		local data = leecher.data[hash]

		-- Consume energy.
		do
			local energy_usage = #(data.water or {}) * ENERGY_AMOUNT
			if energy_usage < 200 then energy_usage = 200 end
			meta:set_int("eups_usage", energy_usage)

			local energy = inv:get_stack("buffer", 1)
			--energy = ItemStack("atomic:energy 60000")

			if energy:get_count() >= energy_usage then
				energy:set_count(energy:get_count() - energy_usage)
				inv:set_stack("buffer", 1, energy)
			else
				-- Try to get energy from network.
				local owner = meta:get_string("owner")
				local gotten = net2.get_energy(pos, owner, BUFFER_SIZE, "hv")
				if gotten >= energy_usage then
					energy = ItemStack("atomic:energy " .. (energy:get_count() + gotten))
					inv:set_stack("buffer", 1, energy)
					-- Wait for next iteration before producing again.
					goto cancel
				end

				-- Not enough energy!
				meta:set_string("error", "Insufficient power.")
				meta:set_int("enabled", 0)
				keeprunning = false
				goto cancel
			end
		end

		if not data.water or #(data.water) == 0 then
			meta:set_string("error", "Warming up (" .. data.timer3 .. ") ...")
		end

		-- Update water surface detection every so often.
		data.timer3 = data.timer3 - 1
		if data.timer3 < 0 then
			data.timer3 = math_random(30, 60*3)
			data.water = get_water_surface(pos)
			data.heights = {}

			-- Initialize the height data.
			for k, v in ipairs(data.water) do
				local hash = minetest.hash_node_position(v)
				data.heights[hash] = 0
			end

			if #(data.water) < 2 then
				meta:set_string("error", "No outsalting fluid!")
				meta:set_int("enabled", 0)
				data.water = {}
				data.heights = {}
				keeprunning = false
				goto cancel
			end
		end

		-- Spawn boiling particles.
		if #(data.water) > 0 then
			local rnd = math_random(1, 3)
			for i = 1, rnd, 1 do
				local p2 = data.water[math_random(1, #(data.water))]
				minetest.after(math_random(1, 10) / 10, do_water_boiling, p2)
			end
		end

		-- Dig ceiling.
		data.timer2 = data.timer2 - 1
		if data.timer2 < 0 then
			data.timer2 = 10

			if #(data.water) > 0 then
				local idx = math_random(1, #(data.water))
				local p2 = data.water[idx]
				local success, rstack = do_ceiling_dig(p2, data.heights)

				if not success then
					table.remove(data.water, idx)

					-- First, check if outsalting reached its max height.
					local reached_max = check_outsalting_done(data.heights)
					if reached_max then
						meta:set_string("error", "Finished.")
						meta:set_int("enabled", 0)
						keeprunning = false
						goto cancel
					end

					-- Check if we ran out of vertical columns.
					-- This could happen before reaching max height if we ran into a
					-- protected region.
					if #(data.water) == 0 then
						meta:set_string("error", "Outsalting aborted!")
						meta:set_int("enabled", 0)
						keeprunning = false
						goto cancel
					end
				end

				if rstack then
					if inv:room_for_item("main", rstack) then
						inv:add_item("main", rstack)
					else
						meta:set_string("error", "Inventory full.")
						meta:set_int("enabled", 0)
						keeprunning = false
						goto cancel
					end
				end
			end
		end
	end

	-- Jump here if something prevents machine from working.
	::cancel::

	-- Determine mode (active or sleep) and set timer accordingly.
	if keeprunning then
		minetest.get_node_timer(pos):start(1.0)
		meta:set_int("active", 1)
	else
		-- Slow down timer during sleep periods to reduce load.
		minetest.get_node_timer(pos):start(math_random(1, 3*60))
		meta:set_int("active", 0)
	end

	-- Update infotext.
	meta:set_string("infotext", leecher.compose_infotext(pos))
	meta:set_string("formspec", leecher.compose_formspec(pos))
end



leecher.on_construct =
function(pos)
	leecher.data[minetest.hash_node_position(pos)] = nil
end



leecher.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
  local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
  inv:set_size("buffer", 1)
	inv:set_size("main", 9)

	net2.clear_caches(pos, owner, "hv")
  meta:set_string("formspec", leecher.compose_formspec(pos))
  meta:set_string("infotext", leecher.compose_infotext(pos))
	nodestore.add_node(pos)

	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end



leecher.on_blast =
function(pos)
  local drops = {}
  drops[#drops+1] = "leecher:leecher"
	default.get_inventory_drops(pos, "main", drops)
  minetest.remove_node(pos)
	leecher.data[minetest.hash_node_position(pos)] = nil
  return drops
end



leecher.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	if minetest.test_protection(pos, pname) then
		return 0
	end
	-- Debug code.
	if minetest.is_singleplayer() then
		if stack:get_name() == "atomic:energy" and listname == "buffer" then
			return stack:get_count()
		end
	end
  return 0
end



leecher.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end



leecher.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	if minetest.test_protection(pos, pname) then
		return 0
	end
	if listname == "main" then
		return stack:get_count()
	end
  return 0
end



leecher.on_metadata_inventory_move =
function(pos)
  leecher.trigger_update(pos)
end



leecher.on_metadata_inventory_put =
function(pos)
  leecher.trigger_update(pos)
end



leecher.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  leecher.trigger_update(pos)
end



leecher.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	net2.clear_caches(pos, meta:get_string("owner"), "hv")
	nodestore.del_node(pos)
	leecher.data[minetest.hash_node_position(pos)] = nil
end



leecher.on_place = function(itemstack, placer, pt)
	if pt.type == "node" then
		if city_block:in_no_leecher_zone(pt.under) then
			local pname = placer:get_player_name()
			minetest.chat_send_player(pname, "# Server: Mineral extraction is forbidden this close to a residential area!")
			return itemstack
		end
	end
	return minetest.item_place(itemstack, placer, pt)
end



if not leecher.run_once then
	minetest.register_node(":leecher:leecher", {
		description = "HV Mineral Outsalter\n\nThis leeches trace ores from rock above, very slowly.\nMust be placed in a water pool (wider is better).",
		tiles = {
			"technic_carbon_steel_block.png^default_tool_mesepick.png",
			"technic_carbon_steel_block.png",
			"technic_carbon_steel_block.png",
			"technic_carbon_steel_block.png",
			"technic_carbon_steel_block.png",
			"technic_carbon_steel_block.png",
		},

		groups = utility.dig_groups("machine"),

		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),

		drop = "leecher:leecher",

		on_rotate = function(...)
			return screwdriver.rotate_simple(...) end,
		allow_metadata_inventory_put = function(...)
			return leecher.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_move = function(...)
			return leecher.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_take = function(...)
			return leecher.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...)
			return leecher.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...)
			return leecher.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...)
			return leecher.on_metadata_inventory_take(...) end,
		on_punch = function(...)
			return leecher.on_punch(...) end,
		can_dig = function(...)
			return leecher.can_dig(...) end,
		on_timer = function(...)
			return leecher.on_timer(...) end,
		on_construct = function(...)
			return leecher.on_construct(...) end,
		on_destruct = function(...)
			return leecher.on_destruct(...) end,
		on_blast = function(...)
			return leecher.on_blast(...) end,
		after_place_node = function(...)
			return leecher.after_place_node(...) end,
		on_receive_fields = function(...)
			return leecher.on_receive_fields(...) end,
		on_place = function(...)
			return leecher.on_place(...) end,
	})

	minetest.register_craft({
		output = "leecher:leecher",
		recipe = {
			{"techcrafts:carbon_plate", "stack_filter:filter", "techcrafts:composite_plate"},
			{"techcrafts:electric_motor", "techcrafts:machine_casing", "gem_cutter:blade"},
			{"carbon_steel:block", "cb2:hv", "carbon_steel:block"}},
	})

  local c = "leecher:core"
  local f = leecher.modpath .. "/leecher.lua"
  reload.register_file(c, f, false)

	leecher.run_once = true
end

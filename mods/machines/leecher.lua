
leecher = leecher or {}
leecher.data = leecher.data or {}
leecher.modpath = minetest.get_modpath("machines")

-- Localize for performance.
local math_random = math.random

local BUFFER_SIZE = tech.leecher.buffer
local ENERGY_AMOUNT = tech.leecher.power
local DISSOLVE_HEIGHT = 50
local LEECH_RESULT = "default:river_water_source"



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
	local curpos, hash, exists, name, found, depth, is_water
	local first = true
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
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

	if depth >= 10 then
		goto next
	end

	name = get_node(curpos).name
	found = false
	is_water = false

	if name == "default:water_source" or name == "default:river_water_source" then
		is_water = true
		found = true
	end

	if name == "leecher:leecher" then
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
		if is_water then
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

local function get_ore_position_tables(pos, water_count)
	local ores = {}
	local cids = {}

	-- Get content IDs from names.
	-- This code only needs to run once.
	if not leecher.cids then
		leecher.cids = {}
		for k, v in pairs(ore_conversion_data) do
			if minetest.registered_items[k] then
				local id = minetest.get_content_id(k)
				leecher.cids[id] = k
			end
		end
	end

	local rad = 10

	local height = math.ceil(water_count/2)
	if height < 10 then
		height = 10
	end

	local minp = {x=pos.x-rad, y=pos.y+1, z=pos.z-rad}
	local maxp = {x=pos.x+rad, y=pos.y+height, z=pos.z+rad}
  local vm = minetest.get_voxel_manip(minp, maxp)
	local emin, emax = vm:get_emerged_area()
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	-- Count all content IDs.
  for z = minp.z, maxp.z, 1 do
    for x = minp.x, maxp.x, 1 do
      for y = minp.y, maxp.y, 1 do
				local vp = area:index(x, y, z)
				local id = data[vp]
				-- Record positions for nodes that we care about.
				-- This way, we can refer to their positions later.
				-- This allows us to remove ores from time to time.
				if leecher.cids[id] then
					if not cids[id] then
						cids[id] = {}
					end
					cids[id][#(cids[id])+1] = {x=x, y=y, z=z}
				end
			end
		end
	end

	-- Convert content IDs to names.
	for k, v in pairs(cids) do
		local name = minetest.get_name_from_content_id(k)
		-- Don't record ore unless we can produce it.
		if ore_conversion_data[name] then
			if minetest.registered_items[ore_conversion_data[name]] then
				ores[name] = v
			end
		end
	end

	-- Debug!
	--for k, v in pairs(ores) do
	--	minetest.chat_send_all("# Server: '" .. k .. "=" .. #v .. "!")
	--end

	return ores
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



-- Dig ceiling above position.
local function do_ceiling_dig(pos)
	-- Helper to remove water above a dislodged node.
	-- This avoids annoying liquid messes.
	local remove_water_above
	remove_water_above = function(p2)
		local p3 = vector.add(p2, {x=0, y=1, z=0})
		if minetest.test_protection(p3, "") then
			return
		end
		if minetest.get_node(p3).name == LEECH_RESULT then
			minetest.remove_node(p3)
		else
			return
		end
		local adjacent = {
			{x=p3.x+1, y=p3.y, z=p3.z},
			{x=p3.x-1, y=p3.y, z=p3.z},
			{x=p3.x, y=p3.y, z=p3.z+1},
			{x=p3.x, y=p3.y, z=p3.z-1},
		}
		for k, v in ipairs(adjacent) do
			if minetest.get_node(v).name == LEECH_RESULT then
				if not minetest.test_protection(v, "") then
					minetest.remove_node(v)
				end
			end
		end
		local p4 = vector.add(p3, {x=0, y=1, z=0})
		if minetest.get_node(p4).name == LEECH_RESULT then
			remove_water_above(p4)
		end
	end

	-- A random horizontal offset allows us to get around small
	-- obstructions (usually power cables and whatnot).
	local x = math_random(-1, 1)
	local z = math_random(-1, 1)

	for i = 1, DISSOLVE_HEIGHT, 1 do
		local p = {x=pos.x+x, y=pos.y+i, z=pos.z+z}
		local node = minetest.get_node(p)
		if node.name == "air" then
			-- Keep going.
		elseif ore_dissolve_data[node.name] then
			if not minetest.test_protection(p, "") then
				remove_water_above(p)
				minetest.remove_node(p)
				minetest.check_for_falling(p)
			end
			break
		elseif ore_conversion_data[node.name] then
			-- If we encounter a dissolvable node that wasn't dissolved yet,
			-- we drop it instead.
			if not minetest.test_protection(p, "") then
				remove_water_above(p)
				sfn.drop_node(p)
				minetest.check_for_falling(p)
			end
			break
		elseif ore_drop_data[node.name] then
			if not minetest.test_protection(p, "") then
				remove_water_above(p)
				sfn.drop_node(p)
				minetest.check_for_falling(p)
			end
			break
		else
			-- Anything unrecognized should stop ceilingward iteration.
			break
		end
	end
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
		eups = ENERGY_AMOUNT
	end
	local infotext = "HV Mineral Outsalter (" .. state .. ")\n" ..
		"Demand: " .. eups .. " EU Per/Sec"
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
	local need_mapread = false
	local produce_ore = false
	local read_water = false
	local try_run = false

	-- If the machine is enabled, keep running.
	if meta:get_int("enabled") == 1 then
		try_run = true
	end

	::try_again::
	if try_run then
		-- Assuming we can keep running unless someone says otherwise.
		keeprunning = true

		-- Consume energy.
		do
			local energy = inv:get_stack("buffer", 1)
			if energy:get_count() >= ENERGY_AMOUNT then
				energy:set_count(energy:get_count() - ENERGY_AMOUNT)
				inv:set_stack("buffer", 1, energy)
			else
				-- Try to get energy from network.
				local owner = meta:get_string("owner")
				local gotten = net2.get_energy(pos, owner, BUFFER_SIZE, "hv")
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

		-- Ensure external datatable exists.
		if not leecher.data[hash] then
			leecher.data[hash] = {
				timer = 0,
				timer2 = math_random(1, 10),
				timer3 = math_random(1, 60),
				ores = {},
				dist = {},
				water = {},
			}
			need_mapread = true
		end

		-- Bring datatable local.
		local data = leecher.data[hash]

		-- Reread map region every long while.
		data.timer = data.timer + elapsed
		if data.timer > (60*15)+math_random(1, 10) then
			data.timer = 0
			data.timer3 = math_random(1, 60)
			data.ores = {}
			data.dist = {}
			data.water = {}
			need_mapread = true
		end

		if need_mapread then
			data.ores = {}
			data.dist = {}
			data.water = {}

			-- Read counts of all ores in local region.
			data.water = get_water_surface(pos)
			data.ores = get_ore_position_tables(pos, #(data.water))

			-- Build ore distribution table.
			-- This allows us to pick ores randomly.
			local dist = {}
			local last = 0
			for k, v in pairs(data.ores) do
				local count = #v
				if count > 0 then
					local inst = {
						name = k,
						min = last,
						max = last+count,
					}
					--minetest.chat_send_all("# Server: " .. inst.name .. ": " .. inst.min .. " -> " .. inst.max .. "!")
					last = last+count+1
					dist[#dist+1] = inst
				end
			end

			data.dist = dist
		end

		-- Produce ores every now and then.
		data.timer2 = data.timer2 - 1
		if data.timer2 < 0 then
			data.timer2 = math_random(1, 10)
			produce_ore = true
		end

		if produce_ore then
			if #(data.dist) > 0 then
				-- Choose a random ore and produce it.
				local last = 0
				for k, v in ipairs(data.dist) do
					if v.max > last then
						last = v.max
					end
				end
				local rnd = math_random(1, last)
				local ore = ""
				for k, v in ipairs(data.dist) do
					if rnd >= v.min and rnd <= v.max then
						ore = v.name
						break
					end
				end
				if ore ~= "" then
					local realore = ""
					if ore_conversion_data[ore] then
						realore = ore_conversion_data[ore]
					end
					if realore ~= "" then
						if inv:room_for_item("main", realore) then
							-- Occasionally remove an ore.
							-- Frequency of removal is a balance between performance
							-- and machine efficiency.
							if math_random(1, 20) == 1 then
								local sz = #(data.ores[ore])
								if sz > 0 then
									-- Get the location of a random ore of this type.
									local rnd = math_random(1, sz)
									local p2 = data.ores[ore][rnd]

									-- Can't dig ores that are protected.
									if minetest.test_protection(p2, "") then
										keeprunning = false
										goto cancel
									end

									table.remove(data.ores[ore], rnd)

									-- Get node, loading it if needed.
									-- Note: this will return 'ignore' if position was never created by mapgen!
									local vm = nil
									local node = minetest.get_node_or_nil(p2)
									if not node then
										local minp = {x=p2.x-1, y=p2.y-1, z=p2.z-1}
										local maxp = {x=p2.x+1, y=p2.y+1, z=p2.z+1}
										vm = minetest.get_voxel_manip(minp, maxp)
										node = vm:get_node_at(p2)
									end

									-- If node was successfully loaded try replacing it.
									-- We make sure nodename is as expected, to avoid
									-- breaking people's stuff.
									if node and node.name == ore then
										--minetest.chat_send_all("# Server: Placing water @ " .. minetest.pos_to_string(p2) .. "!")
										minetest.add_node(p2, {name=LEECH_RESULT})
									end
								end
							end

							-- Don't actually add item unless removing the ore
							-- (if removal was attempted) was successful.
							inv:add_item("main", realore)
						else
							-- Output storage is full.
							keeprunning = false
							goto cancel
						end
					end
				else
					-- No ore chosen, bug maybe?
					keeprunning = false
					goto cancel
				end
			else
				-- Shutdown if no ores available.
				keeprunning = false
				goto cancel
			end
		end

		-- Update water surface detection every so often.
		data.timer3 = data.timer3 - 1
		if data.timer3 < 0 then
			data.timer3 = math_random(30, 60*3)
			read_water = true
		end

		if read_water then
			data.water = get_water_surface(pos)
		end

		-- Spawn boiling particles.
		if #(data.water) > 0 and math_random(1, 2) == 1 then
			local rnd = math_random(1, 2)
			for i = 1, rnd, 1 do
				local p2 = data.water[math_random(1, #(data.water))]
				do_water_boiling(p2)
			end
		end

		-- Occasionally dig ceiling.
		if math_random(1, 20) == 1 then
			if #(data.water) > 0 then
				local p2 = data.water[math_random(1, #(data.water))]
				do_ceiling_dig(p2)
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
			minetest.chat_send_player(pname, "# Server: Mineral extraction is forbidden within 200 meters of a residential area!")
			return itemstack
		end
	end
	return minetest.item_place(itemstack, placer, pt)
end



if not leecher.run_once then
	minetest.register_node(":leecher:leecher", {
		description = "HV Mineral Outsalter\n\nThis leeches trace ores from rock above, very slowly.\nMust be placed in a water pool (wider is better).",
		tiles = {"technic_carbon_steel_block.png^default_tool_mesepick.png"},

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

	---[[
	minetest.register_craft({
		output = "leecher:leecher",
		recipe = {
			{"techcrafts:carbon_plate", "stack_filter:filter", "techcrafts:composite_plate"},
			{"techcrafts:electric_motor", "techcrafts:machine_casing", "gem_cutter:blade"},
			{"carbon_steel:block", "cb2:hv", "carbon_steel:block"}},
	})
	--]]

  local c = "leecher:core"
  local f = leecher.modpath .. "/leecher.lua"
  reload.register_file(c, f, false)

	leecher.run_once = true
end

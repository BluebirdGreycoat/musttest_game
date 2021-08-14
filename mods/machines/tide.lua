
tide = tide or {}
tide.modpath = minetest.get_modpath("machines")

-- Localize for performance.
local math_random = math.random
local item_group = minetest.get_item_group
local vector_distance = vector.distance

local BUFFER_SIZE = tech.tidal.buffer
local ENERGY_AMOUNT = tech.tidal.power



local function is_water(nn)
	if item_group(nn, "water") ~= 0 then
		return true
	end
end



-- Queued algorithm.
local function count_nearby_ocean(startpos)
	local traversal = {}
	local queue = {}
	local curpos, hash, exists, name, found_water, found_tide, depth
	local first = true
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
	local num_waters = 0
	local num_tidals = 0
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

	if depth >= 20 then
		goto next
	end

	name = get_node(curpos).name
	found_water = false
	found_tide = false

	if is_water(name) then
		found_water = true
	elseif name == "tide:tide" then
		found_tide = true
	end

	if not found_water and not found_tide then
		goto next
	end

	traversal[hash] = depth
	if not exists then
		if found_tide then
			-- The amount this tidal contributes to the total number of tidals is
			-- dependant on its distance to the source tidal.
			local mult = vector_distance(startpos, curpos) / -20 + 1
			if mult < 0 then mult = 0 end
			num_tidals = num_tidals + mult
		elseif found_water then
			num_waters = num_waters + 1
		end
	end

	-- Queue up adjacent locations.
	queue[#queue+1] = {x=curpos.x+1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x-1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y+1, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y-1, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z+1, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z-1, d=depth+1}

	::next::
	first = false
	if #queue > 0 then
		goto continue
	end

	return num_waters, num_tidals
end

tide.on_energy_get =
function(pos, energy)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local have = inv:get_stack("buffer", 1):get_count()
	if have < energy then
		inv:set_stack("buffer", 1, ItemStack(""))
		tide.trigger_update(pos)
		return have
	end
	have = have - energy
	inv:set_stack("buffer", 1, ItemStack("atomic:energy " .. have))
	tide.trigger_update(pos)
	return energy
end



tide.compose_formspec =
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

tide.compose_infotext =
function(pos)
	local meta = minetest.get_meta(pos)
	local eups = meta:get_int("eups")
	local state = "Standby"
	if meta:get_int("active") == 1 then
		state = "Active"
	end
	local infotext = "MV Tidal Generator (" .. state .. ")\n" ..
		"Output: " .. eups .. " EU Per/Sec"
	local err = meta:get_string("error")
	if err ~= "" and err ~= "DUMMY" then
		infotext = infotext .. "\n" .. err
	end
	return infotext
end

tide.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
	-- Restart timer even if already running.
	timer:start(1.0)
end

tide.on_punch =
function(pos, node, puncher, pointed_thing)
  tide.trigger_update(pos)
	--minetest.get_meta(pos):set_int("chktmr", 0)
	--minetest.chat_send_player("MustTest", "TESTING!")
	tide.privatize(minetest.get_meta(pos))
end

tide.can_dig =
function(pos, player)
	return true
end

tide.check_environment =
function(pos, meta)
  local timer = meta:get_int("chktmr")
  local active = meta:get_int("active")

  if timer <= 0 then
		local result = false
		local good = false
		local eups = ENERGY_AMOUNT

		local sides = {
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+1},
			{x=pos.x, y=pos.y, z=pos.z-1},
		}
		local sidewater = 0
		for k, v in ipairs(sides) do
			if is_water(minetest.get_node(v).name) then
				sidewater = sidewater + 1
			end
		end

		-- Start from self-pos so that at least one tidal (self) is always found.
		local ocean, tidals = count_nearby_ocean({x=pos.x, y=pos.y, z=pos.z})
		--minetest.chat_send_player("MustTest", "# Server: Ocean: " .. ocean)
		if ocean >= 500 and sidewater >= 4 then
			good = true
		end

    if good then
			--minetest.chat_send_all("# Server: Good!")

			-- Prevent divide-by-zero.
			local div = tidals or 0
			if div < 1 then div = 1 end

			-- Scale energy production by size of the ocean.
			-- If a player could build a REALLY big reservoir, it would be possible to
			-- get this to go higher than x1. In that case it might be worth it to
			-- build more tidals in close proximity.
			local amount = eups * (ocean / (17*11*17))
			if amount > eups then amount = eups end

			-- Scale energy production by number of neighbor tidals.
			-- This makes packing them very inefficient, but not entirely pointless
			-- in small numbers.
			amount = amount / (div * 0.85)

      -- Randomize time to next nodecheck.
      meta:set_int("chktmr", math_random(1, 60*3))
      meta:set_int("active", 1)
      meta:set_int("eups", amount)
			meta:set_string("error", "DUMMY")
      result = true
    else
			---minetest.chat_send_all("# Server: Bad!")
      -- Don't set timer if generator is offline.
      -- The next check needs to happen the next time the machine is punched.
      meta:set_int("chktmr", 0)
      meta:set_int("active", 0)
      meta:set_int("eups", 0)
			if sidewater < 4 then
				meta:set_string("error", "Machine not properly submerged!")
			elseif ocean == 0 then
				meta:set_string("error", "Turbine has insufficient contact with water!")
			elseif ocean < 500 then
				meta:set_string("error", "Insufficient current strength (" .. ocean .. ")!")
			else
				meta:set_string("error", "Unknown issue, please contact admin.")
			end
      result = false
    end

		meta:set_string("infotext", tide.compose_infotext(pos))
		return result
  end

  -- Decrement check timer.
  timer = timer - 1
  meta:set_int("chktmr", timer)

  -- No check performed; just return whatever the result of the last check was.
  return (active == 1)
end

tide.on_timer =
function(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local inv = meta:get_inventory()
	local keeprunning = false

	-- Check if we can produce energy from environment.
	-- Note that this uses a caching algorithm.
	local canrun = tide.check_environment(pos, meta)

	-- If environment is no longer producing energy,
	-- unload the buffered energy.
	if not canrun then
		local energy = inv:get_stack("buffer", 1)
		energy:set_count(net2.put_energy(pos, owner, energy:get_count(), "mv"))
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

		-- Not actually producing any energy? Go to sleep.
		if eups < 1 then
			keeprunning = false
		end
	end

	-- Discharge energy.
	if needdischarge then
		--minetest.chat_send_player("MustTest", "DISCHARGING!")
		local energy = inv:get_stack("buffer", 1)
		-- Unload energy onto the network.
		local old = energy:get_count()
		energy:set_count(net2.put_energy(pos, owner, old, "mv"))
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
		meta:set_string("infotext", tide.compose_infotext(pos))
	end
end

tide.on_construct =
function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_int("eups", 0)
	meta:set_int("active", 0)
	meta:set_int("chktmr", 0)
	meta:set_string("error", "DUMMY")
	meta:set_string("owner", "DUMMY")
	meta:set_string("nodename", "DUMMY")
	tide.privatize(meta)
end

tide.privatize =
function(meta)
	meta:mark_as_private({
		"nodename",
		"owner",
		"chktmr",
		"error",
		"eups",
		"active",
	})
end

tide.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
  local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
  inv:set_size("buffer", 1)

	net2.clear_caches(pos, owner, "mv")
  meta:set_string("formspec", tide.compose_formspec(pos))
  meta:set_string("infotext", tide.compose_infotext(pos))
	nodestore.add_node(pos)

	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end

tide.on_blast =
function(pos)
  local drops = {}
  drops[#drops+1] = "tide:tide"
  minetest.remove_node(pos)
  return drops
end

tide.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
  return 0
end

tide.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

tide.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
  return 0
end

tide.on_metadata_inventory_move =
function(pos)
  tide.trigger_update(pos)
end

tide.on_metadata_inventory_put =
function(pos)
  tide.trigger_update(pos)
end

tide.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  tide.trigger_update(pos)
end

tide.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	net2.clear_caches(pos, meta:get_string("owner"), "mv")
	nodestore.del_node(pos)
end



if not tide.run_once then
	local nodebox = {
		{0, 16, 0, 16, 15, 16}, -- Base.
		{2, 15, 2, 14, 10, 14}, -- Box shaft.
		{7, 15, 7, 9, -1, 9}, -- Shaft.
		{-6, 3, 6, 22, 4, 10}, -- Upper blade.
		{6, 0, -6, 10, 1, 22}, -- Lower blade.
	}
	for k, v in ipairs(nodebox) do
		for m, n in ipairs(v) do
			local p = nodebox[k][m]
			p = p / 16
			p = p - 0.5
			nodebox[k][m] = p
		end
	end

	minetest.register_node(":tide:tide", {
		drawtype = "nodebox",
		description = "MV Tidal Generator",
		tiles = {"technic_carbon_steel_block.png"},

		groups = utility.dig_groups("machine"),

		node_box = {
			type = "fixed",
			fixed = nodebox,
		},

		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
		drop = "tide:tide",

		on_energy_get = function(...)
			return tide.on_energy_get(...) end,
		on_rotate = function(...)
			return screwdriver.rotate_simple(...) end,
		allow_metadata_inventory_put = function(...)
			return tide.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_move = function(...)
			return tide.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_take = function(...)
			return tide.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...)
			return tide.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...)
			return tide.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...)
			return tide.on_metadata_inventory_take(...) end,
		on_punch = function(...)
			return tide.on_punch(...) end,
		can_dig = function(...)
			return tide.can_dig(...) end,
		on_timer = function(...)
			return tide.on_timer(...) end,
		on_construct = function(...)
			return tide.on_construct(...) end,
		on_destruct = function(...)
			return tide.on_destruct(...) end,
		on_blast = function(...)
			return tide.on_blast(...) end,
		after_place_node = function(...)
			return tide.after_place_node(...) end,
	})

	minetest.register_craft({
		output = 'tide:tide',
		recipe = {
			{'', 'cb2:mv', ''},
			{'carbon_steel:ingot', 'carbon_steel:block', 'carbon_steel:ingot'},
			{'', 'techcrafts:electric_motor', ''},
		}
	})

  local c = "tide:core"
  local f = tide.modpath .. "/tide.lua"
  reload.register_file(c, f, false)

	tide.run_once = true
end


if not minetest.global_exists("windy") then windy = {} end
windy.modpath = minetest.get_modpath("machines")

-- Localize for performance.
local math_random = math.random

local BUFFER_SIZE = tech.windy.buffer
local ENERGY_AMOUNT = tech.windy.power



-- Queued algorithm.
local function count_nearby_air(startpos)
	local traversal = {}
	local queue = {}
	local curpos, hash, exists, name, found, depth
	local first = true
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
	local count = 0
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

	if name == "air" then
		found = true
	end

	if not found then
		goto next
	end

	traversal[hash] = depth
	if not exists then
		count = count + 1
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

	return count
end

windy.on_energy_get =
function(pos, energy)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local have = inv:get_stack("buffer", 1):get_count()
	if have < energy then
		inv:set_stack("buffer", 1, ItemStack(""))
		windy.trigger_update(pos)
		return have
	end
	have = have - energy
	inv:set_stack("buffer", 1, ItemStack("atomic:energy " .. have))
	windy.trigger_update(pos)
	return energy
end



windy.compose_formspec =
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

windy.compose_infotext =
function(pos)
	local meta = minetest.get_meta(pos)
	local eups = meta:get_int("eups")
	local state = "Standby"
	if meta:get_int("active") == 1 then
		state = "Active"
	end
	local infotext = "MV Wind Catcher (" .. state .. ")\n" ..
		"Output: " .. eups .. " EU Per/Sec"
	local err = meta:get_string("error")
	if err ~= "" and err ~= "DUMMY" then
		infotext = infotext .. "\n" .. err
	end
	return infotext
end

windy.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
	-- Restart timer even if already running.
	timer:start(1.0)
end

windy.on_punch =
function(pos, node, puncher, pointed_thing)
  windy.trigger_update(pos)
	windy.privatize(minetest.get_meta(pos))
end

windy.can_dig =
function(pos, player)
	return true
end

windy.check_environment =
function(pos, meta)
  local timer = meta:get_int("chktmr")
  local active = meta:get_int("active")

  if timer <= 0 then
		local result = false
		local good = false
		local eups = ENERGY_AMOUNT

		local numnodes = 0
		for y = pos.y-1, pos.y-15, -1 do
			local node = minetest.get_node({x=pos.x, y=y, z=pos.z})
			-- Nodes which aren't wind frames may intervene.
			if node.name == "windy:frame" then
				numnodes = numnodes + 1
			end
		end
		local aircount = count_nearby_air({x=pos.x, y=pos.y+1, z=pos.z})
		--minetest.chat_send_all("# Server: Air: " .. aircount)
		if numnodes >= 10 and pos.y >= 10 and aircount >= 800 then
			good = true
		end

    if good then
			--minetest.chat_send_all("# Server: Good!")
      -- Randomize time to next nodecheck.
      meta:set_int("chktmr", math_random(1, 60*3))
      meta:set_int("active", 1)
      meta:set_int("eups", eups)
			meta:set_string("error", "DUMMY")
      result = true
    else
			--minetest.chat_send_all("# Server: Bad!")
      -- Don't set timer if generator is offline.
      -- The next check needs to happen the next time the machine is punched.
      meta:set_int("chktmr", 0)
      meta:set_int("active", 0)
      meta:set_int("eups", 0)

			local success, windlevel = rc.get_wind_level_at_pos(pos)

			if not success then
				meta:set_string("error", "Invalid realm!")
			elseif numnodes < 10 then
				meta:set_string("error", "Not enough wind catcher frames!")
			elseif pos.y < windlevel then
				meta:set_string("error", "Not enough altitude!")
			elseif aircount == 0 then
				meta:set_string("error", "Machine is obstructed!")
			elseif aircount < 800 then
				meta:set_string("error", "Insufficient wind velocity in region (" .. aircount .. ")!")
			else
				meta:set_string("error", "Unknown issue with configuration!")
			end
      result = false
    end

		meta:set_string("infotext", windy.compose_infotext(pos))
		return result
  end

  -- Decrement check timer.
  timer = timer - 1
  meta:set_int("chktmr", timer)

  -- No check performed; just return whatever the result of the last check was.
  return (active == 1)
end

windy.on_timer =
function(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local inv = meta:get_inventory()
	local keeprunning = false

	-- Check if we can produce energy from environment.
	-- Note that this uses a caching algorithm.
	local canrun = windy.check_environment(pos, meta)

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
	end

	-- Discharge energy.
	if needdischarge then
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
		meta:set_string("infotext", windy.compose_infotext(pos))
	end
end

windy.on_construct =
function(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("owner", "DUMMY")
	meta:set_string("nodename", "DUMMY")
	meta:set_string("error", "DUMMY")
	meta:set_int("eups", 0)
	meta:set_int("active", 0)
	meta:set_int("chktmr", 0)

	windy.privatize(meta)
end

windy.privatize =
function(meta)
	meta:mark_as_private({
		"owner",
		"nodename",
		"error",
		"eups",
		"active",
		"chktmr",
	})
end

windy.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
  local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
  inv:set_size("buffer", 1)

	net2.clear_caches(pos, owner, "mv")
  meta:set_string("formspec", windy.compose_formspec(pos))
  meta:set_string("infotext", windy.compose_infotext(pos))
	nodestore.add_node(pos)

	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end

windy.on_blast =
function(pos)
  local drops = {}
  drops[#drops+1] = "windy:winder"
  minetest.remove_node(pos)
  return drops
end

windy.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
  return 0
end

windy.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

windy.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
  return 0
end

windy.on_metadata_inventory_move =
function(pos)
  windy.trigger_update(pos)
end

windy.on_metadata_inventory_put =
function(pos)
  windy.trigger_update(pos)
end

windy.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  windy.trigger_update(pos)
end

windy.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	net2.clear_caches(pos, meta:get_string("owner"), "mv")
	nodestore.del_node(pos)
end



if not windy.run_once then
	minetest.register_node(":windy:frame", {
		description = "Wind Catcher Frame",
		drawtype = "glasslike_framed",
		tiles = {"technic_carbon_steel_block.png", "default_glass.png"},
		sunlight_propagates = true,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_stone_defaults(),
		paramtype = "light",
	})

	minetest.register_craft({
		output = 'windy:frame 1',
		recipe = {
			{'carbon_steel:ingot', '', 'carbon_steel:ingot'},
			{'', 'default:glass', ''},
			{'carbon_steel:ingot', '', 'carbon_steel:ingot'},
		}
	})

	local nodebox = {
		{0, 0, 0, 16, 1, 16}, -- Base.
		{5, 1, 6, 11, 16, 10}, -- Vertical post.
		{3, 4, 2, 13, 12, 14}, -- Main arm.
		{7, 7, -2, 9, 9, 18}, -- Shaft.

		-- Front blades.
		{6, -6, -2, 10, 22, -1}, -- Vertical blade.
		{-6, 6, -2, 22, 10, -1}, -- Horizontal blade.

		-- Back blades.
		{6, -6, 17, 10, 22, 18}, -- Vertical blade.
		{-6, 6, 17, 22, 10, 18}, -- Horizontal blade.
	}
	for k, v in ipairs(nodebox) do
		for m, n in ipairs(v) do
			local p = nodebox[k][m]
			p = p / 16
			p = p - 0.5
			nodebox[k][m] = p
		end
	end

	minetest.register_node(":windy:winder", {
		drawtype = "nodebox",
		description = "MV Wind Catcher",
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
		drop = "windy:winder",

		on_energy_get = function(...)
			return windy.on_energy_get(...) end,
		on_rotate = function(...)
			return screwdriver.rotate_simple(...) end,
		allow_metadata_inventory_put = function(...)
			return windy.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_move = function(...)
			return windy.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_take = function(...)
			return windy.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...)
			return windy.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...)
			return windy.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...)
			return windy.on_metadata_inventory_take(...) end,
		on_punch = function(...)
			return windy.on_punch(...) end,
		can_dig = function(...)
			return windy.can_dig(...) end,
		on_timer = function(...)
			return windy.on_timer(...) end,
		on_construct = function(...)
			return windy.on_construct(...) end,
		on_destruct = function(...)
			return windy.on_destruct(...) end,
		on_blast = function(...)
			return windy.on_blast(...) end,
		after_place_node = function(...)
			return windy.after_place_node(...) end,
	})

	minetest.register_craft({
		output = 'windy:winder',
		recipe = {
			{'techcrafts:electric_motor', '', 'techcrafts:electric_motor'},
			{'carbon_steel:ingot', 'techcrafts:machine_casing', 'carbon_steel:ingot'},
			{'', 'cb2:mv', ''},
		}
	})

  local c = "windy:core"
  local f = windy.modpath .. "/windy.lua"
  reload.register_file(c, f, false)

	windy.run_once = true
end

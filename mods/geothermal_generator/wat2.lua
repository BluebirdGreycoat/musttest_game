
wat2 = wat2 or {}
wat2.modpath = minetest.get_modpath("geothermal_generator")

local BUFFER_SIZE = tech.hydroturbine.buffer
local ENERGY_AMOUNT = tech.hydroturbine.power

wat2.on_energy_get =
function(pos, energy)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local have = inv:get_stack("buffer", 1):get_count()
	if have < energy then
		inv:set_stack("buffer", 1, ItemStack(""))
		wat2.trigger_update(pos)
		return have
	end
	have = have - energy
	inv:set_stack("buffer", 1, ItemStack("atomic:energy " .. have))
	wat2.trigger_update(pos)
	return energy
end



wat2.compose_formspec =
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

wat2.compose_infotext =
function(pos)
	local meta = minetest.get_meta(pos)
	local state = "Standby"
	if meta:get_int("active") == 1 then
		state = "Active"
	end
	local eups = meta:get_int("eups")
	local infotext = "LV Hydroturbine (" .. state .. ")\n" ..
		"Output: " .. eups .. " EU Per/Sec"
	return infotext
end

wat2.trigger_update =
function(pos)
  local timer = minetest.get_node_timer(pos)
	-- Start timer even if already running.
	timer:start(1.0)
end

wat2.on_punch =
function(pos, node, puncher, pointed_thing)
  wat2.trigger_update(pos)
end

wat2.can_dig =
function(pos, player)
	return true
end

wat2.check_environment =
function(pos, meta)
  local timer = meta:get_int("chktmr")
  local active = meta:get_int("active")

  if timer <= 0 then
		local result = false
    -- Check all 4 sides of the geothermal generator.
    local targets = {
      {x=pos.x+1, y=pos.y, z=pos.z},
      {x=pos.x-1, y=pos.y, z=pos.z},
      {x=pos.x, y=pos.y, z=pos.z+1},
      {x=pos.x, y=pos.y, z=pos.z-1},

      {x=pos.x+1, y=pos.y, z=pos.z+1},
      {x=pos.x+1, y=pos.y, z=pos.z-1},
      {x=pos.x-1, y=pos.y, z=pos.z+1},
      {x=pos.x-1, y=pos.y, z=pos.z-1},

      {x=pos.x+1, y=pos.y-1, z=pos.z},
      {x=pos.x-1, y=pos.y-1, z=pos.z},
      {x=pos.x, y=pos.y-1, z=pos.z+1},
      {x=pos.x, y=pos.y-1, z=pos.z-1},

      {x=pos.x+1, y=pos.y-1, z=pos.z+1},
      {x=pos.x+1, y=pos.y-1, z=pos.z-1},
      {x=pos.x-1, y=pos.y-1, z=pos.z+1},
      {x=pos.x-1, y=pos.y-1, z=pos.z-1},

      {x=pos.x+1, y=pos.y+1, z=pos.z},
      {x=pos.x-1, y=pos.y+1, z=pos.z},
      {x=pos.x, y=pos.y+1, z=pos.z+1},
      {x=pos.x, y=pos.y+1, z=pos.z-1},

      {x=pos.x+1, y=pos.y+1, z=pos.z+1},
      {x=pos.x+1, y=pos.y+1, z=pos.z-1},
      {x=pos.x-1, y=pos.y+1, z=pos.z+1},
      {x=pos.x-1, y=pos.y+1, z=pos.z-1},
    }

    local cw = 0

		-- Only flowing water counts.
    for k, v in ipairs(targets) do
      local node = minetest.get_node(v)
      if node.name == "default:water_flowing" or
					node.name == "default:river_water_flowing" then
        cw = cw + 1
      end
    end

    if cw > 0 then
      -- Randomize time to next nodecheck.
      meta:set_int("chktmr", math.random(3, 15))

      meta:set_int("active", 1)
      meta:set_int("eups", math.floor(cw * ENERGY_AMOUNT))

      machines.swap_node(pos, "wat2:lv_active")
      result = true
    else
      -- Don't set timer if generator is offline.
      -- The next check needs to happen the next time the machine is punched.
      meta:set_int("chktmr", 0)

      meta:set_int("active", 0)
      meta:set_int("eups", 0)

      machines.swap_node(pos, "wat2:lv_inactive")
      result = false
    end

		meta:set_string("infotext", wat2.compose_infotext(pos))
		return result
  end

  -- Decrement check timer.
  timer = timer - 1
  meta:set_int("chktmr", timer)

  -- No check performed; just return whatever the result of the last check was.
  return (active == 1)
end

wat2.on_timer =
function(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local inv = meta:get_inventory()
	local keeprunning = false

	-- Check if we can produce energy from environment.
	-- Note that this uses a caching algorithm.
	local canrun = wat2.check_environment(pos, meta)

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
		minetest.get_node_timer(pos):start(math.random(1, 3*60))
		meta:set_int("chktmr", 0)
		meta:set_int("active", 0)
		meta:set_int("eups", 0)
		meta:set_string("infotext", wat2.compose_infotext(pos))
		machines.swap_node(pos, "wat2:lv_inactive")
	end
end

wat2.on_construct =
function(pos)
end

wat2.after_place_node =
function(pos, placer, itemstack, pointed_thing)
  local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local owner = placer:get_player_name()
  local inv = meta:get_inventory()

	meta:set_string("owner", owner)
	meta:set_string("nodename", node.name)
  inv:set_size("buffer", 1)

	net2.clear_caches(pos, owner, "lv")
	meta:set_string("formspec", wat2.compose_formspec(pos))
	meta:set_string("infotext", wat2.compose_infotext(pos))
	nodestore.add_node(pos)

	local timer = minetest.get_node_timer(pos)
	timer:start(1.0)
end

wat2.on_blast =
function(pos)
  local drops = {}
  drops[#drops+1] = "wat2:lv_inactive"
  minetest.remove_node(pos)
  return drops
end

wat2.allow_metadata_inventory_put =
function(pos, listname, index, stack, player)
  return 0
end

wat2.allow_metadata_inventory_move =
function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

wat2.allow_metadata_inventory_take =
function(pos, listname, index, stack, player)
  return 0
end

wat2.on_metadata_inventory_move =
function(pos)
  wat2.trigger_update(pos)
end

wat2.on_metadata_inventory_put =
function(pos)
  wat2.trigger_update(pos)
end

wat2.on_metadata_inventory_take =
function(pos, listname, index, stack, player)
  wat2.trigger_update(pos)
end

wat2.on_destruct =
function(pos)
	local meta = minetest.get_meta(pos)
	net2.clear_caches(pos, meta:get_string("owner"), "lv")
	nodestore.del_node(pos)
end



if not wat2.run_once then
  for k, v in ipairs({
    {name="inactive", tile="geothermal_generator_top.png"},
    {name="active", tile="geothermal_generator_top_active.png"},
  }) do
    minetest.register_node(":wat2:lv_" .. v.name, {
      description = "LV Hydroturbine Generator",
      tiles = {
        v.tile, v.tile,
        "water_mill_side.png", "water_mill_side.png",
        "water_mill_side.png", "water_mill_side.png"
      },

      groups = {level=1, cracky=3},

      paramtype2 = "facedir",
      is_ground_content = false,
      sounds = default.node_sound_metal_defaults(),
      drop = "wat2:lv_inactive",

			on_energy_get = function(...)
				return wat2.on_energy_get(...) end,
      on_rotate = function(...)
				return screwdriver.rotate_simple(...) end,
      allow_metadata_inventory_put = function(...)
        return wat2.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return wat2.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return wat2.allow_metadata_inventory_take(...) end,
      on_metadata_inventory_move = function(...)
        return wat2.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return wat2.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return wat2.on_metadata_inventory_take(...) end,
      on_punch = function(...)
        return wat2.on_punch(...) end,
      can_dig = function(...)
        return wat2.can_dig(...) end,
      on_timer = function(...)
        return wat2.on_timer(...) end,
      on_construct = function(...)
        return wat2.on_construct(...) end,
			on_destruct = function(...)
				return wat2.on_destruct(...) end,
      on_blast = function(...)
        return wat2.on_blast(...) end,
      after_place_node = function(...)
        return wat2.after_place_node(...) end,
    })
  end

	minetest.register_craft({
		output = 'wat2:lv_inactive',
		recipe = {
			{'morerocks:marble', 'default:diamond',        'morerocks:marble'},
			{'group:wood',     'techcrafts:machine_casing', 'group:wood'},
			{'techcrafts:copper_coil', 'cb2:lv',       'techcrafts:electric_motor'},
		}
	})

  local c = "wat2:core"
  local f = wat2.modpath .. "/wat2.lua"
  reload.register_file(c, f, false)

	wat2.run_once = true
end

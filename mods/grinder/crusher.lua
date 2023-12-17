
if not minetest.global_exists("grinder") then grinder = {} end
grinder.crusher = grinder.crusher or {}
local crusher = grinder.crusher

-- Localize for performance.
local math_floor = math.floor



-- Get active formspec.
crusher.get_active_formspec = function(fuel_percent, item_percent)
  local formspec =
    "size[8,8.5]"..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors() ..

    "label[2.75,0;Fuel & Input]" ..
    "list[context;src;2.75,0.5;1,1;]"..
    "list[context;fuel;2.75,2.5;1,1;]"..

    "image[2.75,1.5;1,1;machine_progress_bg.png^[lowpart:" ..
    (100-fuel_percent) .. ":machine_progress_fg.png]" ..

    "image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
    (item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
    "label[4.75,0.46;Destination]" ..
    "list[context;dst;4.75,0.96;2,2;]"..
    "list[current_player;main;0,4.25;8,1;]"..
    "list[current_player;main;0,5.5;8,3;8]"..
    "listring[context;dst]"..
    "listring[current_player;main]"..
    "listring[context;src]"..
    "listring[current_player;main]"..
    "listring[context;fuel]"..
    "listring[current_player;main]"..
    default.get_hotbar_bg(0, 4.25)
  return formspec
end



crusher.get_inactive_formspec = function()
  return crusher.get_active_formspec(100, 0)
end



crusher.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end



crusher.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  if listname == "fuel" then
    if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
      if inv:is_empty("src") then
        meta:set_string("infotext", "Crushing Machine is Empty.")
      end
      return stack:get_count()
    else
      return 0
    end
  elseif listname == "src" then
    return stack:get_count()
  elseif listname == "dst" then
    return 0
  end
end



crusher.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return crusher.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



crusher.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  return stack:get_count()
end



crusher.on_timer = function(pos, elapsed)
  --
  -- Inizialize metadata
  --
  local meta = minetest.get_meta(pos)
  local fuel_time = meta:get_float("fuel_time") or 0
  local src_time = meta:get_float("src_time") or 0
  local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

  local inv = meta:get_inventory()
  local srclist = inv:get_list("src")
  local fuellist = inv:get_list("fuel")

  --
  -- Cooking
  --

  -- Check if we have cookable content
  local cooked, aftercooked = minetest.get_craft_result({
		method = "crushing", width = 1, items = srclist})
  local cookable = true

  if cooked.time == 0 then
    cookable = false
  end

  -- Check if we have enough fuel to burn
  if fuel_time < fuel_totaltime then
    -- The furnace is currently active and has enough fuel
    fuel_time = fuel_time + 1

    -- If there is a cookable item then check if it is ready yet
    if cookable then
      src_time = src_time + 1
      if src_time >= cooked.time then
        -- Place result in dst list if possible
        if inv:room_for_item("dst", cooked.item) then
          inv:add_item("dst", cooked.item)
          inv:set_stack("src", 1, aftercooked.items[1])
          src_time = 0
        end
      end
    end
  else
    -- Furnace ran out of fuel
    if cookable then
      -- We need to get new fuel
      local fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})

      if fuel.time == 0 then
        -- No valid fuel in fuel list
        fuel_totaltime = 0
        fuel_time = 0
        src_time = 0
      else
        -- Take fuel from fuel list
        inv:set_stack("fuel", 1, afterfuel.items[1])

        fuel_totaltime = fuel.time
        fuel_time = 0
      end
    else
      -- We don't need to get new fuel since there is no cookable item
      fuel_totaltime = 0
      fuel_time = 0
      src_time = 0
    end
  end

  --
  -- Update formspec, infotext and node
  --
  local formspec = crusher.get_inactive_formspec()
  local item_state
  local item_percent = 0
  if cookable then
    item_percent = math_floor(src_time / cooked.time * 100)
    if item_percent > 100 then
      item_state = "100% (Output Full)"
    else
      item_state = item_percent .. "%"
    end
  else
    if srclist[1]:is_empty() then
      item_state = "Empty"
    else
      item_state = "Not Crushable"
    end
  end

  local fuel_state = "Empty"
  local active = "Inactive "
  local result = false

  if fuel_time <= fuel_totaltime and fuel_totaltime ~= 0 then
    active = "Active "
    local fuel_percent = math_floor(fuel_time / fuel_totaltime * 100)
    fuel_state = fuel_percent .. "%"
    formspec = crusher.get_active_formspec(fuel_percent, item_percent)
    local swapped = machines.swap_node(pos, "crusher:active")

    if swapped then
      ambiance.spawn_sound_beacon("ambiance:grinder_active", pos)
    end

    -- make sure timer restarts automatically
    result = true
  else
    if not fuellist[1]:is_empty() then
      fuel_state = "0%"
    end
    machines.swap_node(pos, "crusher:inactive")
    -- stop timer on the inactive furnace
    local timer = minetest.get_node_timer(pos)
    timer:stop()
  end

  local infotext = "Crushing Machine " .. active .. "\n" ..
    "Item: " .. item_state .. "\n" .. "Fuel Burn: " .. fuel_state

  --
  -- Set meta values
  --
  meta:set_float("fuel_totaltime", fuel_totaltime)
  meta:set_float("fuel_time", fuel_time)
  meta:set_float("src_time", src_time)
  meta:set_string("formspec", formspec)
  meta:set_string("infotext", infotext)

  return result
end



crusher.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  drops[#drops+1] = "crusher:inactive"
  minetest.remove_node(pos)
  return drops
end



crusher.on_construct = function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("infotext", "Crushing Machine")
  meta:set_string("formspec", crusher.get_inactive_formspec())
  local inv = meta:get_inventory()
  inv:set_size('src', 1)
  inv:set_size('fuel', 1)
  inv:set_size('dst', 4)
end



crusher.on_metadata_inventory_move = function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
		timer:start(1.0)
	end
end



crusher.on_metadata_inventory_put = function(pos)
  -- Start timer function, it will sort out whether furnace can burn or not.
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
		timer:start(1.0)
	end
end



crusher.on_metadata_inventory_take = function(pos)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
		timer:start(1.0)
	end
end



if not crusher.registered then
  for k, v in ipairs({
    {name="inactive", light=0, tile="crusher_front.png"},
    {name="active", light=7, tile="crusher_front_active.png"},
  }) do
    minetest.register_node(":crusher:" .. v.name, {
      description = "Crushing Machine\n\nCrushes (or grinds) things, but slowly and inefficiently.\nUses coal or kalite for fuel.",
      tiles = {
        "crusher_top.png",  "crusher_bottom.png",
        "crusher_side.png", "crusher_side.png",
        "crusher_side.png", v.tile,
      },

      paramtype2 = "facedir",
      groups = utility.dig_groups("machine", {immovable = 1}),
			light_source = v.light,

      on_rotate = function(...) return screwdriver.rotate_simple(...) end,
      is_ground_content = false,
      sounds = default.node_sound_stone_defaults(),
      drop = "crusher:inactive",

      can_dig = function(...)
        return crusher.can_dig(...) end,
      on_timer = function(...)
        return crusher.on_timer(...) end,
      on_construct = function(...)
        return crusher.on_construct(...) end,
      on_blast = function(...)
        return crusher.on_blast(...) end,
      on_metadata_inventory_move = function(...)
        return crusher.on_metadata_inventory_move(...) end,
      on_metadata_inventory_put = function(...)
        return crusher.on_metadata_inventory_put(...) end,
      on_metadata_inventory_take = function(...)
        return crusher.on_metadata_inventory_take(...) end,
      allow_metadata_inventory_put = function(...)
        return crusher.allow_metadata_inventory_put(...) end,
      allow_metadata_inventory_move = function(...)
        return crusher.allow_metadata_inventory_move(...) end,
      allow_metadata_inventory_take = function(...)
        return crusher.allow_metadata_inventory_take(...) end,
    })
  end

  minetest.register_craft({
    output = 'crusher:inactive',
    recipe = {
      {'default:cobble', 'default:steelblock','default:cobble'},
      {'', 'default:diamondblock', ''},
      {'default:stonebrick','default:cobble','default:stonebrick'},
    }
  })

	minetest.register_craft({
		type = "crushing",
		output = 'default:gravel',
		recipe = 'default:cobble',
		time = 60*2,
	})

	minetest.register_craft({
		type = "crushing",
		output = 'darkage:darkdirt',
		recipe = 'default:gravel',
		time = 60*1.5,
	})

	minetest.register_craft({
		type = "crushing",
		output = 'default:sand',
		recipe = 'default:stone',
		time = 60*2.5,
	})

	minetest.register_craft({
		type = "crushing",
		output = 'default:desert_sand',
		recipe = 'default:desert_stone',
		time = 60*2.5,
	})

	minetest.register_craft({
		type = "crushing",
		output = 'default:obsidian_shard 6',
		recipe = 'default:obsidian',
		time = 60*3,
	})

	crusher.registered = true
end

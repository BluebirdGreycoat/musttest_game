
if not minetest.global_exists("redstone_furnace") then redstone_furnace = {} end
redstone_furnace.modpath = minetest.get_modpath("redstone_furnace")
local FURNACE_SPEED = 1.5

-- Localize for performance.
local math_floor = math.floor



-- Get active formspec.
redstone_furnace.get_active_formspec = function(fuel_percent, item_percent)
	-- Obtain hooks into the trash mod's trash slot inventory.
	local ltrash, mtrash = trash.get_listname()
	local itrash = trash.get_iconname()

  local formspec = 
    "size[8,8.5]"..
    default.formspec.get_form_colors() ..
    default.formspec.get_form_image() ..
    default.formspec.get_slot_colors() ..
    
    "label[2.75,0;Fuel & Input]" ..
    "list[context;src;2.75,0.5;1,1;]"..
    "list[context;fuel;2.75,2.5;1,1;]"..

		utility.progress_image(2.75, 1.5, "default_furnace_fire_bg.png", "default_furnace_fire_fg.png", fuel_percent) ..
		utility.progress_image(3.75, 1.5, "gui_furnace_arrow_bg.png", "gui_furnace_arrow_fg.png", item_percent, "^[transformR270") ..

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

		-- Trash icon.
		.. "list[" .. ltrash .. ";" .. mtrash .. ";0.75,0.5;1,1;]" ..
		"image[0.75,0.5;1,1;" .. itrash .. "]"

  return formspec
end



redstone_furnace.get_inactive_formspec = function()
  return redstone_furnace.get_active_formspec(0, 0)
end



redstone_furnace.can_dig = function(pos, player)
  local meta = minetest.get_meta(pos);
  local inv = meta:get_inventory()
  return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end



redstone_furnace.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  if listname == "fuel" then
    if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
      if inv:is_empty("src") then
        meta:set_string("infotext", "Coal Furnace is Empty.")
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



redstone_furnace.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack(from_list, from_index)
  return redstone_furnace.allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end



redstone_furnace.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  if minetest.test_protection(pos, player:get_player_name()) then
    return 0
  end
  return stack:get_count()
end



redstone_furnace.on_timer = function(pos, elapsed)
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
  local cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
  local cookable = true

  if cooked.time == 0 then
    cookable = false
	else
		cooked.time = cooked.time * FURNACE_SPEED
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

        fuel_totaltime = fuel.time * FURNACE_SPEED
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
  local formspec = redstone_furnace.get_inactive_formspec()
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
      item_state = "Not Cookable"
    end
  end

  local fuel_state = "Empty"
  local active = "Inactive "
  local result = false

  if fuel_time <= fuel_totaltime and fuel_totaltime ~= 0 then
    active = "Active "
    local fuel_percent = 100 - math_floor(fuel_time / fuel_totaltime * 100)
    fuel_state = fuel_percent .. "%"
    formspec = redstone_furnace.get_active_formspec(fuel_percent, item_percent)
		local nnn = minetest.get_node(pos).name
	  if machines.swap_node(pos, "redstone_furnace:active") then
			torchmelt.start_melting(pos)
			notify.notify_adjacent(pos)
			ambiance.spawn_sound_beacon("ambiance:furnace_active", pos)
		end
    -- make sure timer restarts automatically
    result = true
  else
    if not fuellist[1]:is_empty() then
      fuel_state = "0%"
    end
    machines.swap_node(pos, "redstone_furnace:inactive")
    -- stop timer on the inactive furnace
    local timer = minetest.get_node_timer(pos)
    timer:stop()
  end

  local infotext = "Coal Furnace " .. active .. "\n" ..
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



redstone_furnace.on_blast = function(pos)
  local drops = {}
  default.get_inventory_drops(pos, "src", drops)
  default.get_inventory_drops(pos, "fuel", drops)
  default.get_inventory_drops(pos, "dst", drops)
  drops[#drops+1] = "redstone_furnace:inactive"
  minetest.remove_node(pos)
  return drops
end



redstone_furnace.on_construct = function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("infotext", "Coal Furnace")
  meta:set_string("formspec", redstone_furnace.get_inactive_formspec())
  local inv = meta:get_inventory()
  inv:set_size('src', 1)
  inv:set_size('fuel', 1)
  inv:set_size('dst', 4)
end



redstone_furnace.on_metadata_inventory_move = function(pos)
  local timer = minetest.get_node_timer(pos)
  timer:start(1.0)
end



redstone_furnace.on_metadata_inventory_put = function(pos)
  -- Start timer function, it will sort out whether furnace can burn or not.
  local timer = minetest.get_node_timer(pos)
  timer:start(1.0)
end

redstone_furnace.burn_feet = function(pos, player)
	if not heatdamage.is_immune(player:get_player_name()) then
    utility.damage_player(player, "heat", 1*500)
	end
end



if not redstone_furnace.run_once then
  minetest.register_node("redstone_furnace:inactive", {
    description = "Fuel-Fired Furnace\n\nCooks or smelts things, but slowly and inefficiently.\nBurns coal and other flammable things.",
    tiles = {
      "redstone_furnace_top.png", "redstone_furnace_bottom.png",
      "redstone_furnace_side.png", "redstone_furnace_side.png",
      "redstone_furnace_side.png", "redstone_furnace_front.png"
    },
    
    groups = utility.dig_groups("cobble", {
      tubedevice = 1, tubedevice_receiver = 1,
      immovable = 1,
    }),
    
    paramtype2 = "facedir",
    on_rotate = function(...) return screwdriver.rotate_simple(...) end,
    is_ground_content = false,
    sounds = default.node_sound_stone_defaults(),

    can_dig = function(...)
      return redstone_furnace.can_dig(...) end,
    on_timer = function(...)
      return redstone_furnace.on_timer(...) end,
    on_construct = function(...)
      return redstone_furnace.on_construct(...) end,

    on_metadata_inventory_move = function(...)
      return redstone_furnace.on_metadata_inventory_move(...) end,
    on_metadata_inventory_put = function(...)
      return redstone_furnace.on_metadata_inventory_put(...) end,
    on_blast = function(...)
      return redstone_furnace.on_blast(...) end,

    allow_metadata_inventory_put = function(...)
      return redstone_furnace.allow_metadata_inventory_put(...) end,
    allow_metadata_inventory_move = function(...)
      return redstone_furnace.allow_metadata_inventory_move(...) end,
    allow_metadata_inventory_take = function(...)
      return redstone_furnace.allow_metadata_inventory_take(...) end,
  })



  minetest.register_node("redstone_furnace:active", {
    tiles = {
      "redstone_furnace_top.png", "redstone_furnace_bottom.png",
      "redstone_furnace_side.png", "redstone_furnace_side.png",
      "redstone_furnace_side.png",
      {
        image = "redstone_furnace_front_active.png",
        backface_culling = false,
        animation = {
          type = "vertical_frames",
          aspect_w = 16,
          aspect_h = 16,
          length = 1.5
        },
      }
    },
    light_source = 8,
    drop = "redstone_furnace:inactive",
    
    groups = utility.dig_groups("cobble", {
      not_in_creative_inventory=1, 
      melt_around = 4,
      tubedevice = 1, tubedevice_receiver = 1,
      immovable = 1,
    }),
    
    paramtype2 = "facedir",
    on_rotate = function(...) return screwdriver.rotate_simple(...) end,
    is_ground_content = false,
    sounds = default.node_sound_stone_defaults(),
    
    on_timer = function(...)
      return redstone_furnace.on_timer(...) end,
    can_dig = function(...)
      return redstone_furnace.can_dig(...) end,
    on_blast = function(...)
      return redstone_furnace.on_blast(...) end,

    allow_metadata_inventory_put = function(...)
      return redstone_furnace.allow_metadata_inventory_put(...) end,
    allow_metadata_inventory_move = function(...)
      return redstone_furnace.allow_metadata_inventory_move(...) end,
    allow_metadata_inventory_take = function(...)
      return redstone_furnace.allow_metadata_inventory_take(...) end,

		on_player_walk_over = function(...)
			return redstone_furnace.burn_feet(...) end,
  })



  -- Recipe modified by MustTest.
  minetest.register_craft({
    output = 'redstone_furnace:inactive',
    recipe = {
      {'rackstone:cobble', 'rackstone:cobble', 'rackstone:cobble'},
      {'rackstone:cobble', 'group:torch_craftitem', 'rackstone:cobble'},
      {'rackstone:cobble', 'rackstone:cobble', 'rackstone:cobble'},
    }
  })
  
  minetest.register_craft({
    output = 'redstone_furnace:inactive',
    recipe = {
      {'default:desert_cobble', 'default:desert_cobble', 'default:desert_cobble'},
      {'default:desert_cobble', 'group:torch_craftitem', 'default:desert_cobble'},
      {'default:desert_cobble', 'default:desert_cobble', 'default:desert_cobble'},
    }
  })

  local c = "redstone_furnace:core"
  local f = redstone_furnace.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  redstone_furnace.run_once = true
end


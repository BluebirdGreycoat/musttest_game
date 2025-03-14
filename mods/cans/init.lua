
if not minetest.global_exists("cans") then cans = {} end

-- Localize for performance.
local math_floor = math.floor


local function set_can_wear(itemstack, level, max_level)
  local temp
  if level == 0 then
    temp = 0
  else
    temp = 65536 - math_floor(level / max_level * 65535)
    if temp > 65535 then temp = 65535 end
    if temp < 1 then temp = 1 end
  end
  itemstack:set_wear(temp)
end

local function get_can_level(itemstack)
  if itemstack:get_metadata() == "" then
    return 0
  else
    return tonumber(itemstack:get_metadata())
  end
end
cans.get_can_level = get_can_level

local function set_can_level(itemstack, charge)
  itemstack:set_metadata(tostring(charge))
end

function cans.set_can_level(itemstack, level)
  if level < 0 then
    level = 0
  end

  local idef = minetest.registered_items[itemstack:get_name()]
  local max_level = idef._can_max_liquid_level

  set_can_level(itemstack, level)
  set_can_wear(itemstack, level, max_level)
end

local function node_in_group(name, list)
	if type(list) == "string" then
		return (name == list)
	elseif type(list) == "table" then
		for k, v in ipairs(list) do
			if name == v then
				return true
			end
		end
	end
	return false
end



function cans.register_can(d)
  local data = table.copy(d)
  
  minetest.register_tool(data.can_name, {
    description = data.can_description,
    inventory_image = data.can_inventory_image,
    stack_max = 1,
    liquids_pointable = true,
		wear_represents = "liquid_amount",
		groups = {not_repaired_by_anvil = 1, disable_repair = 1},
		_can_max_liquid_level = data.can_capacity,
    
    on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then return end
      local node = minetest.get_node(pointed_thing.under)
      if not node_in_group(node.name, data.liquid_source_name) then return end
      local charge = get_can_level(itemstack)
      if charge == data.can_capacity then return end

      if minetest.is_protected(pointed_thing.under, user:get_player_name()) then
        minetest.log("action", user:get_player_name().." tried to take "..node.name.." at protected position "..minetest.pos_to_string(pointed_thing.under).." with a "..data.can_name)
        minetest.chat_send_player(user:get_player_name(), "# Server: That is on someone else's land!")
        return
      end
      
      if node.name == "default:lava_source" then
        minetest.add_node(pointed_thing.under, {name="fire:basic_flame"})
        local pos = user:get_pos()
        minetest.sound_play("default_cool_lava", {pos = pos, max_hear_distance = 16, gain = 0.25}, true)
        if not heatdamage.is_immune(user:get_player_name()) then
          bucket.harm_player_after(user:get_player_name(), 2*500)
        end
      else
        minetest.remove_node(pointed_thing.under)
      end
      
      charge = charge + 1
      set_can_level(itemstack, charge)
      set_can_wear(itemstack, charge, data.can_capacity)
      return itemstack
    end,
    
    on_place = function(itemstack, user, pointed_thing)
			if not user or not user:is_player() then
				return
			end
			local pname = user:get_player_name()

      if pointed_thing.type ~= "node" then return end
      local pos = pointed_thing.under
			local node = minetest.get_node(pos)

      local def = minetest.reg_ns_nodes[node.name] or {}
      if def.on_rightclick and not user:get_player_control().sneak then
        return def.on_rightclick(pos, node, user, itemstack, pointed_thing)
      end

			if node_in_group(node.name, data.liquid_source_name) or node_in_group(node.name, data.liquid_flowing_name) then
				-- Do nothing, `pos' already set.
      elseif not def.buildable_to then
        pos = pointed_thing.above
				local node = minetest.get_node(pos)
        def = minetest.reg_ns_nodes[node.name] or {}
        if not def.buildable_to then return end
      end

      local charge = get_can_level(itemstack)
      if charge == 0 then return end

			-- Check against local ground level.
			local success, ground_level = rc.get_ground_level_at_pos(pos)
			if not success then
				minetest.chat_send_player(pname, "# Server: That position is in the Void!")
				easyvend.sound_error(pname)
				return
			end

      if rc.liquid_forbidden_at(pos) then
        minetest.chat_send_player(pname, "# Server: Liquids forbidden in this region.")
        easyvend.sound_error(pname)
        return
      end

			-- Above 10000 XP, player can use buckets.
			-- Note: this will allow high-XP players to place lava (which ignores
			-- protection) above ground. If such a player decides to grief somebody,
			-- I guess you'll need to form a posse! (You can still use city blocks
			-- to protect builds.)
			local lxp = (xp.get_xp(pname, "digxp") >= 10000)
			if not lxp or sheriff.is_cheater(pname) then
				if pos.y > ground_level then
					minetest.chat_send_player(pname, "# Server: Don't do that above ground!")
					easyvend.sound_error(pname)
					return
				end
			end

      if minetest.is_protected(pos, pname) then
        minetest.log("action", pname .. " tried to place " .. data.place_name .. " at protected position " .. minetest.pos_to_string(pos) .. " with a "..data.can_name)
        minetest.chat_send_player(pname, "# Server: Not on somebody else's land!")
        easyvend.sound_error(pname)
        return
      end

			if city_block:in_disallow_liquid_zone(pos, user) then
				minetest.chat_send_player(pname, "# Server: Don't do that in town!")
				easyvend.sound_error(pname)
				return
			end

      minetest.set_node(pos, {name=data.place_name})
      charge = charge - 1
      set_can_level(itemstack, charge)
      set_can_wear(itemstack, charge, data.can_capacity)

      -- Notify dirt.
      dirtspread.on_environment(pos)
			droplift.notify(pos)

      return itemstack
    end,
  })
end



cans.register_can({
  can_name = "cans:water_can",
  can_description = "Water Can",
  can_inventory_image = "technic_water_can.png",
  can_capacity = 16,
  liquid_source_name = {"default:water_source", "cw:water_source"},
  liquid_flowing_name = {"default:water_flowing", "cw:water_flowing"},
	place_name = "default:water_source",
})

minetest.register_craft({
  output = 'cans:water_can',
  recipe = {
    {'zinc:ingot', 'rubber:rubber_fiber','zinc:ingot'},
    {'carbon_steel:ingot', '', 'carbon_steel:ingot'},
    {'zinc:ingot', 'carbon_steel:ingot', 'zinc:ingot'},
  }
})

cans.register_can({
  can_name = "cans:river_water_can",
  can_description = "Fresh Water Can",
  can_inventory_image = "technic_river_water_can.png",
  can_capacity = 16,
  liquid_source_name = "default:river_water_source",
  liquid_flowing_name = "default:river_water_flowing",
	place_name = "default:river_water_source",
})

minetest.register_craft({
  type   = "shapeless",
  output = "cans:river_water_can",
  recipe = {"cans:water_can"},
})

minetest.register_craft({
  type   = "shapeless",
  output = "cans:water_can",
  recipe = {"cans:river_water_can"},
})



cans.register_can({
  can_name = "cans:lava_can",
  can_description = "Lava Can",
  can_inventory_image = "technic_lava_can.png",
  can_capacity = 8,
  liquid_source_name = "default:lava_source",
  liquid_flowing_name = "default:lava_flowing",
	place_name = "default:lava_source",
})

minetest.register_craft({
  output = 'cans:lava_can',
  recipe = {
    {'zinc:ingot', 'stainless_steel:ingot','zinc:ingot'},
    {'stainless_steel:ingot', '', 'stainless_steel:ingot'},
    {'zinc:ingot', 'stainless_steel:ingot', 'zinc:ingot'},
  }
})

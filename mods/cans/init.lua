
cans = cans or {}



local function set_can_wear(itemstack, level, max_level)
  local temp
  if level == 0 then
    temp = 0
  else
    temp = 65536 - math.floor(level / max_level * 65535)
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

local function set_can_level(itemstack, charge)
  itemstack:set_metadata(tostring(charge))
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
    
    on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then return end
      local node = minetest.get_node(pointed_thing.under)
      if node.name ~= data.liquid_source_name then return end
      local charge = get_can_level(itemstack)
      if charge == data.can_capacity then return end
      if minetest.is_protected(pointed_thing.under, user:get_player_name()) then
        minetest.log("action", user:get_player_name().." tried to take "..node.name.." at protected position "..minetest.pos_to_string(pointed_thing.under).." with a "..data.can_name)
        minetest.chat_send_player(user:get_player_name(), "# Server: That is on someone else's land!")
        return
      end
      
      if node.name == "default:lava_source" then
        minetest.set_node(pointed_thing.under, {name="fire:basic_flame"})
        local pos = user:getpos()
        minetest.sound_play("default_cool_lava", {pos = pos, max_hear_distance = 16, gain = 0.25})
        if not heatdamage.is_immune(user:get_player_name()) then
          bucket.harm_player_after(user:get_player_name(), 2)
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

      if pointed_thing.type ~= "node" then return end
      local pos = pointed_thing.under
			local node = minetest.get_node(pos)

      local def = minetest.reg_ns_nodes[node.name] or {}
      if def.on_rightclick and not user:get_player_control().sneak then
        return def.on_rightclick(pos, node, user, itemstack, pointed_thing)
      end

			if node.name == data.liquid_source_name or node.name == data.liquid_flowing_name then
				-- Do nothing, `pos' already set.
      elseif not def.buildable_to then
        pos = pointed_thing.above
				local node = minetest.get_node(pos)
        def = minetest.reg_ns_nodes[node.name] or {}
        if not def.buildable_to then return end
      end

      local charge = get_can_level(itemstack)
      if charge == 0 then return end
      if pos.y > -9 then
        minetest.chat_send_player(user:get_player_name(), "# Server: Don't do that above ground!")
				easyvend.sound_error(user:get_player_name())
        return
      end
      if minetest.is_protected(pos, user:get_player_name()) then
        minetest.log("action", user:get_player_name().." tried to place "..data.liquid_source_name.." at protected position "..minetest.pos_to_string(pos).." with a "..data.can_name)
        minetest.chat_send_player(user:get_player_name(), "# Server: Not on somebody else's land!")
        return
      end

			if city_block:in_city(pos) then
				minetest.chat_send_player(user:get_player_name(), "# Server: Don't do that in town!")
				easyvend.sound_error(user:get_player_name())
				return
			end

      minetest.set_node(pos, {name=data.liquid_source_name})
      charge = charge - 1
      set_can_level(itemstack, charge)
      set_can_wear(itemstack, charge, data.can_capacity)
      return itemstack
    end,
  })
end



cans.register_can({
  can_name = "cans:water_can",
  can_description = "Water Can",
  can_inventory_image = "technic_water_can.png",
  can_capacity = 16,
  liquid_source_name = "default:water_source",
  liquid_flowing_name = "default:water_flowing",
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
  can_name = "cans:lava_can",
  can_description = "Lava Can",
  can_inventory_image = "technic_lava_can.png",
  can_capacity = 8,
  liquid_source_name = "default:lava_source",
  liquid_flowing_name = "default:lava_flowing",
})

minetest.register_craft({
  output = 'cans:lava_can',
  recipe = {
    {'zinc:ingot', 'stainless_steel:ingot','zinc:ingot'},
    {'stainless_steel:ingot', '', 'stainless_steel:ingot'},
    {'zinc:ingot', 'stainless_steel:ingot', 'zinc:ingot'},
  }
})

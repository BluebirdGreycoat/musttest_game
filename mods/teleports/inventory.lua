
-- Localize.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_floor = math.floor
local math_random = math.random



teleports.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
  local pname = player:get_player_name()

  -- Protection interferes with building public networks.
  --if minetest.test_protection(pos, pname) then return 0 end

  if listname == "price" and stack:get_name() == "default:mossycobble" then
    return stack:get_count()
  elseif listname == "price" and stack:get_name() == "flowers:waterlily" then
    return stack:get_count()
  elseif listname == "price" and stack:get_name() == "default:mese_crystal_fragment" then
    return stack:get_count()
	elseif listname == "price" and stack:get_name() == "rosestone:head" then
		if minetest.test_protection(pos, pname) then return 0 end
		return stack:get_count()
  end

  return 0
end



teleports.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  -- Protection interferes with building public networks.
	--if minetest.test_protection(pos, pname) then return 0 end

	if stack:get_name() == "rosestone:head" then
		if minetest.test_protection(pos, pname) then return 0 end
		return stack:get_count()
	end

  return stack:get_count()
end



teleports.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end



function teleports.on_metadata_inventory_put(pos, listname, index, stack, player)
	teleports.update_beacon_data(pos)
end



function teleports.on_metadata_inventory_take(pos, listname, index, stack, player)
	teleports.update_beacon_data(pos)
end

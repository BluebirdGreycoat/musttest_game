
-- This file is reloadable.

-- Localize vector.distance() for performance.
local vector_distance = vector.distance



-- Checks if the given position would place the player underwater, swimming, or not-in-water.
ambiance.check_underwater = function(pos)
	local registered = minetest.reg_ns_nodes

	local n2 = minetest.get_node({x=pos.x, y=pos.y+0.2, z=pos.z}).name
	local nf = registered[n2]
	
	if nf and nf.groups and nf.groups.water then
		local n1 = minetest.get_node({x=pos.x, y=pos.y+1.4, z=pos.z}).name
		local nh = registered[n1]
		
		if nh and nh.groups and nh.groups.water then
			return 2 -- Feet and head submerged.
		end
		return 1 -- Feet submerged.
	end
	
	return 0 -- Not in water.
end



-- Checks given time against the named time, returning success if the time matches.
ambiance.check_time = function(timename, curtime)
	if timename == "" then
		return true
	end
	local goodtime = false
	local curtime = minetest.get_timeofday()
	if curtime then
		if timename == "night" and (curtime < 0.2 or curtime > 0.8) then
			goodtime = true
		elseif timename == "day" and (curtime > 0.3 and curtime < 0.7) then
			goodtime = true
		elseif timename == "noon" and (curtime > 0.4 and curtime < 0.6) then
			goodtime = true
		elseif timename == "midnight" and (curtime > 0.9 or curtime < 0.1) then
			goodtime = true
		elseif timename == "dusk" and (curtime > 0.7 and curtime < 0.8) then
			goodtime = true
		elseif timename == "dawn" and (curtime > 0.2 and curtime < 0.3) then
			goodtime = true
		elseif timename == "liminal" and ((curtime > 0.2 and curtime < 0.3) or (curtime > 0.7 and curtime < 0.8)) then
			goodtime = true
		end
	end
	return goodtime
end



local compute_gain = function(distance, max)
  assert(max >= 1)
  local res = (100.0 * distance) / max
  res = res / 100.0
  if res < 0 then res = 0 end
  if res > 1 then res = 1 end
  res = (res * -1) + 1
  return res
end
ambiance.compute_gain = compute_gain
  
-- This function plays a sound for each player within a given range.
-- The audio gain is reduced for players far from the position at which the sound should play.
ambiance.sound_play = function(name, pos, gain, range, exempt_player, ephemeral)
  -- Range check! Stupid engine bug. >:(
  if pos.x > 31000 or pos.x < -31000 or pos.z > 31000 or pos.z < -31000 or pos.y > 31000 or pos.y < -31000 then
    return -- Abort!
  end

	local eph = true
	if ephemeral ~= nil then
		eph = ephemeral
	end

  local exempt = exempt_player or ""
  local players = minetest.get_objects_inside_radius(pos, range)
  for k, v in ipairs(players) do
    if v:is_player() then
      local n = v:get_player_name()
      if n ~= exempt then
        local p1 = v:get_pos()
        local dist = vector_distance(p1, pos)
        local gn = compute_gain(dist, range)
				-- Ephemeral sound.
        minetest.sound_play(name, {to_player=n, gain=gn*gain}, eph)
      end
    end
  end
end



-- Check if the given position is in-doors, or out in the open.
ambiance.check_indoors = function(pname, pos)
	-- Check for sunlight if on the surface. This is a fast, quick hack that works.
	if pos.y > -20 then
		-- Is position indoors?
		-- The brightest lamp gives light-level 13 on its 8 adjacent nodes.
		-- This means light-level 14 and 15 represent sunlight.
		if (minetest.get_node_light(vector.add(pos, {x=0, y=1, z=0}), 0.5) or 0) < 14 then
			return true
		end
	else
		-- Player is underground. In this case, 'indoors' can be taken to mean 'inside a developed area'.
		-- Undeveloped areas will be made out of stone.
		-- So we can check what material the player is standing on, this will work most of the time.
		local nodename = sky.get_last_walked_node(pname)
		-- Capture stone.
		if nodename == "default:stone" or string.find(nodename, "stone_with") then
			return false
		end
		-- Capture (non-default) ores in stone, and anything cobble (including stairs).
		if string.find(nodename, "cobble") or string.find(nodename, "[_:]ore") or string.find(nodename, "mineral") then
			return false
		end
		-- Capture anything in the 'rackstone' group. This group should not be used for materials a player might build a house out of.
		if minetest.get_item_group(nodename, "rackstone") ~= 0 then
			return false
		end

		-- Player is underground, but standing on something manmade, therefore not 'out-doors'.
		return true
	end
	return false
end


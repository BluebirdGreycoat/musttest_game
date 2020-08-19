
function pm.seek_player_or_mob_or_item(pos)
	local obj = nil
	local dst = pm.sight_range

	local all = minetest.get_objects_inside_radius(pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		else
			ent = all[i]:get_luaentity()
			if ent then
				if ent.mob or ent.name == "__builtin:item" then
					objects[#objects+1] = all[i]
				end
			end
		end
	end

	for i=1, #objects, 1 do
		local ref = objects[i]
		local p = ref:get_pos()
		local d = vector.distance(pos, p)
		-- Distance > 1 to ignore self (basically a hack).
		if d > 1 and d < dst then
			dst = d
			obj = ref
		end
	end

	-- Object or nil.
	return nil, obj
end

function pm.seek_player_or_item(pos)
	local obj = nil
	local dst = pm.sight_range

	local all = minetest.get_objects_inside_radius(pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		else
			ent = all[i]:get_luaentity()
			if ent then
				if ent.name == "__builtin:item" then
					objects[#objects+1] = all[i]
				end
			end
		end
	end

	for i=1, #objects, 1 do
		local ref = objects[i]
		local p = ref:get_pos()
		local d = vector.distance(pos, p)
		-- Distance > 1 to ignore self (basically a hack).
		if d > 1 and d < dst then
			dst = d
			obj = ref
		end
	end

	-- Object or nil.
	return nil, obj
end

function pm.seek_player(pos)
	local obj = nil
	local dst = pm.sight_range

	local all = minetest.get_objects_inside_radius(pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		end
	end

	for i=1, #objects, 1 do
		local ref = objects[i]
		local p = ref:get_pos()
		local d = vector.distance(pos, p)
		-- Distance > 1 to ignore self (basically a hack).
		if d > 1 and d < dst then
			dst = d
			obj = ref
		end
	end

	-- Object or nil.
	return nil, obj
end

function pm.seek_node_with_meta(pos)
	local minp = vector.add(pos, {x=-16, y=-8, z=-16})
	local maxp = vector.add(pos, {x=16, y=8, z=16})

	local positions = minetest.find_nodes_with_meta(minp, maxp)

	if positions then
		if #positions > 0 then
			local pos = positions[math.random(1, #positions)]
			local minp = vector.add(pos, {x=-1, y=-1, z=-1})
			local maxp = vector.add(pos, {x=1, y=1, z=1})
			local airs = minetest.find_nodes_in_area(minp, maxp, "air")
			if airs and #airs > 0 then
				return airs[math.random(1, #airs)], nil
			end
		end
	end

	return nil, nil
end

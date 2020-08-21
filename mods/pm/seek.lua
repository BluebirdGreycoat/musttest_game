
function pm.seek_flammable_node(self, pos)
	local minp = vector.add(pos, {x=-8, y=-8, z=-8})
	local maxp = vector.add(pos, {x=8, y=8, z=8})
	local positions = minetest.find_nodes_in_area_under_air(minp, maxp, "group:flammable")
	if #positions > 0 then
		local p2 = positions[math.random(1, #positions)]
		if not minetest.test_protection(p2, "") then
			return p2, nil
		end
	end
	return nil, nil
end

function pm.seek_player_or_mob_or_item(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		else
			local ent = all[i]:get_luaentity()
			if ent then
				if ent.mob or ent.name == "__builtin:item" then
					objects[#objects+1] = all[i]
				end
			end
		end
	end

	if #objects > 0 then
		return nil, objects[math.random(1, #objects)]
	end

	return nil, nil
end

function pm.seek_player_or_mob(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		else
			local ent = all[i]:get_luaentity()
			if ent then
				if ent.mob then
					objects[#objects+1] = all[i]
				end
			end
		end
	end

	if #objects > 0 then
		return nil, objects[math.random(1, #objects)]
	end

	return nil, nil
end

function pm.seek_player_or_mob_not_wisp(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		else
			local ent = all[i]:get_luaentity()
			if ent then
				if ent.mob then
					if ent.name ~= "pm:follower" then
						objects[#objects+1] = all[i]
					end
				end
			end
		end
	end

	if #objects > 0 then
		return nil, objects[math.random(1, #objects)]
	end

	return nil, nil
end

function pm.seek_player_or_item(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		else
			local ent = all[i]:get_luaentity()
			if ent then
				if ent.name == "__builtin:item" then
					objects[#objects+1] = all[i]
				end
			end
		end
	end

	if #objects > 0 then
		return nil, objects[math.random(1, #objects)]
	end

	return nil, nil
end

function pm.seek_player(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() and all[i]:get_hp() > 0 then
			objects[#objects+1] = all[i]
		end
	end

	if #objects > 0 then
		return nil, objects[math.random(1, #objects)]
	end

	return nil, nil
end

function pm.seek_node_with_meta(self, pos)
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

function pm.seek_wisp(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		local ent = all[i]:get_luaentity()
		if ent then
			if ent.mob and ent._name and ent._name == "pm:follower" then
				objects[#objects+1] = all[i]
			end
		end
	end

	if #objects > 0 then
		local wisp = objects[math.random(1, #objects)]
		local p = wisp:get_pos()
		p.y = p.y - 3 -- Keep communal wisps from following each other into the sky.
		return p, wisp
	end

	return nil, nil
end

function pm.seek_solitude(self, pos)
	local all = pm.get_nearby_objects(self, pos, pm.sight_range)

	-- Filter out anything that isn't a player or mob or dropped item.
	local objects = {}
	for i=1, #all, 1 do
		if all[i]:is_player() then
			objects[#objects+1] = all[i]
		else
			local ent = all[i]:get_luaentity()
			if ent then
				if ent.mob then
					objects[#objects+1] = all[i]
				end
			end
		end
	end

	if #objects > 0 then
		-- Calculate average center of the group.
		local center = {x=0, y=0, z=0}
		for k, v in ipairs(objects) do
			local p = v:get_pos()
			center.x = center.x + p.x
			center.y = center.y + p.y
			center.z = center.z + p.z
		end
		center.x = center.x / #objects
		center.y = center.y / #objects
		center.z = center.z / #objects

		-- Find/return position away from the center of the group.
		local dir = vector.subtract(pos, center)
		dir = vector.normalize(dir)
		dir = vector.multiply(dir, 10)
		local air = minetest.find_node_near(vector.add(pos, dir), 11, "air", true)

		-- Don't go flying when looking for solitude, stay near ground.
		if air then
			while minetest.get_node(vector.add(air, {x=0, y=-1, z=0})).name == "air" do
				air.y = air.y - 1
			end
		end

		return air, nil
	end

	return nil, nil
end


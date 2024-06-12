
function dungeon_loot.place_oerkki_stones(data)
	if not data or #data < 1 then
		return
	end

	-- 1/3 chance to spawn.
	if math.random(1, 3) <= 2 then
		return
	end

	-- Place a random number of stones.
	local count = math.random(1, 3)

	for k = 1, count do
		local pos = data[math.random(1, #data)]
		local minp = vector.offset(pos, -5, -5, -5)
		local maxp = vector.offset(pos, 5, 5, 5)
		local targets = minetest.find_nodes_in_area_under_air(minp, maxp, dungeon_loot.DUNGEON_NODES)

		if targets and #targets > 0 then
			local target = targets[math.random(1, #targets)]
			minetest.set_node(target, {name="griefer:grieferstone"})
		end
	end
end

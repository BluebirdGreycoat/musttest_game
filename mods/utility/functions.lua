
function utility.detach_player_with_message(player)
	local k = default.detach_player_if_attached(player)
	if k then
		local t = player:get_player_name()
		if k == "cart" then
			minetest.chat_send_all("# Server: Someone threw <" .. rename.gpn(t) .. "> out of a minecart.")
		elseif k == "boat" then
			minetest.chat_send_all("# Server: Boater <" .. rename.gpn(t) .. "> was tossed overboard.")
		elseif k == "sled" then
			minetest.chat_send_all("# Server: Someone kicked <" .. rename.gpn(t) .. "> off a sled.")
		elseif k == "bed" then
			minetest.chat_send_all("# Server: <" .. rename.gpn(t) .. "> was rudely kicked out of bed.")
		end
	end
end



-- Function to find an ignore node NOT beyond the world edge.
-- This is useful when we must check for `ignore`, but don't want to be confused at the edge of the world.
function utility.find_node_near_not_world_edge(pos, rad, node)
	local minp = vector.subtract(pos, rad)
	local maxp = vector.add(pos, rad)

	minp.x = math.max(minp.x, -30912)
	minp.y = math.max(minp.y, -30912)
	minp.z = math.max(minp.z, -30912)

	maxp.x = math.min(maxp.x, 30927)
	maxp.y = math.min(maxp.y, 30927)
	maxp.z = math.min(maxp.z, 30927)

	local positions = minetest.find_nodes_in_area(minp, maxp, node)

	if (#positions > 0) then
		return positions[math.random(1, #positions)]
	end
end

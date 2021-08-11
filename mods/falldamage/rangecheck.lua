
local DIST = vector.distance
local RANGE = 6 + DIST({x=0,y=0,z=0},{x=.5,y=.5,z=.5})
local OFFSET = function(v, y) return {x = v.x, y = v.y + y, z = v.z} end

function falldamage.apply_range_checks(def)
	if def.allow_metadata_inventory_move then
		local func = def.allow_metadata_inventory_move
		function def.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
			if DIST(pos, OFFSET(player:get_pos(), player:get_properties().eye_height)) > RANGE then
				return 0
			end
			afk_removal.reset_timeout(player:get_player_name())
			return func(pos, from_list, from_index, to_list, to_index, count, player)
		end
	elseif def.on_metadata_inventory_move then
		-- If no `allow' function defined, then define a default func.
		function def.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
			if DIST(pos, OFFSET(player:get_pos(), player:get_properties().eye_height)) > RANGE then
				return 0
			end
			afk_removal.reset_timeout(player:get_player_name())
			return count
		end
	end

	if def.allow_metadata_inventory_put then
		local func = def.allow_metadata_inventory_put
		function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
			if DIST(pos, OFFSET(player:get_pos(), player:get_properties().eye_height)) > RANGE then
				return 0
			end
			afk_removal.reset_timeout(player:get_player_name())
			return func(pos, listname, index, stack, player)
		end
	elseif def.on_metadata_inventory_put then
		-- If no `allow' function defined, then define a default func.
		function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
			if DIST(pos, OFFSET(player:get_pos(), player:get_properties().eye_height)) > RANGE then
				return 0
			end
			afk_removal.reset_timeout(player:get_player_name())
			return stack:get_count()
		end
	end

	if def.allow_metadata_inventory_take then
		local func = def.allow_metadata_inventory_take
		function def.allow_metadata_inventory_take(pos, listname, index, stack, player)
			if DIST(pos, OFFSET(player:get_pos(), player:get_properties().eye_height)) > RANGE then
				return 0
			end
			afk_removal.reset_timeout(player:get_player_name())
			return func(pos, listname, index, stack, player)
		end
	elseif def.on_metadata_inventory_take then
		-- If no `allow' function defined, then define a default func.
		function def.allow_metadata_inventory_take(pos, listname, index, stack, player)
			if DIST(pos, OFFSET(player:get_pos(), player:get_properties().eye_height)) > RANGE then
				return 0
			end
			afk_removal.reset_timeout(player:get_player_name())
			return stack:get_count()
		end
	end
end


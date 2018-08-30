
local RANGE = 6



function falldamage.apply_range_checks(def)
	if def.allow_metadata_inventory_move then
		local func = def.allow_metadata_inventory_move
		function def.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
			if vector.distance(pos, player:get_pos()) > RANGE then
				return 0
			end
			return func(pos, from_list, from_index, to_list, to_index, count, player)
		end
	elseif def.on_metadata_inventory_move then
		-- If no `allow' function defined, then define a default func.
		function def.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
			if vector.distance(pos, player:get_pos()) > RANGE then
				return 0
			end
			return count
		end
	end

	if def.allow_metadata_inventory_put then
		local func = def.allow_metadata_inventory_put
		function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
			if vector.distance(pos, player:get_pos()) > RANGE then
				return 0
			end
			return func(pos, listname, index, stack, player)
		end
	elseif def.on_metadata_inventory_put then
		-- If no `allow' function defined, then define a default func.
		function def.allow_metadata_inventory_put(pos, listname, index, stack, player)
			if vector.distance(pos, player:get_pos()) > RANGE then
				return 0
			end
			return stack:get_count()
		end
	end

	if def.allow_metadata_inventory_take then
		local func = def.allow_metadata_inventory_take
		function def.allow_metadata_inventory_take(pos, listname, index, stack, player)
			if vector.distance(pos, player:get_pos()) > RANGE then
				return 0
			end
			return func(pos, listname, index, stack, player)
		end
	elseif def.on_metadata_inventory_take then
		-- If no `allow' function defined, then define a default func.
		function def.allow_metadata_inventory_take(pos, listname, index, stack, player)
			if vector.distance(pos, player:get_pos()) > RANGE then
				return 0
			end
			return stack:get_count()
		end
	end
end


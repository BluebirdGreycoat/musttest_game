
function city_block.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
	return 0
end



function city_block.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function city_block.allow_metadata_inventory_put(pos, listname, index, stack, user)
	local pname = user:get_player_name()
	local context = city_block.formspecs[pname]

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not context then
		return 0
	end

	if listname == "config" and stack:get_name() == "cfg:dev" then
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local inv = meta:get_inventory()
		if inv:is_empty("config") and owner == pname then
			return 1
		end
	end

	return 0
end



function city_block.on_metadata_inventory_put(pos, listname, index, stack, user)
end



function city_block.allow_metadata_inventory_take(pos, listname, index, stack, user)
	local pname = user:get_player_name()
	local context = city_block.formspecs[pname]

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not context then
		return 0
	end

	if listname == "config" then
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if owner == pname then
			return stack:get_count()
		end
	end

	return 0
end



function city_block.on_metadata_inventory_take(pos, listname, index, stack, user)
end

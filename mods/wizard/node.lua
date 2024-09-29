
function wizard.on_construct(pos)
end



function wizard.on_destruct(pos)
end



function wizard.on_pre_fall(pos)
end



function wizard.on_blast(pos)
end



function wizard.on_collapse_to_entity(pos, node)
end



function wizard.on_finish_collapse(pos, node)
end



function wizard.on_rightclick(pos, node, user, itemstack, pt)
end



function wizard.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function wizard.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



function wizard.allow_metadata_inventory_put(pos, listname, index, stack, user)
end



function wizard.on_metadata_inventory_put(pos, listname, index, stack, user)
end



function wizard.allow_metadata_inventory_take(pos, listname, index, stack, user)
end



function wizard.on_metadata_inventory_take(pos, listname, index, stack, user)
end



function wizard.after_place_node(pos, user, itemstack, pt)
	--[[
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	if not gdac.player_is_admin(pname) then
		return
	end

	local meta = minetest.get_meta(pos)
	meta:set_int("down", 50)
	meta:set_int("up", 350)
	meta:mark_as_private({"down", "up"})

	local timer = minetest.get_node_timer(pos)
	timer:start(1)
	--]]
end



function wizard.on_punch(pos, node, user, pt)
end



function wizard.on_timer(pos, elapsed)
	--[[
	local meta = minetest.get_meta(pos)
	local under = vector.add(pos, {x=0, y=-1, z=0})
	local above = vector.add(pos, {x=0, y=1, z=0})

	local nodeunder = minetest.get_node(under)
	local nodeabove = minetest.get_node(above)

	if nodeunder.name == "ignore" or nodeabove.name == "ignore" then
		return true
	end

	if nodeunder.name ~= "air" and meta:get_int("down") > 0 then
		if nodeunder.name ~= "wizard:stone" then
			minetest.set_node(under, {name="wizard:stone"})
			local nmeta = minetest.get_meta(under)
			nmeta:set_int("down", meta:get_int("down") - 1)
			nmeta:mark_as_private("down")
			meta:set_string("down", "")
			local ntimer = minetest.get_node_timer(under)
			ntimer:start(1)
		end
	else
		meta:set_string("down", "")
	end

	if meta:get_int("up") > 0 then
		if nodeabove.name ~= "wizard:stone" then
			minetest.set_node(above, {name="wizard:stone"})
			local nmeta = minetest.get_meta(above)
			nmeta:set_int("up", meta:get_int("up") - 1)
			nmeta:mark_as_private("up")
			meta:set_string("up", "")
			local ntimer = minetest.get_node_timer(above)
			ntimer:start(1)
		end
	else
		meta:set_string("up", "")
	end
	--]]
end



function wizard.can_dig(pos, user)
end



function wizard.on_rotate(pos, node, user, mode, new_param2)
end

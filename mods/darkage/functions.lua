
function darkage.on_rightclick(pos, node, clicker, itemstack, pt)
	local pname = clicker:get_player_name()

	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local defgui = default.gui_bg .. default.gui_bg_img .. default.gui_slots

	local formspec = "size[8,7]" .. defgui ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,2;]" ..
		"list[current_player;main;0,2.85;8,1;]" ..
		"list[current_player;main;0,4.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0, 2.85)

	minetest.show_formspec(pname, "darkage:box", formspec)
	return itemstack
end

function darkage.on_player_receive_fields(player, formname, fields)
	if formname ~= "darkage:box" then
		return
	end

	return true
end

function darkage.on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "Open Storage")

	local inv = meta:get_inventory()
	inv:set_size("main", 16)
end

function darkage.after_place_node(pos, placer, itemstack, pt)
end

function darkage.can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:is_empty("main")
end

function darkage.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	return count
end

function darkage.allow_metadata_inventory_put(pos, listname, index, stack, player)
	return stack:get_count()
end

function darkage.allow_metadata_inventory_take(pos, listname, index, stack, player)
	return stack:get_count()
end

function darkage.on_blast(pos, intensity)
	local drops = {}
	default.get_inventory_drops(pos, "main", drops)
	drops[#drops+1] = minetest.get_node(pos).name
	minetest.remove_node(pos)
	return drops
end

function darkage.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local pname = player:get_player_name()
	minetest.log("action", pname .. " moves stuff in storage at " .. minetest.pos_to_string(pos))
end

function darkage.on_metadata_inventory_put(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	minetest.log("action", pname .. " moves " .. stack:get_name() .. " to storage at " .. minetest.pos_to_string(pos))
end

function darkage.on_metadata_inventory_take(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	minetest.log("action", pname .. " takes " .. stack:get_name() .. " from storage at " .. minetest.pos_to_string(pos))
end




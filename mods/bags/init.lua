--[[

Bags for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-bags
License: BSD-3-Clause https://raw.github.com/cornernote/minetest-bags/master/LICENSE

Edited by TenPlus1

]]--


local get_formspec = function(player, page)

	if page == "bags" then

		return "size[8,8.5]"
			..default.gui_bg..default.gui_bg_img..default.gui_slots
			.."list[current_player;main;0,4.25;8,1;]"
			.."list[current_player;main;0,5.5;8,3;8]"
			.."button[0,1;2,0.5;main;Back]"
			.."button[2.5,1;1.3,0.5;bag1;Bag 1]"
			.."button[2.5,2.2;1.3,0.5;bag2;Bag 2]"
			.."button[5.2,1;1.3,0.5;bag3;Bag 3]"
			.."button[5.2,2.2;1.3,0.5;bag4;Bag 4]"
			.."list[detached:"..player:get_player_name().."_bags;bag1;3.8,.8;1,1;]"
			.."list[detached:"..player:get_player_name().."_bags;bag2;3.8,2;1,1;]"
			.."list[detached:"..player:get_player_name().."_bags;bag3;6.5,.8;1,1;]"
			.."list[detached:"..player:get_player_name().."_bags;bag4;6.5,2;1,1;]"
			..default.get_hotbar_bg(0, 4.25)
	end

	for i = 1, 4 do

		if page == "bag" .. i then

			local image = player:get_inventory():get_stack("bag"
				.. i, 1):get_definition().inventory_image
--[[
			return "size[8,9.5]"
				..default.gui_bg..default.gui_bg_img..default.gui_slots
				.."list[current_player;main;0,5.5;8,4;]"
				.."button[6,0.2;2,0.5;main;Main]"
				.."button[4,0.2;2,0.5;bags;Bags]"
				.."image[0,0;1,1;" .. image .. "]"
				.."list[current_player;bag" .. i .. "contents;0,1;8,4;]"
--]]
			return "size[8,9.5]"
				.. default.gui_bg .. default.gui_bg_img .. default.gui_slots
				.. "list[current_player;bag" .. i .. "contents;0,0;8,4;]"
				.. "button[0,4.2.2;2,0.5;main;Main]"
				.. "label[2,4.2;" .. minetest.formspec_escape("Bag #" .. i .. "") .. "]"
				.. "button[6,4.2.2;2,0.5;bags;Bags]"
				.. "image[3.5,4;1,1;" .. image .. "]"
				.. "list[current_player;main;0,5.5;8,1;]"
				.. "list[current_player;main;0,6.75;8,3;8]"
				.. "listring[current_player;main]"
				.. "listring[current_player;bag" .. i .. "contents]"
				.. default.get_hotbar_bg(0, 5.5)
		end
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)

	if fields.bags then
		inventory_plus.set_inventory_formspec(player, get_formspec(player, "bags"))
		return
	end

	for i = 1, 4 do

		local page = "bag" .. i

		if fields[page] then
	
			if player:get_inventory():get_stack(page, 1):get_definition().groups.bagslots == nil then
				page = "bags"
			end
	
			inventory_plus.set_inventory_formspec(player, get_formspec(player, page))
	
			return
		end
	end
end)

minetest.register_on_joinplayer(function(player)

	local player_inv = player:get_inventory()
	local bags_inv = minetest.create_detached_inventory(player:get_player_name().."_bags",{

		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, stack)
			player:get_inventory():set_size(listname.."contents", stack:get_definition().groups.bagslots)
		end,

		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, nil)
		end,

		allow_put = function(inv, listname, index, stack, player)
			if stack:get_definition().groups.bagslots then
				return 1
			else
				return 0
			end
		end,

		allow_take = function(inv, listname, index, stack, player)
			if player:get_inventory():is_empty(listname .. "contents") == true then
				return stack:get_count()
			else
				return 0
			end
		end,

		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return 0
		end,
	}, player:get_player_name())

	for i = 1, 4 do
		local bag = "bag" .. i

		player_inv:set_size(bag, 1)
		bags_inv:set_size(bag, 1)
		bags_inv:set_stack(bag, 1, player_inv:get_stack(bag, 1))
	end
end)

-- register bags items

minetest.register_craftitem("bags:small", {
	description = "Small Bag",
	inventory_image = "bags_small.png",
	groups = {bagslots = 8},
})

minetest.register_craftitem("bags:medium", {
	description = "Medium Bag",
	inventory_image = "bags_medium.png",
	groups = {bagslots = 16},
})

minetest.register_craftitem("bags:large", {
	description = "Large Bag",
	inventory_image = "bags_large.png",
	groups = {bagslots = 24},
})

minetest.register_tool("bags:trolley", {
	description = "Trolley",
	inventory_image = "bags_trolley.png",
	groups = {bagslots = 32},
})

-- register bag crafts

minetest.register_craft({
	output = "bags:small",
	recipe = {
		{"farming:string", "group:stick", "farming:string"},
		{"group:leather", "group:leather", "group:leather"},
		{"group:leather", "group:leather", "group:leather"},
	},
})

minetest.register_craft({
	output = "bags:medium",
	recipe = {
		{"farming:string", "group:stick", "farming:string"},
		{"bags:small", "bags:small", "bags:small"},
	},
})

minetest.register_craft({
	output = "bags:large",
	recipe = {
		{"farming:string", "group:stick", "farming:string"},
		{"bags:medium", "bags:medium", "bags:medium"},
	},
})

minetest.register_craft({
	output = "bags:trolley",
	recipe = {
		{"", "group:stick", ""},
		{"bags:large", "bags:large", "bags:large"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})

-- Register button once.
inventory_plus.register_button("bags", "Bags")

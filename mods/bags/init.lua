--[[

Bags for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-bags
License: BSD-3-Clause https://raw.github.com/cornernote/minetest-bags/master/LICENSE

Edited by TenPlus1

]]--

if not minetest.global_exists("bags") then bags = {} end
bags.modpath = minetest.get_modpath("bags")



function bags.get_formspec(player, page)

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
			local by = 5.05
			local bx = 5.37
			local bw = 0.57
			local bh = 0.41

			return "size[8,9.5]"
				.. default.gui_bg .. default.gui_bg_img .. default.gui_slots
				.. "list[current_player;bag" .. i .. "contents;0,0;8,4;]"
				.. "button[0,4.2.2;2,0.5;main;Main]"
				.. "label[2,4.2;" .. minetest.formspec_escape("Bag #" .. i .. "") .. "]"
				.. "button[6,4.2;2,0.5;bags;Bags]"
				.. "image[3,4;1,1;" .. image .. "]"

				.. "real_coordinates[true]"
				.. "button[" .. bx + bw * 0 .. "," .. by .. ";" .. bw .. "," .. bh .. ";bag1;1]"
				.. "button[" .. bx + bw * 1 .. "," .. by .. ";" .. bw .. "," .. bh .. ";bag2;2]"
				.. "button[" .. bx + bw * 2 .. "," .. by .. ";" .. bw .. "," .. bh .. ";bag3;3]"
				.. "button[" .. bx + bw * 3 .. "," .. by .. ";" .. bw .. "," .. bh .. ";bag4;4]"
				.. "button[" .. bx + bw * 0 .. "," .. by + bh .. ";" .. bw * 2 .. "," .. bh .. ";bagdrop" .. i .. ";Chuck]"
				.. "button[" .. bx + bw * 2 .. "," .. by + bh .. ";" .. bw * 2 .. "," .. bh .. ";baggrab" .. i .. ";Snatch]"
				.. "real_coordinates[false]"

				.. "list[current_player;main;0,5.5;8,1;]"
				.. "list[current_player;main;0,6.75;8,3;8]"
				.. "listring[current_player;main]"
				.. "listring[current_player;bag" .. i .. "contents]"
				.. default.get_hotbar_bg(0, 5.5)
		end
	end
end



function bags.get_chest(player)
	local lookdir = player:get_look_dir()
	local eyeheight = player:get_properties().eye_height
	local eye = vector.add(player:get_pos(), {x=0, y=eyeheight, z=0})
	local sop = vector.add(eye, vector.multiply(lookdir, 5))
	local ray = Raycast(eye, sop, false, false)

	local pos, protected
	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			if minetest.get_item_group(node.name, "chest") ~= 0 then
				local trypos = pointed_thing.under
				local nodename = minetest.get_node(trypos).name
				local nodemeta = minetest.get_meta(trypos)
				local nodedef = minetest.registered_nodes[nodename] or {}

				-- Check if it's really registered as a chest with the chest API.
				if nodedef._chest_basename then
					if nodedef.protected then
						-- Chest is protected.
						if chest_api.has_locked_chest_privilege(trypos, nodename, nodemeta, player) then
							pos = trypos
							protected = true
							break
						end
					else
						-- Chest not protected, no access check.
						pos = trypos
						break
					end
				end
			end
		end
	end

	return pos, protected
end



function bags.drop_items(player, bagnum)
	local bag = "bag" .. bagnum .. "contents"
	local inv = player:get_inventory()
	if not inv then return end
	if inv:get_size(bag) <= 0 then return end

	local pos, protected = bags.get_chest(player)
	if not pos then return end

	local meta = minetest.get_meta(pos)
	local inv2 = meta:get_inventory()
	if not inv2 then return end
	if inv2:get_size("main") <= 0 then return end

	local size = inv:get_size(bag)
	local count = 0

	for k = 1, size, 1 do
		local stack = inv:get_stack(bag, k)
		count = count + stack:get_count()
		stack = inv2:add_item("main", stack)
		count = count - stack:get_count()
		inv:set_stack(bag, k, stack)
	end

	return pos, count, protected
end



function bags.grab_items(player, bagnum)
	local bag = "bag" .. bagnum .. "contents"
	local inv = player:get_inventory()
	if not inv then return end
	if inv:get_size(bag) <= 0 then return end

	local pos, protected = bags.get_chest(player)
	if not pos then return end

	local meta = minetest.get_meta(pos)
	local inv2 = meta:get_inventory()
	if not inv2 then return end
	if inv2:get_size("main") <= 0 then return end

	local size = inv2:get_size("main")
	local count = 0

	for k = 1, size, 1 do
		local stack = inv2:get_stack("main", k)
		count = count + stack:get_count()
		stack = inv:add_item(bag, stack)
		count = count - stack:get_count()
		inv2:set_stack("main", k, stack)
	end

	return pos, count, protected
end



function bags.receive_fields(player, formname, fields)
	if fields.bags then
		inventory_plus.set_inventory_formspec(player, bags.get_formspec(player, "bags"))
		return
	end

	local pname = player:get_player_name()

	for i = 1, 4 do
		local page = "bag" .. i
		local drop = "bagdrop" .. i
		local grab = "baggrab" .. i

		if fields[page] then
			if player:get_inventory():get_stack(page, 1):get_definition().groups.bagslots == nil then
				page = "bags"
			end

			inventory_plus.set_inventory_formspec(player, bags.get_formspec(player, page))

			return
		end

		if fields[drop] then
			local target, count, protected = bags.drop_items(player, i)
			if target then
				local protstr = ""
				if protected then protstr = "protected " end
				minetest.chat_send_player(pname, "# Server: Bag #" .. i .. ": " .. count .. " items chucked into " .. protstr .. "chest at " .. rc.pos_to_namestr(target) .. ".")
				if count > 0 then
					easyvend.sound_vend(player:get_pos())
				end
			else
				easyvend.sound_error(pname)
			end
			return
		end

		if fields[grab] then
			local target, count, protected = bags.grab_items(player, i)
			if target then
				local protstr = ""
				if protected then protstr = "protected " end
				minetest.chat_send_player(pname, "# Server: Bag #" .. i .. ": " .. count .. " items snatched from " .. protstr .. "chest at " .. rc.pos_to_namestr(target) .. ".")
				if count > 0 then
					easyvend.sound_vend(player:get_pos())
				end
			else
				easyvend.sound_error(pname)
			end
			return
		end
	end
end



if not bags.loaded then
	local c = "bags:core"
	local f = bags.modpath .. "/init.lua"
	reload.register_file(c, f, false)
	bags.loaded = true

	minetest.register_on_player_receive_fields(function(...)
		return bags.receive_fields(...) end)

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
end

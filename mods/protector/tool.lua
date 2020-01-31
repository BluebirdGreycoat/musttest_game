
-- protector placement tool (thanks to Shara for code and idea)

local get_public_time = function()
  return os.date("!%Y/%m/%d UTC")
end

minetest.register_craftitem("protector:tool", {
	description = "Protector Placer Tool\n\nStand near protector, face direction and use.\nHold sneak to copy member names.\nHold 'E' to double the gap distance.",
	inventory_image = "nodeinspector.png^protector_lock.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)

		local name = user:get_player_name()

		-- check for protector near player (2 block radius)
		local pos = vector.round(user:get_pos())
		local pp = minetest.find_nodes_in_area(
			vector.subtract(pos, 2), vector.add(pos, 2),
			{"protector:protect", "protector:protect2",
       "protector:protect3", "protector:protect4"})

		if #pp == 0 then return end -- none found

		pos = pp[1] -- take position of first protector found

		-- get type of protector, its radius and size class
		local r -- Protector radius
		local s -- Small protector: true, else false
		local node = minetest.get_node(pos)
		local protname
		if node.name == "protector:protect" or node.name == "protector:protect2" then
			r = protector.radius
			s = false
			protname = node.name
		elseif node.name == "protector:protect3" or node.name == "protector:protect4" then
			r = protector.radius_small
			s = true
			protname = node.name
		else
			minetest.chat_send_player(name, "# Server: PPT internal error!")
			return
		end

		-- get members on protector
		local meta = minetest.get_meta(pos)
		local members = meta:get_string("members") or ""

		-- get direction player is facing
		local dir = minetest.dir_to_facedir( user:get_look_dir() )
		local vec = {x = 0, y = 0, z = 0}
		local gap = (r * 2) + 1
		local pit =  user:get_look_vertical()

		-- double the gap distance if player is holding 'E'
		if user:get_player_control().aux1 then
			gap = gap * 2
		end

		-- set placement coords
		if pit > 1.2 then
			vec.y = -gap -- up
		elseif pit < -1.2 then
			vec.y = gap -- down
		elseif dir == 0 then
			vec.z = gap -- north
		elseif dir == 1 then
			vec.x = gap -- east
		elseif dir == 2 then
			vec.z = -gap -- south
		elseif dir == 3 then
			vec.x = -gap -- west
		end

		-- new position
		pos.x = pos.x + vec.x
		pos.y = pos.y + vec.y
		pos.z = pos.z + vec.z

		-- ensure position is within a valid realm
		if not rc.is_valid_realm_pos(pos) then
			minetest.chat_send_player(name, "# Server: Cannot place protector in the Void!")
			return
		end
		if not minetest.get_node_or_nil(pos) then
			minetest.chat_send_player(name, "# Server: Cannot place protector within IGNORE!")
			return
		end

		-- does placing a protector overlap existing area
		-- this is the most important check! must not mess this up!
		local success, reason = protector.check_overlap_main(protname, name, pos)
		if not success then
			if reason == 1 then
				minetest.chat_send_player(name, "# Server: Protection bounds overlap into another person's area claim.")
			elseif reason == 2 then
				minetest.chat_send_player(name, "# Server: You cannot claim this area while someone's fresh corpse is nearby!")
			elseif reason == 3 then
				minetest.chat_send_player(name, "# Server: You must remove all corpses before you can claim this area.")
			else
				minetest.chat_send_player(name, "# Server: Cannot place protection for unknown reason.")
			end
			return
		end

		-- does a protector already exist ?
		if #minetest.find_nodes_in_area(vector.subtract(pos, 1), vector.add(pos, 1),
				{"protector:protect", "protector:protect2", "protector:protect3", "protector:protect4"}) > 0 then
			minetest.chat_send_player(name, "# Server: Protector already in place!")
			return
		end

		-- do not replace containers with inventory space
		if minetest.get_inventory({type = "node", pos = pos}) then
			minetest.chat_send_player(name, "# Server: Cannot place protector, container at " .. rc.pos_to_namestr(pos) .. ".")
			return
		end

		-- protection check for other stuff, like bedrock, etc
		if minetest.is_protected(pos, name) then
			minetest.chat_send_player(name, "Cannot place protector, already protected at " .. rc.pos_to_namestr(pos) .. ".")
			return
		end

		-- check not replacing an immovable object
		local node = minetest.get_node(pos)
		if minetest.get_item_group(node.name, "immovable") ~= 0 then
			minetest.chat_send_player(name, "# Server: Cannot place protector in place of immovable object!")
			return
		end

		local nod
		local inv = user:get_inventory()

		-- try to take protector from player inventory (block first then logo)
		if s then
			if inv:contains_item("main", "protector:protect3") then
				inv:remove_item("main", "protector:protect3")
				nod = "protector:protect3"
			elseif inv:contains_item("main", "protector:protect4") then
				inv:remove_item("main", "protector:protect4")
				nod = "protector:protect4"
			end
		else
			if inv:contains_item("main", "protector:protect") then
				inv:remove_item("main", "protector:protect")
				nod = "protector:protect"
			elseif inv:contains_item("main", "protector:protect2") then
				inv:remove_item("main", "protector:protect2")
				nod = "protector:protect2"
			end
		end

		-- did we get a protector to use ?
		if not nod then
			minetest.chat_send_player(name, "# Server: No protectors available to place!")
			return
		end

		-- place protector
		minetest.set_node(pos, {name = nod, param2 = 1})

		-- set protector metadata
		local meta = minetest.get_meta(pos)
		local dname = rename.gpn(name)
		local placedate = get_public_time()

		meta:set_string("placedate", placedate)
		meta:set_string("owner", name)
		meta:set_string("rename", dname)
		meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)\nPlaced on " .. placedate)

		-- copy members across if holding sneak when using tool
		local members_copied = false
		if user:get_player_control().sneak then
			meta:set_string("members", members)
			members_copied = true
		else
			meta:set_string("members", "")
		end

		-- Notify nearby players.
		protector.update_nearby_players(pos)

		ambiance.sound_play(electric_screwdriver.sound, pos, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)

		if members_copied then
			minetest.chat_send_player(name, "# Server: Protector placed at " .. rc.pos_to_namestr(pos) .. ". Members copied.")
		else
			minetest.chat_send_player(name, "# Server: Protector placed at " .. rc.pos_to_namestr(pos) .. ".")
		end
	end,
})

-- tool recipe
minetest.register_craft({
	output = "protector:tool",
	recipe = {
		{"protector:protect4"},
		{"nodeinspector:nodeinspector"},
	}
})

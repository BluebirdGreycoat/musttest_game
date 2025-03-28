
-- protector placement tool (thanks to Shara for code and idea)

-- Localize for performance.
local vector_round = vector.round

local get_public_time = function()
	return os.date("!%Y/%m/%d UTC")
end

local function pos_has_inventory(pos)
	local meta = minetest.get_meta(pos)
	local inv = minetest.get_inventory({type = "node", pos = pos})
	if not inv then
		return false
	end

	local lists = inv:get_lists()

	if next(lists) == nil then
		return false
	end

	return true
end

minetest.register_craftitem("protector:tool", {
	description = "Claim Expansion Tool\n\nStand near protector, face direction and use.\nHold sneak to copy member names.\nHold 'E' to double the gap distance.",
	inventory_image = "nodeinspector.png^protector_lock.png",
	stack_max = 1,
	groups = {not_repaired_by_anvil=1},

	on_use = function(itemstack, user, pointed_thing)

		local name = user:get_player_name()

		-- check for protector near player (2 block radius)
		local pos = vector_round(user:get_pos())
		local pp = minetest.find_nodes_in_area(
			vector.subtract(pos, 2), vector.add(pos, 2),
			{"protector:protect", "protector:protect2",
			"protector:protect3", "protector:protect4"})

		if #pp == 0 then return end -- none found

		if #pp > 1 then
			minetest.chat_send_player(name, "# Server: Too many protectors nearby, choice would be ambiguous.")
			return
		end

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
		local owner = meta:get_string("owner") or ""

		-- require the tool user to be the owner of the initial protector node
		if owner ~= name then
			minetest.chat_send_player(name, "# Server: Cannot expand claim from origin, the protector is not yours!")
			return
		end

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

		-- Does location already have a protector?
		if minetest.get_node(pos).name:find("^protector:protect") then
			minetest.chat_send_player(name, "# Server: Protector already in place!")
			prospector.ptool_mark_single(name, pos, "Protector")
			return
		end

		-- does a protector already exist nearby?
		local nearby_protectors = minetest.find_nodes_in_area(vector.subtract(pos, 1), vector.add(pos, 1),
			{"protector:protect", "protector:protect2", "protector:protect3", "protector:protect4"})
		if #nearby_protectors > 0 then
			minetest.chat_send_player(name, "# Server: Protector already near target!")
			for k, v in ipairs(nearby_protectors) do
				prospector.ptool_mark_single(name, v, "Protector")
			end
			return
		end

		-- do not replace containers with inventory space.
		if pos_has_inventory(pos) then
			minetest.chat_send_player(name, "# Server: Cannot place protector, container at " .. rc.pos_to_namestr(pos) .. ".")
			prospector.ptool_mark_single(name, pos, "Blockage")
			return
		end

		-- protection check for other stuff, like bedrock, etc
		if minetest.is_protected(pos, name) then
			minetest.chat_send_player(name, "Cannot place protector, already protected at " .. rc.pos_to_namestr(pos) .. ".")
			prospector.ptool_mark_single(name, pos, "Blockage")
			return
		end

		-- check not replacing an immovable object
		local node = minetest.get_node(pos)
		if minetest.get_item_group(node.name, "immovable") ~= 0
		   or minetest.get_item_group(node.name, "unbreakable") ~= 0
		then
			minetest.chat_send_player(name, "# Server: Cannot place protector in place of immovable object!")
			prospector.ptool_mark_single(name, pos, "Blockage")
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
			if s then
				minetest.chat_send_player(name, "# Server: No basic protectors available to place!")
			else
				minetest.chat_send_player(name, "# Server: No advanced protectors available to place!")
			end
			return
		end

		-- place protector
		minetest.set_node(pos, {name = nod, param2 = 1})

		-- We are going to execute callbacks.
		local protdef = minetest.registered_nodes[nod]

		if protdef.on_construct then
			protdef.on_construct(pos)
		end
		if protdef.after_place_node then
			-- Assume callback only requires 'pos' and 'user'.
			protdef.after_place_node(pos, user)
		end

		-- Copy members across if holding sneak when using tool.
		local members_copied = false
		if user:get_player_control().sneak then
			local meta = minetest.get_meta(pos)
			meta:set_string("members", members)
			members_copied = true
		else
			local meta = minetest.get_meta(pos)
			meta:set_string("members", "")
		end

		ambiance.sound_play(electric_screwdriver.sound, pos, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)

		if members_copied and not s then
			minetest.chat_send_player(name, "# Server: Protector placed at " .. rc.pos_to_namestr(pos) .. ". Members copied.")
			prospector.ptool_mark_single(name, pos, "Success")
		else
			minetest.chat_send_player(name, "# Server: Protector placed at " .. rc.pos_to_namestr(pos) .. ".")
			prospector.ptool_mark_single(name, pos, "Success")
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



-- This tool is useful if you just want to move a protector without resetting
-- some of its meta, e.g., placement date.
minetest.register_craftitem("protector:tool2", {
	description = "Protector Mover Tool\n\nStand near protector, face direction and use.",
	inventory_image = "nodeinspector.png^protector_lock.png",
	stack_max = 1,
	groups = {not_repaired_by_anvil=1},

	on_use = function(itemstack, user, pointed_thing)

		local name = user:get_player_name()

		-- check for protector near player (2 block radius)
		local pos = vector_round(user:get_pos())
		local pp = minetest.find_nodes_in_area(
			vector.subtract(pos, 2), vector.add(pos, 2),
			{"protector:protect", "protector:protect2",
			"protector:protect3", "protector:protect4"})

		if #pp == 0 then return end -- none found

		if #pp > 1 then
			minetest.chat_send_player(name, "# Server: Too many protectors nearby, choice would be ambiguous.")
			return
		end

		pos = pp[1] -- take position of first protector found

		-- get members on protector
		local meta = minetest.get_meta(pos)
		local members = meta:get_string("members") or ""
		local owner = meta:get_string("owner") or ""
		local placedate = meta:get_string("placedate") or ""
		local protname = minetest.get_node(pos).name

		-- require the tool user to be the owner of the initial protector node
		if not minetest.check_player_privs(name, {protection_bypass=true}) then
			if owner ~= name then
				minetest.chat_send_player(name, "# Server: Cannot expand claim from origin, the protector is not yours!")
				return
			end
		end

		-- get direction player is facing
		local dir = minetest.dir_to_facedir( user:get_look_dir() )
		local vec = {x = 0, y = 0, z = 0}
		local gap = 1
		local pit = user:get_look_vertical()

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

		-- new position (save old position)
		local oldpos = {x=pos.x, y=pos.y, z=pos.z}
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
		local success, reason = protector.check_overlap_main(protname, owner, pos)
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
		if #minetest.find_nodes_in_area(vector.subtract(pos, 0), vector.add(pos, 0),
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
		if minetest.is_protected(pos, owner) then
			minetest.chat_send_player(name, "Cannot place protector, already protected at " .. rc.pos_to_namestr(pos) .. ".")
			return
		end

		-- check not replacing an immovable object
		local node = minetest.get_node(pos)
		if minetest.get_item_group(node.name, "immovable") ~= 0 then
			minetest.chat_send_player(name, "# Server: Cannot place protector in place of immovable object!")
			return
		end

		local nod = minetest.get_node(oldpos).name

		-- place protector
		minetest.set_node(pos, {name = nod, param2 = 1})
		minetest.remove_node(oldpos)

		-- We are going to execute callbacks.
		local protdef = minetest.registered_nodes[nod]

		if protdef.on_construct then
			protdef.on_construct(pos)
		end
		if protdef.after_place_node then
			-- Assume callback only requires 'pos' and 'user'.
			protdef.after_place_node(pos, user)
		end

		-- set protector metadata
		local meta = minetest.get_meta(pos)
		local dname = rename.gpn(owner)

		-- Restore original placement date and members list.
		meta:set_string("placedate", placedate)
		meta:set_string("members", members)

		ambiance.sound_play(electric_screwdriver.sound, pos, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)
		minetest.chat_send_player(name, "# Server: Protector moved to " .. rc.pos_to_namestr(pos) .. ".")
	end,
})

-- tool recipe
minetest.register_craft({
	output = "protector:tool2",
	recipe = {
		{"nodeinspector:nodeinspector"},
		{"protector:protect4"},
	}
})

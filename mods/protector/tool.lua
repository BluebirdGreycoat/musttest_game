
-- protector placement tool (thanks to Shara for code and idea)
-- Customized for EnyekalaMT by MustTest.

local get_public_time = function()
	-- Warning: never change this format!
	-- It gets parsed by other code to get a timestamp.
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

-- Chose protector to place at 'pos' (using the protector placer tool).
local function choose_protector(pos, user, small)
	local inv = user:get_inventory()

	local function contains(name)
		return inv:contains_item("main", name)
	end
	local function remove(name)
		inv:remove_item("main", name)
	end

	local solid = true
	local protectors = {
		--[[ Small prots ]] [true] = {[true]="protector:protect3", [false]="protector:protect4"},
		--[[ Big prots   ]] [false] = {[true]="protector:protect", [false]="protector:protect2"},
	}

	-- Determine whether to try placing a solid or logo protector,
	-- based on how much air is around the placement location.
	local minp = vector.subtract(pos, 1)
	local maxp = vector.add(pos, 1)
	local airnodes = minetest.find_nodes_in_area(minp, maxp, "air")
	if airnodes and #airnodes > math.floor((3*3*3-1)/3*2) then -- 2/3rds total volume is air
		solid = false
	end

	-- Try to remove protector from inventory.
	-- First one type, then the other. (Small is fixed, but solid can be toggled.)
	if contains(protectors[small][solid]) then
		remove(protectors[small][solid])
		return protectors[small][solid]
	end
	solid = not solid
	if contains(protectors[small][solid]) then
		remove(protectors[small][solid])
		return protectors[small][solid]
	end
end



-- If exactly 1 protector display entity is found in a radius, return its position.
-- Else, return original pos.
local function find_protector_by_entity(pos)
	local radius = 7
	local objs = minetest.get_objects_inside_radius(pos, radius)
	local displayents = {}

	for _, obj in ipairs(objs) do
		local entity = obj:get_luaentity()
		if entity and entity.name then
			local n = entity.name
			if n == "protector:display" or n == "protector:display_small" then
				displayents[#displayents + 1] = entity
			end
		end
	end

	if #displayents == 1 then
		return vector.round(displayents[1].object:get_pos())
	end
	return pos
end



-- Claim EXPANSION tool.
function protector.on_use_tool(itemstack, user, pointed_thing)
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	local function response(message)
		minetest.chat_send_player(pname, "# Server: " .. message)
	end

	-- check for protector near player (2 block radius)
	-- If there's exactly 1 display entity in the area, use that position instead.
	local pos = vector.round(user:get_pos())
	pos = find_protector_by_entity(pos)

	local pp = minetest.find_nodes_in_area(
		vector.subtract(pos, 2), vector.add(pos, 2),
		{"protector:protect", "protector:protect2",
		"protector:protect3", "protector:protect4"})

	if #pp == 0 then return end -- none found

	if #pp > 1 then
		response("Too many protectors nearby, choice would be ambiguous.")
		return
	end

	pos = pp[1] -- take position of first protector found

	-- get type of protector, its radius and size class
	local radius_prot -- Protector radius
	local small_prot -- Small protector: true, else false
	local node = minetest.get_node(pos)
	local protname

	if node.name == "protector:protect" or node.name == "protector:protect2" then
		radius_prot = protector.radius
		small_prot = false
		protname = node.name
	elseif node.name == "protector:protect3" or node.name == "protector:protect4" then
		radius_prot = protector.radius_small
		small_prot = true
		protname = node.name
	else
		response("PPT internal error!")
		return
	end

	-- get members on protector
	local meta = minetest.get_meta(pos)
	local oldmeta = meta:to_table()
	local owner = meta:get_string("owner")

	-- require the tool user to be the owner of the initial protector node
	if not minetest.check_player_privs(pname, {protection_bypass=true}) then
		if owner ~= pname then
			response("Cannot expand claim from origin, the protector is not yours!")
			return
		end
	end

	-- double the gap distance if player is holding 'E'
	local gap = (radius_prot * 2) + 1
	if user:get_player_control().aux1 then
		gap = gap * 2
	end

	-- get location to place protector
	local dir = minetest.facedir_to_dir(minetest.dir_to_facedir(user:get_look_dir(), true))
	local vec = vector.multiply(dir, gap)

	-- new position
	pos.x = pos.x + vec.x
	pos.y = pos.y + vec.y
	pos.z = pos.z + vec.z

	-- ensure position is within a valid realm
	if not rc.is_valid_realm_pos(pos) then
		response("Cannot place protector in the Void!")
		return
	end
	if not minetest.get_node_or_nil(pos) then
		response("Cannot place protector within IGNORE!")
		return
	end

	-- does placing a protector overlap existing area
	-- this is the most important check! must not mess this up!
	local success, reason, message = protector.check_overlap_main(protname, owner, pos)
	if not success then
		if reason == 1 then
			response("Protection bounds overlap into another person's area claim.")
		elseif reason == 2 then
			response("You cannot claim this area while someone's fresh corpse is nearby!")
		elseif reason == 3 then
			response("You must remove all corpses before you can claim this area.")
		else
			response("Cannot place protection. System says: " .. message)
		end
		return
	end

	-- Does location already have a protector?
	if minetest.get_node(pos).name:find("^protector:protect") then
		response("Protector already in place!")
		prospector.ptool_mark_single(pname, pos, "Protector")
		return
	end

	-- does a protector already exist nearby?
	local nearby_protectors = minetest.find_nodes_in_area(vector.subtract(pos, 1), vector.add(pos, 1),
		{"protector:protect", "protector:protect2", "protector:protect3", "protector:protect4"})
	if #nearby_protectors > 0 then
		response("Protector already near target!")
		for k, v in ipairs(nearby_protectors) do
			prospector.ptool_mark_single(pname, v, "Protector")
		end
		return
	end

	-- do not replace containers with inventory space.
	if pos_has_inventory(pos) then
		response("Cannot place protector, container at " .. rc.pos_to_namestr_ex(pos) .. ".")
		prospector.ptool_mark_single(pname, pos, "Blockage")
		return
	end

	-- protection check for other stuff, like bedrock, etc
	if minetest.is_protected(pos, pname) then
		response("Cannot place protector, already protected at " .. rc.pos_to_namestr_ex(pos) .. ".")
		prospector.ptool_mark_single(pname, pos, "Blockage")
		return
	end

	-- check not replacing an immovable object
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "immovable") ~= 0 or minetest.get_item_group(node.name, "unbreakable") ~= 0
	then
		response("Cannot place protector in place of immovable object!")
		prospector.ptool_mark_single(pname, pos, "Blockage")
		return
	end

	-- did we get a protector to use?
	-- check this before we dig the target location.
	local nod = choose_protector(pos, user, small_prot)
	if not nod then
		response("No protectors available to place!")
		return
	end

	-- check node digs successfully, run all side effects and callbacks.
	-- note: 'dig_node' returns false if position is air.
	local dig_successful = minetest.dig_node(pos, user)
	if node.name ~= "air" and not dig_successful then
		response("Could not dig node to place protector.")
		prospector.ptool_mark_single(pname, pos, "Blockage")
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

	-- Set up meta. The 'after_place_node' callback added the protector as if the
	-- tool user placed it. We need to fix owner name in case the tool user is admin.
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", oldmeta.fields.owner)
	meta:set_string("rename", rename.gpn(oldmeta.fields.owner))

	-- Copy members across if holding sneak when using tool.
	local members_copied = false
	if user:get_player_control().sneak then
		meta:set_string("members", oldmeta.fields.members)
		meta:set_string("area_name", oldmeta.fields.area_name)
		members_copied = true
	end

	-- Update infotext. (Needed after restoring meta.)
	protector.update_infotext(meta)

	ambiance.sound_play(electric_screwdriver.sound, pos, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)

	if members_copied and not small_prot then
		response("Protector placed at " .. rc.pos_to_namestr_ex(pos) .. ". Members copied.")
		prospector.ptool_mark_single(pname, pos, "Success")
	else
		response("Protector placed at " .. rc.pos_to_namestr_ex(pos) .. ".")
		prospector.ptool_mark_single(pname, pos, "Success")
	end
end



-- Protector MOVER tool.
function protector.on_use_tool2(itemstack, user, pointed_thing)
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	local function response(message)
		minetest.chat_send_player(pname, "# Server: " .. message)
	end

	-- check for protector near player (2 block radius)
	local pos = vector.round(user:get_pos())
	local pp = minetest.find_nodes_in_area(
		vector.subtract(pos, 2), vector.add(pos, 2),
		{"protector:protect", "protector:protect2",
		"protector:protect3", "protector:protect4"})

	if #pp == 0 then return end -- none found

	if #pp > 1 then
		response("Too many protectors nearby, choice would be ambiguous.")
		return
	end

	pos = pp[1] -- take position of first protector found

	local meta = minetest.get_meta(pos)
	local oldmeta = meta:to_table()
	local owner = meta:get_string("owner")
	local numtimes = meta:get_int("moved")
	local protname = minetest.get_node(pos).name

	-- require the tool user to be the owner of the initial protector node
	if not minetest.check_player_privs(pname, {protection_bypass=true}) then
		if owner ~= pname then
			response("Cannot move protector, the protector is not yours!")
			return
		end
	end

	-- get location to move protector
	local gap = 1
	local dir = minetest.facedir_to_dir(minetest.dir_to_facedir(user:get_look_dir(), true))
	local vec = vector.multiply(dir, gap)

	-- new position (save old position)
	local oldpos = {x=pos.x, y=pos.y, z=pos.z}
	pos.x = pos.x + vec.x
	pos.y = pos.y + vec.y
	pos.z = pos.z + vec.z

	-- ensure position is within a valid realm
	if not rc.is_valid_realm_pos(pos) then
		response("Cannot place protector in the Void!")
		return
	end
	if not minetest.get_node_or_nil(pos) then
		response("Cannot place protector within IGNORE!")
		return
	end

	-- does placing a protector overlap existing area
	-- this is the most important check! must not mess this up!
	local success, reason, message = protector.check_overlap_main(protname, owner, pos)
	if not success then
		if reason == 1 then
			response("Protection bounds overlap into another person's area claim.")
		elseif reason == 2 then
			response("You cannot claim this area while someone's fresh corpse is nearby!")
		elseif reason == 3 then
			response("You must remove all corpses before you can claim this area.")
		else
			response("Cannot place protection. System says: " .. message)
		end
		return
	end

	-- does a protector already exist ?
	if #minetest.find_nodes_in_area(vector.subtract(pos, 0), vector.add(pos, 0),
			{"protector:protect", "protector:protect2", "protector:protect3", "protector:protect4"}) > 0 then
		response("Protector already in place!")
		return
	end

	-- do not replace containers with inventory space
	if pos_has_inventory(pos) then
		response("Cannot place protector, container at " .. rc.pos_to_namestr_ex(pos) .. ".")
		return
	end

	-- protection check for other stuff, like bedrock, etc
	if minetest.is_protected(pos, owner) then
		response("Cannot place protector, already protected at " .. rc.pos_to_namestr_ex(pos) .. ".")
		return
	end

	-- check not replacing an immovable object
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "immovable") ~= 0 then
		response("Cannot place protector in place of immovable object!")
		return
	end

	-- check node digs successfully, run all side effects and callbacks.
	-- note: 'dig_node' returns false if position is air.
	local dig_successful = minetest.dig_node(pos, user)
	if node.name ~= "air" and not dig_successful then
		response("Could not dig node to move protector.")
		return
	end

	-- If a display entity is active, remove it and keep track.
	-- Then we can activate a display entity after moving the protector.
	local displayent_visible = protector.remove_area_display(oldpos)

	-- place protector
	local nodename = minetest.get_node(oldpos).name
	minetest.set_node(pos, {name = nodename, param2 = 1})
	minetest.remove_node(oldpos)

	-- We are going to execute callbacks.
	local protdef = minetest.registered_nodes[nodename]
	if protdef.on_construct then
		protdef.on_construct(pos)
	end
	if protdef.after_place_node then
		-- Assume callback only requires 'pos' and 'user'.
		-- This updates the node metadata as if 'user' placed it!
		protdef.after_place_node(pos, user)
	end

	-- Restore original meta.
	-- This should restore original owner (if prot was moved by admin).
	-- Placetime should also be restored.
	local meta = minetest.get_meta(pos)
	meta:from_table(oldmeta)

	-- It might be important in the future to know if a protector was ever moved.
	-- And how many times.
	meta:set_int("moved", numtimes + 1)
	meta:mark_as_private("moved")

	-- Update infotext. (Needed after restoring meta.)
	protector.update_infotext(meta)

	if displayent_visible then
		protector.toggle_area_display(pos)
	end

	ambiance.sound_play(electric_screwdriver.sound, pos, electric_screwdriver.sound_gain, electric_screwdriver.sound_dist)
	response("Protector moved to " .. rc.pos_to_namestr_ex(pos) .. ".")
end



-- Run only once.
if not protector.tools_registered then
	protector.tools_registered = true

	minetest.register_craftitem("protector:tool", {
		description = "Claim Expansion Tool\n\nStand near protector, face direction and use.\nHold sneak to copy member names.\nHold 'E' to double the gap distance.",
		inventory_image = "nodeinspector.png^protector_lock.png",
		stack_max = 1,
		groups = {not_repaired_by_anvil=1},

		on_use = function(...)
			return protector.on_use_tool(...)
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

		on_use = function(...)
			return protector.on_use_tool2(...)
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
end

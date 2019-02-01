
commandtools = commandtools or {}
commandtools.modpath = minetest.get_modpath("commandtools")



-- Pick.
commandtools.pick_on_use = function(itemstack, user, pointed_thing)
	local pname = user:get_player_name()

	local havepriv = minetest.check_player_privs(pname, {commandtools_pick=true})
	assert(type(havepriv) == "boolean")
	if havepriv == false then
		-- Try and remove it from the bad player.
		itemstack:take_item()
		return itemstack
	end

	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		if not pos then return end

		if minetest.get_node(pos).name ~= "air" then
			minetest.log("action", pname .. " digs " .. minetest.get_node(pos).name .. " at " .. minetest.pos_to_string(pos) .. " using an Admin Pickaxe.")
			minetest.remove_node(pos) -- The node is removed directly, which means it even works on non-empty containers and group-less nodes.
			minetest.check_for_falling(pos) -- Run node update actions like falling nodes.
		end
	elseif pointed_thing.type == "object" then
		local ref = pointed_thing.ref
		if ref then
			local tool_capabilities = {
				full_punch_interval = 0.1,
				max_drop_level = 3,
				groupcaps= {
					unbreakable = {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					fleshy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					choppy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					bendy =       {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					cracky =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					crumbly =     {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					snappy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
				},
				damage_groups = {fleshy = 1000},
			}
			ref:punch(user, 1, tool_capabilities, nil)
		end
	end
end



-- Inventory is for display purposes only, don't allow taking, putting, or moving items.
local detached_inventory_callbacks = {
	allow_move = function() return 0 end,
	allow_put = function() return 0 end,
	allow_take = function() return 0 end,
}



-- Hoe.
commandtools.hoe_on_use = function(itemstack, user, pointed_thing)
	if not user then return end
	if not user:is_player() then return end

	local havepriv = minetest.check_player_privs(user, {commandtools_hoe=true})
	assert(type(havepriv) == "boolean")
	if havepriv == false then
		-- Try and remove it from the bad player.
		itemstack:take_item()
		return itemstack
	end

	if pointed_thing.type == "object" then
		local ref = pointed_thing.ref
		if ref == nil then return end

		if ref:is_player() then
			local inv = minetest.create_detached_inventory("commandtools:hoe:inv", detached_inventory_callbacks)
			local pinv = ref:get_inventory()
			if inv == nil then return end
			if pinv == nil then return end

			inv:set_size("main", 8*4)
			inv:set_list("main", pinv:get_list("main"))

			inv:set_size("craft", 3*3)
			inv:set_list("craft", pinv:get_list("craft"))

			local formspec = "size[8,9]" ..
				default.gui_bg ..
				default.gui_bg_img ..
				default.gui_slots ..
				"label[0,0;Static inventory view for player <" .. minetest.formspec_escape(rename.gpn(ref:get_player_name())) .. ">]" ..
				"list[detached:commandtools:hoe:inv;craft;0,1;3,3]" ..
				"list[detached:commandtools:hoe:inv;main;0,5;8,4]"
			minetest.show_formspec(user:get_player_name(), "commandtools:hoe", formspec)
		else
			-- Pick up item drops, or punch mobs.
			local tool_capabilities = {
				full_punch_interval = 0.1,
				max_drop_level = 3,
				groupcaps= {
					unbreakable = {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					fleshy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					choppy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					bendy =       {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					cracky =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					crumbly =     {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
					snappy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
				},
				damage_groups = {fleshy = 1},
			}
			ref:punch(user, 1, tool_capabilities, nil)
		end
	elseif pointed_thing.type == "node" then
		local pos = pointed_thing.under
		if not pos then return end
		pos = vector.round(pos)

		--sfn.update_node(pos)
		--do return end

		local node = minetest.get_node(pos)
		if node.name == "protector:protect" or
			node.name == "protector:protect2" or
			node.name == "protector:protect3" or
			node.name == "protector:protect4" then
			local def = minetest.reg_ns_nodes[node.name]
			if def and def.on_punch then
				def.on_punch(pos, node, user)
			end
		else
			local owner = protector.get_node_owner(pos)
			if owner then
				minetest.chat_send_player(user:get_player_name(), "# Server: Block owned by <" .. rename.gpn(owner) .. ">. (Should be protected.)")
			else
				minetest.chat_send_player(user:get_player_name(), "# Server: Block not owned by anyone.")
			end
			if minetest.test_protection(pos, "") then
				minetest.chat_send_player(user:get_player_name(), "# Server: The location is indeed protected!")
			else
				minetest.chat_send_player(user:get_player_name(), "# Server: This location is not protected.")
			end
		end
	end
end



local function get_right_dir(fdir)
	if fdir.x == 1 then
		return {x=0, y=0, z=-1}
	elseif fdir.x == -1 then
		return {x=0, y=0, z=1}
	elseif fdir.z == 1 then
		return {x=1, y=0, z=0}
	elseif fdir.z == -1 then
		return {x=-1, y=0, z=0}
	end
	return {x=0, y=0, z=0}
end

local function find_floor(pos)
	pos = {x=pos.x, y=pos.y+20, z=pos.z}
	local name = minetest.get_node(pos).name
	while name == "air" or name == "default:snow" do
		pos.y = pos.y - 1
		name = minetest.get_node(pos).name
	end
	-- Returns "base" position of the road surface at this location.
	pos.y = pos.y + 1
	return pos
end

local function choose_dir(dir)
	if dir.z == 1 then
		return "north"
	elseif dir.z == -1 then
		return "south"
	elseif dir.x == 1 then
		return "east"
	elseif dir.x == -1 then
		return "west"
	end
	return ""
end

local function fix_param2(pos)
	-- Reset param2 on all stonebrick nodes.
	local minp = vector.subtract(pos, 7)
	local maxp = vector.add(pos, 7)
	local nodes = minetest.find_nodes_in_area(minp, maxp, "default:stonebrick")
	if nodes then
		local stonebrick = {name="default:stonebrick"}
		for i=1, #nodes do
			minetest.set_node(nodes[i], stonebrick)

			local under = vector.add(nodes[i], {x=0, y=-1, z=0})
			if minetest.get_node(under).name == "default:stone" then
				minetest.set_node(under, stonebrick)
			end
		end
	end
end

local schems = {
	north = {
		up = {schem = "roadsection_n_up.mts", offset = {x=0, y=0, z=0}, rotation="0", prot = {x=2, y=1, z=3}},
		up_steep =  {schem = "roadsection_n_up_steep.mts", offset = {x=0, y=0, z=0}, rotation="0", prot = {x=2, y=3, z=3}},
		down = {schem = "roadsection_n_down.mts", offset = {x=0, y=-2, z=0}, rotation="0", prot = {x=2, y=-1, z=3}},
		down_steep = {schem = "roadsection_n_down_steep.mts", offset = {x=0, y=-5, z=0}, rotation="0", prot = {x=2, y=-2, z=3}},
		flat = {schem = "roadsection_ns.mts", offset = {x=0, y=-3, z=0}, rotation="0", prot = {x=2, y=0, z=3}},
		corner = {schem = "roadcorner_ne.mts", offset = {x=0, y=-3, z=0}, rotation="90", prot = {x=2, y=0, z=2}},
	},
	south = {
		up = {schem = "roadsection_n_down.mts", offset = {x=-4, y=0, z=-6}, rotation="0", prot = {x=-2, y=1, z=-3}},
		up_steep =  {schem = "roadsection_n_down_steep.mts", offset = {x=-4, y=0, z=-6}, rotation="0", prot = {x=-2, y=3, z=-3}},
		down = {schem = "roadsection_n_up.mts", offset = {x=-4, y=-2, z=-6}, rotation="0", prot = {x=-2, y=-1, z=-3}},
		down_steep = {schem = "roadsection_n_up_steep.mts", offset = {x=-4, y=-5, z=-6}, rotation="0", prot = {x=-2, y=-2, z=-3}},
		flat = {schem = "roadsection_ns.mts", offset = {x=-4, y=-3, z=-6}, rotation="0", prot = {x=-2, y=0, z=-3}},
		corner = {schem = "roadcorner_ne.mts", offset = {x=-4, y=-3, z=-4}, rotation="270", prot = {x=-2, y=0, z=-2}},
	},
	east = {
		up = {schem = "roadsection_n_up.mts", offset = {x=0, y=0, z=-4}, rotation="90", prot = {x=3, y=1, z=-2}},
		up_steep =  {schem = "roadsection_n_up_steep.mts", offset = {x=0, y=0, z=-4}, rotation="90", prot = {x=3, y=3, z=-2}},
		down = {schem = "roadsection_n_down.mts", offset = {x=0, y=-2, z=-4}, rotation="90", prot = {x=3, y=-1, z=-2}},
		down_steep = {schem = "roadsection_n_down_steep.mts", offset = {x=0, y=-5, z=-4}, rotation="90", prot = {x=3, y=-2, z=-2}},
		flat = {schem = "roadsection_ns.mts", offset = {x=0, y=-3, z=-4}, rotation="90", prot = {x=3, y=0, z=-2}},
		corner = {schem = "roadcorner_ne.mts", offset = {x=0, y=-3, z=-4}, rotation="180", prot = {x=2, y=0, z=-2}},
	},
	west = {
		up = {schem = "roadsection_n_down.mts", offset = {x=-6, y=0, z=0}, rotation="90", prot = {x=-3, y=1, z=2}},
		up_steep =  {schem = "roadsection_n_down_steep.mts", offset = {x=-6, y=0, z=0}, rotation="90", prot = {x=-3, y=3, z=2}},
		down = {schem = "roadsection_n_up.mts", offset = {x=-6, y=-2, z=0}, rotation="90", prot = {x=-3, y=-1, z=2}},
		down_steep = {schem = "roadsection_n_up_steep.mts", offset = {x=-6, y=-5, z=0}, rotation="90", prot = {x=-3, y=-2, z=2}},
		flat = {schem = "roadsection_ns.mts", offset = {x=-6, y=-3, z=0}, rotation="90", prot = {x=-3, y=0, z=2}},
		corner = {schem = "roadcorner_ne.mts", offset = {x=-4, y=-3, z=0}, rotation="0", prot = {x=-2, y=0, z=2}},
	},
}

local function place_schem(pos, dir, slope, placer)
	local data = schems[dir][slope]
	local path = minetest.get_worldpath() .. "/schems/" .. data.schem
	minetest.place_schematic(vector.add(pos, data.offset), path, data.rotation)

	if data.prot then
		local p = vector.add(pos, data.prot)
		local def = minetest.reg_ns_nodes["protector:protect3"]
		if def and def.after_place_node then
			minetest.set_node(p, {name="protector:protect3"})
			def.after_place_node(p, placer)
		end
	end

	-- Bridge/tunnel building.
	local control = placer:get_player_control()
	if control.jump then
		return
	end

	if slope ~= "corner" then
		local path2 = minetest.get_worldpath() .. "/schems/roadbed_ns.mts"
		local bp = vector.add(vector.add(pos, data.offset), {x=0, y=-4, z=0})
		for i=1, 3, 1 do
			minetest.place_schematic(bp, path2, data.rotation)
			bp.y = bp.y - 4
		end

		local path3 = minetest.get_worldpath() .. "/schems/roadair_ns.mts"
		local ap
		if slope ~= "up_steep" and slope ~= "down_steep" then
			ap = vector.add(vector.add(pos, data.offset), {x=0, y=5, z=0})
		else
			-- Must start air a little bit higher up.
			ap = vector.add(vector.add(pos, data.offset), {x=0, y=7, z=0})
		end
		for i=1, 3, 1 do
			minetest.place_schematic(ap, path3, data.rotation)
			ap.y = ap.y + 4
		end
	else
		local path2 = minetest.get_worldpath() .. "/schems/cornerbed_ne.mts"
		local bp = vector.add(vector.add(pos, data.offset), {x=0, y=-4, z=0})
		for i=1, 3, 1 do
			minetest.place_schematic(bp, path2, data.rotation)
			bp.y = bp.y - 4
		end

		local path3 = minetest.get_worldpath() .. "/schems/cornerair_ne.mts"
		local ap = vector.add(vector.add(pos, data.offset), {x=0, y=5, z=0})
		for i=1, 3, 1 do
			minetest.place_schematic(ap, path3, data.rotation)
			ap.y = ap.y + 4
		end
	end
end

local function place_smart(pos, vdir, placer)
	local rd = get_right_dir(vdir)

	local p1 = vector.add(pos, vector.multiply(vdir, 4))
	local p2 = vector.add(p1, vector.multiply(rd, 4))
	local p3 = vector.add(pos, vector.multiply(vdir, 8))
	local p4 = vector.add(p3, vector.multiply(rd, 4))
	local p5 = vector.add(pos, vector.multiply(vdir, 18))
	local p6 = vector.add(p5, vector.multiply(rd, 4))

	-- Find out whether we are going up, down, or flat.
	p1 = find_floor(p1)
	p2 = find_floor(p2)
	p3 = find_floor(p3)
	p4 = find_floor(p4)
	p5 = find_floor(p5)
	p6 = find_floor(p6)

	-- Get the average slope.
	local y1 = (p1.y + p2.y + p3.y + p4.y + p5.y + p6.y) / 6

	local ny = 0
	if y1 < (pos.y - 4) then
		place_schem(pos, choose_dir(vdir), "down_steep", placer)
		ny = -5
	elseif y1 > (pos.y + 4) then
		place_schem(pos, choose_dir(vdir), "up_steep", placer)
		ny = 5
	elseif y1 < (pos.y - 2) then
		place_schem(pos, choose_dir(vdir), "down", placer)
		ny = -2
	elseif y1 > (pos.y + 2) then
		place_schem(pos, choose_dir(vdir), "up", placer)
		ny = 2
	else
		place_schem(pos, choose_dir(vdir), "flat", placer)
	end

	fix_param2(pos)

	--minetest.chat_send_player("MustTest", y1 .. ", " .. ny)

	-- Returns the wanted position of the next road section.
	local rp = vector.add(pos, vector.multiply(vdir, 7))
	rp.y = rp.y + ny
	return rp
end



commandtools.gateinfo = {
	target_pos = {x=0, y=0, z=0},
	origin_pos = {x=0, y=0, z=0},
	target_dest = {x=0, y=0, z=0},
	origin_dest = {x=0, y=0, z=0},
	target_owner = "",
	origin_owner = "",
	direction = ""
}

function commandtools.gaterepair_origin(pname, pos)
	local result
	local points
	local counts
	local origin

	local northsouth
	local ns_key
	local playerorigin

	-- Find the gateway (threshold under player)!
	result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ns_data)
	northsouth = true
	ns_key = "ns"

	if not result then
		-- Couldn't find northsouth gateway, so try to find eastwest.
		result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ew_data)
		northsouth = false
		ns_key = "ew"
	end

	-- Debugging.
	if not result then
		minetest.chat_send_player(pname, "# Server: Bad gateway.")
		return
	else
		minetest.chat_send_player(pname, "# Server: Found gateway @ " .. minetest.pos_to_string(origin) .. ".")
	end

	if commandtools.gateinfo.direction ~= ns_key then
		minetest.chat_send_player(pname, "# Server: Gateway orientations do NOT match!")
		return
	end

	local target = table.copy(commandtools.gateinfo.target_pos)
	target = vector.round(target)

	if ns_key == "ns" then
		playerorigin = vector.add(target, {x=1, y=1, z=0})
	elseif ns_key == "ew" then
		playerorigin = vector.add(target, {x=0, y=1, z=1})
	else
		playerorigin = table.copy(target)
	end

	local meta = minetest.get_meta(origin)
	meta:set_string("obsidian_gateway_success_" .. ns_key, "yes")
	meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
	meta:set_string("obsidian_gateway_owner_" .. ns_key, commandtools.gateinfo.target_owner)
	meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 0) -- Not used by origin gates.

	minetest.chat_send_player(pname, "# Server: Pasted gateway information (linked ORIGIN to TARGET)!")
end

function commandtools.gaterepair_target(pname, pos)
	local result
	local points
	local counts
	local origin

	local northsouth
	local ns_key
	local playerorigin

	-- Find the gateway (threshold under player)!
	result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ns_data)
	northsouth = true
	ns_key = "ns"

	if not result then
		-- Couldn't find northsouth gateway, so try to find eastwest.
		result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ew_data)
		northsouth = false
		ns_key = "ew"
	end

	-- Debugging.
	if not result then
		minetest.chat_send_player(pname, "# Server: Bad gateway.")
		return
	else
		minetest.chat_send_player(pname, "# Server: Found gateway @ " .. minetest.pos_to_string(origin) .. ".")
	end

	if commandtools.gateinfo.direction ~= ns_key then
		minetest.chat_send_player(pname, "# Server: Gateway orientations do NOT match!")
		return
	end

	local target = table.copy(commandtools.gateinfo.origin_pos)
	target = vector.round(target)

	if ns_key == "ns" then
		playerorigin = vector.add(target, {x=1, y=1, z=0})
	elseif ns_key == "ew" then
		playerorigin = vector.add(target, {x=0, y=1, z=1})
	else
		playerorigin = table.copy(target)
	end

	local meta = minetest.get_meta(origin)
	meta:set_string("obsidian_gateway_success_" .. ns_key, "") -- Not used by return gates.
	meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
	meta:set_string("obsidian_gateway_owner_" .. ns_key, commandtools.gateinfo.origin_owner)
	meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 1)

	minetest.chat_send_player(pname, "# Server: Pasted gateway information (linked TARGET to ORIGIN)!")
end

function commandtools.gatecopy_origin(pname, pos)
	local result
	local points
	local counts
	local origin

	local northsouth
	local ns_key
	local playerorigin

	-- Find the gateway (threshold under player)!
	result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ns_data)
	northsouth = true
	ns_key = "ns"

	if not result then
		-- Couldn't find northsouth gateway, so try to find eastwest.
		result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ew_data)
		northsouth = false
		ns_key = "ew"
	end

	-- Debugging.
	if not result then
		minetest.chat_send_player(pname, "# Server: Bad gateway.")
		return
	else
		minetest.chat_send_player(pname, "# Server: Found gateway @ " .. minetest.pos_to_string(origin) .. ".")
	end

	local meta = minetest.get_meta(origin)
	local target = minetest.string_to_pos(meta:get_string("obsidian_gateway_destination_" .. ns_key))
	local owner = meta:get_string("obsidian_gateway_owner_" .. ns_key)

	if target and owner and owner ~= "" then
		minetest.chat_send_player(pname, "# Server: Copied ORIGIN gateway information!")
		commandtools.gateinfo.origin_pos = vector.round(origin)
		commandtools.gateinfo.origin_dest = vector.round(target)
		commandtools.gateinfo.origin_owner = owner
		commandtools.gateinfo.direction = ns_key
	else
		minetest.chat_send_player(pname, "# Server: Invalid gateway metadata. Cannot copy!")
	end
end

function commandtools.gatecopy_target(pname, pos)
	local result
	local points
	local counts
	local origin

	local northsouth
	local ns_key
	local playerorigin

	-- Find the gateway (threshold under player)!
	result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ns_data)
	northsouth = true
	ns_key = "ns"

	if not result then
		-- Couldn't find northsouth gateway, so try to find eastwest.
		result, points, counts, origin = schematic_find.detect_schematic(pos, obsidian_gateway.gate_ew_data)
		northsouth = false
		ns_key = "ew"
	end

	-- Debugging.
	if not result then
		minetest.chat_send_player(pname, "# Server: Bad gateway.")
		return
	else
		minetest.chat_send_player(pname, "# Server: Found gateway @ " .. minetest.pos_to_string(origin) .. ".")
	end

	local meta = minetest.get_meta(origin)
	local target = minetest.string_to_pos(meta:get_string("obsidian_gateway_destination_" .. ns_key))
	local owner = meta:get_string("obsidian_gateway_owner_" .. ns_key)

	if target and owner and owner ~= "" then
		minetest.chat_send_player(pname, "# Server: Copied TARGET gateway information!")
		commandtools.gateinfo.target_pos = vector.round(origin)
		commandtools.gateinfo.target_dest = vector.round(target)
		commandtools.gateinfo.target_owner = owner
		commandtools.gateinfo.direction = ns_key
	else
		minetest.chat_send_player(pname, "# Server: Invalid gateway metadata. Cannot copy!")
	end
end



function commandtools.shovel_on_use(itemstack, user, pt)
	if not user then return end
	if not user:is_player() then return end
	local pname = user:get_player_name()

	local havepriv = minetest.check_player_privs(user, {commandtools_shovel=true})
	if not havepriv then
		-- Try and remove it from the bad player.
		itemstack:take_item()
		return itemstack
	end

	local control = user:get_player_control()
	local good
	local err

	if control.aux1 then
		if control.sneak then
			-- Use + sneak: copy origin gate info.
			good, err = pcall(function() commandtools.gatecopy_origin(pname, pt.under) end)
		else
			-- Use - sneak: copy target gate info.
			good, err = pcall(function() commandtools.gatecopy_target(pname, pt.under) end)
		end
	else
		if control.sneak then
			-- Sneak (no use): paste target information onto origin gate.
			good, err = pcall(function() commandtools.gaterepair_origin(pname, pt.under) end)
		else
			-- Regular tool use: paste origin information onto target gate.
			good, err = pcall(function() commandtools.gaterepair_target(pname, pt.under) end)
		end
	end

	if not good then
		minetest.chat_send_player(pname, "# Server: Error running code! " .. err)
	else
		minetest.chat_send_player(pname, "# Server: Success.")
	end

	--[[

	if pt.type ~= "node" then
		return
	end

	local control = user:get_player_control()
	local ldir = user:get_look_dir()
	local fdir = minetest.dir_to_facedir(ldir)
	local vdir = minetest.facedir_to_dir(fdir)

	-- Start 1 meter ahead of the target node.
	local start = vector.add(pt.under, vdir)

	if control.left and control.right and control.aux1 then
		local pos = {x=start.x, y=start.y, z=start.z}
		for i=1, 7, 1 do
			pos = place_smart(pos, vdir, user)
		end
		return
	elseif control.left and control.right then
		place_smart(start, vdir, user)
		return
	end

	if control.aux1 and not control.sneak and control.up then
		place_schem(start, choose_dir(vdir), "up", user)
	elseif control.aux1 and control.sneak and control.down then
		place_schem(start, choose_dir(vdir), "down_steep", user)
	elseif control.aux1 and control.sneak and control.up then
		place_schem(start, choose_dir(vdir), "up_steep", user)
	elseif control.aux1 and not control.sneak and control.down then
		place_schem(start, choose_dir(vdir), "down", user)
	elseif control.left then
		place_schem(start, choose_dir(vdir), "corner", user)
	else
		place_schem(start, choose_dir(vdir), "flat", user)
	end

	fix_param2(start)
	--]]
end



-- Run-once initialization code only.
if not commandtools.run_once then
	minetest.register_privilege("commandtools_pick", {
		description = "Player is allowed to use the Admin Pick.",
		give_to_singleplayer = false,
	})

	-- Used for destroying nodes and killing players/mobs.
	minetest.register_tool("commandtools:pick", {
		description = "Admin Pick\n\nUse for breaking stuff and killing things!",
		range = 12,
		inventory_image = "commandtools_pickaxe.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(...) return commandtools.pick_on_use(...) end,
	})
	minetest.register_alias("maptools:pick_admin1", "commandtools:pick")

	minetest.register_privilege("commandtools_hoe", {
		description = "Player is allowed to use the Admin Hoe.",
		give_to_singleplayer = false,
	})

	-- Used for peaking at a player's inventory.
	minetest.register_tool("commandtools:hoe", {
		description = "Admin Hoe\n\nUse to look at player inventories & check node protection.",
		range = 12,
		inventory_image = "commandtools_hoe.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(...) return commandtools.hoe_on_use(...) end,
	})

	minetest.register_privilege("commandtools_shovel", {
		description = "Player is allowed to use the Admin Shovel.",
		give_to_singleplayer = false,
	})

	-- Tester tool.
	minetest.register_tool("commandtools:shovel", {
		description = "Admin Shovel\n\nTester tool.",
		range = 12,
		inventory_image = "commandtools_shovel.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(...) return commandtools.shovel_on_use(...) end,
	})

	-- Reloadable.
	local file = commandtools.modpath .. "/init.lua"
	local name = "commandtools:core"
	reload.register_file(name, file, false)

	commandtools.run_once = true
end



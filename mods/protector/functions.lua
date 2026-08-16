
-- Localize.
local math_floor = math.floor
local math_random = math.random



-- Can use this in node definitions to allow a node to be placed inside
-- protected areas (similar to snow). The node is marked "protection_cancel"
-- so anyone else could come and remove it. (Only if necessary.)
function protector.on_place_ignore_protection(itemstack, placer, pointed_thing)
	local pname = placer and placer:get_player_name() or ""

	-- Must call 'on_rightclick' manually.
	-- Can't just use 'core.item_place()' later because we're disabling protection
	-- JUST for the node placement. If the node has 'on_rightclick' then we need
	-- to call it while protection is still enabled, in case it checks protection
	-- for any reason.
	if pointed_thing.type == "node" then
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local ndef = node and minetest.reg_ns_nodes[node.name]
		if ndef and ndef.on_rightclick and placer and not placer:get_player_control().sneak then
			return ndef.on_rightclick(pointed_thing.under, node, placer, itemstack, pointed_thing)
		end
	end

	-- Protection prevents proper operation of 'item_place_node'
	protector.enable_protection(false)
	local newstack, place_to = core.item_place_node(itemstack, placer, pointed_thing)
	protector.enable_protection(true)

	-- Check if player put object in location protected by someone else.
	if place_to and minetest.test_protection(place_to, pname) then
		local meta = minetest.get_meta(place_to)
		meta:set_int("protection_cancel", 1)
		meta:mark_as_private("protection_cancel")
	end

	return newstack
end



-- Remove all "protection_cancel" around protector.
-- To be called in 'after_place_node'.
function protector.clear_protection_cancel(place_to)
	local node = minetest.get_node(place_to)
	local ndef = minetest.registered_nodes[node.name] or {}

	if not ndef._protector_node_radius then
		return
	end

	local minp = vector.subtract(place_to, ndef._protector_node_radius)
	local maxp = vector.add(place_to, ndef._protector_node_radius)
	local nodes = core.find_nodes_with_meta(minp, maxp)

	for _, pos in ipairs(nodes) do
		local meta = minetest.get_meta(pos)
		if meta:get_int("protection_cancel") == 1 then
			meta:set_string("protection_cancel", "") -- Completely remove.
		end
	end
end



function protector.initialize_meta(meta, placer)
	-- Critical. Never change this time format, we have to be able to parse
	-- it to get a timestamp in seconds. This is the only way to get a time for
	-- old prots placed before August 2026.
	local placedate = os.date("!%Y/%m/%d UTC")

	local pname = placer:get_player_name() or ""
	local dname = rename.gpn(pname)

	meta:set_string("placedate", placedate) -- Not available on extremely old prots.
	meta:set_string("placetime", tostring(os.time())) -- New as of August 2026.
	meta:set_string("owner", pname)
	meta:set_string("rename", dname)
	meta:set_string("infotext", protector.get_infotext(meta))
	meta:set_string("members", "")

	meta:mark_as_private({
		"placedate",
		"placetime",
		"owner",
		"rename",
		"members",
	})
end



-- Called by rename LBM.
function protector.on_update_infotext_lbm(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local placedate = meta:get_string("placedate")

	-- Nobody placed this block.
	if owner == "" then
		return
	end
	if placedate == "" then
		placedate = "an unknown date!"
	end

	meta:set_string("rename", rename.gpn(owner))
	meta:set_string("infotext", protector.get_infotext(meta))
end



-- Singular function to find relevant protector nodes in an area.
local PROTECTOR_NODENAMES = {"protector:protect", "protector:protect2", "protector:protect3", "protector:protect4"}
function protector.find_protector_nodes(pos, r, mult, nodename)
	-- Arguments:
	-- `pos` = the point of interaction.
	-- `r` = the primary radius, either 1 or 5. If 1 then we're only looking for the protector itself.
	-- `mult` = how much to scale the primary radius by. 1 or 2. 2 is for checking overlaps.
	-- `nodename` = the name of the protector calling this function. May be "".
	-- The logic is complex.

	r = r * mult
	local positions, counts = minetest.find_nodes_in_area(
		{x = pos.x - r, y = pos.y - r, z = pos.z - r},
		{x = pos.x + r, y = pos.y + r, z = pos.z + r},
		PROTECTOR_NODENAMES)

	local p1 = counts["protector:protect"] or 0
	local p2 = counts["protector:protect2"] or 0

	-- Does scanned zone contain any smaller protectors?
	local p3 = counts["protector:protect3"] or 0
	local p4 = counts["protector:protect4"] or 0

	if p1 > 0 or p2 > 0 then
		-- Determine necessary culling radius based on what we're doing.
		local r2 = protector.radius * mult
		if mult == 2 and (nodename == "protector:protect3" or nodename == "protector:protect4") then
			r2 = protector.radius + protector.radius_small
		end

		-- Remove irrelevant protectors.
		-- These are protectors that are too far away for their protection radius to matter to us.
		::redo::
		for i = 1, #positions, 1 do
			local p = positions[i]
			local nn = minetest.get_node(p).name
			if nn == "protector:protect" or nn == "protector:protect2" then
				local minp = {x=pos.x-r2, y=pos.y-r2, z=pos.z-r2}
				local maxp = {x=pos.x+r2, y=pos.y+r2, z=pos.z+r2}
				if p.x > maxp.x or p.x < minp.x or p.y > maxp.y or p.y < minp.y or p.z > maxp.z or p.z < minp.z then
					table.remove(positions, i)
					goto redo
				end
			end
		end
	end

	if p3 > 0 or p4 > 0 then
		-- Determine necessary culling radius based on what we're doing.
		local r2 = protector.radius_small * mult
		if mult == 2 and (nodename == "protector:protect" or nodename == "protector:protect2") then
			r2 = protector.radius + protector.radius_small
		end

		-- Remove irrelevant protectors.
		-- These are protectors that are too far away for their protection radius to matter to us.
		::redo::
		for i = 1, #positions, 1 do
			local p = positions[i]
			local nn = minetest.get_node(p).name
			if nn == "protector:protect3" or nn == "protector:protect4" then
				local minp = {x=pos.x-r2, y=pos.y-r2, z=pos.z-r2}
				local maxp = {x=pos.x+r2, y=pos.y+r2, z=pos.z+r2}
				if p.x > maxp.x or p.x < minp.x or p.y > maxp.y or p.y < minp.y or p.z > maxp.z or p.z < minp.z then
					table.remove(positions, i)
					goto redo
				end
			end
		end
	end

	-- Return only positions that matter.
	return positions
end



-- This is called by the node inspector tool to toggle display entities for buried protectors.
function protector.toggle_protector_entities_in_area(pname, pos)
	local r = protector.radius
  local positions = protector.find_protector_nodes(pos, r, 1, "")
  for n = 1, #positions do
    local meta = minetest.get_meta(positions[n])
    local owner = meta:get_string("owner")
		if owner == pname then -- Can only toggle display entities for owned protectors.
			local node = minetest.get_node(positions[n])
			if node.name == "protector:protect" or node.name == "protector:protect2" then
				protector.toggle_area_display(positions[n], "protector:display")
			elseif node.name == "protector:protect3" or node.name == "protector:protect4" then
				protector.toggle_area_display(positions[n], "protector:display_small")
			end
		end
	end
end



function protector.punish_player(pos, pname)
	if not pname or pname == "" then
		return
	end

	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	-- hurt player if protection violated
	if protector.hurt > 0 and not armor.player_in_duel(pname) then
		local hp = player:get_hp()
		if hp > 0 then -- Avoid writing message twice.
			player:set_hp(hp - (protector.hurt*500))

			if player:get_hp() <= 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> was killed by a protection block.")
			end
		end
	end

	-- flip player when protection violated
	if protector.flip then
		-- yaw +/- 180°
		local yaw = player:get_look_horizontal() + (math_random(-(math.pi*100), (math.pi*100))/100)
		player:set_look_horizontal(yaw)

		-- Invert pitch.
		player:set_look_vertical(-player:get_look_vertical())

		-- if digging below player, move up to avoid falling through hole
		local pla_pos = player:get_pos()

		if pos.y < pla_pos.y then

			player:set_pos({
				x = pla_pos.x,
				y = pla_pos.y + 0.8,
				z = pla_pos.z
			})
		end
	end

	-- drop tool/item if protection violated
	-- This is disabled because it is too easy to exploit using lag -- TenPlus1.
	--[[
	if protector.drop == true then
		local holding = player:get_wielded_item()

		if holding:to_string() ~= "" then
			-- take stack
			local sta = holding:take_item(holding:get_count())
			player:set_wielded_item(holding)

			-- incase of lag, reset stack
			minetest.after(0.1, function()
				-- Get player reference anew, in case player has left game.
				local player = minetest.get_player_by_name(pname)
				if not player then
					return
				end

				player:set_wielded_item(holding)

				-- drop stack
				local obj = minetest.add_item(player:get_pos(), sta)
				if obj then
					obj:set_velocity({x = math_random(-5, 5), y = 5, z = math_random(-5, 5)})
				end
			end)

		end
	end
	--]]
end



-- Function to determine whether player may place protection in a realm.
-- Admin can always place protection regardless of realm.
local function realm_allows_protection(pos, pname)
	if gdac.player_is_admin(pname) then
		return true
	end

	-- Do NOT allow players to place protection in the Void, or the Outback.
	local rn = rc.current_realm_at_pos(pos)
	if rn == "abyss" or rn == "" then
		return false
	end

	return true
end



-- Make sure protection block doesn't overlap another protector's area
function protector.check_overlap_main(protname, pname, spos)
	if not realm_allows_protection(spos, pname) then
		return false, 4
	end

	-- Do not allow protections to be placed near the Outback gate's exit coordinates.
	-- Note: this prevents the admin from placing protection here, too.
	-- Existing protections (if any) remain untouched.
	local realmname = rc.current_realm_at_pos(spos)
	if not serveressentials.protector_can_place(spos, realmname) then
		return false, 5
	end

	if not protector.can_dig(protector.radius, 2, protname, spos, pname, true, 3) then
		-- Overlap with other player's protection.
		return false, 1
	end

	local ndef = minetest.registered_nodes[protname] or {}
	if not city_block:may_place_protector_at(spos, ndef._protector_node_radius or 0) then
		-- Overlap with a cityblock that says "no."
		return false, 6
	end

	local pos = {x=spos.x, y=spos.y, z=spos.z}
	local rad = protector.radius
	local bones = minetest.find_nodes_in_area(
		{x = pos.x - rad, y = pos.y - rad, z = pos.z - rad},
		{x = pos.x + rad, y = pos.y + rad, z = pos.z + rad},
		{"bones:bones"})

	if bones and #bones > 0 then
		for k, v in ipairs(bones) do
			local meta = minetest.get_meta(v)
			local owner = meta:get_string("owner") or ""
			if owner ~= "" and owner ~= "server" then
				-- fresh bones nearby
				return false, 2
			end
			local oldowner = meta:get_string("oldowner") or ""
			if oldowner ~= "" and oldowner ~= "server" then
				-- old bones nearby
				return false, 3
			end
		end
	end

	-- no overlap with other protection
	return true, 0
end



-- Called in 'on_place' of node definition.
function protector.check_overlap(itemstack, placer, pt)
	if pt.type ~= "node" then
		return itemstack
	end

	local pname = placer:get_player_name()
	local prot_type = itemstack:get_name()

	local success, reason = protector.check_overlap_main(prot_type, pname, pt.above)

	if not success then
		if reason == 1 then
			minetest.chat_send_player(pname, "# Server: Protection bounds overlap into another person's area claim.")
		elseif reason == 2 then
			minetest.chat_send_player(pname, "# Server: You cannot claim this area while someone's fresh corpse is nearby!")
		elseif reason == 3 then
			minetest.chat_send_player(pname, "# Server: You must remove all corpses before you can claim this area.")
		elseif reason == 4 then
			minetest.chat_send_player(pname, "# Server: Cannot claim protection here, there is no land authority.")
		elseif reason == 5 then
			minetest.chat_send_player(pname, "# Server: The area near the Outback gate's exit is public. Cannot claim land here.")
		elseif reason == 6 then
			minetest.chat_send_player(pname, "# Server: A nearby city block forbids placing protectors.")
		else
			minetest.chat_send_player(pname, "# Server: Cannot place protection for unknown reason.")
		end
		return
	end

	return minetest.item_place(itemstack, placer, pt)
end



-- Called in the `after_place_node` of protector node.
function protector.timed_setup(pos, placer, meta)
	local pname = placer:get_player_name()

	local is_temp_prot = false

	-- If protector was placed by someone without a Key, then it is a temporary protector.
	if not passport.player_has_key(pname, placer) then
		is_temp_prot = true
	end

	-- Determining how soon a protector should expire is tricky. On the one
	-- wing, if protection expires too quickly, players feel like they HAVE to
	-- login and do work often in order to save their claims. On the other wing,
	-- if protection lasts too long, it becomes too easy to deny land to other
	-- players, if someone decides to mass-protect some spot. This can be
	-- particularlly troublesome if the amount of land available is small (e.g.,
	-- certain small realms).
	local protection_time = 60*60*24*30

	-- Check if realm restricts protection to temporary mode only.
	local realmdata = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if realmdata then
		if realmdata.protection_temporary then
			is_temp_prot = true
			meta:set_int("realmdisable", 1)
		end

		if realmdata.protection_time then
			protection_time = realmdata.protection_time
		end
	end

	-- Set up timer stuff if needed.
	if is_temp_prot then
		local timer = minetest.get_node_timer(pos)
		timer:start(60) -- Run once a minute.

		-- Set "timerot" to a date in the future (in seconds).
		meta:set_int("temprot", 1)
		meta:set_int("timerot", (os.time() + protection_time))
		meta:mark_as_private({"temprot", "timerot", "realmdisable"})
	end
end



-- Called in the `on_timer` of protector node.
function protector.on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	if meta:get_int("temprot") == 1 then
		local timefut = meta:get_int("timerot")

		if (timefut - os.time()) > 0 then
			meta:set_string("infotext", protector.get_infotext(meta))

			-- Rerun timer for same timeout.
			minetest.get_node_timer(pos):start(60)
			return
		end

		-- Replace protector with expired protector node.
		-- Preserve param2 and node appearance.
		local node = minetest.get_node(pos)
		local ndef = minetest.registered_nodes[node.name]
		node.name = ndef._expired_protector_name
		minetest.set_node(pos, node)
	end
end



-- Using data from the meta, assemble and return an infotext string.
function protector.get_infotext(meta)
	local owner = meta:get_string("owner")
	local dname = rename.gpn(owner)
	local pdate = meta:get_string("placedate")

	if not pdate or pdate == "" then
		pdate = "an unknown date!"
	end

	local timeout = ""
	if meta:get_int("temprot") == 1 then
		local timefut = meta:get_int("timerot")
		local seconds = (timefut - os.time())
		if seconds < 0 then seconds = 0 end
		local hours = math_floor((seconds / 60) / 60)

		timeout = "\n------------------------------------------\n"

		if hours <= 24 then
			timeout = timeout .. "Expires in " .. hours .. " hours"
		else
			timeout = timeout .. "Expires in " .. math_floor(hours / 24) .. " days"
		end

		if meta:get_int("realmdisable") ~= 1 then
			timeout = timeout .. "\nGet KEY to make permanent claims"
		else
			timeout = timeout .. "\nRealm disallows perpetual claims"
		end
	end

	return "Protection (Owned by <" .. dname .. ">!)\nPlaced on " .. pdate .. timeout
end



local function system_response(pname, message)
	minetest.chat_send_player(pname, "# Server: " .. message)
end

-- Infolevel:
-- 0 for no info
-- 1 for "This area is owned by <owner> !" if you can't dig
-- 2 for "This area is owned by <owner>.
-- 3 for checking protector overlaps
function protector.can_dig(r, mult, nodename, pos, digger, onlyowner, infolevel)
	if not digger or not pos then
		return false
	end

	-- Bedrock is always protected.
	local node = minetest.get_node(pos)
	local ndef = minetest.reg_ns_nodes[node.name] or
		minetest.registered_nodes[node.name]
	if not ndef then
		return false
	end
	if ndef.always_protected then
		return false
	end

	-- Delprotect privileged users can override protections.
	if (minetest.check_player_privs(digger, {delprotect = true}) or minetest.check_player_privs(digger, {protection_bypass = true}))
			and
		 (infolevel == 1 or infolevel == 0) then
		return true
	end

	-- E.g., snow.
	-- This actually cannot work because it would allow players to place/drop snow
	-- (or any never_protected buildable_to) and then place nodes inside the
	-- buildable_to!
	--[[
	if ndef.never_protected == true and (infolevel == 1 or infolevel == 0) then
		return true
	end
	--]]

	-- Prevent users from modifying the map outside of any realm.
	if not rc.is_valid_realm_pos(pos) then
		return false
	end

	if infolevel == 3 then
		infolevel = 1
	end

	-- Find the protector nodes.
	local positions = protector.find_protector_nodes(pos, r, mult, nodename)
	local meta, owner, members

	-- Anyone can dig nodes marked as override in their meta.
	-- We don't bother checking the meta unless a protector is present.
	if #positions > 0 then
		-- `protection_cancel' only applies if the node is NOT buildable_to.
		-- This ensures players cannot break protection by dropping `buildable_to' nodes, and then placing into them.

		-- The falling block code is responsible for ensuring that a `buildable_to'
		-- node can never be dropped into a protected zone.
		local def = minetest.reg_ns_nodes[node.name] or
			minetest.registered_nodes[node.name]
		if def and not def.buildable_to then
			local meta2 = minetest.get_meta(pos)
			-- This is generally only set on nodes which have fallen.
			if meta2:get_int("protection_cancel") == 1 then
				-- Pretend that we found no protectors.
				-- Continue code as if we found none.
				positions = {}
			end
		end
	end

	for n = 1, #positions do
		meta = minetest.get_meta(positions[n])
		owner = meta:get_string("owner") or ""
		members = meta:get_string("members") or ""

		if owner ~= digger then
			if onlyowner or not protector.is_member(meta, digger) then
				if infolevel == 1 then
					system_response(digger, "This area is protected by <" .. rename.gpn(owner) .. ">!")
				elseif infolevel == 2 then
					system_response(digger, "This area is protected by <" .. rename.gpn(owner) .. ">.")
					system_response(digger, "Protection located at: " .. rc.pos_to_namestr_ex(positions[n]))

					if members ~= "" then
						local memlist = table.concat(members:split(" "), ', ')
						system_response(digger, "Members: [" .. memlist .. "].")
					end
				end
				return false
			end
		end

		if infolevel == 2 then
			system_response(digger, "This area is protected by <" .. rename.gpn(owner) .. ">.")
			system_response(digger, "Protection located at: " .. rc.pos_to_namestr_ex(positions[n]))

			if members ~= "" then
				local memlist = table.concat(members:split(" "), ', ')
				system_response(digger, "Members: [" .. memlist .. "].")
			end
			return false
		end
	end

	if infolevel == 2 then
		if #positions < 1 then
			system_response(digger, "This area is not protected.")
		end

		system_response(digger, "You can build here.")
	end

	return true
end



function protector.after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	protector.timed_setup(pos, placer, meta)
	protector.initialize_meta(meta, placer)

	-- Notify nearby players.
	protector.update_nearby_players(pos)
	protector.clear_protection_cancel(pos)
end



function protector.on_destruct(pos)
	-- Notify nearby players.
	minetest.after(0, protector.update_nearby_players, pos)
	protector.remove_area_display(pos)
end



function protector.on_blast(pos, intensity)
	-- TNT-proof.
end



-- Called in 'can_dig' of node definition.
function protector.node_can_dig(pos, player)
	if not player then
		return false
	end

	local node = minetest.get_node(pos)
	local pname = player:get_player_name()
	return protector.can_dig(1, 1, node.name, pos, pname, true, 1)
end



-- Called in 'on_use' of node definition.
function protector.node_on_use(itemstack, user, pointed_thing)
	if pointed_thing.type ~= "node" then
		return
	end
	if not user or not user:is_player() then
		return
	end

	local pos = pointed_thing.under
	local node = minetest.get_node(pos)
	local pname = user:get_player_name()
	protector.can_dig(protector.radius, 1, node.name, pos, pname, false, 2)
end



-- Called in 'on_punch' of node definition.
function protector.node_on_punch(pos, node, puncher)
	if not puncher or not puncher:is_player() then
		return
	end

	local pname = puncher:get_player_name()
	if minetest.test_protection(pos, pname) then
		return
	end

	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name] or {}
	if not ndef._protector_displayent_name then
		return
	end

	protector.toggle_area_display(pos, ndef._protector_displayent_name)
end



-- Called in 'on_rightclick' of node definition. (Note: only some nodes.)
function protector.node_on_rightclick(pos, node, clicker, itemstack)
	if not clicker or not clicker:is_player() then
		return
	end

	local meta = minetest.get_meta(pos)
	local pname = clicker:get_player_name()
	local node = minetest.get_node(pos)

	if protector.can_dig(1, 1, node.name, pos, pname, true, 1) then
		protector.players[pname] = pos -- Security + context.
		minetest.show_formspec(pname, "protector:node", protector.generate_formspec(pname, meta))
	end
end


protector = protector or {}
protector.players = protector.players or {}
protector.mod = "redo"
protector.modpath = minetest.get_modpath("protector")
protector.radius = 5
protector.radius_small = 3 -- Must always be smaller than primary radius.
protector.max_share_count = 12

-- Tool drop is disabled because it is too easy to exploit this using lag.
--protector.drop = minetest.setting_getbool("protector_drop") or false

protector.flip = minetest.settings:get_bool("protector_flip") or false
protector.hurt = (tonumber(minetest.settings:get("protector_hurt")) or 0)
protector.display_time = 60*2

dofile(protector.modpath .. "/hud.lua")

-- Temporary pos store.
local player_pos = protector.players



-- Use this function ONLY when calling a Minetest API in
-- a situation where protection interferes!
local PROTECTION_ENABLED = true
function protector.enable_protection(enable)
	PROTECTION_ENABLED = enable
end



-- Singular function to find relevant protector nodes in an area.
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
		{"protector:protect", "protector:protect2", "protector:protect3", "protector:protect4"})

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



minetest.register_privilege("delprotect", {
    description = "Ignore player protection.",
    give_to_singleplayer = false,
})



protector.get_member_list = function(meta)
	return meta:get_string("members"):split(" ")
end

protector.set_member_list = function(meta, list)
	meta:set_string("members", table.concat(list, " "))
end

protector.is_member = function(meta, name)
	for _, n in pairs(protector.get_member_list(meta)) do
		if n == name then
			return true
		end
	end

	return false
end

protector.add_member = function(meta, name)
	-- Constant (20) defined by player.h
	if name:len() > 25 then
		return
	end

	name = rename.grn(name)
	if protector.is_member(meta, name) then
		return
	end

	local list = protector.get_member_list(meta)
	if #list >= protector.max_share_count then
		return
	end

	table.insert(list, name)
	protector.set_member_list(meta, list)
end

protector.del_member = function(meta, name)
	name = rename.grn(name)
	local list = protector.get_member_list(meta)

	for i, n in pairs(list) do
		if n == name then
			table.remove(list, i)
			break
		end
	end

	protector.set_member_list(meta, list)
end

-- Protector Interface

protector.generate_formspec = function(meta)

	local formspec = "size[8,7]"
		.. default.formspec.get_form_colors()
		.. default.formspec.get_form_image()
		.. default.formspec.get_slot_colors()
		.. "label[0,0;" .. "11x11x11 Protector Interface" .. "]"
		.. "label[0,0.5;" .. "PUNCH node to show protected area or USE for area check." .. "]"
		.. "label[0,2;" .. "Members:" .. "]"
		.. "button_exit[3,6.2;2,0.5;close_me;" .. "Close" .. "]"
		.. "field_close_on_enter[protector_add_member;false]"

	local members = protector.get_member_list(meta)
	local npp = protector.max_share_count -- max users added onto protector list
	local i = 0

	for n = 1, #members do

		if i < npp then

			-- show username
			formspec = formspec .. "button[" .. (i % 4 * 2)
			.. "," .. math.floor(i / 4 + 3)
			.. ";1.5,.5;protector_member;" .. rename.gpn(members[n]) .. "]"

			-- username remove button
			.. "button[" .. (i % 4 * 2 + 1.25) .. ","
			.. math.floor(i / 4 + 3)
			.. ";.75,.5;protector_del_member_" .. members[n] .. ";X]"
		end

		i = i + 1
	end

	if i < npp then

		-- user name entry field
		formspec = formspec .. "field[" .. (i % 4 * 2 + 1 / 3) .. ","
		.. (math.floor(i / 4 + 3) + 1 / 3)
		.. ";1.433,.5;protector_add_member;;]"

		-- username add button
		.."button[" .. (i % 4 * 2 + 1.25) .. ","
		.. math.floor(i / 4 + 3) .. ";.75,.5;protector_submit;+]"

	end

	return formspec
end

protector.get_node_owner = function(pos)
	local r = protector.radius
	local positions = protector.find_protector_nodes(pos, r, 1, "")
	for n = 1, #positions do
		local meta = minetest.get_meta(positions[n])
		local owner = meta:get_string("owner")
		return owner
	end
end

-- This is called by the node inspector tool to toggle display entities for buried protectors.
protector.toggle_protector_entities_in_area = function(pname, pos)
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

-- Infolevel:
-- 0 for no info
-- 1 for "This area is owned by <owner> !" if you can't dig
-- 2 for "This area is owned by <owner>.
-- 3 for checking protector overlaps

protector.can_dig = function(r, mult, nodename, pos, digger, onlyowner, infolevel)
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
					minetest.chat_send_player(digger, "# Server: This area is protected by <" .. rename.gpn(owner) .. ">!")
				elseif infolevel == 2 then
					minetest.chat_send_player(digger, "# Server: This area is protected by <" .. rename.gpn(owner) .. ">.")
					minetest.chat_send_player(digger, "# Server: Protection located at: " .. minetest.pos_to_string(positions[n]))

					if members ~= "" then
						minetest.chat_send_player(digger, "# Server: Members: [" .. members .. "].")
					end
				end
				return false
			end
		end

		if infolevel == 2 then
			minetest.chat_send_player(digger, "# Server: This area is protected by <" .. rename.gpn(owner) .. ">.")
			minetest.chat_send_player(digger, "# Server: Protection located at: " .. minetest.pos_to_string(positions[n]))

			if members ~= "" then
				minetest.chat_send_player(digger, "# Server: Members: [" .. members .. "].")
			end
			return false
		end
	end

	if infolevel == 2 then
		if #positions < 1 then
			minetest.chat_send_player(digger, "# Server: This area is not protected.")
		end

		minetest.chat_send_player(digger, "# Server: You can build here.")
	end

	return true
end

-- Can node be added or removed, if so return node else true (for protected)

function protector.punish_player(pos, pname)
	if not pname or pname == "" then
		return
	end

	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	-- hurt player if protection violated
	if protector.hurt > 0 then
		local hp = player:get_hp()
		if hp > 0 then -- Avoid writing message twice.
			player:set_hp(hp - protector.hurt)
			if player:get_hp() <= 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> was killed by a protection block.")
			end
		end
	end

	-- flip player when protection violated
	if protector.flip then

		-- yaw + 180°
		local yaw = player:get_look_yaw() + math.pi

		if yaw > 2 * math.pi then
			yaw = yaw - 2 * math.pi
		end

		player:set_look_horizontal(yaw)

		-- Invert pitch.
		player:set_look_vertical(-player:get_look_vertical())

		-- if digging below player, move up to avoid falling through hole
		local pla_pos = player:get_pos()

		if pos.y < pla_pos.y then

			player:setpos({
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
					obj:setvelocity({x = math.random(-5, 5), y = 5, z = math.random(-5, 5)})
				end
			end)

		end
	end
	--]]
end

protector.old_is_protected = minetest.is_protected

function minetest.is_protected(pos, digger, nodename)
	digger = digger or "" -- nil check

	-- Allow protection to be temporarily disabled for API purposes.
	if not PROTECTION_ENABLED then
		return protector.old_is_protected(pos, digger)
	end

	if not protector.can_dig(protector.radius, 1, "", pos, digger, false, 1) then
		-- Slight delay to separate call stacks; hopefully this fixes the rare recursion/crash issue.
		-- Update: it seems to have fixed the rare crashes, there have been no more related to this since some months.
		minetest.after(0, function()
			protector.punish_player(pos, digger)
		end)
		return true
	end

	return protector.old_is_protected(pos, digger)
end

-- Called when protection should be checked, but no retaliation should be carried out.
function minetest.test_protection(pos, digger)
	digger = digger or "" -- nil check

	-- Allow protection to be temporarily disabled for API purposes.
	if not PROTECTION_ENABLED then
		return protector.old_is_protected(pos, digger)
	end

	-- Don't give chat messages. Infolevel 0.
	if not protector.can_dig(protector.radius, 1, "", pos, digger, false, 0) then
		return true
	end

	return protector.old_is_protected(pos, digger)
end

-- Make sure protection block doesn't overlap another protector's area

function protector.check_overlap(itemstack, placer, pt)
	if pt.type ~= "node" then
		return itemstack
	end
	local pname = placer:get_player_name()
	local prot_type = itemstack:get_name()

	if not protector.can_dig(protector.radius, 2, prot_type, pt.above, pname, true, 3) then
		minetest.chat_send_player(pname, "# Server: Protection bounds overlap into another person's area claim.")
		return
	end

	local pos = {x=pt.under.x, y=pt.under.y, z=pt.under.z}
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
				minetest.chat_send_player(pname, "# Server: You cannot claim this area while someone's fresh corpse is nearby!")
				return
			end
			local oldowner = meta:get_string("oldowner") or ""
			if oldowner ~= "" and oldowner ~= "server" then
				minetest.chat_send_player(pname, "# Server: You must remove all corpses before you can claim this area.")
				return
			end
		end
	end

	return minetest.item_place(itemstack, placer, pt)
end

--= Protection Lock

minetest.register_node("protector:protect", {
	description = "Advanced Protection Lock\nArea Protected: 11x11x11",
	drawtype = "nodebox",
	tiles = {
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png",
		"moreblocks_circle_stone_bricks.png^protector_logo.png"
	},
	sounds = default.node_sound_stone_defaults(),
	groups = {
    level = 1, dig_immediate = 2,
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  },
	is_ground_content = false,
	paramtype = "light",
	movement_speed_multiplier = default.NORM_SPEED,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)

		local pname = placer:get_player_name() or ""
		local dname = rename.gpn(pname)
		meta:set_string("owner", pname)
		meta:set_string("rename", dname)
		meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		meta:set_string("members", "")

		-- Notify nearby players.
		protector.update_nearby_players(pos)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name() or ""

		if meta and protector.can_dig(1, 1, "protector:protect", pos, name, true, 1) then
			player_pos[name] = pos
			minetest.show_formspec(name, "protector:node", protector.generate_formspec(meta))
		end
	end,

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local cname = meta:get_string("rename")
		local dname = rename.gpn(owner)
		-- Check if the owner's current alias has changed.
		if cname ~= dname then
			meta:set_string("rename", dname)
			meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		end
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)
	
		return protector.remove_area_display(pos)
	end,
})

minetest.register_node("protector:protect3", {
	description = "Protection Lock\nArea Protected: 7x7x7",
	drawtype = "nodebox",
	tiles = {"cityblock.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {
    level = 1, dig_immediate = 2,
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  },
	is_ground_content = false,
	paramtype = "light",
	movement_speed_multiplier = default.NORM_SPEED,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	node_box = {
		type = "fixed",
		fixed = {
			{-0.5 ,-0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)

		local pname = placer:get_player_name() or ""
		local dname = rename.gpn(pname)
		meta:set_string("owner", pname)
		meta:set_string("rename", dname)
		meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		meta:set_string("members", "")

		-- Notify nearby players.
		protector.update_nearby_players(pos)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect3", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	-- This protector does not have a formspec, no on_rightclick defined.

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display_small")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect3", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local cname = meta:get_string("rename")
		local dname = rename.gpn(owner)
		-- Check if the owner's current alias has changed.
		if cname ~= dname then
			meta:set_string("rename", dname)
			meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		end
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)
	
		return protector.remove_area_display(pos)
	end,
})


--= Protection Logo

minetest.register_node("protector:protect2", {
	description = "Advanced Protection Logo\nArea Protected: 11x11x11",
	tiles = {"protector_logo.png"},
	wield_image = "protector_logo.png",
	inventory_image = "protector_logo.png",
	sounds = default.node_sound_stone_defaults(),
	groups = {
    level = 1, dig_immediate = 2,
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  },
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)

		local pname = placer:get_player_name() or ""
		local dname = rename.gpn(pname)
		meta:set_string("owner", pname)
		meta:set_string("rename", dname)
		meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		meta:set_string("members", "")

		-- Notify nearby players.
		protector.update_nearby_players(pos)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect2", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name() or ""

		if meta and protector.can_dig(1, 1, "protector:protect2", pos, name, true, 1) then
			player_pos[name] = pos
			minetest.show_formspec(name, "protector:node", protector.generate_formspec(meta))
		end
	end,

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect2", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local cname = meta:get_string("rename")
		local dname = rename.gpn(owner)
		-- Check if the owner's current alias has changed.
		if cname ~= dname then
			meta:set_string("rename", dname)
			meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		end
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)
	
		return protector.remove_area_display(pos)
	end,
})

minetest.register_node("protector:protect4", {
	description = "Protection Logo\nArea Protected: 7x7x7",
	tiles = {"protector_lock.png"},
	wield_image = "protector_lock.png",
	inventory_image = "protector_lock.png",
	sounds = default.node_sound_stone_defaults(),
	groups = {
    level = 1, dig_immediate = 2,
    immovable = 1, -- No pistons, no nothing.
		protector = 1,
  },
	paramtype = 'light',
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,

	-- Protectors shall not emit light. By MustTest
	--light_source = 4,

	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	on_place = protector.check_overlap,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)

		local pname = placer:get_player_name() or ""
		local dname = rename.gpn(pname)
		meta:set_string("owner", pname)
		meta:set_string("rename", dname)
		meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		meta:set_string("members", "")

		-- Notify nearby players.
		protector.update_nearby_players(pos)
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		protector.can_dig(protector.radius, 1, "protector:protect4", pointed_thing.under, user:get_player_name(), false, 2)
	end,

	-- This protector does not have a formspec, no on_rightclick defined.

	on_punch = function(pos, node, puncher)
		if minetest.test_protection(pos, puncher:get_player_name()) then
			return
		end

		protector.toggle_area_display(pos, "protector:display_small")
	end,

	can_dig = function(pos, player)
		return player and protector.can_dig(1, 1, "protector:protect4", pos, player:get_player_name(), true, 1)
	end,

	-- TNT-proof.
	on_blast = function() end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local cname = meta:get_string("rename")
		local dname = rename.gpn(owner)
		-- Check if the owner's current alias has changed.
		if cname ~= dname then
			meta:set_string("rename", dname)
			meta:set_string("infotext", "Protection (Owned by <" .. dname .. ">!)")
		end
	end,

	on_destruct = function(pos)
		-- Notify nearby players.
		minetest.after(0, protector.update_nearby_players, pos)
	
		return protector.remove_area_display(pos)
	end,
})

-- If name entered or button press

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "protector:node" then
		return
	end

	local pname = player:get_player_name() or "" -- Nil check.
	local pos = player_pos[pname] -- Context should have been created during on_rightclick. CSM protection.

	-- Localize field member.
	local add_member_input = fields.protector_add_member

	-- Reset formspec until close button pressed.
	if (fields.close_me or fields.quit)
	and (not add_member_input or add_member_input == "") then
		player_pos[pname] = nil
		return true
	end

	if not pos then
		return true
	end

	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)

	-- Meta nil check.
	if not meta then
		return true
	end

	-- Are we actually working on a protection node? (CSM protection.)
	if node.name ~= "protector:protect"
	and node.name ~= "protector:protect2"
	and node.name ~= "protector:protect3"
	and node.name ~= "protector:protect4" then
		player_pos[pname] = nil
		return true
	end

	-- Only advanced protectors support member names.
	if node.name == "protector:protect3" or node.name == "protector:protect4" then
		minetest.chat_send_player(pname, "# Server: Sharing feature not supported by basic protectors!")
		return true
	end

	-- Do not permit caller to modify a protector they do not own.
	if not protector.can_dig(1, 1, node.name, pos, pname, true, 1) then
		return true
	end

	if add_member_input then
		for _, i in pairs(add_member_input:split(" ")) do
			protector.add_member(meta, i)
		end
	end

	for field, value in pairs(fields) do
		if string.sub(field, 0, string.len("protector_del_member_")) == "protector_del_member_" then
			protector.del_member(meta, string.sub(field,string.len("protector_del_member_") + 1))
		end
	end

	-- Clear formspec context.
	minetest.show_formspec(pname, formname, protector.generate_formspec(meta))
	return true
end)

-- Display entity shown when protector node is punched

minetest.register_entity("protector:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"protector:display_node"},
	timer = 0,
	--glow = 255, -- Does not work.

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > protector.display_time then
			self.object:remove()
		end
	end,

	on_blast = function(self, damage)
		return false, false, {}
	end,
})

minetest.register_entity("protector:display_small", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"protector:display_node_small"},
	timer = 0,
	--glow = 13, -- Does not work.

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > protector.display_time then
			self.object:remove()
		end
	end,

	on_blast = function(self, damage)
		return false, false, {}
	end,
})

-- Display-zone node, Do NOT place the display as a node,
-- it is made to be used as an entity (see above)

do
	local x = protector.radius
	minetest.register_node("protector:display_node", {
		tiles = {"protector_display.png"},
		use_texture_alpha = true,
		walkable = false,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				-- sides
				{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
				{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
				-- top
				{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
				-- bottom
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
				-- middle (surround protector)
				{-.55,-.55,-.55, .55,.55,.55},
			},
		},
		selection_box = {
			type = "regular",
		},
		paramtype = "light",
		groups = {level = 1, dig_immediate = 3, not_in_creative_inventory = 1},
		drop = "",
	})
end



do
	local x = protector.radius_small
	minetest.register_node("protector:display_node_small", {
		tiles = {"protector_display.png"},
		use_texture_alpha = true,
		walkable = false,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				-- sides
				{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
				{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
				-- top
				{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
				-- bottom
				{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
				-- middle (surround protector)
				{-.55,-.55,-.55, .55,.55,.55},
			},
		},
		selection_box = {
			type = "regular",
		},
		paramtype = "light",
		groups = {level = 1, dig_immediate = 3, not_in_creative_inventory = 1},
		drop = "",
	})
end



function protector.remove_area_display(pos)
	local ents = minetest.get_objects_inside_radius(pos, 0.5)
	for k, n in ipairs(ents) do
		if not n:is_player() and n:get_luaentity() then
			local name = n:get_luaentity().name or ""
			if name == "protector:display" or name == "protector:display_small" then
				n:remove()
			end
		end
	end
end

function protector.toggle_area_display(pos, entity)
	local got_any = false
	local ents = minetest.get_objects_inside_radius(pos, 0.5)
	for k, n in ipairs(ents) do
		if not n:is_player() and n:get_luaentity() then
			local name = n:get_luaentity().name or ""
			if name == "protector:display" or name == "protector:display_small" then
				n:remove()
				got_any = true
			end
		end
	end
	if not got_any then
		minetest.add_entity(pos, entity)
	end
end

dofile(protector.modpath .. "/crafts.lua")

-- This file is reloadable.
bones = bones or {}

-- Contains the positions of last known player deaths, indexed by player name.
bones.last_known_death_locations = bones.last_known_death_locations or {}

local get_public_time = function()
  return os.date("!%Y/%m/%d, %H:%M:%S UTC")
end

local share_bones_time = tonumber(minetest.setting_get("share_bones_time")) or 1200
local share_bones_time_early = tonumber(minetest.setting_get("share_bones_time_early")) or share_bones_time / 4



local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
    
	-- Don't let dead players pick bones.
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then return false end
	if player:get_hp() <= 0 then return false end
    
	if owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
end



local function may_replace(pos, player)
	local nn = minetest.get_node(pos).name
	local ndef = minetest.reg_ns_nodes[nn]

	-- If the node is unknown, we return false.
	if not ndef then
		return false
	end

	local pname = player and player:get_player_name() or ""
	local protected = minetest.test_protection(pos, pname)

	-- Allow replacing air and (non-walkable) liquids.
	if nn == "air" or (ndef.liquidtype ~= "none" and not ndef.walkable) then
		return true
	end

	-- Don't replace filled chests and other nodes that don't allow it.
	-- Includes bedrock, admin TNT, etc.
	local can_dig = ndef.can_dig
	if can_dig and not can_dig(pos, player) then
		return false
	end

	-- Default to each nodes buildable_to; if a placed block would replace it, why
	-- shouldn't bones? Flowers being squished by bones are more realistical than
	-- a squished stone, too. Exception are of course any protected buildable_to.
	return ndef.buildable_to and not protected
end



local drop = function(pos, itemstack)
	local obj = minetest.add_item(pos, itemstack:take_item(itemstack:get_count()))
	if obj then
		obj:setvelocity({
			x = math.random(-10, 10) / 9,
			y = 5,
			z = math.random(-10, 10) / 9,
		})
	end
end



local player_inventory_empty = function(inv, name)
	local list = inv:get_list(name)
	-- Nil check.
	if not list then
		-- Could not get list, list does not exist.
		-- This is true in the case of bags.
		return true -- Inventory list doesn't exist.
	end
	for i = 1, #list do
		local stack = list[i]
		if not stack:is_empty() then
			if not passport.is_passport(stack:get_name()) then
				return false -- Not empty.
			end
		end
	end
	return true -- Inventory list is empty.
end



local find_ground = function(pos, player)
	local p = {x=pos.x, y=pos.y, z=pos.z}
  local count = 0

	local cr1 = may_replace({x=p.x, y=p.y, z=p.z}, player)
	local cr2 = may_replace({x=p.x, y=p.y-1, z=p.z}, player)

  while (not (cr1 and not cr2)) or (cr1 and cr2) do
    p.y = p.y - 1

    count = count + 1
    if count > 10 then return pos end

		cr1 = may_replace({x=p.x, y=p.y, z=p.z}, player)
		cr2 = may_replace({x=p.x, y=p.y-1, z=p.z}, player)
  end

	-- Return position, if we can replace to it, but not to the node under it.
	if cr1 and not cr2 then
		return p
	end

  return pos
end



local function find_suitable_bone_location(pos, player)
	-- Locate position directly above ground level.
  local air = find_ground(pos, player)

	-- Check whether the initial location is suitable.
	if not may_replace(air, player) then
		air = nil
	end

	-- Is the initial location not suitable? Try to locate a suitable location on
	-- a horizontal plane from the actual death location.
	if not air then
		local sidepos = {
			{x=pos.x, y=pos.y, z=pos.z},
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+1},
			{x=pos.x, y=pos.y, z=pos.z-1},
		}
		for k, v in ipairs(sidepos) do
			if may_replace(v, player) then
				air = v
				break
			end
		end
	end

	-- Didn't find a replaceable node that way, try a short-range search for air.
	if not air then
		air = minetest.find_node_near(pos, 2, {"air"})
	end

	-- Still didn't find air? Try a longer range search,
	-- and include liquid/fire/etc nodes that player can die in.
	if not air then
		-- If we couldn't find air, fallback to finding a location in these
		-- substances. Search 1 meter farther than at first.
		air = minetest.find_node_near(pos, 3, {
			"air",
			"default:water_source",
			"default:water_flowing",
			"default:river_water_source",
			"default:river_water_flowing",
			"default:lava_source",
			"default:lava_flowing",
			"lbrim:lava_source",
			"lbrim:lava_flowing",
			"group:gas",
			"rackstone:nether_grit",
			"rackstone:void",
			"fire:basic_flame",
		})
	end

	-- If we found air, try to make sure we found a replaceable node directly
	-- above ground.
	if air then
		air = find_ground(air, player)
	end

	-- By now, we have either found air or nothing.
	return air -- May be nil.
end



-- This function may be called from mods to dump player bones EXACTLY as if the
-- player had died, including any side-effects. The sole exception is that the
-- player's health is not actually changed. You might need to update a few other
-- datums too, to get exactly the right result.
function bones.dump_bones(pname)
	local player = minetest.get_player_by_name(pname)
	if player then
		bones.on_dieplayer(player)
	end
end



bones.on_dieplayer = function(player)
	local bones_mode = "bones"
	local player_inv = player:get_inventory()
  local pname = player:get_player_name()

	-- If player died while attached to cart/boat/etc, they must be detached.
	default.detach_player_if_attached(player)

	-- Record position of player on death.
	-- This is needed because this information is lost on respawn.
	-- We must record this info *always*, even if player does not leave bones.
	bones.last_known_death_locations[pname] = utility.get_foot_pos(player:get_pos())

	-- Record all player deaths, whether they leave bones or not.
	minetest.log("action", "player <" .. pname .. "> died @ " .. minetest.pos_to_string(player:get_pos()))

	-- Death sound.
	coresounds.play_death_sound(player, pname)

	-- Notify of death.
	chat_colorize.notify_death(pname)
	jail.notify_player_death(player)

	-- Don't make bones if player doesn't have anything.
	-- This also means that player won't lose XP. Keep this, it is a feature!
	if player_inventory_empty(player_inv, "main") and
		player_inventory_empty(player_inv, "craft") and
		player_inventory_empty(player_inv, "bag1contents") and
		player_inventory_empty(player_inv, "bag2contents") and
		player_inventory_empty(player_inv, "bag3contents") and
		player_inventory_empty(player_inv, "bag4contents") and
		player_inventory_empty(player_inv, "bag1") and
		player_inventory_empty(player_inv, "bag2") and
		player_inventory_empty(player_inv, "bag3") and
		player_inventory_empty(player_inv, "bag4") and
		player_inventory_empty(player_inv, "armor") then
		return
	end

	local pos = vector.round(utility.get_middle_pos(player:get_pos()))

	-- Check if it's possible to place bones, if not find space near player.
	if bones_mode == "bones" then
		local boneloc = find_suitable_bone_location(pos, player)
		if boneloc then
			pos = boneloc
		else
			bones_mode = "drop"
		end
	end

	if not rc.is_valid_realm_pos(pos) then
		bones_mode = "drop"
	end

	-- If player died and ought to leave bones because they have stuff in their
	-- inventory, BUT we cannot actually place bones (no suitable location found),
	-- then player doesn't lose their items. This is a safety feature since it is
	-- possible to die in locations where bones cannot physically be placed.
	-- E.g., player dies in a 1x1 mineshaft occupied by ladder nodes.
	if bones_mode ~= "bones" then
		-- Cannot create bones, therefore we don't modify player inventories.
		minetest.log("action", "Player <" .. pname .. "> died @ " .. minetest.pos_to_string(pos) .. ", but cannot create bones!")

		-- Reduce player's mining XP without storing it anywhere.
		-- Prevents player from being able to use this as an exploit.
		-- Death should always have a cost!
		local xp_amount = xp.get_xp(pname, "digxp")
		xp_amount = (xp_amount / 3) * 2
		xp.set_xp(pname, "digxp", xp_amount)
		hud_clock.update_xp(pname)

		return
	end

	-- Halve player XP!
	local xp_amount = xp.get_xp(pname, "digxp")
	xp_amount = xp_amount/2
	local xp_for_bones = (xp_amount/3)*2
	xp.set_xp(pname, "digxp", xp_amount)

	-- Note: portal sickness only removed if player would leave bones.
	portal_sickness.on_die_player(pname)

	-- These inventories are always cleared.
	player_inv:set_list("craftpreview", {})
	player_inv:set_list("craftresult", {})

	-- Clear the virtual bags inventories.
	do
		local bags_inv = minetest.get_inventory({type="detached", name=pname .. "_bags"})
		bags_inv:set_list("bag1", {})
		bags_inv:set_list("bag2", {})
		bags_inv:set_list("bag3", {})
		bags_inv:set_list("bag4", {})
	end

	-- The player can die while holding something. Remove it.
  minetest.after(0.1, function()
    local ply = minetest.get_player_by_name(pname)
    if not ply then return end
    local inv = ply:get_inventory()
    if not inv then return end
    if inv:is_empty("hand") then return end
    inv:set_list("hand", {}) -- Fixes a bug if the player dies while holding something.
  end)


	-- Preload map just in case.
	local minp = vector.add(pos, -16)
	local maxp = vector.add(pos, 16)
	utility.ensure_map_loaded(minp, maxp)
    
	local param2 = minetest.dir_to_facedir(player:get_look_dir())
	minetest.add_node(pos, {name = "bones:bones", param2 = param2})

	local meta = minetest.get_meta(pos)
	meta:set_float("digxp", xp_for_bones)
	meta:set_string("diedate", get_public_time())
	local inv = meta:get_inventory()
	inv:set_size("main", 200) -- Enuf space for everything!
	-- Keep track of how many stacks are stored in bones.
	local location = minetest.pos_to_string(pos)
	local num_stacks = 0

	-- Note: clear player inventory slot-by-slot to avoid clobbering PoC/KoC items.
	-- Empty the player's main inv. We must not to clobber any passports.
	do
		local list = player_inv:get_list("main")
		if list then -- Nil check necessary.
			for i = 1, #list do
				local stack = list[i]
				if not passport.is_passport(stack:get_name()) then
					if stack:get_count() > 0 and inv:room_for_item("main", stack) then
						inv:add_item("main", stack)
						minetest.log("action", "Put " .. stack:to_string() .. " in bones @ " .. location .. ".")
						num_stacks = num_stacks + 1

						-- Stack was added to bones inventory, remove it from list.
						list[i]:set_count(0)
						list[i]:set_name("")
					else
						drop(pos, stack)
					end
				end
			end
			player_inv:set_list("main", list)
		end
	end

	-- Empty the player's craft-grid. Passports are not preserved, here.
	do
		local list = player_inv:get_list("craft")
		if list then -- Nil check necessary.
			for i = 1, #list do
				local stack = list[i]
				if stack:get_count() > 0 and inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					minetest.log("action", "Put " .. stack:to_string() .. " in bones @ " .. location .. ".")
					num_stacks = num_stacks + 1
				else
					drop(pos, stack)
				end
			end
			player_inv:set_list("craft", {})
		end
	end

	-- Armor goes into bones after main and crafting grid items.
  armor.on_dieplayer(player, pos)

	-- Empty the bag slots. Passports are not preserved, here. (It should not be possible to store a passport in here, anyway.)
	for j = 1, 4, 1 do
		local bag = "bag" .. j
		local list = player_inv:get_list(bag)
		if list then -- Nil check necessary.
			for i = 1, #list do
				local stack = list[i]
				if stack:get_count() > 0 and inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					minetest.log("action", "Put " .. stack:to_string() .. " in bones @ " .. location .. ".")
					num_stacks = num_stacks + 1
				else
					drop(pos, stack)
				end
			end
			player_inv:set_list(bag, {})
		end
	end

	-- Empty the bag inventories. Passports are not preserved, here.
	for j = 1, 4, 1 do
		local bag = "bag" .. j .. "contents"
		local list = player_inv:get_list(bag)
		if list then -- Nil check necessary.
			for i = 1, #list do
				local stack = list[i]
				if stack:get_count() > 0 and inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					minetest.log("action", "Put " .. stack:to_string() .. " in bones @ " .. location .. ".")
					num_stacks = num_stacks + 1
				else
					drop(pos, stack)
				end
			end
			player_inv:set_list(bag, {})
		end
	end

	-- We use on_rightclick instead.
	--meta:set_string("formspec", bones_formspec)
	meta:set_string("owner", pname)
	meta:set_int("numstacks", num_stacks)

	-- Notify the mapping code it needs to recalculate the mapkit cache.
	minetest.after(0, function()
		map.clear_inventory_info(pname)
	end)

	if share_bones_time ~= 0 then
		meta:set_string("infotext",
			"Unfortunate <" .. rename.gpn(pname) ..
			">'s Undecayed Bones\nMineral XP: " .. string.format("%.2f", xp_for_bones) .. "\n" ..
			"Died On " .. meta:get_string("diedate"))

		if share_bones_time_early == 0 or not minetest.test_protection(pos, "") then
			meta:set_int("time", 0)
		else
			meta:set_int("time", (share_bones_time - share_bones_time_early))
		end

		minetest.get_node_timer(pos):start(10)
	else
		meta:set_string("infotext",
			"Unfortunate <" .. rename.gpn(pname) ..
			">'s Bones\nMineral XP: " .. string.format("%.2f", xp_for_bones) .. "\n" ..
			"Died On " .. meta:get_string("diedate"))
	end
  
	hud_clock.update_xp(pname)

  if bones_mode == "bones" then
    if bones and bones.do_messages then
      bones.do_messages(pos, pname, num_stacks)
    end
		if minetest.get_node(pos).name == "bones:bones" then
			minetest.log("action", "Successfully spawned bones @ " .. minetest.pos_to_string(pos) .. "!")
		end
  end

	-- Check if bones still exist after 1 second.
	minetest.after(1, function()
		local name = minetest.get_node(pos).name
		if name == "bones:bones" then
			minetest.log("action", "Bones exist @ " .. minetest.pos_to_string(pos) .. " after 1 second check!")
		elseif name == "ignore" then
			minetest.log("action", "Got ignore @ " .. minetest.pos_to_string(pos) .. " after 1 second bone check!")
		else
			minetest.log("action", "Got " .. name .. " @ " .. minetest.pos_to_string(pos) .. " after 1 second bone check!")
		end
	end)
end



bones.can_dig = function(pos, player)
	local inv = minetest.get_meta(pos):get_inventory()
	local name = ""
	if player then
		name = player:get_player_name()
	end
	return is_owner(pos, name) and inv:is_empty("main")
end



bones.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	if is_owner(pos, player:get_player_name()) then
		return count
	end
	return 0
end



bones.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
	minetest.chat_send_player(player:get_player_name(), "# Server: Bones are not a place to store items!")
	return 0
end



bones.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
	-- Prevent picking bones right after respawn, before player is repositioned.
	if bones.nohack.on_hackdetect(player) then
		local pname = player:get_player_name()
		minetest.chat_send_player(pname, "# Server: Wait a bit before taking from bones.")
		return 0
	end

	if is_owner(pos, player:get_player_name()) then
		return stack:get_count()
	end

	return 0
end



bones.on_metadata_inventory_take = function(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	local meta = minetest.get_meta(pos)
	if meta:get_inventory():is_empty("main") then
		bones.reward_xp(meta, pname)
		bones.do_grab_bones_message(pname, pos, meta)

		minetest.after(0, function() minetest.close_formspec(pname, "bones:main") end)
		minetest.log("action", "Player " .. pname .. " took all from bones @ " .. minetest.pos_to_string(pos) .. ". Removing bones.")
		minetest.remove_node(pos)
	end
end



bones.reward_xp = function(meta, pname)
	-- Give XP stored in bones to player.
	-- But only if player removed the bones!
	local digxp = meta:get_float("digxp")
	local current_xp = xp.get_xp(pname, "digxp")
	current_xp = current_xp + digxp
	if current_xp > xp.digxp_max then
		current_xp = xp.digxp_max
	end
	xp.set_xp(pname, "digxp", current_xp)
	hud_clock.update_xp(pname)
	meta:set_float("digxp", 0)
end



bones.on_punch = function(pos, node, player)
		-- Fix stopped timers.
		minetest.get_node_timer(pos):start(10)

		local pname = player:get_player_name()
    if not is_owner(pos, pname) then
			return
    end

		if sheriff.player_punished(pname) then
			if sheriff.punish_probability(pname) then
				sheriff.punish_player(pname)
				return
			end
		end

		-- Prevent picking bones right after respawn, before player is repositioned.
		if bones.nohack.on_hackdetect(player) then
			minetest.chat_send_player(pname, "# Server: Wait a bit before picking bones.")
			return
		end

		-- Dead players cannot pick bones.
		if player:get_hp() <= 0 then
			return
		end

		local meta = minetest.get_meta(pos)

		-- Bones that are neither fresh nor old aren't 'punchable'.
    if meta:get_string("infotext") == "" then
			return
    end

    local inv = meta:get_inventory()
    local player_inv = player:get_inventory()
    local has_space = true
		local added_map = false

    for i = 1, inv:get_size("main") do
			local stk = inv:get_stack("main", i)
			if player_inv:room_for_item("main", stk) then
				inv:set_stack("main", i, nil)
				player_inv:add_item("main", stk)

				-- Notify if a mapping kit was added.
				if map.is_mapping_kit(stk:get_name()) then
					added_map = true
				end
			else
				has_space = false
				break
			end
    end

		-- Notify if a mapping kit was added.
		if added_map then
			map.update_inventory_info(pname)
		end

    -- remove bones if player emptied them
    if has_space then
			-- Give player the bones.
			if player_inv:room_for_item("main", {name = "bones:bones_type2"}) then
					player_inv:add_item("main", {name = "bones:bones_type2"})
			else
					minetest.add_item(pos,"bones:bones_type2")
			end

			bones.reward_xp(meta, pname)
			bones.do_grab_bones_message(pname, pos, meta)

			-- Remove the bones from the world.
			minetest.log("action", "Bones @ " .. minetest.pos_to_string(pos) .. " punched by " .. pname .. ". Removing bones.")
			minetest.remove_node(pos)
    end
end



bones.do_grab_bones_message = function(pname, pos, meta)
	-- Send chat messages about bones retrieval.
	-- Don't spam the chatstream.
	if not bones.players[pname] then
		local public = true
		if player_labels.query_nametag_onoff(pname) == false then
			public = false
		end

		local numstacks = meta:get_int("numstacks")
		local stacks = "stacks"
		if numstacks == 1 then
			stacks = "stack"
		elseif numstacks == 0 then
			numstacks = "an unknown number of"
		end
		local boneowner = meta:get_string("owner")
		if boneowner == "" then
			boneowner = meta:get_string("oldowner")
		end
		local ownerstring = "<" .. rename.gpn(boneowner) .. ">'s"
		if pname == boneowner then
			local sex = skins.get_gender_strings(pname)
			ownerstring = sex.his .. " own"
		end
		if boneowner == "" then
			ownerstring = "someone's"
		end
		local agestring = "fresh"
		if meta:get_string("owner") == "" then
			agestring = "old"
		end

		if public then
			minetest.chat_send_all(
				"# Server: Player <" ..
				rename.gpn(pname) ..
				"> claimed " .. ownerstring .. " " .. agestring .. " bones at " ..
				rc.pos_to_namestr(vector.round(pos)) ..
				" with " .. numstacks .. " " .. stacks .. ".")
		else
			minetest.chat_send_all(
				"# Server: Someone claimed " .. agestring .. " bones with " .. numstacks ..
				" " .. stacks .. ".")
		end

		bones.players[pname] = true
		minetest.after(60, bones.release_player, pname)
	end
end



bones.on_timer = function(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local digxp = string.format("%.2f", meta:get_float("digxp"))
	local time = meta:get_int("time") + elapsed
	if time >= share_bones_time then
		-- Function may have been called twice or more. This prevents an issue.
		if meta:get_string("owner") == "" then
			return
		end

		-- Bones will NOT decay as long as cheaters are present on the server. This
		-- prevents cheaters from being able to steal other player's stuff. If the
		-- player that died is themself a cheater, they don't get this protection.
		if not sheriff.player_punished(meta:get_string("owner")) then
			local cheaters_are_present = false
			local all_players = minetest.get_connected_players()
			for k, v in ipairs(all_players) do
				if sheriff.player_punished(v:get_player_name()) then
					cheaters_are_present = true
					break
				end
			end
			if cheaters_are_present then
				local timer = minetest.get_node_timer(pos)
				timer:start(60*math.random(10, 60))
				return
			end
		end

		minetest.log("action", "Fresh bones @ " .. minetest.pos_to_string(pos) .. " decay into old bones.")
		local diedate = meta:get_string("diedate")
		if diedate == "" then
			diedate = "An Unknown Date"
		end
		meta:set_string("infotext",
			"Unfortunate <" .. rename.gpn(meta:get_string("owner")) ..
			">'s Old Bones\nMineral XP: " .. digxp .. "\n" ..
			"Died On " .. diedate)
		meta:set_string("oldowner", meta:get_string("owner"))
		meta:set_string("owner", "")
	else
		meta:set_int("time", time)
		return true
	end
end



bones.on_blast = function(pos)
	minetest.log("action", "Bones @ " .. minetest.pos_to_string(pos) .. " experienced explosion blast.")
end



bones.on_destruct = function(pos)
	minetest.log("action", "Bones @ " .. minetest.pos_to_string(pos) .. " destructor called. Bones removed.")

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	if inv:is_empty("main") then
		return
	end

	-- If the inventory is not empty, we must respawn the bones.
	-- This is a workaround for a bug that just won't go away.
	local node = minetest.get_node(pos)
	local list = inv:get_list("main")
	local infotext = meta:get_string("infotext")
	local owner = meta:get_string("owner")
	local oldowner = meta:get_string("oldowner")
	local numstacks = meta:get_int("numstacks")
	local time = meta:get_int("time")
	local digxp = meta:get_float("digxp")
	local diedate = meta:get_string("diedate")

	minetest.after(0, function()
		minetest.log("action", "Bones @ " .. minetest.pos_to_string(pos) .. " were not empty! Attempting to restore bones.")
		minetest.set_node(pos, {name="bones:bones", param2=node.param2})
		local meta2 = minetest.get_meta(pos)
		local inv2 = meta2:get_inventory()
		inv2:set_size("main", 200)
		inv2:set_list("main", list)
		meta2:set_string("infotext", infotext)
		meta2:set_string("owner", owner)
		meta2:set_string("oldowner", oldowner)
		meta2:set_int("numstacks", numstacks)
		meta2:set_int("time", time)
		meta2:set_float("digxp", digxp)
		meta2:set_string("diedate", diedate)
		if time < share_bones_time then
			minetest.get_node_timer(pos):start(10)
		end
	end)
end



-- Show bones inventory.
function bones.on_rightclick(pos, node, clicker, itemstack, pt)
	local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") == "" then
		return
	end

	-- Put all inventory contents toward the front of the list.
	local inv = meta:get_inventory()
	local list = inv:get_list("main") or {}
	local tmp = {}
	for index, stack in ipairs(list) do
		if not stack:is_empty() then
			tmp[#tmp+1] = stack
		end
	end
	inv:set_list("main", {})
	for index, stack in ipairs(tmp) do
		if inv:room_for_item("main", stack) then
			inv:add_item("main", stack)
		else
			minetest.add_item(pos, stack)
		end
	end

	local pname = clicker:get_player_name()
	minetest.log("action", "Player " .. pname .. " opens bones @ " .. minetest.pos_to_string(pos) .. ".")

	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,9]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,4.85)

	minetest.show_formspec(pname, "bones:main", formspec)
end



function bones.kill_bully_on_leaveplayer(pref, timeout)
end




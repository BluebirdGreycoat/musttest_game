
-- This file is designed to be reloadable.

teleports = teleports or {}
teleports.teleports = teleports.teleports or {}
teleports.min_range = 250
teleports.datafile = minetest.get_worldpath() .. "/teleports.txt"



local nyanbow = "nyancat:nyancat_rainbow"

-- Table of blocks which can be used to super-charge a teleport. Each block has a specific charge value.
teleports.charge_blocks = {
  ["default:diamondblock"]    = {charge=14   },
  ["default:mese"]            = {charge=4    },
  ["default:steelblock"]      = {charge=1    },
  ["default:copperblock"]     = {charge=1.5  },
  ["default:bronzeblock"]     = {charge=1.8  },
  ["default:goldblock"]       = {charge=2    },
  ["moreores:silver_block"]   = {charge=2    },
  ["moreores:tin_block"]      = {charge=1.5  },
  ["moreores:mithril_block"]  = {charge=24   },
  ["chromium:block"]          = {charge=0.9  },
  ["zinc:block"]              = {charge=1.8  },
  ["lead:block"]              = {charge=0.4  },
  
  ["akalin:block"]            = {charge=0.9  },
  ["alatro:block"]            = {charge=0.7  },
  ["arol:block"]              = {charge=0.5  },
  ["talinite:block"]          = {charge=1.1  },
}



teleports.is_nyanbow_teleport = function(pos)
	local positions = {
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z-1},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x-1, y=pos.y, z=pos.z-1},
		{x=pos.x+1, y=pos.y, z=pos.z+1},
		{x=pos.x-1, y=pos.y, z=pos.z+1},
		{x=pos.x+1, y=pos.y, z=pos.z-1},
	}

	local bows = 0
	for k, v in ipairs(positions) do
		local n = minetest.get_node(v).name
		if n == nyanbow then
			bows = bows + 1
		end
	end

	return (bows == 8)
end



teleports.save = function()
    local datastring = xban.serialize(teleports.teleports)
    if not datastring then
        return
    end
    local file, err = io.open(teleports.datafile, "w")
    if err then
        return
    end
    file:write(datastring)
    file:close()
end



teleports.load = function()
    local file, err = io.open(teleports.datafile, "r")
    if err then
        teleports.teleports = {}
        return
    end
    teleports.teleports = minetest.deserialize(file:read("*all"))
    if type(teleports.teleports) ~= "table" then
        teleports.teleports = {}
    end
    file:close()
end



teleports.clear_area = function(blockpos, action, calls_remaining, param)
    if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
        return
    end
    
    for x = param.minp.x, param.maxp.x, 1 do
        for y = param.minp.y, param.maxp.y, 1 do
            for z = param.minp.z, param.maxp.z, 1 do
                local pos = {x=x, y=y, z=z}
                local node = minetest.get_node(pos)
                if node.name ~= "ignore" then
                    if node.name ~= "air" and node.name ~= "bones:bones" then
                        minetest.remove_node(pos)
                    end
                end
            end
        end
    end
end



teleports.teleport_player = function(player, origin_pos, teleport_pos, target)
	if not player or not player:is_player() then
		return
	end
	local pname = player:get_player_name()

	local p = vector.round(teleport_pos)
	local minp = {x=p.x-1, y=p.y+1, z=p.z-1}
	local maxp = {x=p.x+1, y=p.y+3, z=p.z+1}

	-- Kill players standing on target teleport pad.
	local dead_players = minetest.get_objects_inside_radius({x=teleport_pos.x, y=teleport_pos.y+1, z=teleport_pos.z}, 2)
	for k, v in ipairs(dead_players) do
			if v and v:is_player() then
				if not gdac.player_is_admin(v) then -- Don't kill admin.
					-- Only if player isn't already dead.
					if v:get_hp() > 0 then
						-- If there's a player here already the map must be loaded, so we
						-- can put fire where they're standing no problem.
						local dp = vector.round(utility.get_foot_pos(v:get_pos()))
						local node = minetest.get_node(dp)
						if node.name == "air" then
							minetest.set_node(dp, {name="fire:basic_flame"})
						end
						v:set_hp(0)
						minetest.chat_send_all("# Server: <" .. rename.gpn(v:get_player_name()) .. "> was killed by a teleport. Noob!")
					end
				end
			end
	end

	local pos = vector.round(target)

	local start_realm = rc.current_realm_at_pos(origin_pos)
	local target_realm = rc.current_realm_at_pos(pos)
	if target_realm == "" or start_realm == "" or start_realm ~= target_realm then
		minetest.chat_send_player(pname, "# Server: Target location is in a different realm! Aborting.")
		return
	end

	minetest.log("[teleports] teleporting player <" .. pname .. "> to " .. minetest.pos_to_string(pos))

	-- Teleport player to chosen location.
	preload_tp.preload_and_teleport(pname, pos, 32, function()
		-- Delete 3x3x3 area above teleport.
		for x=minp.x, maxp.x do
			for y=minp.y, maxp.y do
				for z=minp.z, maxp.z do
					local pos = {x=x, y=y, z=z}
					local node = minetest.get_node(pos)
					if node.name ~= "ignore" then
						-- Do not destroy players' bones.
						if node.name ~= "air" and node.name ~= "bones:bones" then
							minetest.set_node(pos, {name="fire:basic_flame"})
						end
					end
				end
			end
		end
	end, nil, nil, false)
end



teleports.find_nearby = function(pos, count, network, yespublic)
    local nearby = {}
    local trange, isnyan = teleports.calculate_range(pos)
    
    for i = #teleports.teleports, 1, -1 do
        local tp = teleports.teleports[i]
        if not vector.equals(tp.pos, pos) and vector.distance(tp.pos, pos) <= trange then
            local othernet = tp.channel or ""
            
            if othernet == network or (othernet == "" and yespublic == 'true') then
                table.insert(nearby, tp)
                if #nearby >= count then
                    break
                end
            end
        end
    end
    
    return nearby
end



teleports.find_specific = function(pos)
    for i = 1, #teleports.teleports, 1 do
        local tp = teleports.teleports[i]
        if vector.equals(tp.pos, pos) then
            return i -- Return index of teleport.
        end
    end
end



teleports.calculate_charge = function(pos)
    local positions = {
        {x=pos.x-1, y=pos.y, z=pos.z},
        {x=pos.x+1, y=pos.y, z=pos.z},
        {x=pos.x, y=pos.y, z=pos.z-1},
        {x=pos.x, y=pos.y, z=pos.z+1},
        {x=pos.x-1, y=pos.y, z=pos.z-1},
        {x=pos.x+1, y=pos.y, z=pos.z+1},
        {x=pos.x-1, y=pos.y, z=pos.z+1},
        {x=pos.x+1, y=pos.y, z=pos.z-1},
    }
    
		local bows = 0
    local ncount = 0
    local charge = 1 -- Ambient charge is at least 1 (the teleport block provides 1 KJ).
    for k, v in ipairs(positions) do
        local n = minetest.get_node(v).name
        local c = 0
        if teleports.charge_blocks[n] ~= nil then
					c = teleports.charge_blocks[n].charge
				end
        charge = charge + c
        ncount = ncount + 1
				if n == nyanbow then
					bows = bows + 1
				end
    end

		local is_nyanporter = false
		if bows == 8 then
			is_nyanporter = true
		end
    
    charge = math.floor(charge + 0.5)
    return charge, ncount, is_nyanporter
end



local function cds(y)
  local scalar = 1
  if y < 0 then
    local depth = math.abs(y)
    scalar = depth / 30912
    if scalar > 1 then scalar = 1 end
    if scalar < 0 then scalar = 0 end
    scalar = (scalar * -1) + 1
  end
  return scalar
end



teleports.calculate_range = function(pos)
  -- Compute charge.
  local chg, cnt, nyan = teleports.calculate_charge(pos)
	if nyan then
		local owner = minetest.get_meta(pos):get_string("owner")
		-- There is an admin teleport pair between the Surface Colony and the City of Fire.
		if owner == "MustTest" then
			return 31000, nyan
		else
			return 7770, nyan
		end
	end
  
  -- How much distance each unit of charge is good for.
  local inc = 25
  
  -- Compute extra range.
  local rng = math.floor(inc * chg)
  
  -- Calculate how much to scale extra range by depth.
  local scalar = cds(pos.y)
  
  -- Scale extra range by depth.
  rng = rng * scalar
  
  -- Add extra range to base (minimum) range.
  rng = rng + 250
  
  -- Teleport range shall not go below 250 meters.
  return math.floor(rng), nyan
end



function teleports.write_infotext(pos)
	local meta = minetest.get_meta(pos)
	local name = meta:get_string("name")
	local network = meta:get_string("network")
	local owner = meta:get_string("owner")
	local dname = rename.gpn(owner)

	local public = meta:get_int("public") or 1
	if public == 1 then public = 'true' else public = 'false' end

	local id = "<" .. name .. ">"
	local net = "<" .. network .. ">"
	local own = "<" .. dname .. ">"

	if name == "" then id = "NONE" end
	if network == "" then net = "PUBLIC" end
	if public == 'false' then net = "SUPPRESSED" end

	meta:set_string("infotext", "Teleporter. Punch to update controls.\nOwner: " .. own .. "\nBeacon ID: " .. id .. "\nBeacon Channel: " .. net)
end



teleports.update = function(pos)
	local meta = minetest.get_meta(pos)
    
	local network = meta:get_string("network") or ""
	local owner = meta:get_string("owner") or ""
	local name = meta:get_string("name") or ""
	local yespublic = meta:get_string("yespublic") or 'true'

	local buttons = "";
	local nearby = teleports.find_nearby(pos, 5, network, yespublic)

	for i, v in ipairs(nearby) do
			local tp = v.pos
			local label = tp.x .. "," .. tp.y .. "," .. tp.z
			meta:set_string("loc" .. (i), label)
			if v.name ~= nil then
					if v.name ~= "" then
							label = v.name
					end
			end
			buttons = buttons .. "button_exit[5," .. (i) .. ";3,0.5;tp" .. i .. ";" .. label .. "]";
	end

	local public = meta:get_int("public") or 1
	if public == 1 then public = 'true' else public = 'false' end

	teleports.write_infotext(pos)

	local net = "<" .. network .. ">"
	local nm = "<" .. name .. ">"
	if name == "" then nm = "NONE" end
	if network == "" then net = "PUBLIC" end
	if public == 'false' then net = "SUPPRESSED" end

	local charge, count, isnyan = teleports.calculate_charge(pos)
	local range = teleports.calculate_range(pos)

	if isnyan then
		charge = "NYBW"
	end

	local formspec = "size[8,7;]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..

			"label[0,0;" .. 'Transport to nearby beacons! Need mossy cobble for energy.' .. "]" ..

			"label[1,0.70;Beacon ID: " .. minetest.formspec_escape(nm) .. "]" ..
			"label[1,1.2;Beacon Channel: " .. minetest.formspec_escape(net) .. "]" ..

			"field[0.3,2.7;2,0.5;id;Change Beacon ID;]" .. "button_exit[2,2.4;2,0.5;change_id;Confirm]" ..
			"field[0.3,3.9;2,0.5;network;Change Channel;]" .. "button_exit[2,3.6;2,0.5;change_network;Confirm]" ..

			buttons ..

			"button_exit[0,5.2;2,0.5;cancel;Close]" ..
			"checkbox[0.02,4.1;showhide;Show Channel;" .. public .. "]" ..
			"checkbox[2,4.1;yespublic;Connect Public;" .. yespublic .. "]" ..

			"label[2,5;Ambient Charge: " .. charge .. " KJ]" ..
			"label[2,5.35;Transport Range: " .. range .. " M]" ..

			"list[context;price;0,0.75;1,1;]" ..
			"list[current_player;main;0,6;8,1;]" ..
			"listring[]" ..
			default.get_hotbar_bg(0, 6)
    
	meta:set_string("formspec", formspec)
end



teleports.on_receive_fields = function(pos, formname, fields, player)
    if not player then return end
    if not player:is_player() then return end
    if player:get_hp() <= 0 then return end -- Ignore dead players.
    
    local playername = player:get_player_name()
    local meta = minetest.get_meta(pos)
		local isnyan = teleports.is_nyanbow_teleport(pos)
    local owner = meta:get_string("owner") or ""

		local infinite_fuel = false
		if owner == "MustTest" then
			infinite_fuel = true
		end
    
    local admin = minetest.check_player_privs(playername, {server=true})
    local needsave = false
    
    -- Make sure this teleport, at this postion, has an entry.
    local tp_idx = teleports.find_specific(pos)
    if not tp_idx then
        minetest.chat_send_player(playername, "# Server: Transporter data error: 0xDEADBEEF.")
				easyvend.sound_error(playername)
        return
    end
    if not teleports.teleports[tp_idx] then
        minetest.chat_send_player(playername, "# Server: Transporter data error: 0xDEADBEEF.")
				easyvend.sound_error(playername)
        return
    end

    if fields.showhide then
        if owner == playername or admin then
            if fields.showhide == "true" then
                meta:set_int("public", 1)
            else
                meta:set_int("public", 0)
            end
        else
            minetest.chat_send_player(playername, "# Server: Only the owner can change the configuration.")
						easyvend.sound_error(playername)
        end
    end
    
    if fields.yespublic then
        if owner == playername or admin then
            if fields.yespublic == "true" then
                meta:set_string("yespublic", 'true')
            else
                meta:set_string("yespublic", 'false')
            end
        else
            minetest.chat_send_player(playername, "# Server: Only the owner can change the configuration.")
						easyvend.sound_error(playername)
        end
    end
    
    if fields.change_id and fields.id then
        if owner == playername or admin then
            meta:set_string("name", fields.id)
            teleports.teleports[tp_idx].name = fields.id
            needsave = true
        else
            minetest.chat_send_player(playername, "# Server: Only the owner can change the configuration.")
						easyvend.sound_error(playername)
        end
    end
    
    if fields.change_network and fields.network then
        if owner == playername or admin then
            meta:set_string("network", fields.network)
            teleports.teleports[tp_idx].channel = fields.network
            needsave = true
        else
            minetest.chat_send_player(playername, "# Server: Only the owner can change the configuration.")
						easyvend.sound_error(playername)
        end
    end
    
    if needsave == true then
        teleports.save()
    end
    
    if fields.tp1 or fields.tp2 or fields.tp3 or fields.tp4 or fields.tp5 then
        local have_biofuel = false
        local tpname = nil
        local have_target = false
        local target_pos = {x=0, y=0, z=0}
        
        if fields.tp1 then
            tpname = meta:get_string("loc1")
        elseif fields.tp2 then
            tpname = meta:get_string("loc2")
        elseif fields.tp3 then
            tpname = meta:get_string("loc3")
        elseif fields.tp4 then
            tpname = meta:get_string("loc4")
        elseif fields.tp5 then
            tpname = meta:get_string("loc5")
        end
           
        if tpname and type(tpname) == "string" then
            local tppos = minetest.string_to_pos(tpname)
            if tppos then
                if vector.distance(tppos, pos) <= teleports.calculate_range(pos) then
										-- Do not permit teleporting from one realm to another.
										-- Doing so requires a different kind of teleport device.
										local start_realm = rc.current_realm_at_pos(pos)
										local target_realm = rc.current_realm_at_pos(tppos)
										if start_realm ~= "" and start_realm == target_realm then
											local exists = false
											for i = 1, #teleports.teleports, 1 do
													local tp = teleports.teleports[i]
													if vector.equals(tp.pos, tppos) then
															exists = true
															break
													end
											end

											if exists then
												have_target = true
												target_pos = tppos
											else
													minetest.chat_send_player(playername, "# Server: Transport control error: target no longer exists.")
													easyvend.sound_error(playername)
											end
										else
											minetest.chat_send_player(playername, "# Server: Cannot teleport between realm boundaries!")
											easyvend.sound_error(playername)
										end
                else
                    minetest.chat_send_player(playername, "# Server: Transport control error: target out of range!")
										easyvend.sound_error(playername)
                end
            else
                minetest.chat_send_player(playername, "# Server: Transport control error: 0xDEADBEEF.")
								easyvend.sound_error(playername)
            end
        else
            minetest.chat_send_player(playername, "# Server: Transport control error: formspec.")
						easyvend.sound_error(playername)
        end
         
        if have_target == true then -- Don't use fuel unless a valid target is found.
          local inv = meta:get_inventory();
          
          if not admin and not isnyan and not infinite_fuel then -- Don't do fuel calculation if admin is using teleport.
            -- Cost is 1 item of fuel per 300 meters.
            -- This means players save on fuel when using long range teleports,
            -- instead of using a chain of short-range teleports.
            -- However, long range teleports cost more to make.
            local rcost = math.floor(vector.distance(pos, target_pos) / 300)
            if rcost < 1 then rcost = 1 end
            
            local price1 = {name="default:mossycobble", count=rcost, wear=0, metadata=""}
            local price2 = {name="flowers:waterlily", count=rcost, wear=0, metadata=""}
            if not inv:is_empty("price") then
              if inv:contains_item("price", price1) then
                inv:remove_item("price", price1)
                have_biofuel = true
              elseif inv:contains_item("price", price2) then
                inv:remove_item("price", price2)
                have_biofuel = true
              else
                minetest.chat_send_player(playername, "# Server: Insufficient stored energy for transport. Add more biofuel.")
								easyvend.sound_error(playername)
              end
            else
              minetest.chat_send_player(playername, "# Server: Transporter is on maintenance energy only. Add biofuel to use.")
							easyvend.sound_error(playername)
            end
          end
          
          if have_biofuel or admin or isnyan or infinite_fuel then
            local teleport_pos = {x=target_pos.x, y=target_pos.y, z=target_pos.z}
            local spawn_pos = {x=teleport_pos.x-1+math.random(0, 2), y=teleport_pos.y+1, z=teleport_pos.z-1+math.random(0, 2)}
            teleports.teleport_player(player, pos, teleport_pos, spawn_pos)
          end
        end
    end

    -- Always update the teleport formspec.
    teleports.update(pos)
end



teleports.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  
  -- Protection interferes with building public networks.
  --if minetest.test_protection(pos, pname) then return 0 end
  
  if listname == "price" and stack:get_name() == "default:mossycobble" then
    return stack:get_count()
  elseif listname == "price" and stack:get_name() == "flowers:waterlily" then
    return stack:get_count()
  end
  
  return 0
end



teleports.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  -- Protection interferes with building public networks.
  --if minetest.test_protection(pos, pname) then return 0 end
  return stack:get_count()
end



teleports.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end



teleports.can_dig = function(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty("price")
end



teleports.after_place_node = function(pos, placer)
	if placer and placer:is_player() then
		local meta = minetest.get_meta(pos)

		local pname = placer:get_player_name()
		local dname = rename.gpn(pname)

		meta:set_string("owner", pname)
		meta:set_string("rename", dname)
		meta:set_string("name", "")
		meta:set_string("network", "")
		meta:set_int("public", 1)

		local inv = meta:get_inventory()
		inv:set_size("price", 1)
		local initialcharge = {name="default:mossycobble", count=30, wear=0, metadata=""}
		inv:add_item("price", initialcharge)

		teleports.update(pos)

		table.insert(teleports.teleports, {pos=vector.round(pos)})
		teleports.save()
	end
end



teleports.on_destruct = function(pos)
	--minetest.chat_send_all("# Server: Destructing teleport!")
	for i, EachTeleport in ipairs(teleports.teleports) do
		if vector.equals(EachTeleport.pos, pos) then
			table.remove(teleports.teleports, i)
			teleports.save()
		end
	end
end



teleports.on_punch = function(pos, node, puncher, pointed_thing)
    teleports.update(pos)
    -- Maybe this is a bit too spammy and generally unnecessary?
    if puncher and puncher:is_player() then
        minetest.chat_send_player(puncher:get_player_name(), "# Server: This machine has been updated.")
    end
end



teleports.on_diamond_place = function(itemstack, placer, pointed_thing)
    local stack = ItemStack("default:diamondblock")
    local pos = pointed_thing.above
    local name = "default:diamondblock"
    
    if minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z}).name == name and
        minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z+1}).name == name and
        minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z-1}).name == name and
        minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z}).name == name and
        minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z+1}).name == name and
        minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z-1}).name == name and
        minetest.get_node({x=pos.x,y=pos.y,z=pos.z+1}).name == name and
        minetest.get_node({x=pos.x,y=pos.y,z=pos.z-1}).name == name
    then
        stack = ItemStack("teleports:teleport")
    end
    
    local ret = minetest.item_place(stack, placer, pointed_thing)
    if ret == nil then
        return itemstack
    else
        return ItemStack("default:diamondblock " .. itemstack:get_count() - (1 - ret:get_count()))
    end
end

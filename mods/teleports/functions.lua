
-- This file is designed to be reloadable.

teleports = teleports or {}
teleports.teleports = teleports.teleports or {}
teleports.min_range = 250
teleports.datafile = minetest.get_worldpath() .. "/teleports.txt"

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_floor = math.floor
local math_random = math.random

dofile(teleports.modpath .. "/sickness.lua")



local nyanbow = "rosestone:tail"

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



function teleports.nearest_beacons_to_position(pos, num, rangelim)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = teleports.teleports
	for i=1, #sblocks, 1 do
		local v = sblocks[i]
		local p = v.pos
		if v.is_recall then
			if rangelim then
				if vector_distance(p, pos) < rangelim then
					if get_rn(p) == realm then
						blocks[#blocks+1] = v
					end
				end
			else
				if get_rn(p) == realm then
					blocks[#blocks+1] = v
				end
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
	local ret = {}
	for i=1, num, 1 do
		if i <= #blocks then
			ret[#ret+1] = blocks[i]
		else
			break
		end
	end
	return ret
end



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



function teleports.kill_players_at_pos(teleport_pos, pname)
	local dead_players = minetest.get_objects_inside_radius({x=teleport_pos.x, y=teleport_pos.y+1, z=teleport_pos.z}, 2)
	for k, v in ipairs(dead_players) do
			if v and v:is_player() then
				if not gdac.player_is_admin(v) and v:get_player_name() ~= pname then -- Don't kill admin or self (can happen due to lag).
					-- Only if player isn't already dead.
					if v:get_hp() > 0 then
						-- If there's a player here already the map must be loaded, so we
						-- can put fire where they're standing no problem.
						local dp = vector_round(v:get_pos())
						local node = minetest.get_node(dp)
						if node.name == "air" then
							minetest.add_node(dp, {name="fire:basic_flame"})
						end
						v:set_hp(0)
						minetest.chat_send_all("# Server: <" .. rename.gpn(v:get_player_name()) .. "> was killed by a teleport. Noob!")
					end
				end
			end
	end
end



-- Calculates the probability scalar of a TP to misjump based on range vs max range.
local function tpc(r1, r2)
	if r1 > r2 then return 0 end
	local d = r1 / r2
	d = d * -1 + 1
	for i=1, 10, 1 do
		d = d * 1.719 + 1
		d = math.log(d)
	end
	if d < 0 then d = 0 end
	if d > 1 then d = 1 end
	return d
end



teleports.teleport_player = function(player, origin_pos, teleport_pos, teleport_range)
	if not player or not player:is_player() then
		return
	end
	local pname = player:get_player_name()

	if sheriff.is_cheater(pname) then
		if sheriff.punish_probability(pname) then
			sheriff.punish_player(pname)
			return
		end
	end

	local player_pos = player:get_pos()
	if (player_pos.y < origin_pos.y) or (vector_distance(player_pos, origin_pos) > 2) then
		minetest.chat_send_player(pname, "# Server: You must stand on portal activation surface!")
		return
	end

	-- Small chance to be teleported somewhere completely random.
	-- The chance increases a LOT if teleports are crowded.
	-- You could theorize that their signals interfere with each other.
	local use_random = false
	local random_chance = 1030 -- Actually 1000, because nearby-count is always at least 1 (counting self).
	local count_nearby = 0

	-- Count number of nearby teleports (including self).
	for k, v in ipairs(teleports.teleports) do
		if vector_distance(v.pos, origin_pos) < 100 then
			count_nearby = count_nearby + 1
		end
	end

	-- Chance of misjump increases if teleports are crowded.
	random_chance = random_chance - (count_nearby * 30)
	if random_chance < 0 then random_chance = 0 end

	-- Chance of misjump increases as teleport is operated closer to its max range.
	local teleport_distance = vector_distance(origin_pos, teleport_pos)
	random_chance = random_chance * tpc(teleport_distance, teleport_range)

	-- Chance should never be worse than 1 in 50.
	if random_chance < 50 then
		random_chance = 50
	end
	random_chance = math_floor(random_chance)

	--minetest.chat_send_all('chance: ' .. random_chance)
	if math_random(1, random_chance) == 1 then
		if #(teleports.teleports) > 0 then
			local tp = teleports.teleports[math_random(1, #(teleports.teleports))]
			if not tp then
				minetest.chat_send_player(pname, "# Server: Transport error! Aborted.")
				return
			end
			teleport_pos = tp.pos
			use_random = true
		end
	end

	local p = vector_round(teleport_pos)
	local minp = {x=p.x-1, y=p.y+1, z=p.z-1}
	local maxp = {x=p.x+1, y=p.y+3, z=p.z+1}
	local target = {x=p.x-1+math_random(0, 2), y=p.y+1, z=p.z-1+math_random(0, 2)}
	local pos = vector_round(target)

	-- Perform this check only if teleport target wasn't randomized.
	if not use_random then
		local start_realm = rc.current_realm_at_pos(origin_pos)
		local target_realm = rc.current_realm_at_pos(pos)
		if target_realm == "" or start_realm == "" or start_realm ~= target_realm then
			minetest.chat_send_player(pname, "# Server: Target location is in a different realm! Aborting.")
			return
		end
	end

	minetest.log("[teleports] teleporting player <" .. pname .. "> to " .. minetest.pos_to_string(pos))

	-- Teleport player to chosen location.
	preload_tp.execute({
		player_name = pname,
		target_position = pos,
		send_blocks = true,
		particle_effects = true,

		pre_teleport_callback = function()
			-- Kill players standing on target teleport pad.
			teleports.kill_players_at_pos(teleport_pos, pname)

			-- Delete 3x3x3 area above teleport.
			for x=minp.x, maxp.x do
				for y=minp.y, maxp.y do
					for z=minp.z, maxp.z do
						local pos = {x=x, y=y, z=z}
						local node = minetest.get_node(pos)
						if node.name ~= "ignore" then
							-- Do not destroy players' bones.
							if node.name ~= "air" and node.name ~= "bones:bones" then
								minetest.add_node(pos, {name="fire:basic_flame"})
							end
						end
					end
				end
			end
		end,

		post_teleport_callback = function()
			portal_sickness.on_use_portal(pname)

			if use_random then
				minetest.after(10, function()
					local RED = core.get_color_escape_sequence("#ff0000")
					minetest.chat_send_player(pname, RED .. "# Server: Coordinate translation error. Unknown destination!")
					chat_core.alert_player_sound(pname)
				end)
			end
		end,
	})

	teleports.ping_all_teleports()
end



teleports.find_nearby = function(pos, count, network, yespublic)
	local nearby = {}
	local trange, isnyan = teleports.calculate_range(pos)
	local start_realm = rc.current_realm_at_pos(pos)

	for i = #teleports.teleports, 1, -1 do
		local tp = teleports.teleports[i]
		if not vector_equals(tp.pos, pos) and vector_distance(tp.pos, pos) <= trange then
			local target_realm = rc.current_realm_at_pos(tp.pos)
			-- Only find teleports in the same dimension.
			if start_realm ~= "" and start_realm == target_realm then
				local othernet = tp.channel or ""

				if othernet == network or (othernet == "" and yespublic == 'true') then
					table.insert(nearby, tp)
					if #nearby >= count then
						break
					end
				end
			end
		end
	end

	return nearby
end



teleports.find_specific = function(pos)
    for i = 1, #teleports.teleports, 1 do
        local tp = teleports.teleports[i]
        if vector_equals(tp.pos, pos) then
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
    local charge = 1 -- Ambient charge is at least 1 (the teleport block provides 1 KJ).
    for k, v in ipairs(positions) do
        local n = minetest.get_node(v).name
        local c = 0
        if teleports.charge_blocks[n] ~= nil then
					c = teleports.charge_blocks[n].charge
				end
        charge = charge + c
				if n == nyanbow then
					bows = bows + 1
				end
    end

		local is_nyanporter = false
		if bows == 8 then
			is_nyanporter = true
		end
    
    charge = math_floor(charge + 0.5)

		-- Combined teleports interfere with each other and reduce their range.
		local minp = vector.add(pos, {x=-2, y=0, z=-2})
		local maxp = vector.add(pos, {x=2, y=0, z=2})
		local others = minetest.find_nodes_in_area(minp, maxp, "teleports:teleport")

		local other_count = 1
		if others and #others > 0 then
			charge = charge / #others
			other_count = #others
		end

    return charge, other_count, is_nyanporter
end



local function cds(y)
	local scalar = 1
	if y < 0 then
		-- You can probably tell that I'm really, really bad at math.

		local depth = math.abs(y)
		scalar = depth / 30912

		-- Clamp.
		if scalar > 1 then scalar = 1 end
		if scalar < 0 then scalar = 0 end

		-- Invert.
		scalar = (scalar * -1) + 1

		-- Magic!
		-- The number of iterations determines the steepness of the curve.
		for i=1, 5, 1 do
			scalar = scalar * 1.719
			scalar = scalar + 1

			-- Input to log should be [1, 2.719].
			-- Log should return something in range [0, 1].
			scalar = math.log(scalar)
		end

		-- Clamp.
		if scalar > 1 then scalar = 1 end
		if scalar < 0 then scalar = 0 end
	end
	return scalar
end



teleports.calculate_range = function(pos)
  -- Compute charge.
  local chg, other_cnt, nyan = teleports.calculate_charge(pos)
	if nyan then
		local owner = minetest.get_meta(pos):get_string("owner")
		-- There is an admin teleport pair between the Surface Colony and the City of Fire.
		-- This special exception code makes it work.
		if owner == gdac.name_of_admin then
			return 31000, nyan
		else
			-- Range of nyan teleports is reduced if they're crowded.
			return (7770 / other_cnt), nyan
		end
	end
  
  -- How much distance each unit of charge is good for.
  local inc = 25
  
  -- Compute extra range.
  local rng = math_floor(inc * chg)
  
  -- Calculate how much to scale extra range by depth.
  local scalar = cds(pos.y)
  
  -- Scale extra range by depth.
  rng = rng * scalar
  
  -- Add extra range to base (minimum) range.
  rng = rng + 250
  
  -- Teleport range shall not go below 250 meters.
  return math_floor(rng), nyan
end



function teleports.write_infotext(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
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

	local beacon = ""
	local item = {name="rosestone:head", count=1, wear=0, metadata=""}
	if inv:contains_item("price", item) then
		beacon = "\nRecall signal emission normal"
	end

	meta:set_string("infotext", "Teleporter. Punch to update controls.\nOwner: " .. own .. "\nBeacon ID: " .. id .. "\nBeacon Channel: " .. net .. beacon)
end



teleports.update = function(pos)
	local meta = minetest.get_meta(pos)
    
	local network = meta:get_string("network") or ""
	local owner = meta:get_string("owner") or ""
	local name = meta:get_string("name") or ""
	local yespublic = meta:get_string("yespublic") or 'true'

	local buttons = "";
	local nearby = teleports.find_nearby(pos, 10, network, yespublic)

	local button_x = 8
	local button_y = 1
	for i, v in ipairs(nearby) do
			local tp = v.pos
			local data = tp.x .. "," .. tp.y .. "," .. tp.z
			local real_label = rc.pos_to_string(tp)
			meta:set_string("loc" .. (i), data)

			if v.name ~= nil then
					if v.name ~= "" then
							real_label = v.name
					end
			end

			buttons = buttons ..
				"button_exit[" .. button_x .. "," .. button_y ..
				";3,0.5;tp" .. i .. ";" .. minetest.formspec_escape(real_label) .. "]";

			button_y = button_y + 1
			if button_y >= 6 then
				button_y = 1
				button_x = 5
			end
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
		charge = "ROSE"
	end

	local formspec = "size[11,7;]" ..
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
			"list[current_player;main;0,6;11,1;]" ..
			"listring[]"
    
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
	else
		local inv = meta:get_inventory()
		local item = {name="rosestone:head", count=1, wear=0, metadata=""}
		if inv:contains_item("price", item) then
			infinite_fuel = true
		end
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

	local pressed_tp_button = false
	local pressed_tp_location
	for i = 1, 10, 1 do
		-- According to button names/data set in the machine update function.
		local btnname = "tp" .. i
		local posname = "loc" .. i
		if fields[btnname] then
			pressed_tp_button = true
			pressed_tp_location = meta:get_string(posname)
			break
		end
	end

	if pressed_tp_button then
		local have_biofuel = false
		local tpname = pressed_tp_location
		local have_target = false
		local target_pos = {x=0, y=0, z=0}
		local teleport_range = nil

		if tpname and type(tpname) == "string" then
			local tppos = minetest.string_to_pos(tpname)
			if tppos then
				teleport_range = teleports.calculate_range(pos)
				if vector_distance(tppos, pos) <= teleport_range then
					-- Do not permit teleporting from one realm to another.
					-- Doing so requires a different kind of teleport device.
					local start_realm = rc.current_realm_at_pos(pos)
					local target_realm = rc.current_realm_at_pos(tppos)
					if start_realm ~= "" and start_realm == target_realm then
						local exists = false
						for i = 1, #teleports.teleports, 1 do
							local tp = teleports.teleports[i]
							if vector_equals(tp.pos, tppos) then
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

			if not admin and not infinite_fuel then -- Don't do fuel calculation if admin is using teleport.
				-- Cost is 1 item of fuel per 300 meters.
				-- This means players save on fuel when using long range teleports,
				-- instead of using a chain of short-range teleports.
				-- However, long range teleports cost more to make.
				local rcost = math_floor(vector_distance(pos, target_pos) / 300)
				if isnyan then
					-- Nyan teleports have much greater fuel efficiency.
					rcost = math_floor(vector_distance(pos, target_pos) / 600)
				end
				if rcost < 1 then rcost = 1 end

				-- If using lilies as fuel, fewer are required.
				-- Lilies are bit harder to get.
				local lcost = math_floor(rcost * 0.5)
				if lcost < 1 then lcost = 1 end

				local price1 = {name="default:mossycobble", count=rcost, wear=0, metadata=""}
				local price2 = {name="flowers:waterlily", count=lcost, wear=0, metadata=""}

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

			if have_biofuel or admin or infinite_fuel then
				local teleport_pos = {x=target_pos.x, y=target_pos.y, z=target_pos.z}
				teleports.teleport_player(player, pos, teleport_pos, teleport_range)
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
	elseif listname == "price" and stack:get_name() == "rosestone:head" then
		if minetest.test_protection(pos, pname) then return 0 end
		return stack:get_count()
  end
  
  return 0
end



teleports.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
  local pname = player:get_player_name()
  -- Protection interferes with building public networks.
	--if minetest.test_protection(pos, pname) then return 0 end

	if stack:get_name() == "rosestone:head" then
		if minetest.test_protection(pos, pname) then return 0 end
		return stack:get_count()
	end

  return stack:get_count()
end



teleports.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end



function teleports.update_beacon_data(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local item = {name="rosestone:head", count=1, wear=0, metadata=""}

	if inv:contains_item("price", item) then
		for k, v in ipairs(teleports.teleports) do
			if vector_equals(v.pos, pos) then
				if not v.is_recall then
					v.is_recall = true
					teleports.save()
				end
			end
		end
	else
		for k, v in ipairs(teleports.teleports) do
			if vector_equals(v.pos, pos) then
				if v.is_recall then
					v.is_recall = nil
					teleports.save()
				end
			end
		end
	end
end



function teleports.on_metadata_inventory_put(pos, listname, index, stack, player)
	teleports.update_beacon_data(pos)
end



function teleports.on_metadata_inventory_take(pos, listname, index, stack, player)
	teleports.update_beacon_data(pos)
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

		table.insert(teleports.teleports, {pos=vector_round(pos)})
		teleports.save()
	end
end



teleports.on_destruct = function(pos)
	--minetest.chat_send_all("# Server: Destructing teleport!")
	for i, EachTeleport in ipairs(teleports.teleports) do
		if vector_equals(EachTeleport.pos, pos) then
			table.remove(teleports.teleports, i)
			teleports.save()
		end
	end
end



function teleports.ping_all_teleports()
	local players = minetest.get_connected_players()

	local ping = function(pos)
		local xd = 1
		local zd = 1

		minetest.add_particlespawner({
			amount = 80,
			time = 5,
			minpos = {x=pos.x-xd, y=pos.y+1, z=pos.z-zd},
			maxpos = {x=pos.x+xd, y=pos.y+3, z=pos.z+zd},
			minvel = {x=-1, y=-1, z=-1},
			maxvel = {x=1, y=1, z=1},
			minacc = {x=-1, y=-1, z=-1},
			maxacc = {x=1, y=1, z=1},
			minexptime = 0.5,
			maxexptime = 1.5,
			minsize = 1,
			maxsize = 1.5,
			collisiondetection = false,
			texture = "nether_particle_anim4.png",

			animation = {
				type = "vertical_frames",
				aspect_w = 7,
				aspect_h = 7,

				-- Disabled for now due to causing older clients to hang.
				--length = -1,
				length = 0.3,
			},

			glow = 14,
		})
	end

	-- Spawn particles over every teleport that's near a player.
	local ports = teleports.teleports
	local tlen = #ports
	local plen = #players

	for k = 1, tlen, 1 do
		local porthub = ports[k]
		local portpos = porthub.pos

		for i = 1, plen, 1 do
			local playerpos = players[i]:get_pos()

			if vector_distance(portpos, playerpos) < 32 then
				ping(portpos)

				if math_random(1, 500) == 1 then
					minetest.after(math_random(1, 5), function()
						pm.spawn_random_wisp(vector_add(portpos, {x=0, y=1, z=0}))
					end)
				end
			end
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



-- Admin API function, refills ALL teleports with fuel (if fuel is empty).
function teleports.refill_all()
	local tps = teleports.teleports

	for k, v in ipairs(tps) do
		local meta = minetest.get_meta(v.pos)
		if meta then
			local inv = meta:get_inventory()
			if inv then
				if inv:is_empty("price") then
					inv:set_stack("price", 1, ItemStack("flowers:waterlily 64"))
				else
					local stack = inv:get_stack("price", 1)
					if stack:get_name() == "default:mossycobble" then
						stack:set_count(64)
						inv:set_stack("price", 1, stack)
					elseif stack:get_name() == "flowers:waterlily" then
						stack:set_count(64)
						inv:set_stack("price", 1, stack)
					end
				end
			end
		end
	end
end

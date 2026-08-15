
-- Localize.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_floor = math.floor
local math_random = math.random



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
			meta:mark_as_private("loc" .. (i))

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

	local defnm = minetest.formspec_escape(name)
	local defnt = minetest.formspec_escape(public == "true" and network or "")

	local formspec = "size[11,7;]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..

			"label[0,0;" .. 'Transport to nearby beacons. Need mese/mossy for energy.' .. "]" ..

			"label[1,0.70;Beacon ID: " .. minetest.formspec_escape(nm) .. "]" ..
			"label[1,1.2;Beacon Channel: " .. minetest.formspec_escape(net) .. "]" ..

			"field[0.3,2.7;2,0.5;id;Change Beacon ID;" .. defnm .. "]" .. "field_close_on_enter[id;false]" .. "button[2,2.4;2,0.5;change_id;Confirm]" ..
			"field[0.3,3.9;2,0.5;network;Change Channel;" .. defnt .. "]" .. "field_close_on_enter[network;false]" .. "button[2,3.6;2,0.5;change_network;Confirm]" ..
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
	if minetest.get_player_privs(owner).server then
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

	if (fields.change_id or fields.key_enter_field == "id") and fields.id then
		if owner == playername or admin then
			meta:set_string("name", fields.id)
			teleports.teleports[tp_idx].name = fields.id
			needsave = true
		else
			minetest.chat_send_player(playername, "# Server: Only the owner can change the configuration.")
			easyvend.sound_error(playername)
		end
	end

	if (fields.change_network or fields.key_enter_field == "network") and fields.network then
		if owner == playername or admin then
			meta:set_string("network", fields.network)
			meta:mark_as_private("network")
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

			if tppos and not fortress.can_teleport_at(tppos) then
				minetest.log("action",
					"Not allowing teleport into fortress at " ..
						minetest.pos_to_string(tppos) .. " by player " .. playername ..
							" from TP at " .. minetest.pos_to_string(pos) .. ".")

				tppos = nil
			end

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

				-- If using mese fragments, cost is a bit higher.
				local mcost = rcost * 1.5

				local price1 = {name="default:mossycobble", count=rcost, wear=0, metadata=""}
				local price2 = {name="flowers:waterlily", count=lcost, wear=0, metadata=""}
				local price3 = {name="default:mese_crystal_fragment", count=mcost, wear=0, metadata=""}

				if not inv:is_empty("price") then
					if inv:contains_item("price", price1) then
						inv:remove_item("price", price1)
						have_biofuel = true
					elseif inv:contains_item("price", price2) then
						inv:remove_item("price", price2)
						have_biofuel = true
					elseif inv:contains_item("price", price3) then
						inv:remove_item("price", price3)
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

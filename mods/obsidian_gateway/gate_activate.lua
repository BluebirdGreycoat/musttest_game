
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local math_random = math.random



function obsidian_gateway.attempt_activation(pos, player, itemstring)
	local pname = player:get_player_name()
	local ppos = vector_round(player:get_pos())

	local under = utility.node_under_pos(player:get_pos())
	local inside = vector.add(under, {x=0, y=1, z=0})
	local nodeunder = minetest.get_node(under).name
	-- Player must be standing on one of these.
	if nodeunder ~= "default:obsidian" and
			nodeunder ~= "griefer:grieferstone" and
			nodeunder ~= "cavestuff:dark_obsidian" and
			nodeunder ~= "cavestuff:glow_obsidian" then
		-- This triggers when other types of portals are used, so is incorrect to display this chat.
		--minetest.chat_send_player(pname, "# Server: You need to be standing in the gateway for it to work!")
		return
	end

	local success
	local origin
	local northsouth
	local ns_key
	local playerorigin
	local airpoints

	success, origin, airpoints, northsouth, ns_key, playerorigin =
		obsidian_gateway.find_gate(pos)

	if not success then
		return
	end

	-- Add/update sound beacon.
	ambiance.spawn_sound_beacon("soundbeacon:gate", origin, 20, 1)
	ambiance.replay_nearby_sound_beacons(origin, 6)

	if sheriff.is_cheater(pname) then
		if sheriff.punish_probability(pname) then
			sheriff.punish_player(pname)
			return
		end
	end

	local target
	local meta = minetest.get_meta(origin)
	-- By spliting the key names by ns/ew, I ensure connected portals don't
	-- stomp on each other's data.
	target = minetest.string_to_pos(meta:get_string("obsidian_gateway_destination_" .. ns_key))
	meta:mark_as_private("obsidian_gateway_destination_" .. ns_key)
	--if not target then
	--	minetest.chat_send_player(pname, "# Server: Gateway has no destination! Aborting.")
	--	return
	--end

	-- If activating the gate in the OUTBACK, and player previously died in
	-- MIDFELD, send them back to MIDFELD, do NOT send them to the overworld.
	if rc.current_realm_at_pos(origin) == "abyss" then
		if player:get_meta():get_int("abyss_return_midfeld") == 1 then
			target = obsidian_gateway.get_midfeld_spawn()
		end
	end

	-- Gates CANNOT be initialized in the Abyss!
	-- (Only the outgoing realm-gate is useable.)
	-- This prevents players from building their own gates in the Abyss.
	if not target and rc.current_realm_at_pos(origin) == "abyss" then
		minetest.after(0, function()
			-- Detonate some TNT!
			tnt.boom(vector.add(ppos, {x=math_random(-3, 3), y=0, z=math_random(-3, 3)}), {
				radius = 3,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 5,
				disable_drops = true,
			})
		end)
		return
	end

	local isreturngate = (meta:get_int("obsidian_gateway_return_gate_" .. ns_key) == 1)
	local actual_owner = meta:get_string("obsidian_gateway_owner_" .. ns_key)
	local isowner = (actual_owner == pname)

	local first_time_init = false

	minetest.log("action", pname .. " activated gateway @ " .. minetest.pos_to_string(pos))

	-- Initialize gateway for the first time.
	if itemstring == "pearl" then
	if not target or (meta:get_string("obsidian_gateway_success_" .. ns_key) ~= "yes" and not isreturngate) then
		-- Target is valid then this could be an OLD gate with old metadata.
		-- This can ALSO happen if player initializes a new gate twice or more times before
		-- the first initialization completes.
		if target and not isreturngate and meta:get_string("obsidian_gateway_success_" .. ns_key) == "" then
			minetest.chat_send_player(pname, "# Server: It looks like this could possibly be an OLD gate! Aborting for safety reasons.")
			minetest.chat_send_player(pname, "# Server: If this Gateway was previously functioning normally, please mail the admin with the coordinates.")
			minetest.chat_send_player(pname, "# Server: If this is a Gate that you have just constructed, you can safely ignore this message.")
			minetest.chat_send_player(pname, "# Server: The Gateway's EXIT location is @ " .. rc.pos_to_namestr(target) .. ".")
			minetest.after(1.5, function() easyvend.sound_error(pname) end)
			return
		end
		-- Algorithm for locating the destination.

		-- Get a potential gate location.
		target = rc.get_random_realm_gate_position(pname, origin)

		-- Is target outside bounds?
		local bad = function(target, origin)
			-- Handle nil.
			if not target then
				return true
			end
			-- Don't allow exit points near the colonies.
			if vector_distance(target, {x=0, y=0, z=0}) < 1000 or
				vector_distance(target, {x=0, y=-30790, z=0}) < 1000 then
				return true
			end
			-- Exit must not be too close to start.
			if vector_distance(target, origin) < 100 then
				return true
			end
			-- Or too far.
			-- This causes too many failures.
			-- Note: this is now handled by the 'rc' mod.
			--if vector_distance(target, origin) > 7000 then
			--	return true
			--end
			if not rc.is_valid_gateway_region(target) then
				return true
			end
		end

		-- Keep trying until the target is within bounds.
		local num_tries = 0
		while bad(target, origin) do
			target = rc.get_random_realm_gate_position(pname, origin)
			num_tries = num_tries + 1

			-- Max 3 tries.
			if num_tries >= 2 then
				---[[
				minetest.after(0, function()
					-- Detonate some TNT!
					tnt.boom(vector.add(ppos, {x=math_random(-3, 3), y=0, z=math_random(-3, 3)}), {
						radius = 3,
						ignore_protection = false,
						ignore_on_blast = false,
						damage_radius = 5,
						disable_drops = true,
					})
				end)
				--]]
				return
			end
		end

		meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(target))
		meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)

		meta:mark_as_private({
			"obsidian_gateway_destination_" .. ns_key,
			"obsidian_gateway_owner_" .. ns_key
		})

		first_time_init = true
		isowner = true
	else
		-- Used a pearl but gate already activated.
		return
	end
	end -- Itemstring is "pearl".

	-- Happens if gate is not initialized and we didn't use a pearl to activate it.
	if not target then
		return
	end

	-- Event horizon color depends on whether we are a return gate.
	obsidian_gateway.spawn_liquid(origin, northsouth, isreturngate)

	if gdac.player_is_admin(pname) then
		isowner = true
	end

	-- Let everyone use gates owned by the admin.
	if minetest.get_player_privs(actual_owner).server then
		isowner = true
	end

	-- Slightly randomize player's exit coordinates.
	-- Without changing the coordinates of the gateway.
	local pdest
	if northsouth then
		pdest = vector.add(target, {x=math_random(0, 1), y=0, z=0})
	else
		pdest = vector.add(target, {x=0, y=0, z=math_random(0, 1)})
	end
	pdest = vector_round(pdest)

	-- Make sure target is within some realm.
	-- This generally should not happen.
	if not rc.is_valid_realm_pos(pdest) then
		-- Show problem.
		minetest.chat_send_player(pname, "# Server: Void portal destination.")
		return
	end

	-- Collect any friends to bring along.
	local friendstobring = {}
	local allplayers = minetest.get_connected_players()
	for k, v in ipairs(allplayers) do
		if v:get_player_name() ~= pname then
			if vector_distance(v:get_pos(), player:get_pos()) < 3 then
				-- Exclude players who are flagged to return to Midfeld.
				if v:get_meta():get_int("abyss_return_midfeld") == 0 then
					friendstobring[#friendstobring+1] = v:get_player_name()
				end
			end
		end
	end

	portal_cb.call_before_use({
		gate_origin = origin,
		gate_orientation = ns_key, -- "ns" or "ew"
		player_name = pname,
		teleport_destination = table.copy(pdest),
	})

	-- Create a gateway at the player's destination.
	-- This gateway links back to the first.
	-- If it is destroyed, the player is stuck!
	preload_tp.execute({
		player_name = pname,
		target_position = pdest,
		emerge_radius = 32,
		particle_effects = true,

		-- Force teleport on first init.
		-- This should reduce problems due to the player moving around and canceling
		-- the teleport on a new gate.
		force_teleport = first_time_init,

		pre_teleport_callback = function()
			-- Cancel teleport if origin gate does not have portal liquid.
			if not obsidian_gateway.have_liquid(origin, northsouth) then
				minetest.chat_send_player(pname, "# Server: Portal disrupted.")
				-- Cancel transport.
				return true
			end

			-- Don't build return portal on top of someone's protected stuff.
			if first_time_init then
				if check_protection(vector.add(target, {x=0, y=3, z=0}), 5) then
					minetest.chat_send_player(pname, "# Server: Return-gate construction FAILED due to protection near " .. rc.pos_to_namestr(target) .. ".")

					-- Clear data for the initial gate. This will permit the player to retry without tearing everything down and building it again.
					local meta = minetest.get_meta(origin)
					meta:set_string("obsidian_gateway_success_" .. ns_key, "")
					meta:set_string("obsidian_gateway_destination_" .. ns_key, "")
					meta:set_string("obsidian_gateway_owner_" .. ns_key, "")

					meta:mark_as_private({
						"obsidian_gateway_success_" .. ns_key,
						"obsidian_gateway_destination_" .. ns_key,
						"obsidian_gateway_owner_" .. ns_key
					})

					-- Cancel transport.
					return true
				end
			end

			-- Build return portal (only if not already using a return portal).
			-- Also, only build return portal on first use of the initial portal.
			if not isreturngate and first_time_init then
				if northsouth then
					-- Place northsouth gateway.
					local path = obsidian_gateway.modpath .. "/obsidian_gateway_northsouth.mts"
					local gpos = vector.add(target, {x=-1, y=-1, z=0})
					minetest.place_schematic(gpos, path, "0", nil, true)
					local meta = minetest.get_meta(gpos)
					meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
					meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)
					meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 1)

					meta:mark_as_private({
						"obsidian_gateway_destination_" .. ns_key,
						"obsidian_gateway_owner_" .. ns_key,
						"obsidian_gateway_return_gate_" .. ns_key
					})
				else
					-- Place eastwest gateway.
					local path = obsidian_gateway.modpath .. "/obsidian_gateway_eastwest.mts"
					local gpos = vector.add(target, {x=0, y=-1, z=-1})
					minetest.place_schematic(gpos, path, "0", nil, true)
					local meta = minetest.get_meta(gpos)
					meta:set_string("obsidian_gateway_destination_" .. ns_key, minetest.pos_to_string(playerorigin))
					meta:set_string("obsidian_gateway_owner_" .. ns_key, pname)
					meta:set_int("obsidian_gateway_return_gate_" .. ns_key, 1)

					meta:mark_as_private({
						"obsidian_gateway_destination_" .. ns_key,
						"obsidian_gateway_owner_" .. ns_key,
						"obsidian_gateway_return_gate_" .. ns_key
					})
				end
			end

			-- Mark the initial gate as success.
			-- If this is not done, then gate will assume it is not initialized
			-- the next time it is used. This fixes a bug where the return gate is
			-- not properly constructed if the player moves during transport
			-- (because this callback function doesn't get called).
			if not isreturngate and first_time_init then
				local meta = minetest.get_meta(origin)
				meta:set_string("obsidian_gateway_success_" .. ns_key, "yes")
				meta:mark_as_private("obsidian_gateway_success_" .. ns_key)
			end

			-- If the destination is the Abyss, then kill player first.
			-- This helps to prevent player from bringing any foreign items into this realm.
			-- Note: this relies on the teleport code already checking all other preconditions
			-- first. I.e., if this callback returns 'false', then the player absolutely
			-- will be teleported.
			if rc.current_realm_at_pos(pdest) == "abyss" then
				-- Dump player bones, as if they died.
				-- This should behave exactly as if the player died, with the exception of
				-- setting the player's health to 0.
				bones.dump_bones(pname, true)
				local pref = minetest.get_player_by_name(pname)
				pref:set_hp(pova.get_active_modifier(pref, "properties").hp_max)
				pref:get_meta():set_string("last_death_pos", "") -- Fake death.
				give_initial_stuff.give(pref)
			end

			-- Always regenerate portal liquid in the destination portal.
			-- (It will often be missing since no one was near it.)
			-- This function will check if there actually is a gate, here.
			obsidian_gateway.regenerate_liquid(target, northsouth)

			-- If the player is someone other than the owner, using this Gate has consequences.
			if not isowner then
				-- This function is already called normally, when a Gate is used.
				-- Calling it again here, effectively doubles the chance that the user
				-- starts feeling rather ill.
				portal_sickness.on_use_portal(pname)
			end
		end,

		post_teleport_callback = function()
			portal_cb.call_after_use({
				gate_origin = origin,
				gate_orientation = ns_key, -- "ns" or "ew"
				player_name = pname,
				teleport_destination = table.copy(pdest),
			})

			-- Any others in area get brought along, too.
			for k, v in ipairs(friendstobring) do
				local friend = minetest.get_player_by_name(v)
				if friend then
					local fname = friend:get_player_name()

					preload_tp.execute({
						player_name = fname,
						target_position = pdest,
						particle_effects = true,

						pre_teleport_callback = function()
							-- If the destination is the Abyss, then kill player first.
							-- Note: this relies on the teleport code already checking all other preconditions
							-- first. I.e., if this callback returns 'false', then the player absolutely
							-- will be teleported.
							if rc.current_realm_at_pos(pdest) == "abyss" then
								-- Dump player bones, as if they died.
								-- This should behave exactly as if the player died, with the exception of
								-- setting the player's health to 0.
								bones.dump_bones(fname, true)
								local pref = minetest.get_player_by_name(fname)
								pref:set_hp(pova.get_active_modifier(pref, "properties").hp_max)
								pref:get_meta():set_string("last_death_pos", "") -- Fake death.
								give_initial_stuff.give(pref)
							end
						end,

						force_teleport = true,
						send_blocks = true,
					})

					portal_sickness.on_use_portal(fname)
				end
			end

			-- Update liquids around on first init.
			if first_time_init then
				minetest.after(2, function()
					mapfix.execute(target, 10)
				end)
			end

			ambiance.spawn_sound_beacon("soundbeacon:gate", target, 20, 1)
			ambiance.replay_nearby_sound_beacons(target, 6)
			portal_sickness.on_use_portal(pname)

			-- Clear player's "died in MIDFELD" flag, once transport to MIDFELD succeeded.
			if rc.current_realm_at_pos(target) == "midfeld" then
				local pref = minetest.get_player_by_name(pname)
				if pref then
					pref:get_meta():set_int("abyss_return_midfeld", 0)
				end
			end
		end,

		teleport_sound = "nether_portal_usual",
		send_blocks = true,
	})

	return true
end

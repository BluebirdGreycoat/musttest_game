
function obsidian_gateway.on_flamestaff_use(item, user, pt)
	if pt.type ~= "node" then
		return
	end
	if not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	ambiance.sound_play("fire_flint_and_steel", pt.above, 0.7, 10)

	-- Punched node must be one of these.
	do
		local nn = minetest.get_node(pt.under).name
		if nn ~= "default:obsidian" and
				nn ~= "griefer:grieferstone" and
				nn ~= "cavestuff:dark_obsidian" and
				nn ~= "cavestuff:glow_obsidian" then
			return
		end
	end

	local pos = pt.under
	local success, origin, airpoints, northsouth, ns_key, playerorigin =
		obsidian_gateway.find_gate(pos)

	if not success then
		return
	end

	-- Using the staff on an uninitialized gate does nothing.
	do
		local meta = minetest.get_meta(origin)
		local target = meta:get_string("obsidian_gateway_destination_" .. ns_key)
		local dest = minetest.string_to_pos(target)
		if not dest then
			return
		end
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

	local do_effect = false

	do
		local meta = item:get_meta()
		if meta:get_string("gate1") == "" then
			meta:set_string("gate1", minetest.pos_to_string(playerorigin))
			meta:set_string("description", "Flame Staff (Partially Linked)")
			do_effect = true
		elseif meta:get_string("gate2") == "" then
			meta:set_string("gate2", minetest.pos_to_string(playerorigin))
			meta:set_string("description", "Flame Staff (Linked)")
			item:set_wear(1)
			do_effect = true
		end
	end

	if do_effect then
		local p = pt.above
		minetest.sound_play("default_item_smoke", {
			pos = pos,
			max_hear_distance = 8,
		}, true)
		minetest.add_particlespawner({
			amount = 3,
			time = 0.1,
			minpos = {x = p.x - 0.1, y = p.y + 0.1, z = p.z - 0.1 },
			maxpos = {x = p.x + 0.1, y = p.y + 0.2, z = p.z + 0.1 },
			minvel = {x = 0, y = 2.5, z = 0},
			maxvel = {x = 0, y = 2.5, z = 0},
			minacc = {x = -0.15, y = -0.02, z = -0.15},
			maxacc = {x = 0.15, y = -0.01, z = 0.15},
			minexptime = 4,
			maxexptime = 6,
			minsize = 5,
			maxsize = 5,
			collisiondetection = true,
			texture = "default_item_smoke.png"
		})
	end

	-- Success, but do not continue to the teleport logic.
	if do_effect then
		return item
	end

	-- Player must be standing in the gate.
	do
		local posunder = utility.node_under_pos(user:get_pos())
		local namunder = minetest.get_node(posunder).name
		if namunder ~= "default:obsidian" and
				namunder ~= "griefer:grieferstone" and
				namunder ~= "cavestuff:dark_obsidian" and
				namunder ~= "cavestuff:glow_obsidian" then
			return
		end
	end

	do
		local meta = item:get_meta()
		local spos1 = meta:get_string("gate1")
		local spos2 = meta:get_string("gate2")
		if spos1 == "" or spos2 == "" then
			return
		end

		local tar1 = minetest.string_to_pos(spos1)
		local tar2 = minetest.string_to_pos(spos2)
		if not tar1 or not tar2 then
			return
		end

		-- If the linked targets are the same, nothing happens.
		if vector.equals(tar1, tar2) then
			return
		end

		-- If either target is in the Abyss, nothing happens.
		if rc.current_realm_at_pos(tar1) == "abyss" or
				rc.current_realm_at_pos(tar2) == "abyss" then
			return
		end

		-- If player activates gate #2 first, then pretend we didn't notice and just
		-- swap the datums.
		if vector.equals(playerorigin, tar2) then
			local tmp

			tmp = tar1
			tar1 = tar2
			tar2 = tmp

			meta:set_string("gate1", spos2)
			meta:set_string("gate2", spos1)

			tmp = spos1
			spos1 = spos2
			spos2 = tmp

			-- Meta changes do not take effect until we return the itemstack.
		end

		-- Player has activated gate #1.
		-- Send them to the Abyss!
		if vector.equals(playerorigin, tar1) then
			local hidden_spawn = {
				-- Hidden cave tunnel.
				x = -9265, y = 4076, z = 5819

				-- Outback gate room.
				--x = -9174, y = 4100, z = 5782
			}

			preload_tp.execute({
				player_name = pname,
				target_position = hidden_spawn,
				emerge_radius = 8,
				particle_effects = true,
				spinup_time = 2,

				pre_teleport_callback = function()
					-- Need better sound someday.
					coresounds.play_death_sound(user, pname)
				end,

				post_teleport_callback = function()
					portal_sickness.on_use_portal(pname)
				end,
			})

			-- The metadata will have been updated if we swapped datums.
			ambiance.sound_play("fire_flint_and_steel", pos, 0.7, 20)
			item:add_wear_by_uses(20)
			return item
		end

		-- Player has activated a gate in the Abyss. Send then back.
		-- Also destroy the flame staff.
		if rc.current_realm_at_pos(origin) == "abyss" then
			preload_tp.execute({
				player_name = pname,
				target_position = tar2,
				emerge_radius = 16,
				particle_effects = true,
				spinup_time = 2,

				pre_teleport_callback = function()
					obsidian_gateway.regenerate_liquid(tar2, nil)
				end,

				post_teleport_callback = function()
					portal_sickness.on_use_portal(pname)
				end,
			})

			ambiance.sound_play("fire_flint_and_steel", pos, 0.7, 20)
			item:add_wear_by_uses(20)
			return item
		end
	end
end

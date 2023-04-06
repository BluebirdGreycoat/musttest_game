
if not minetest.global_exists("jaunt") then jaunt = {} end
jaunt.modpath = minetest.get_modpath("jaunt")

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round



-- private: assemble a formspec string
function jaunt.get_formspec(player)
	local formspec = "size[4.5,5.5]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots

	formspec = formspec ..
		"item_image[0,0;1,1;passport:passport_adv]" ..
    "label[1,0;Key: Teleport to player beacon.]" ..
    "label[1,0.4;Requires teleport for anchor.]" ..
		"field[0.3,1.3;2.9,1;player;;]" ..
		"button[3.0,1.0;1.5,1;go;Jaunt]" ..
		"field_close_on_enter[player;true]" ..
		"button[1.25,2.0;2.25,1;cancel;Abort]" ..
    "label[0,3;Jaunt range is influenced by the status\nof the target's beacon. Marked players can\nbe found from farther.]" ..
		"item_image[1.25,4.5;1,1;command_tokens:mark_player]" ..
		"item_image[2.25,4.5;1,1;player_labels:show]"

	return formspec
end



-- api: show formspec to player
function jaunt.show_formspec(player)
	local formspec = jaunt.get_formspec(player)
	minetest.show_formspec(player, "jaunt:fs", formspec)
end



-- Find nearby teleport, and return its range.
function jaunt.valid_teleport(pos)
	local tar = minetest.find_node_near(pos, 2, "teleports:teleport", true)
	if tar then
		-- Range is halved because when we're jaunting, there is no teleport at the
		-- other end to receive us! Also, this means that when using a nyan TP, the
		-- range is more-or-less the same as the original, hard-coded jaunt range.
		local range = teleports.calculate_range(tar)
		return true, (range * 0.5)
	end
end



jaunt.on_receive_fields = function(player, formname, fields)
  if formname ~= "jaunt:fs" then return end
  local pname = player:get_player_name()

	-- security check to make sure player can use this feature
	if not passport.player_has_key(pname) then
		return true
	end
	if not survivalist.player_beat_cave_challenge(pname) then
		return true
	end

	-- Jaunt ability is revoked for cheaters.
	if sheriff.is_cheater(pname) then
		return true
	end

	if fields.cancel then
    passport.show_formspec(pname)
		return true
	end
	if fields.quit then
		return true
	end

	local uspos = vector_round(player:get_pos())

	if fields.key_enter_field == "player" or fields.go then
		local success, tp_range = jaunt.valid_teleport(uspos)

		if success then -- Teleport was found.
			local target = rename.grn((fields.player or ""):trim())
			if target ~= pname then
				local other = minetest.get_player_by_name(target)
				if other and other:is_player() and not cloaking.is_cloaked(target) then
					local marked = command_tokens.mark.player_marked(target)
					local beacon = player_labels.query_nametag_onoff(target)

					-- a player can be located if either they're marked or their beacon (nametag) is activated
					if marked or beacon then
						if passport.player_has_key(target) then
							-- if a player is marked, but their beacon is off, then the range at which
							-- they can be detected is halved
							local range = tp_range
							if marked and not beacon then
								range = range * 0.5
							elseif marked and beacon then
								range = range * 1.5
							end

							local tarpos = other:get_pos()
							tarpos.y = tarpos.y + 1
							tarpos = vector_round(tarpos)

							if rc.current_realm_at_pos(tarpos) == rc.current_realm_at_pos(uspos) then
								if vector_distance(tarpos, uspos) < range then
									-- Alert player that someone's coming to them.
									local RED = core.get_color_escape_sequence("#ff0000")
									minetest.chat_send_player(target,
										RED .. "# Server: Alert! Incoming jaunt from <" ..
										rename.gpn(pname) .. ">.")
									chat_core.alert_player_sound(target)

									-- Teleport player to chosen location.
									preload_tp.execute({
										player_name = pname,
										target_position = tarpos,
										send_blocks = true,
										particle_effects = true,

										-- Pre-teleport callback.
										pre_teleport_callback = function()
											-- Abort teleport if target player cloaked themselves.
											if cloaking.is_cloaked(target) then
												minetest.chat_send_player(pname, "# Server: Lost link to target beacon.")
												return true -- Abort transport.
											end
										end,

										-- Post-teleport callback.
										post_teleport_callback = function()
											portal_sickness.on_use_portal(pname)
										end,
									})

									-- don't reshow the formspec
									minetest.close_formspec(pname, "jaunt:fs")
									return true
								else
									minetest.chat_send_player(pname, "# Server: Target Key's signal origin is too weak to accurately triangulate!")
								end
							else
								minetest.chat_send_player(pname, "# Server: Target's Key is not located in this realm!")
							end
						else
							minetest.chat_send_player(pname, "# Server: Target's beacon signal does not originate from an authentic Key device.")
						end
					else
						minetest.chat_send_player(pname, "# Server: Could not detect evidence of a Key's beacon signal.")
					end
				else
					minetest.chat_send_player(pname, "# Server: Could not detect evidence of a Key's beacon signal.")
				end
			else
				minetest.chat_send_player(pname, "# Server: Cleverly refusing to scan for your own Key's beacon signal.")
			end
		else
			minetest.chat_send_player(pname, "# Server: Your Key requires access to a proximate teleport to deploy this function.")
		end
	end

	jaunt.show_formspec(pname)
  return true
end



if not jaunt.registered then
  minetest.register_on_player_receive_fields(function(...)
		return jaunt.on_receive_fields(...)
	end)

	local c = "jaunt:core"
	local f = jaunt.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	jaunt.registered = true
end

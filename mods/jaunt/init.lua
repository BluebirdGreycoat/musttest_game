
jaunt = jaunt or {}
jaunt.modpath = minetest.get_modpath("jaunt")
jaunt.jump_range = 1000

-- private: assemble a formspec string
function jaunt.get_formspec(player)
	local formspec = "size[4.5,2.6]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots

	formspec = formspec ..
		"item_image[0,0;1,1;passport:passport_adv]" ..
    "label[1,0;Key: Teleport to Player Beacon]" ..
    "label[1,0.4;Requires Teleport for Anchor]" ..
		"field[0.3,1.3;2.9,1;player;;]" ..
		"button[3.0,1.0;1.5,1;go;Jaunt]" ..
		"button[1.25,2.0;2.25,1;cancel;Abort]"

	return formspec
end

-- api: show formspec to player
function jaunt.show_formspec(player)
	local formspec = jaunt.get_formspec(player)
	minetest.show_formspec(player, "jaunt:fs", formspec)
end

jaunt.on_receive_fields = function(player, formname, fields)
  if formname ~= "jaunt:fs" then return end
  local pname = player:get_player_name()

	-- security check to make sure player can use this feature
	local inv = player:get_inventory()
	if not inv:contains_item("main", "passport:passport_adv") then
		return true
	end
	if not survivalist.player_beat_cave_challenge(pname) then
		return true
	end

	if fields.cancel then
    passport.show_formspec(pname)
		return true
	end
	if fields.quit then
		return true
	end

	if fields.go then
		if sky.get_last_walked_node(pname) == "teleports:teleport" then
			local target = rename.grn((fields.player or ""):trim())
			if target ~= pname then
				local other = minetest.get_player_by_name(target)
				if other and other:is_player() then
					local marked = command_tokens.mark.player_marked(target)
					local beacon = player_labels.query_nametag_onoff(target)

					-- a player can be located if either they're marked or their beacon is activated
					if marked or beacon then
						-- if a player is marked, but their beacon is off, then the range at which
						-- they can be detected is halved
						local range = jaunt.jump_range
						if marked and not beacon then
							range = range / 2
						elseif marked and beacon then
							range = range * 2
						end

						local tarpos = vector.round(other:get_pos())
						if vector.distance(tarpos, player:get_pos()) < range then

							-- Teleport player to chosen location.
							preload_tp.preload_and_teleport(pname, tarpos, 16, nil,
							function()
								portal_sickness.on_use_portal(pname)
							end,
							nil, false)

							-- don't reshow the formspec
							minetest.close_formspec(pname, "jaunt:fs")
							return true
						else
							minetest.chat_send_player(pname, "# Server: Target signal origin is too weak to accurately triangulate!")
						end
					else
						minetest.chat_send_player(pname, "# Server: Could not detect evidence of a beacon signal.")
					end
				else
					minetest.chat_send_player(pname, "# Server: Could not detect evidence of a beacon signal.")
				end
			else
				minetest.chat_send_player(pname, "# Server: Cleverly refusing to scan for own beacon signal.")
			end
		else
			minetest.chat_send_player(pname, "# Server: You need to be standing on a teleport for this function of the Key to work.")
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

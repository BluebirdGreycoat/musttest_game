
-- Cloaking system for players.
-- Note: admin has special invisibility system in gdac_invis directory.
cloaking = cloaking or {}
cloaking.modpath = minetest.get_modpath("cloaking")
cloaking.players = cloaking.players or {}

function cloaking.do_scan(pname)
	-- If player is cloaked, check for reasons to disable the cloak.
	if cloaking.players[pname] then
		local pref = minetest.get_player_by_name(pname)
		if pref then
			local pos = pref:get_pos()

			local player_count = 0
			local mob_count = 0

			-- If there are nearby entities, disable the cloak.
			local objs = minetest.get_objects_inside_radius(pos, 5)
			for i = 1, #objs, 1 do
				if objs[i]:is_player() and objs[i]:get_hp() > 0 then
					if not gdac.player_is_admin(objs[i]) then
						player_count = player_count + 1
					end
				else
					local ent = objs[i]:get_luaentity()
					if ent and ent.mob then
						mob_count = mob_count + 1
					end
				end
			end

			-- There will always be at least one player (themselves).
			if player_count > 1 or mob_count > 0 then
				cloaking.toggle_cloak(pname)
			end
		end
	end

	-- If cloak still enabled for this player, then check again in 1 second.
	if cloaking.players[pname] then
		minetest.after(1, cloaking.do_scan, pname)
	end
end

function cloaking.is_cloaked(pname)
	if cloaking.players[pname] then
		return true
	end
	return false
end

function cloaking.toggle_cloak(pname)
  local player = minetest.get_player_by_name(pname)
  if not player or not player:is_player() then
		return
	end

	if not cloaking.players[pname] then
		-- Enable cloak.
		cloaking.players[pname] = true
		player_labels.disable_nametag(pname)

		-- Notify so health gauges can be removed.
		gauges.on_teleport()

		player:set_properties({
			visual_size = {x=0, y=0},
			is_visible = false,
			pointable = false,
		})

		minetest.chat_send_player(pname, "# Server: Cloak activated.")

		-- Enable scanning for reasons to cancel the cloak.
		minetest.after(1, cloaking.do_scan, pname)
	else
		-- Disable cloak.
		cloaking.players[pname] = nil
		player_labels.enable_nametag(pname)

		-- Restore player properties.
		player:set_properties({
			visual_size = {x=1, y=1},
			is_visible = true,
			pointable = true,
		})

		minetest.chat_send_player(pname, "# Server: Cloak offline.")
	end
end

-- Disable cloak if player dies.
function cloaking.on_dieplayer(player, reason)
	local pname = player:get_player_name()
	if cloaking.is_cloaked(pname) then
		-- Ensure cloak is disabled *after* player is dead (and bones spawned), not before!
		minetest.after(0, cloaking.toggle_cloak, pname)
	end
end

-- Cleanup player info on leave game.
function cloaking.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()
	cloaking.players[pname] = nil
end

if not cloaking.registered then
	minetest.register_on_dieplayer(function(...)
		cloaking.on_dieplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		cloaking.on_leaveplayer(...)
	end)

	local c = "cloaking:core"
	local f = cloaking.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	cloaking.registered = true
end

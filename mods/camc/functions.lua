
local function hide_hud(player)
	player:hud_set_flags({
		hotbar = false,
		healthbar = false,
		crosshair = false,
		wielditem = false,
		breathbar = false,
		minimap = false,
		minimap_radar = false,
		basic_debug = false,
		chat = false,
	})
end

function camc.on_joinplayer(player)
	if minetest.check_player_privs(player, {camc=true}) then
		local pname = player:get_player_name()
		gdac_invis.toggle_invisibility(pname, "")

		hide_hud(player)

		-- By default, camera client starts in explore mode.
		-- This lets us do something useful in case the client disconnects
		-- and has to rejoin.
		minetest.after(10, function() camc.start_exploring() end)
	end
end

function camc.on_leaveplayer(player)
	camc.set_following(nil)
	camc.stop_exploring()
end

function camc.player_is_camera(player_or_name)
	if type(player_or_name) ~= "string" then
		player_or_name = player_or_name:get_player_name()
	end

	-- API call always expects a string playername.
	local privs = minetest.get_player_privs(player_or_name)

	if privs.camc then
		return true
	end
end

-- Get regular, hauntable players.
local function get_regular_players()
	local regular = {}
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if not gdac.player_is_admin(v) and not camc.player_is_camera(v) then
			local pname = v:get_player_name()
			if player_labels.query_nametag_onoff(pname) == true then
				regular[#regular + 1] = v
			end
		end
	end
	return regular
end

function camc.check_camera_activity(params)
	if not params then
		params = {}
	end

	local pcam = minetest.get_player_by_name(camc.HAWKCAM_PLAYER)
	if pcam and camc.player_is_camera(pcam) then
		local old_pos = params.old_pos
		local new_pos = pcam:get_pos()
		params.old_pos = new_pos

		if old_pos then
			if rc.is_valid_realm_pos(old_pos) and rc.is_valid_realm_pos(new_pos) then
				if vector.distance(old_pos, new_pos) < 1 then
					-- Camera hasn't moved in some time.
					camc.set_following(nil)
					camc.stop_exploring()

					rplayers = get_regular_players()

					if #rplayers > 3 then
						if not camc.start_haunting() then
							camc.start_exploring()
						end
					else
						if not camc.start_exploring() then
							camc.start_haunting()
						end
					end
				end
			end
		end
	end

	minetest.after(camc.CAMERA_ACTIVITY_CHECK_SECONDS, function()
		camc.check_camera_activity(params)
	end)
end

function camc.start_camera_checks()
	minetest.after(camc.CAMERA_ACTIVITY_CHECK_SECONDS, function()
		camc.check_camera_activity()
	end)
end

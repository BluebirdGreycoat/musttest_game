
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

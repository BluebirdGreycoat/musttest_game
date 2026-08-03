
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
	end
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

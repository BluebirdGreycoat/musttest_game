
if not minetest.global_exists("camc") then camc = {} end
camc.modpath = minetest.get_modpath("camc")

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

	local privs = minetest.get_player_privs(player_or_name)

	if privs.camc then
		return true
	end
end

if not camc.run_once then
	camc.run_once = true

	local c = "camc:core"
	local f = camc.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	minetest.register_privilege("camc", {
		description = "Whateff.",
		give_to_singleplayer = false,
		give_to_admin = false,
	})

	minetest.register_on_joinplayer(function(...)
		return camc.on_joinplayer(...)
	end)
end


if not minetest.global_exists("camc") then camc = {} end
camc.modpath = minetest.get_modpath("camc")

function camc.on_joinplayer(player)
	if minetest.check_player_privs(player, {camc=true}) then
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
	})

	minetest.register_on_joinplayer(function(...)
		return camc.on_joinplayer(...)
	end)
end

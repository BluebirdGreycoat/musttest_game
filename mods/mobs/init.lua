
if not minetest.global_exists("mobs") then mobs = {} end
mobs.modpath = minetest.get_modpath("mobs")

-- Options.
mobs.debug_paths = false -- Show paths to administrator?
mobs.report_name = "" -- Name of mob for which to send reports to admin.
mobs.enable_reports = false

minetest.register_privilege("mobs_ignore", {
	description = "Mobs will ignore player.",
	give_to_singleplayer = false,
})

dofile(mobs.modpath .. "/api.lua")
dofile(mobs.modpath .. "/crafts.lua")
dofile(mobs.modpath .. "/spawner.lua")
reload.register_file("mobs:chat", mobs.modpath .. "/chat.lua", true)

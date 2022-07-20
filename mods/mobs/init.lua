
mobs = mobs or {}
mobs.modpath = minetest.get_modpath("mobs")
mobs.debug_paths = false
mobs.report_name = ""


minetest.register_privilege("mob_respect", {
    description = "Mobs will respect player.",
    give_to_singleplayer = false,
})



dofile(mobs.modpath .. "/api.lua")
dofile(mobs.modpath .. "/crafts.lua")
dofile(mobs.modpath .. "/spawner.lua")



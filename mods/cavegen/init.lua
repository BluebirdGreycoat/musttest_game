
if not minetest.global_exists("cavegen") then cavegen = {} end
cavegen.modpath = minetest.get_modpath("cavegen")

minetest.register_mapgen_script(cavegen.modpath .. "/generator.lua")


if not minetest.global_exists("darkgen") then darkgen = {} end
darkgen.modpath = minetest.get_modpath("darkgen")

minetest.register_mapgen_script(darkgen.modpath .. "/mapgen.lua")


if not minetest.global_exists("cavegen") then cavegen = {} end
cavegen.modpath = minetest.get_modpath("cavegen")



dofile(cavegen.modpath .. "/generator.lua")

minetest.register_on_generated(function(...)
  cavegen.generate(...)
end)

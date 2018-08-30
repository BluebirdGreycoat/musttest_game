
darkgen = darkgen or {}
darkgen.modpath = minetest.get_modpath("darkgen")

darkgen.SHEET_HEIGHT = 20

dofile(darkgen.modpath .. "/noise.lua")
dofile(darkgen.modpath .. "/mapgen.lua")

-- Register the mapgen callback.
minetest.register_on_generated(function(...)
  darkgen.generate_realm(...)
end)



if not minetest.global_exists("mossgrowth") then mossgrowth = {} end
mossgrowth.modpath = minetest.get_modpath("mossgrowth")



-- Moss growth on cobble near water.
-- This ABM is now PERMANENTLY disabled.
-- Profiling showed it to take too much CPU time.

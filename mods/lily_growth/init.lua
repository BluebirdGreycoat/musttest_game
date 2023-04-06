
if not minetest.global_exists("lily_growth") then lily_growth = {} end
lily_growth.modpath = minetest.get_modpath("lily_growth")

-- Grow water plants.
-- This (ABM) is no longer needed. Lilies are grow via callbacks+nodetimer.
-- ABM code now removed entirely.

xtraores  = {}
xtraores.path = minetest.get_modpath("xtraores")

-- Minerals.
dofile(xtraores.path .. "/minerals.lua")

-- Lumps.
dofile(xtraores.path .. "/ores.lua")

-- Bars.
dofile(xtraores.path .. "/items.lua")

-- Don't add a bunch new armors/tools. :( It's hard enough finding/adjusting
-- unique stats for the weapons/armor I already have.
-- dofile(xtraores.path .. "/armor.lua")
-- dofile(xtraores.path .. "/tools.lua")

-- Bricks.
dofile(xtraores.path .. "/oreblocks.lua")

-- No special weapons (guns/revolver). Doesn't really fit.
-- dofile(xtraores.path .. "/special_weapons.lua")

-- This is just the antracite torch. Seems to already be good for 3D, would fit
-- well with Naraxen's look. Maybe fix this up someday.
-- dofile(xtraores.path .. "/other_blocks.lua")

-- Special shapes.
dofile(xtraores.path .. "/walls.lua")
dofile(xtraores.path .. "/stairs.lua")

-- Mapgen ore registrations.
dofile(xtraores.path .. "/mapgen.lua")

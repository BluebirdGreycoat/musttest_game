
nethermapgen = nethermapgen or {}
nethermapgen.modpath = minetest.get_modpath("nethermapgen")

nethermapgen.NETHER_START = -25000
nethermapgen.BRIMSTONE_OCEAN = -30800
nethermapgen.BEDROCK_DEPTH = -30900

dofile(nethermapgen.modpath .. "/override.lua")
dofile(nethermapgen.modpath .. "/noise.lua")
dofile(nethermapgen.modpath .. "/functions.lua")
dofile(nethermapgen.modpath .. "/oregen.lua")

-- The mapgen function & voxel manipulator code.
dofile(nethermapgen.modpath .. "/mapgen.lua")

-- Register the mapgen callback.
minetest.register_on_generated(function(...)
  nethermapgen.generate_realm(...)
end)


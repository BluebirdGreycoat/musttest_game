
if not minetest.global_exists("nethermapgen") then nethermapgen = {} end
nethermapgen.modpath = minetest.get_modpath("nethermapgen")

-- These are copied in the mapgen script, they MUST match.
nethermapgen.NETHER_START = -25000
nethermapgen.BRIMSTONE_OCEAN = -30800
nethermapgen.BEDROCK_DEPTH = -30900

dofile(nethermapgen.modpath .. "/override.lua")
dofile(nethermapgen.modpath .. "/oregen.lua")

function nethermapgen.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["nether:mapgen_info"])
	if not data then return end

	-- 2024/6/8: this ugly hack is currently the best way I know of to make light
	-- correct after chunk generation.
	minetest.after(math.random(1, 100) / 50, function()
		local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
		local emax = vector.add(data.maxp, {x=16, y=16, z=16})
		--minetest.chat_send_all('mapfix')
		mapfix.work(emin, emax)
	end)
end

minetest.set_gen_notify("custom", nil, {"nether:mapgen_info"})
minetest.register_on_generated(function(...)
	nethermapgen.on_generated(...)
end)

-- The mapgen function & voxel manipulator code.
minetest.register_mapgen_script(nethermapgen.modpath .. "/mapgen.lua")

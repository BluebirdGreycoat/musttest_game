--------------------------------------------------------------------------------
-- Gem Mapgen Mod for Must Test Survival
-- Author: GoldFireUn
-- License of Source Code: MIT
--------------------------------------------------------------------------------

gem_mapgen = gem_mapgen or {}
gem_mapgen.modpath = minetest.get_modpath("gem_mapgen")

if not gem_mapgen.registered then
	local ores = {
		{ore="ruby", scar=48, num=4, size=3, ymin=-30000, ymax=-15000},
		{ore="ruby", scar=24, num=6, size=3, ymin=-20000, ymax=-18000},
		{ore="amethyst", scar=45, num=4, size=3, ymin=-30000, ymax=-5000},
		{ore="amethyst", scar=22, num=6, size=3, ymin=-9000, ymax=-6000},
		{ore="sapphire", scar=42, num=4, size=2, ymin=-30000, ymax=-18000},
		{ore="sapphire", scar=28, num=6, size=3, ymin=-21000, ymax=-18000},
		{ore="emerald", scar=40, num=4, size=2, ymin=-30000, ymax=-5000},
		{ore="emerald", scar=27, num=6, size=3, ymin=-10000, ymax=-8000},
	}

	for k, v in ipairs(ores) do
		local ore = "gems:" .. v.ore .. "_ore"
		local stone = "default:stone"
		local scarcity = v.scar * v.scar * v.scar

		oregen.register_ore({
			ore_type       = "scatter",
			ore            = ore,
			wherein        = stone,
			clust_scarcity = scarcity,
			clust_num_ores = v.num,
			clust_size     = v.size,
			y_min          = v.ymin,
			y_max          = v.ymax,
		})
	end

	local c = "gem_mapgen:core"
	local f = gem_mapgen.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	gem_mapgen.registered = true
end

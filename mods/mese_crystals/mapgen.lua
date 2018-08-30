
if not mese_crystals.mapgen_registered then
	oregen.register_ore({
		ore_type       = "scatter",
		ore            = "mese_crystals:mese_crystal_ore1",
		wherein        = {"rackstone:redrack", "rackstone:mg_redrack"},
		clust_scarcity = 18 * 18 * 18,
		clust_num_ores = 1,
		clust_size     = 5,
		y_min          = -31000,
		y_max          = -25000,
	})

	oregen.register_ore({
		ore_type       = "scatter",
		ore            = "mese_crystals:mese_crystal_ore2",
		wherein        = {"rackstone:redrack", "rackstone:mg_redrack"},
		clust_scarcity = 20 * 20 * 20,
		clust_num_ores = 1,
		clust_size     = 5,
		y_min          = -31000,
		y_max          = -27000,
	})

	oregen.register_ore({
		ore_type       = "scatter",
		ore            = "mese_crystals:mese_crystal_ore3",
		wherein        = {"rackstone:redrack", "rackstone:mg_redrack"},
		clust_scarcity = 20 * 20 * 20,
		clust_num_ores = 1,
		clust_size     = 3,
		y_min          = -31000,
		y_max          = -29000,
	})

	oregen.register_ore({
		ore_type       = "scatter",
		ore            = "mese_crystals:mese_crystal_ore4",
		wherein        = {"rackstone:redrack", "rackstone:mg_redrack"},
		clust_scarcity = 20 * 20 * 20,
		clust_num_ores = 1,
		clust_size     = 5,
		y_min          = -31000,
		y_max          = -30000,
	})

	mese_crystals.mapgen_registered = true
end

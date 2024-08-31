
local REALM_START = 10150
local REALM_END = 15150

local sheet_ores = {
	{ore="morerocks:marble", seed=1, threshhold=0.3},
	{ore="morerocks:serpentine", seed=2, threshhold=0.4},
	{ore="morerocks:marble_pink", seed=3, threshhold=0.2},
	{ore="morerocks:marble_white", seed=4, threshhold=0.2},
	{ore="morerocks:granite", seed=5, threshhold=0.0},
}
local SHEET_ORE_SEED_FLOOR = 8827

for index, data in ipairs(sheet_ores) do
	minetest.register_ore({
		ore_type = "sheet",
		ore = data.ore,
		wherein = "default:stone",
		column_height_min = 4,
		column_height_max = 10,
		column_midpoint_factor = 0.5,
		y_min = REALM_START,
		y_max = REALM_END,
		noise_threshhold = 0.8 + data.threshhold,
		noise_params = {
			offset = 0,
			scale = 2,
			spread = {x=100, y=100, z=100},
			seed = SHEET_ORE_SEED_FLOOR + data.seed,
			octaves = 2,
			persist = 0.8,
		}
	})
end



local scatter_ores = {
	-- Specials.
	{ore="default:mossycobble", seed=298, threshhold=-0.3, scarcity=8, count=8, size=3, wherein="default:cobble"},
	{ore="cavestuff:dark_obsidian", seed=11, threshhold=-0.3, scarcity=8, count=8, size=3, wherein="default:obsidian"},

	-- Commons.
	{ore="default:stone_with_coal", seed=1, threshhold=0.1, scarcity=8, count=8, size=3},
	{ore="default:stone_with_iron", seed=2, threshhold=0.2, scarcity=7, count=5, size=3},
	{ore="default:stone_with_copper", seed=3, threshhold=0.2, scarcity=9, count=5, size=3},
	{ore="quartz:quartz_ore", seed=30, threshhold=0.1, scarcity=9, count=5, size=3},

	-- Rares.
	{ore="default:stone_with_gold", seed=4, threshhold=0.4, scarcity=13, count=5, size=3},
	{ore="default:stone_with_mese", seed=5, threshhold=0.4, scarcity=14, count=5, size=3},
	{ore="default:stone_with_diamond", seed=6, threshhold=0.4, scarcity=15, count=4, size=3},
	{ore="default:mese", seed=6, threshhold=0.5, scarcity=36, count=4, size=2},
}
local SCATTER_ORE_SEED_FLOOR = 2818

for index, data in ipairs(scatter_ores) do
	minetest.register_ore({
		ore_type = "scatter",
		ore = data.ore,
		wherein = data.wherein or {"default:stone", "default:cobble"},
		y_min = REALM_START,
		y_max = REALM_END,
    clust_scarcity = data.scarcity * data.scarcity * data.scarcity,
    clust_num_ores = data.count,
    clust_size     = data.size,
		noise_threshhold = -0.1 + data.threshhold,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=500, y=500, z=500},
			seed = SCATTER_ORE_SEED_FLOOR + data.seed,
			octaves = 4,
			persist = 0.5,
		}
	})
end


local REALM_START = 21150
local REALM_END = 23450
local REALM_GROUND = 21150+2000

local sheet_ores = {
	{ore="morerocks:granite", seed=565, threshhold=0.0},
	{ore="rackstone:blackrack", seed=22, threshhold=0.0},
	{ore="rackstone:dauthsand", seed=7712, threshhold=0.0, y_max=REALM_GROUND-300},
	{ore="default:dirt", seed=2382, threshhold=-1.2, y_max=REALM_START+300},
}
local SHEET_ORE_SEED_FLOOR = 48115

for index, data in ipairs(sheet_ores) do
	minetest.register_ore({
		ore_type = "sheet",
		ore = data.ore,
		wherein = "rackstone:rackstone",
		column_height_min = 4,
		column_height_max = 10,
		column_midpoint_factor = 0.5,
		y_min = data.y_min or REALM_START,
		y_max = data.y_max or REALM_END,
		noise_threshold = 0.8 + data.threshhold,
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



local LAVA_MIN = REALM_START
local LAVA_MAX = REALM_START + 600
local SPECIALS_MAX = REALM_START + 1000
local EXTRA_COMMONS_DEPTH = REALM_START + 1500

local scatter_ores = {
	-- Commons.
	{ore="rackstone:dauthsand", seed=1, threshhold=0.1, scarcity=15, count=10, size=4, wherein={"rackstone:cobble"}},
	{ore="rackstone:rackstone_with_coal", seed=1, threshhold=-0.2, scarcity=17, count=8, size=3, wherein={"rackstone:rackstone", "rackstone:cobble"}},
	{ore="rackstone:rackstone_with_iron", seed=2, threshhold=-0.2, scarcity=17, count=5, size=3, wherein={"rackstone:rackstone", "rackstone:cobble"}},
	{ore="rackstone:rackstone_with_copper", seed=3, threshhold=-0.2, scarcity=17, count=5, size=3},
	{ore="rackstone:rackstone_with_meat", seed=13, threshhold=-0.2, scarcity=16, count=5, size=3},
	{ore="rackstone:redrack_cobble", seed=13, threshhold=-0.2, scarcity=15, count=5, size=3},

	-- Commons which increase with depth.
	{ore="rackstone:rackstone_with_coal", seed=1187, threshhold=-0.2, scarcity=12, count=8, size=4, y_max=EXTRA_COMMONS_DEPTH},
	{ore="rackstone:rackstone_with_iron", seed=482, threshhold=-0.2, scarcity=13, count=5, size=4, y_max=EXTRA_COMMONS_DEPTH},
	{ore="rackstone:rackstone_with_copper", seed=2283, threshhold=-0.2, scarcity=13, count=5, size=4, y_max=EXTRA_COMMONS_DEPTH},

	-- Rares.
	{ore="rackstone:rackstone_with_gold", seed=4, threshhold=0.4, scarcity=24, count=4, size=3, y_max=SPECIALS_MAX},
	{ore="rackstone:rackstone_with_mese", seed=5, threshhold=0.4, scarcity=24, count=4, size=3, y_max=SPECIALS_MAX},
	{ore="rackstone:rackstone_with_diamond", seed=6, threshhold=0.4, scarcity=24, count=4, size=3, y_max=SPECIALS_MAX},

	-- Glows.
	{ore="glowstone:cobble", seed=837, threshhold=0.2, scarcity=15, count=3, size=10},
	{ore="glowstone:minerals", seed=838, threshhold=0.2, scarcity=20, count=3, size=10, wherein={"rackstone:cobble"}},

	-- Problems for the player.
	{ore="default:lava_source", seed=523, threshhold=-0.2, scarcity=15, count=5, size=3, y_min=LAVA_MIN, y_max=LAVA_MAX},
	{ore="default:lava_source", seed=557, threshhold=0.2, scarcity=32, count=10, size=9, y_min=LAVA_MIN, y_max=LAVA_MAX},
}
local SCATTER_ORE_SEED_FLOOR = 48921

for index, data in ipairs(scatter_ores) do
	minetest.register_ore({
		ore_type = "scatter",
		ore = data.ore,
		wherein = data.wherein or {"rackstone:rackstone"},
		y_min = data.y_min or REALM_START,
		y_max = data.y_max or REALM_END,
    clust_scarcity = data.scarcity * data.scarcity * data.scarcity,
    clust_num_ores = data.count,
    clust_size     = data.size,
		noise_threshold = -0.1 + data.threshhold,
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

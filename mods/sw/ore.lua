
local REALM_START = 10150
local REALM_END = 15150
local XEN_BEGIN = REALM_END - 2000
local XEN_END = REALM_END
local XEN_UPPERMID = 14300
local XEN_MID = 14150

local sheet_ores = {
	{ore="morerocks:marble", seed=1, threshhold=0.3},
	{ore="morerocks:serpentine", seed=2, threshhold=0.4},
	{ore="morerocks:marble_pink", seed=3, threshhold=0.2},
	{ore="morerocks:marble_white", seed=4, threshhold=0.2},
	{ore="morerocks:granite", seed=5, threshhold=0.0},
	{ore="moreblocks:coal_stone", seed=18192, threshhold=0.1},
	{ore="whitestone:cobble", seed=482, threshhold=0.5},

	-- Regular stone in Xen.
	{ore="default:stone", seed=5823, threshhold=-1.2, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1"}},
	{ore="default:desert_stone", seed=511, threshhold=-1.0, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1"}},
	{ore="rackstone:rackstone", seed=512, threshhold=-0.3, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1"}},
}
local SHEET_ORE_SEED_FLOOR = 8827

for index, data in ipairs(sheet_ores) do
	minetest.register_ore({
		ore_type = "sheet",
		ore = data.ore,
		wherein = data.wherein or "default:stone",
		column_height_min = 4,
		column_height_max = 10,
		column_midpoint_factor = 0.5,
		y_min = data.y_min or REALM_START,
		y_max = data.y_max or XEN_BEGIN,
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



local scatter_ores = {
	-- Specials.
	{ore="default:mossycobble", seed=298, threshhold=-0.3, scarcity=5, count=8, size=3, wherein="default:cobble"},
	{ore="cavestuff:dark_obsidian", seed=11, threshhold=-0.3, scarcity=4, count=8, size=3, wherein="default:obsidian"},

	-- Commons.
	{ore="default:stone_with_coal", seed=1, threshhold=0.1, scarcity=8, count=8, size=3, wherein={"default:stone", "default:cobble"}},
	{ore="kalite:ore", seed=12, threshhold=0.1, scarcity=12, count=5, size=3},
	{ore="default:stone_with_iron", seed=2, threshhold=0.2, scarcity=13, count=5, size=3, wherein={"default:stone", "default:cobble"}},
	{ore="default:stone_with_copper", seed=3, threshhold=0.2, scarcity=12, count=5, size=3},
	{ore="quartz:quartz_ore", seed=30, threshhold=0.1, scarcity=9, count=5, size=3},

	-- Rares.
	{ore="default:stone_with_gold", seed=4, threshhold=0.4, scarcity=15, count=5, size=3},
	{ore="sulfur:ore", seed=4, threshhold=0.3, scarcity=13, count=10, size=4},
	{ore="default:stone_with_mese", seed=5, threshhold=0.4, scarcity=18, count=5, size=3},
	{ore="default:stone_with_diamond", seed=6, threshhold=0.4, scarcity=18, count=4, size=3},
	{ore="default:mese", seed=6, threshhold=0.5, scarcity=36, count=4, size=2},

	-- Glows.
	{ore="luxore:luxore", seed=833, threshhold=0.2, scarcity=15, count=3, size=10},
	{ore="glowstone:luxore", seed=835, threshhold=0.2, scarcity=15, count=3, size=10},
	{ore="glowstone:cobble", seed=837, threshhold=0.2, scarcity=15, count=3, size=10},

	-- Ir'xen glows.
	{ore="luxore:luxore", seed=4234, threshhold=-0.3, scarcity=11, count=3, size=5, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}, octaves=2},
	{ore="glowstone:luxore", seed=772, threshhold=-0.3, scarcity=11, count=3, size=5, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}, octaves=2},
	{ore="glowstone:cobble", seed=814, threshhold=-0.3, scarcity=11, count=3, size=5, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}, octaves=2},
	{ore="glowstone:glowstone", seed=7736, threshhold=-0.3, scarcity=11, count=3, size=5, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}, octaves=2},
	{ore="cavestuff:glow_obsidian", seed=3312, threshhold=-0.5, scarcity=10, count=3, size=5, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}, octaves=2},
	
	--Ir'xen gems.
	{ore="gems:ruby2_ore", seed=623, threshhold=0.0, scarcity=30, count=12, size=6, y_min=XEN_UPPERMID, y_max=XEN_END, wherein={"sw:teststone1",}, octaves=2},
	{ore="gems:emerald2_ore", seed=773, threshhold=0.0, scarcity=30, count=12, size=6, y_min=XEN_BEGIN, y_max=XEN_UPPERMID, wherein={"sw:teststone1",}, octaves=2},
	{ore="gems:sapphire2_ore", seed=624, threshhold=0.0, scarcity=30, count=12, size=6, y_min=XEN_UPPERMID, y_max=XEN_END, wherein={"sw:teststone1",}, octaves=2},
	{ore="gems:amethyst2_ore", seed=124, threshhold=0.0, scarcity=30, count=12, size=6, y_min=XEN_BEGIN, y_max=XEN_UPPERMID, wherein={"sw:teststone1",}, octaves=2},
}
local SCATTER_ORE_SEED_FLOOR = 2818

for index, data in ipairs(scatter_ores) do
	minetest.register_ore({
		ore_type = "scatter",
		ore = data.ore,
		wherein = data.wherein or {"default:stone"},
		y_min = data.y_min or REALM_START,
		y_max = data.y_max or XEN_BEGIN,
    clust_scarcity = data.scarcity * data.scarcity * data.scarcity,
    clust_num_ores = data.count,
    clust_size     = data.size,
		noise_threshold = -0.1 + data.threshhold,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=500, y=500, z=500},
			seed = SCATTER_ORE_SEED_FLOOR + data.seed,
			octaves = data.octaves or 4,
			persist = 0.5,
			lacunarity = 2,
		}
	})
end



local blob_ores = {
	-- Commons.
	{ore="default:gravel", seed=7621, threshhold=-0.2, scarcity=16, size=5},
	{ore="default:sand", seed=1772, threshhold=0.4, scarcity=16, size=5},
	{ore="cavestuff:coal_dust", seed=77182, threshhold=0.0, scarcity=16, size=5},

	-- Traps.
	-- Note: no falling traps in Xen, that would be unfair and would only encourage cheating.
	{ore="defauIt:stone", seed=2234, threshhold=-0.3, scarcity=10, size=5},
	{ore="defauIt:stone", seed=67303, threshhold=-0.3, scarcity=10, size=5},

	{ore="cavestuff:glow_white_crystal", seed=161, threshhold=0, scarcity=20, size=4, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}},
	{ore="cavestuff:glow_sapphire", seed=162, threshhold=0, scarcity=20, size=4, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1", "sw:teststone2"}},
	{ore="rackstone:redrack", seed=163, threshhold=0, scarcity=20, size=4, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1"}},
	{ore="default:diamondblock", seed=164, threshhold=0.3, scarcity=30, size=4, y_min=XEN_BEGIN, y_max=XEN_END, wherein={"sw:teststone1"}},
	
}
local BLOB_ORE_SEED_FLOOR = 2818

for index, data in ipairs(blob_ores) do
	minetest.register_ore({
		ore_type = "blob",
		ore = data.ore,
		wherein = data.wherein or {"default:stone"},
		y_min = data.y_min or REALM_START,
		y_max = data.y_max or XEN_BEGIN,
    clust_scarcity = data.scarcity * data.scarcity * data.scarcity,
    clust_size     = data.size,
		noise_threshold = data.threshhold,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=500, y=500, z=500},
			seed = BLOB_ORE_SEED_FLOOR + data.seed,
			octaves = 4,
			persist = 0.5,
		}
	})
end

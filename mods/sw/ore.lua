
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
		y_min = 10150,
		y_max = 15150,
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

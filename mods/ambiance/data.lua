
-- This file is reloadable.

-- Localize for performance.
local math_random = math.random



-- Table of registered sounds. Algorithm intended for intermittent sounds only, continuous sounds need special treatment.
-- Data includes what environment the sound needs to play, what time of day, what elevations, etc. This table is updated dynamically.
ambiance.allsounds = {}
ambiance.tmpsounds = {
	-- Dripping water: occurs in over-world caves at any time of day.
	-- Can also be heard in developed areas, underground.
	{
		name="drippingwater", mingain=0.2, maxgain = 1.0, miny=-25000, maxy=-30,    time="",        indoors=nil,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 2129394,
			octaves = 3,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = 0.0,
	},

	-- Cave bats: occurs in over-world caves, only at night.
	{
		name="cave_bats",      gain=0.7, miny=-25000, maxy=-60,    time="night",   indoors=false, mintime=60, maxtime=120,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 577891,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	-- Wind: surface sound only, any time of day (but more common at night).
	{name="wind1",          gain=0.5, miny=-15,    maxy=3300,  time="day",      indoors=false, },
	{name="wind2",          gain=0.5, miny=-15,    maxy=3300,  time="day",      indoors=false, },
	{name="desertwind",     gain=0.5, miny=-15,    maxy=3300,  time="day",      indoors=false, },
	{name="wind1",          gain=1.0, miny=-15,    maxy=3300,  time="night",    indoors=false, mintime=20, maxtime=50, },
	{name="wind2",          gain=1.0, miny=-15,    maxy=3300,  time="night",    indoors=false, mintime=20, maxtime=50, },
	{name="desertwind",     gain=1.0, miny=-15,    maxy=3300,  time="night",    indoors=false, mintime=20, maxtime=50, },

	-- Plays in caverealms.
	{
		name="cavewind",     gain=1.0, miny=-31000,    maxy=-256,  time="",    indoors=nil, mintime=25, maxtime=45,

		-- These parameters match the mapgen.
		noise_params = {
			flags = "defaults",
			lacunarity = 2,
			offset = 0,
			scale = 1,
			spread = {x=768, y=256, z=768},
			seed = 59033,
			octaves = 6,
			persistence = 0.63,
		},
   -- Mapgen threshold is 0.6.
   -- Use a slightly lower threshold so that the sound extends outside the caverns a bit.
   noise_threshold = 0.5,

   -- The world-seed is very large, causing integer overflow.
   -- So we need to get the engine to calculate it against the world seed,
   -- in order to ensure we use the same final seed the engine uses.
   include_world_seed = true,
   absvalue = true,
	},

	{
		name="cavedraft",     gain=1.0, miny=-31000,    maxy=-256,  time="",    indoors=nil, mintime=100, maxtime=400,

		-- These parameters match the mapgen.
		noise_params = {
			flags = "defaults",
			lacunarity = 2,
			offset = 0,
			scale = 1,
			spread = {x=768, y=256, z=768},
			seed = 59033,
			octaves = 6,
			persistence = 0.63,
		},
   -- Mapgen threshold is 0.6.
   -- Use a slightly lower threshold so that the sound extends outside the caverns a bit.
   noise_threshold = 0.5,

   -- The world-seed is very large, causing integer overflow.
   -- So we need to get the engine to calculate it against the world seed,
   -- in order to ensure we use the same final seed the engine uses.
   include_world_seed = true,
   absvalue = true,
	},

	{
		name="darkwind",     gain=1.0, miny=-31000,    maxy=-256,  time="",    indoors=nil, mintime=200, maxtime=500,

		-- These parameters match the mapgen.
		noise_params = {
			flags = "defaults",
			lacunarity = 2,
			offset = 0,
			scale = 1,
			spread = {x=768, y=256, z=768},
			seed = 59033,
			octaves = 6,
			persistence = 0.63,
		},
   -- Mapgen threshold is 0.6.
   -- Use a slightly lower threshold so that the sound extends outside the caverns a bit.
   noise_threshold = 0.5,

   -- The world-seed is very large, causing integer overflow.
   -- So we need to get the engine to calculate it against the world seed,
   -- in order to ensure we use the same final seed the engine uses.
   include_world_seed = true,
   absvalue = true,
	},

	-- This plays in both overworld and channelwood (jarkati has its own entry).
	-- Continuous quiet loop.
	{name="desertwind",     mingain=0.1, maxgain=0.2, miny=-15,maxy=3300,time="", indoors=nil, mintime=6,  maxtime=8, },

	-- Various animal sounds.
	{
		name="wolves",         gain=1.0, miny=-10,    maxy=1000,   time="night",   indoors=false,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 381783,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = 0.5,
	},

	{
		name="coyote",         gain=1.0, miny=-10,    maxy=1000,   time="night",   indoors=false,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 6822034,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	{name="craw",           gain=1.0, miny=3000,   maxy=3300,   time="day"  ,   indoors=false, },
	{name="hornedowl",      gain=1.0, miny=3000,   maxy=3300,   time="night",   indoors=false, },

	-- Owl in Overworld.
	{
		name="owl",           gain=1.0, miny=-10,    maxy=1000,   time="night",   indoors=false,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 589981,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.5,
	},

	-- Owl in Channelwood.
	{
		name="owl",           gain=1.0, miny=3000, maxy=3300,   time="night",   indoors=false,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 2819294,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.2,
	},

	-- Continuous lava rumble in the nether.
	{name="lava",           gain=0.8, miny=-31000, maxy=-25000, time="",        indoors=nil,   mintime=7, maxtime=7, },

	-- More animal sounds. These should play with less frequency.
	-- Only in Channelwood. Overworld nature bird/insect sounds use sound-beacons (due to scarcity of trees/water).
	{name="cricket",        gain=1.0, miny=3000,    maxy=3300,   time="night",   indoors=false, mintime=10, maxtime=30, },
	{name="jungle_night_1", gain=1.0, miny=3000,    maxy=3300,   time="night",   indoors=false, mintime=10, maxtime=30, },
	{name="cardinal",       gain=1.0, miny=3000,    maxy=3300,   time="day",     indoors=false, mintime=20, maxtime=60, },
	{name="crestedlark",    gain=1.0, miny=3000,    maxy=3300,   time="day",     indoors=false, mintime=20, maxtime=60, },
	{name="deer",           gain=1.0, miny=3000,    maxy=3300,   time="night",   indoors=false, mintime=20, maxtime=120, },
	{name="frog",           gain=0.7, miny=3000,    maxy=3300,   time="liminal", indoors=false, },
	{name="frog",           gain=0.1, miny=3000,    maxy=3070,   time="night",   indoors=false, mintime=5, maxtime=15},
	{name="robin",          gain=1.0, miny=3000,    maxy=3300,   time="day",     indoors=false, },
	{name="bluejay",        gain=1.0, miny=3000,    maxy=3300,   time="liminal", indoors=false, },
	{name="gull",           gain=1.0, miny=3000,    maxy=3300,   time="day",     indoors=false, },
	{name="peacock",        gain=1.0, miny=3000,    maxy=3300,   time="liminal", indoors=false, },

	{
		name="canadianloon1",  gain=1.0, miny=3000,    maxy=3300,   time="night",   indoors=false, mintime=120, maxtime=360,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 6582929,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	-- Noise parameters match the spawning perlin for the moonheron mob.
	{
		name="night_master",  gain=1.0, miny=3000,    maxy=3300,   time="",   indoors=nil, mintime=180, maxtime=360,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=512, y=512, z=512},
			seed = 2852,
			octaves = 5,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = 0.4,
	},

	-- Rare deep cave sounds.
	{
   name="obsidianmonster_obsidianmonster", gain=1.0, miny=-31000, maxy=-128, time="", indoors=false, mintime=280, maxtime=560,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 589731,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	{
		name="mobs_sandmonster",                gain=1.0, miny=-31000, maxy=-128, time="", indoors=false, mintime=280, maxtime=560,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 57187382,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	{
		name="mobs_spider",                     gain=1.0, miny=-31000, maxy=-128, time="", indoors=false, mintime=280, maxtime=560,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 5672824,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	-- Nether yuck.
	{
		name="nether_extract_blood", gain=1.0, miny=-31000, maxy=-20000, time="", indoors=false, mintime=280, maxtime=860,
		noise_params = {
			offset = 0,
			scale = 1,
			spread = {x=256, y=256, z=256},
			seed = 282934,
			octaves = 2,
			persist = 0.5,
			lacunarity = 1.5,
			flags = "",
		},
		noise_threshold = -0.3,
	},

	-- Continuous wind on Jarkati surface.
	{name="wind1",          gain=1.5, miny=3735, maxy=3900,  time="", indoors=false, mintime=20, maxtime=40, },
	{name="wind2",          gain=1.5, miny=3735, maxy=3900,  time="", indoors=false, mintime=20, maxtime=40, },
	{name="desertwind",     gain=1.5, miny=3735, maxy=3900,  time="", indoors=false, mintime=20, maxtime=40, },
	{name="desertwind",     mingain=0.2, maxgain=0.4, miny=3735, maxy=3900, time="", indoors=nil, mintime=6, maxtime=8, }, -- Continuous quiet loop.

	-- OUTBACK
	{name="desertwind",     realm="abyss", gain=1.0, miny=4560, maxy=4600, time="", indoors=nil, mintime=20, maxtime=40, },
	{name="wind1",          realm="abyss", gain=1.0, miny=4560, maxy=4600, time="", indoors=nil, mintime=20, maxtime=40, },
	{name="wind2",          realm="abyss", gain=1.0, miny=4560, maxy=4600, time="", indoors=nil, mintime=20, maxtime=40, },
	{name="desertwind",     realm="abyss", mingain=0.2, maxgain=0.4, miny=4560, maxy=4600, time="", indoors=nil, mintime=6, maxtime=8, }, -- Continuous quiet loop.
	{name="night_cicadas",  realm="abyss", mingain=0.2, maxgain=1.0, miny=4560, maxy=4600, time="night", indoors=nil, mintime=7, maxtime=11, }, -- Continuous quiet loop.
	{name="wolves",         realm="abyss", mingain=0.2, maxgain=1.3, miny=4560, maxy=4600, time="night", indoors=nil, mintime=20, maxtime=60, },
	{name="coyote",         realm="abyss", mingain=0.2, maxgain=1.3, miny=4560, maxy=4600, time="night", indoors=nil, mintime=10, maxtime=30, },

	-- MIDFELD
	{name="wind1",          realm="midfeld", gain=1.0, miny=4085, maxy=4250, time="", indoors=nil, mintime=20, maxtime=40, },
	{name="wind2",          realm="midfeld", gain=1.0, miny=4085, maxy=4250, time="", indoors=nil, mintime=20, maxtime=40, },
	{name="desertwind",     realm="midfeld", gain=1.0, miny=4085, maxy=4250, time="", indoors=nil, mintime=20, maxtime=40, },
	{name="desertwind",     realm="midfeld", mingain=0.2, maxgain=0.4, miny=4085, maxy=4250, time="", indoors=nil, mintime=6, maxtime=8, }, -- Continuous quiet loop.
	{name="night_cicadas",  realm="midfeld", mingain=0.2, maxgain=1.0, miny=4085, maxy=4250, time="night", indoors=nil, mintime=7, maxtime=11, }, -- Continuous quiet loop.
	{name="wolves",         realm="midfeld", mingain=0.2, maxgain=1.3, miny=4085, maxy=4250, time="night", indoors=nil, mintime=60, maxtime=360, },
	{name="coyote",         realm="midfeld", mingain=0.2, maxgain=1.3, miny=4085, maxy=4250, time="night", indoors=nil, mintime=60, maxtime=360, },
	{name="owl",            realm="midfeld", mingain=0.2, maxgain=1.3, miny=4085, maxy=4250, time="night", indoors=nil, mintime=60, maxtime=360, },
	{name="hornedowl",      realm="midfeld", mingain=0.2, maxgain=1.3, miny=4085, maxy=4250, time="night", indoors=nil, mintime=60, maxtime=360, },
	{name="drippingwater",  realm="midfeld", mingain=0.2, maxgain=1.0, miny=4050, maxy=4085, time="", indoors=nil, },
	{name="cave_bats",      realm="midfeld", gain=0.7, miny=4050, maxy=4085, time="night", indoors=false, mintime=60, maxtime=360, },
}



-- Add stoneworld cavern layer sounds.
for k = 1, 5 do
  local nbeg = 5150 -- Stoneworld REALM_START.
  local y_level = nbeg + (k * 500)
  local y_offset = 0

  local y_min = y_level + y_offset - 50
  local y_max = y_level + y_offset + 50

  local sound1 = {
		name = "cavewind",
		gain = 1.0,
		miny = y_min,
		maxy = y_max,
		time = "",
		indoors = nil,
		mintime = 25,
		maxtime = 45,
  }
  local sound2 = {
		name = "cavedraft",
		gain = 1.0,
		miny = y_min,
		maxy = y_max,
		time = "",
		indoors = nil,
		mintime = 100,
		maxtime = 400,
  }
  local sound3 = {
		name = "darkwind",
		gain = 1.0,
		miny = y_min,
		maxy = y_max,
		time = "",
		indoors = nil,
		mintime = 200,
		maxtime = 500,
	}

	table.insert(ambiance.tmpsounds, sound1)
	table.insert(ambiance.tmpsounds, sound2)
	table.insert(ambiance.tmpsounds, sound3)
end



-- Initialize extra table parameters.
minetest.after(0, function()
	for k, v in ipairs(ambiance.tmpsounds) do
		-- Mintime & maxtime are the min and max seconds a sound can play again after it has played.
		-- The timer is reset to a new random value between min and max every time the sound plays.
		v.mintime = v.mintime or 30
		v.maxtime = v.maxtime or 120
		if v.mintime < 0 then v.mintime = 0 end
		if v.maxtime < v.mintime then v.maxtime = v.mintime end

		-- If minimum or maximum gain are not specified, calculate min and max gain.
		v.mingain = v.mingain or (v.gain - 0.5)
		v.maxgain = v.maxgain or (v.gain + 0.1)
		if v.mingain < 0 then v.mingain = 0 end
		if v.maxgain < v.mingain then v.maxgain = v.mingain end

		-- Initialize timer to a random value between min and max time.
		-- This ensures all sounds start with random times on first run.
		v.timer = math_random(v.mintime, v.maxtime)

		-- Create perlin noise object if wanted.
		if v.noise_params then
			if v.include_world_seed then
				v.perlin = minetest.get_perlin(v.noise_params)
				assert(v.perlin)
			else
				v.perlin = PerlinNoise(v.noise_params)
				assert(v.perlin)
			end
			assert(v.perlin)
		end
		v.noise_threshold = v.noise_threshold or 0
	end

	ambiance.allsounds = ambiance.tmpsounds
	ambiance.tmpsounds = nil
end)

-- Lava & scuba sounds (or any special sound) must be handled differently.


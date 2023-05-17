
-- Clear registration table afresh. Allows loading file multiple times.
mob_spawn.registered = {}
local register = mob_spawn.register_spawn

-- This is not working, for some reason.
-- Anyway, the wisp mob has special spawning code.
--[[
register({
	name = "pm:follower",
	nodes = {
    "basictrees:jungletree_leaves2",
  },
	min_height = 3111-16,
	max_height = 3115+16,
	clearance = 1,

	mob_limit = 1,
	absolute_mob_limit = 5,
	mob_range = 100,

	-- After a successful spawn, wait a lot of time before spawning another one.
	success_time_min = 60*5,
	success_time_max = 60*10,

	min_count = 1,
	max_count = 3,

	add_entity_func = function(...) pm.spawn_random_wisp(...) end,
})
--]]

register({
	name = "nssm:white_werewolf",
	nodes = {
    "default:snow",
    "snow:footprints",
  },
	min_height = -10,
	max_height = 300,
	clearance = 3,

	mob_limit = 1,
	absolute_mob_limit = 100,
	mob_range = 100,

	-- After a successful spawn, wait a lot of time before spawning another one.
	success_time_min = 60*5,
	success_time_max = 60*10,

	-- Never spawn more than 1 mob at a time.
	min_count = 1,
	max_count = 1,

	-- Matches noise params for the ambiant wolf sound.
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
	noise_threshold = 0.6, -- Higher than noise_threshold for ambiant sound.
})

register({
	name = "dm:dm",
	nodes = {
    "default:stone",
    "cavestuff:cobble_with_moss",
    "cavestuff:cobble_with_lichen",
    "cavestuff:cobble_with_algae",
  },
	min_light = 0,
	max_light = 2,
	min_height = -26000,
	max_height = -2048,
	clearance = 3,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 48912,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.5,
})

register({
	name = "dm:dm",
	nodes = {
    "rackstone:rackstone",
    "rackstone:redrack",
    "rackstone:mg_rackstone",
    "rackstone:mg_redrack",
  },
	min_light = 0,
	max_light = 4,
	max_height = -25000,
	clearance = 3,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 48912,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.3,
})

register({
	name = "golem:stone_golem",
	nodes = {"whitestone:stone"},
	min_light = 0,
	max_light = 6,
	max_height = -25000,
	clearance = 3,
})

-- Naraxen.
register({
	name = "golem:stone_golem",
	nodes = {"darkage:basaltic_rubble", "darkage:basaltic"},
	min_light = 0,
	max_light = 6,
  min_height = 5150,
  max_height = 8150,
	clearance = 3,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 25206,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = -0.3,
})

-- Caverealm griefer mob.
-- Spawning behavior is similar to icemen on the surface.
register({
  name = "griefer:griefer",
  nodes = {
    "cavestuff:dark_obsidian",
		"cavestuff:cobble_with_moss",
		"cavestuff:cobble_with_algae",
  },
  min_light = 0,
  max_light = 4,
  min_height = -31000,
  max_height = -5000,
  day_toggle = true,
})

register({
  name = "iceman:iceman",
  nodes = {
		-- Does not spawn on tree snow or ice.
    "default:snow",
		"snow:footprints",
  },
  min_light = 0,
  max_light = 4,
  mob_limit = 10,
  min_height = -21,
  max_height = 70,
  day_toggle = false,

	spawn_chance = 1,
	mob_range = 30,
	absolute_mob_limit = 20,
	player_min_range = 5,
	player_max_range = 20,
	spawn_radius = 20,
	node_skip = 4,
	node_jitter = 4,
	success_time_min = 1,
	success_time_max = 20,

	min_count = 1,
	max_count = 4,
})

register({
	name = "obsidianmonster:obsidianmonster",
	nodes = {"air"},
	min_light = 0,
	max_light = 0,
	max_height = -256,
	clearance = 2, -- Wants a 3x3x3 area.
	flyswim = "flyswim",

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 2837189,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.3,
})

-- Naraxen.
register({
	name = "obsidianmonster:obsidianmonster",
	nodes = {"air"},
	min_light = 0,
	max_light = 0,
  min_height = 5150,
  max_height = 8150,
	clearance = 2, -- Wants a 3x3x3 area.
	flyswim = "flyswim",

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 25206,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = -0.3,
})

-- That flying thing.
register({
	name = "oerkki:oerkki",
	nodes = {"air"},
	min_light = 0,
	max_light = 0,
	min_height = -31000,
	max_height = -10,
	clearance = 2, -- Wants a 3x3x3 area.
	flyswim = "flyswim",

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 27192,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.3,
})

-- Naraxen.
register({
	name = "oerkki:oerkki",
	nodes = {"air"},
	min_light = 0,
	max_light = 0,
  min_height = 5150,
  max_height = 8150,
	clearance = 2, -- Wants a 3x3x3 area.
	flyswim = "flyswim",

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 25206,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = -0.3,
})

-- Night Master.
register({
	name = "oerkki:night_master",
	nodes = {"air"},
	min_light = 0,
	max_light = 15,
	day_toggle = false,
	min_height = 3080,
	max_height = 3280,
	clearance = 3,
	flyswim = "flyswim",

	mob_limit = 1,
	absolute_mob_limit = 5,
	mob_range = 50,

	-- Never spawn more than 1 mob at a time.
	min_count = 1,
	max_count = 1,

	-- After a successful spawn, wait before spawning another one.
	success_time_min = 60*5,
	success_time_max = 60*10,

	-- Same as moonheron, with higher threshold.
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
	noise_threshold = 0.8,
})

register({
	name = "nssm:moonheron",
	nodes = {"air"},
	min_light = 0,
	max_light = 15,
	day_toggle = false,
	min_height = 3060,
	max_height = 3280,
	clearance = 3,
	flyswim = "flyswim",

	mob_limit = 3,
	absolute_mob_limit = 5,
	mob_range = 50,

	-- Never spawn more than 1 mob at a time.
	min_count = 1,
	max_count = 1,

	-- Same as night master, with lower threshold.
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
	noise_threshold = 0.7,
})

register({
	name = "rat:rat",
	nodes = {"default:stone"},
	min_light = 0,
	max_light = default.LIGHT_MAX,
	min_height = -128,
	max_height = 31000,
	clearance = 1,
})

register({
	name = "sheep:sheep",
	nodes = {"default:dirt_with_grass", "moregrass:darkgrass", "default:dirt_with_dry_grass"},
	min_light = 10,
	max_light = default.LIGHT_MAX,
	min_height = -30,
	max_height = 31000,
	day_toggle = nil, -- They spawn anytime.
})

register({
	name = "skeleton:skeleton",
	nodes = {
    "rackstone:rackstone",
    "rackstone:redrack",
    "rackstone:mg_rackstone",
    "rackstone:mg_redrack",
  },
	min_light = 0,
	max_light = 6,
	mob_limit = 10,
	max_height = -25000,
	clearance = 3,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 4817889,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.3,
})

-- Naraxen.
register({
	name = "skeleton:skeleton",
	nodes = {"darkage:basaltic_rubble", "darkage:basaltic"},
	min_light = 0,
	max_light = 0,
  min_height = 5150,
  max_height = 8150,
	clearance = 3,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 25206,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = -0.3,
})

register({
	name = "stoneman:stoneman",
	nodes = {"default:stone", "default:cobble"},
	min_light = 0,
	max_light = 1,
	mob_limit = 10,
	max_height = -128,
})

-- Naraxen.
register({
	name = "stoneman:stoneman",
	nodes = {"darkage:basaltic_rubble", "darkage:basaltic"},
	min_light = 0,
	max_light = 1,
  min_height = 5150,
  max_height = 8150,
	clearance = 3,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 25206,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = -0.3,
})

-- Naraxen.
-- Disgusting eldritch.
register({
	name = "nssm:morde",
	nodes = {"darkage:basaltic_rubble", "darkage:basaltic"},
	min_light = 0,
	max_light = 1,
  min_height = 5150,
  max_height = 8150,
	clearance = 3,

	mob_limit = 1,
	min_count = 1,
	max_count = 1,
	mob_range = 40,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 16804,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.3,
})

register({
	name = "warthog:warthog",
	nodes = {
    "rackstone:rackstone",
    "rackstone:redrack",
    "rackstone:mg_rackstone",
    "rackstone:mg_redrack",
  },
	min_light = 0,
	max_light = 3,
	mob_limit = 10,
	max_height = -25000,
	min_count = 7,
	max_count = 16,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 423821,
		octaves = 3,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.3,
})

register({
  name = "sandman:sandman",
  nodes = {
    "default:desert_sand",
  },
  min_light = 0,
  max_light = 4,
  mob_limit = 10,
  min_height = 3700,
  max_height = 3800,
  day_toggle = false,

	spawn_chance = 1,
	mob_range = 30,
	absolute_mob_limit = 20,
	player_min_range = 5,
	player_max_range = 20,
	spawn_radius = 20,
	node_skip = 4,
	node_jitter = 4,
	success_time_min = 1,
	success_time_max = 20,

	min_count = 1,
	max_count = 4,
})

register({
	name = "sandman:stoneman",
	nodes = {"default:desert_stone"},
	min_light = 0,
	max_light = 4,
	mob_limit = 10,
	min_height = 3600,
	max_height = 3800,
	spawn_chance = 1,
})

register({
	name = "nssm:phoenix",
	nodes = {"air"},
	min_light = 12,
	max_light = 15,
	day_toggle = true,
	min_height = 3735,
	max_height = 3800,
	clearance = 3,
	flyswim = "flyswim",

	mob_limit = 1,
	absolute_mob_limit = 5,
	mob_range = 40,

	min_count = 1,
	max_count = 1,

	-- After a successful spawn, wait before spawning another one.
	success_time_min = 60*5,
	success_time_max = 60*10,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 10548,
		octaves = 5,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.8,
})

register({
	name = "nssm:scrausics",
	nodes = {"air"},
	min_light = 12,
	max_light = 15,
	day_toggle = true,
	min_height = 3735,
	max_height = 3800,
	clearance = 3,
	flyswim = "flyswim",

	mob_limit = 3,
	absolute_mob_limit = 5,
	mob_range = 40,

	min_count = 1,
	max_count = 2,

	noise_params = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 48727,
		octaves = 5,
		persist = 0.5,
		lacunarity = 1.5,
		flags = "",
	},
	noise_threshold = 0.8,
})

-- Pigs in the Outback.
register({
	name = "animalworld:suboar",
	nodes = {"rackstone:cobble"},
	min_light = 0,
	max_light = 15,
	day_toggle = false,
	min_height = 4160+400,
	max_height = 4200+400,
	clearance = 2,

	mob_limit = 2,
	absolute_mob_limit = 6,
	mob_range = 40,
	realm_restriction = true,

	-- After a successful spawn, wait before spawning another one.
	success_time_min = 60*5,
	success_time_max = 60*10,

	-- Never spawn more than 1 mob at a time.
	min_count = 1,
	max_count = 1,
})

-- A very rare, very hard mob.
register({
	name = "griefer:elite_griefer",
	nodes = {
		"bedrock:bedrock",
		"cavestuff:dark_obsidian",
	},

	min_height = -35000,
	max_height = 35000,
	clearance = 2,

	mob_limit = 2,
	absolute_mob_limit = 10,
	mob_range = 40,

	-- After a successful spawn, wait a lot of time before spawning another one.
	-- Between 1 and 4 hours.
	success_time_min = 60*60,
	success_time_max = 60*60*4,

	-- Min/max amount of mobs to spawn at one time.
	min_count = 1,
	max_count = 2,

	-- Because it is allowed to spawn in the Abyss, at the bedrock layer.
	realm_restriction = true,
})

-- Reinit per-player data.
mob_spawn.players = {}

local function re_init()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		-- This is an indexed array.
		local pname = v:get_player_name()
		mob_spawn.reinit_player(pname)
	end
end

minetest.after(1, re_init)


-- Clear registration table afresh. Allows loading file multiple times.
mob_spawn.registered = {}
local register = mob_spawn.register_spawn

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
	mob_limit = 1,
	mob_range = 50,
	max_height = -2048,
	min_count = 1,
	max_count = 2,
	player_min_range = 30,
	player_max_range = 100,
	spawn_height = 3,
	saturation_time_min = 60*1,
	saturation_time_max = 60*3,
	success_time_min = 60*3,
	success_time_max = 60*15,
	node_skip = 10,
	node_jitter = 10,
	spawn_radius = 100,
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
	mob_limit = 2,
	mob_range = 40,
	max_height = -25000,
	player_min_range = 10,
	player_max_range = 100,
	spawn_height = 3,
	saturation_time_min = 60*1,
	saturation_time_max = 60*3,
	success_time_min = 60*3,
	success_time_max = 60*15,
	node_skip = 10,
	node_jitter = 10,
	spawn_radius = 100,
})

register({
	name = "golem:stone_golem",
	nodes = {"whitestone:stone"},
	min_light = 0,
	max_light = 6,
	interval = 20,
	chance = 16000,
	mob_limit = 1,
	mob_range = 100,
	max_height = -25000,
	player_min_range = 20,
	player_max_range = 60,
	spawn_height = 3,
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
  interval = 60,
  chance = 3000,
  mob_limit = 2,
  absolute_mob_limit = 3,
  mob_range = 20,
  min_height = -31000,
  max_height = -5000,
  day_toggle = true,
  player_min_range = 20,
  player_max_range = 60,
})

register({
  name = "iceman:iceman",
  nodes = {
		-- Does not spawn on tree snow or footstep snow or ice.
    "default:snow",
  },
  min_light = 0,
  max_light = 4,
  interval = 20,
  chance = 200,
  mob_limit = 4,
  absolute_mob_limit = 6,
  mob_range = 25,
  min_height = -21,
  max_height = 70,
  day_toggle = false,
  player_min_range = 5,
  player_max_range = 30,
	success_time_min = 1,
	success_time_max = 6,

	-- The hight limit for this mob means we can afford more spawn checks.
	saturation_time_min = 20,
	saturation_time_max = 60,

	node_skip = 4,
	node_jitter = 4,
	spawn_radius = 16,
})

register({
	name = "obsidianmonster:obsidianmonster",
	nodes = {"air"},
	min_light = 0,
	max_light = 0,
	interval = 60,
	chance = 10000,
	mob_limit = 1,
	absolute_mob_limit = 2,
	mob_range = 50,
	max_height = -256,
	player_min_range = 20,
	player_max_range = 60,
})

-- That flying thing.
register({
	name = "oerkki:oerkki",
	nodes = {"air"},
	min_light = 0,
	max_light = 0,
	interval = 60,
	chance = 7000,
	mob_limit = 1,
	absolute_mob_limit = 2,
	mob_range = 50,
	min_height = -31000,
	max_height = -10,
	player_min_range = 20,
	player_max_range = 60,
})

register({
	name = "rat:rat",
	nodes = {"default:stone"},
	min_light = 0,
	max_light = default.LIGHT_MAX,
	interval = 300,
	chance = 10000,
	mob_limit = 3,
	mob_range = 100,
	min_height = -128,
	max_height = 31000,
	spawn_height = 1,
})

register({
	name = "sheep:sheep",
	nodes = {"default:dirt_with_grass", "moregrass:darkgrass", "default:dirt_with_dry_grass"},
	min_light = 10,
	max_light = 15,
	interval = 60,
	chance = 10000,
	mob_limit = 2,
  mob_range = 30,
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
	mob_limit = 5,
	mob_range = 100,
	max_height = -25000,
	min_count = 1,
	max_count = 1,
	player_max_range = 40,
	spawn_height = 3,
	node_skip = 7,
	node_jitter = 7,
	spawn_radius = 40,
})

register({
	name = "stoneman:stoneman",
	nodes = {"default:stone", "default:cobble"},
	min_light = 0,
	max_light = 1,
	interval = 30,
	chance = 7000,
	mob_limit = 1,
	absolute_mob_limit = 1,
	mob_range = 30,
	max_height = -128,
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
	max_light = 6,
	interval = 360,
	chance = 10000,
	mob_limit = 3,
	mob_range = 50,
	max_height = -25000,
	min_count = 7,
	max_count = 16,
	player_min_range = 30,
	player_max_range = 100,
})

-- Reinit per-player data.
mob_spawn.players = {}
local players = minetest.get_connected_players()
for k, v in ipairs(players) do
	-- This is an indexed array.
	local registered = mob_spawn.registered
	local pname = v:get_player_name()
	local random = math.random

	players[pname] = {}

	for k, v in pairs(registered) do
		players[pname][k] = {
			-- Initial interval. Wait this long before trying to spawn this mob again.
			interval = random(v.success_time_min, v.success_time_max)
		}
	end
end

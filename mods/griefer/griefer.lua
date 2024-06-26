
mobs.register_mob("griefer:griefer", {
	description = "Black-Hearted Oerkki",
	type = "npc",
	passive = false,
	attack_type = "dogfight",
	attack_animals = true,
	attack_players = true,
	specific_allies = {
		["griefer:elite_griefer"] = true,
		["dm:dm"] = true,
	},
	pathfinding = 2,
	pathing_radius = 16,
	reach = 2,
	damage = 4*500,
	damage_group = "crumbly",
	hp_min = 8*500,
	hp_max = 34*500,
	armor = 100,
	armor_level = 2,
	-- Slightly smaller collision box makes mob movement easier.
	collisionbox = {-0.3, -1, -0.3, 0.3, 0.7, 0.3},
	--collisionbox = {-0.4, -1, -0.4, 0.4, 0.9, 0.4},
	visual = "mesh",
	mesh = "griefer_griefer.b3d",
	textures = {
		{"griefer_griefer1.png"},
		{"griefer_griefer2.png"},
	},
	makes_footstep_sound = false,
	sounds = {
		random = "griefer_griefer",
	},
	walk_velocity = 1,
	run_velocity = 3,
	sprint_velocity = 3.5,
	view_range = 20,
	jump = true,
	drops = {
		{name = "default:junglegrass", chance = 10*3, min = 1, max = 2},
		{name = "default:grass_dummy", chance = 6*3, min = 1, max = 2},
		{name = "default:cactus", chance = 15*3, min = 1, max = 1},
		{name = "default:dry_shrub", chance = 8, min = 1, max = 5},
		{name = "default:dry_shrub2", chance = 8, min = 1, max = 5},
		{name = "default:papyrus", chance = 15, min = 1, max = 3},

		-- Required to make it possible to obtain more dirt in Caverealm survival.
		{name = "bones:bones_type2", chance = 5, min = 1, max = 1},
	},
	water_damage = 0,
	lava_damage = 4*500,
	makes_bones_in_lava = false,
	light_damage = 0,
	fear_height = 3,
	animation = {
		stand_start = 0,
		stand_end = 23,
		walk_start = 24,
		walk_end = 36,
		run_start = 37,
		run_end = 49,
		punch_start = 37,
		punch_end = 49,
		speed_normal = 15,
		speed_run = 15,
	},
	replace_rate = 10,
	replace_what = {
    "torches:torch_floor",
    "torches:torch_wall",
    "torches:torch_ceiling",
    "torches:kalite_torch_floor",
    "torches:kalite_torch_wall",
    "torches:kalite_torch_ceiling",
  },
	replace_with = "air",
	replace_offset = 0,
	replace_range = 2,
	immune_to = {
		{"default:gold_lump", -10}, -- heals by 10 points
	},
})



mobs.register_spawn_abm({
  name = "griefer:griefer",
  nodes = {"griefer:grieferstone"},
  interval = 3,
  chance = 30,

  -- Warning, do NOT change! The cursed-stone configuration in the Outback's gateroom depends on this.
  min_light = 0,
  max_light = 5,
  player_min_range = 4,
  player_max_range = 30,

  mob_limit = 3,
  absolute_mob_limit = 16,
  mob_range = 30,
  min_count = 1,
  max_count = 3,
})



mobs.register_spawn_abm({
  name = "griefer:griefer",
  nodes = {"griefer:naraxen"},
  interval = 3,
  chance = 10,

  -- Warning, do NOT change! Required for Naraxen lava fortresses.
  min_light = 0,
  max_light = 10,

  player_min_range = 4,
  player_max_range = 30,

  mob_limit = 3,
  absolute_mob_limit = 16,
  mob_range = 20,
  min_count = 1,
  max_count = 3,
})



mobs.register_egg("griefer:griefer", "Black Hearted Griefer", "default_obsidian.png", 1)



mobs.alias_mob("mobs_monster:oerkki",   "griefer:griefer")
mobs.alias_mob("mobs:oerkki",           "griefer:griefer")


mobs.register_mob("griefer:elite_griefer", {
	description = "Elite Oerkki",
	type = "npc",
	passive = false,
	attack_animals = true,
	attack_players = true,
	attack_type = "dogfight",
	specific_allies = {
		["griefer:griefer"] = true,
		["dm:dm"] = true,
	},
	pathfinding = 3,
	pathing_radius = 20,
	max_node_dig_level = 2,
	reach = 2, -- Mob will try to move this close to target.
	punch_reach = 3, -- Mob can hit from this far away.
	damage = 8*500,
	damage_min = 8*500,
	damage_max = 16*500,
	damage_group = "crumbly",
	hp_min = 160*500,
	hp_max = 260*500,
	armor = 100,
	show_health = false,

	-- Never expires.
	lifetimer = 100000,

	-- Require level 3 weapon to get any drops.
	armor_level = 3,

	-- Slightly smaller collision box makes mob movement easier.
	collisionbox = {-0.3, -1, -0.3, 0.3, 0.7, 0.3},
	--collisionbox = {-0.4, -1, -0.4, 0.4, 0.9, 0.4},
	visual = "mesh",
	visual_size = {x=1.3, y=1.1, z=1.3},
	mesh = "griefer_elite.b3d",
	textures = {
		{"griefer_griefer3.png"},
	},
	makes_footstep_sound = false,
	sounds = {
		random = "griefer_elite",
		war_cry = "griefer_elite",
		shoot_attack = "dm_fireball",
	},
	walk_velocity = 1,
	run_velocity = 3,
	sprint_velocity = 4,
	view_range = 30,
	jump = true,

	drops = {
		{name = "default:goldblock", chance = 1, min = 1, max = 1},
		{name = "cavestuff:dark_obsidian", chance = 1, min = 1, max = 5},
	},

	-- The node needs to be something the Oerkki can also dig,
	-- otherwise it might trap itself.
	place_node = "default:cobble",

	water_damage = 0,
	lava_damage = 4*500,
	makes_bones_in_lava = false,
	light_damage = 0,
	fear_height = 3,
	animation = {
		speed_normal = 30,
		speed_run = 30,
		stand_start = 0,
		stand_end = 79,
		walk_start = 168,
		walk_end = 187,
		run_start = 168,
		run_end = 187,
		punch_start = 200,
		punch_end = 219,
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
	ignore_invisibility = true,
	--knock_back = false,
	--hunt_players = true,
	hunt_chance = 5,
	arrow = "griefer:fireball",
	shoot_offset = 1,

	do_custom = function(...)
		return griefer.elite_do_custom(...)
	end,

	do_punch = function(...)
		return griefer.elite_do_punch(...)
	end,
})



mobs.register_egg("griefer:elite_griefer", "Elite Griefer", "default_gold_block.png", 1)

mobs.register_spawn_abm({
  name = "griefer:elite_griefer",
  nodes = {"griefer:elitestone"},
  interval = 3,
  chance = 100,

  min_light = 0,
  max_light = 11,
  player_min_range = 20,
  player_max_range = 60,

  mob_limit = 1,
  absolute_mob_limit = 32,
  mob_range = 40,
  min_count = 1,
  max_count = 1,
})

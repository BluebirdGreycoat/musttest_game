
mobs.register_mob("animalworld:suboar", {
	stepheight = 2,
	type = "animal",
	description = "Swinepig",
	passive = false,
	attack_type = "dogfight",
	group_attack = true,

	-- Mob should defend itself but does not attack first.
	attack_players = false,
	attack_npcs = false,
	pathfinding = 1,

	reach = 2,
	damage = 8*500,
	damage_group = "snappy",
	hp_min = 5*500,
	hp_max = 35*500,
	armor = 70,
	collisionbox = {-0.5, -0.01, -0.5, 0.5, 0.95, 0.5},
	visual = "mesh",
	mesh = "mobs_pumba.b3d",
	visual_size = {x = 1.0, y = 1.0},
	textures = {
		{"animalworld_suboar2.png"},
	},
	sounds = {
		random = "animalworld_suboar",
		attack = "animalworld_suboar",
	},
	makes_footstep_sound = true,
	walk_velocity = 1,
	run_velocity = 3,
	runaway = false,
	runaway_from = {"player"},
	jump = true,
	drops = {
		{name = "mobs:meat_raw", chance = 1, min = 1, max = 1},
		{name = "mobs:leather", chance = 1, min = 1, max = 1},
	},
	water_damage = 0,
	lava_damage = 4*500,
	light_damage = 0,
	fear_height = 3,
	animation = {
		speed_normal = 15,
		stand_start = 25,
		stand_end = 55,
		walk_start = 70,
		walk_end = 100,
		run_start = 70,
		run_end = 100,
		run_speed = 30,
		punch_start = 70,
		punch_end = 100,
	},
	view_range = 20,
  makes_bones_in_lava = true,
})

mobs.register_egg("animalworld:suboar", "Swinepig", "default_dirt.png", 1)

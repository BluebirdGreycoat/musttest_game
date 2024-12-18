
mobs.register_mob("animalworld:murdertusk", {
	stepheight = 2,
	type = "animal",
	description = "Murdertusk",
	passive = false,
	attack_type = "dogfight",
	group_attack = true,

	attack_players = true,
	attack_npcs = false,
	pathfinding = 1,

	reach = 2,
	damage = 10*500,
	damage_group = "snappy",
	hp_min = 20*500,
	hp_max = 40*500,
	armor = 50,
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
	walk_velocity = 1.5,
	run_velocity = 3.5,
	jump = true,
	drops = {
		{name = "mobs:meat_raw_pork", chance = 2, min = 1, max = 1},
		{name = "mobs:leather", chance = 2, min = 1, max = 1},
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
	view_range = 50,
  makes_bones_in_lava = true,
})

mobs.register_egg("animalworld:murdertusk", "Murdertusk", "default_dirt.png", 1)

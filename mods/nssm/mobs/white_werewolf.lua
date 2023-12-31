
local scale = 0.5
local hpmul = 2.0

mobs.register_mob("nssm:white_werewolf", {
	type = "monster",
	description = "Giant White Wolf",
	pathfinding = 1,
	hp_max = 40*hpmul*500,
	hp_min = 25*hpmul*500,
	collisionbox = {-0.85*scale, -0.01, -0.85*scale, 0.85*scale, 3.50*scale, 0.85*scale},
	visual = "mesh",
	mesh = "white_werewolf.x",
	textures = {
		{"white_werewolf.png"}
	},
	visual_size = {x = 4*scale, y = 4*scale},
	makes_footstep_sound = true,
	view_range = 30,
	walk_velocity = 3,
	fear_height = 4,
	run_velocity = 5,
	sounds = {
		random = "werewolf",
	},
	damage = 10*500,
	jump = true,
	drops = {
		{name = "nssm:white_wolf_leg", chance = 2, min = 1, max = 2},
		{name = "nssm:white_wolf_fur", chance = 2, min = 3, max = 5},
	},
	armor = 80,
	drawtype = "front",
	water_damage = 2*500,
	lava_damage = 5*500,
	light_damage = 0,
	group_attack = true,
	attack_animals = true,
	knock_back = 2,
	blood_texture = "nssm_blood.png",
	stepheight = 1.1,
	attack_type = "dogfight",
	animation = {
		speed_normal = 15,
		speed_run = 25,
		stand_start = 1,
		stand_end = 60,
		walk_start = 90,
		walk_end = 130,
		run_start = 140,
		run_end = 160,
		punch_start = 170,
		punch_end = 193,
	}
})

mobs.register_egg("nssm:white_werewolf", "White Wolf", "default_snow.png", 1)

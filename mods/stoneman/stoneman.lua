
mobs.register_mob("stoneman:stoneman", {
	description = "Stone Golem",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
	pathfinding = 1,
	reach = 2,
	damage = 3*500,
	damage_group = "cracky",
	hp_min = 12*500,
	hp_max = 35*500,
	armor = 80,
	collisionbox = {-0.4, -1, -0.4, 0.4, 0.9, 0.4},
	visual = "mesh",
	mesh = "stoneman_stoneman.b3d",
	textures = {
		{"stoneman_stoneman.png"},
	},
	makes_footstep_sound = true,
	sounds = {
		random = "stoneman_stoneman",
		death = "stoneman_stoneman",
	},
	walk_velocity = 1,
	run_velocity = 2,
	jump = true,
	floats = 0,
	view_range = 15,
	drops = {
        {name = "default:cobble",       chance = 6,     min = 1,    max = 6},
        {name = "whitestone:cobble",    chance = 10,    min = 5,    max = 15},
	},
	water_damage = 0,
	lava_damage = 1*500,
	makes_bones_in_lava = false,
	light_damage = 0,
	animation = {
		speed_normal = 15,
		speed_run = 15,
		stand_start = 0,
		stand_end = 14,
		walk_start = 15,
		walk_end = 38,
		run_start = 40,
		run_end = 63,
		punch_start = 40,
		punch_end = 63,
	},
	hunt_chance = 5,
})





mobs.register_egg("stoneman:stoneman", "Stoneman", "default_stone.png", 1)



-- Compatibility.
mobs.alias_mob("mobs:stone_monster",            "stoneman:stoneman")
mobs.alias_mob("mobs_monster:stone_monster",    "stoneman:stoneman")



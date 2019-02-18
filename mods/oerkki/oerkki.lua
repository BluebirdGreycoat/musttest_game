
-- That flying thing.
mobs.register_mob("oerkki:oerkki", {
	type = "monster",
	description = "Flying Menace",
	passive = false,
	attack_type = "dogfight",
	pathfinding = 2,
	reach = 2,
	damage = 3,
	hp_min = 8,
	hp_max = 34,
	armor = 100,
	--collisionbox = {-0.3, -1, -0.3, 0.3, 0.7, 0.3},
	collisionbox = {-0.4, -0.4, -0.4, 0.4, 0.4, 0.4},
	visual = "mesh",
	mesh = "mobs_oerkki2.b3d",
	textures = {
		{"mobs_oerkki3.png"},
	},
	rotate = 270,
	makes_footstep_sound = false,
	sounds = {
		random = "mobs_oerkki",
	},
	walk_velocity = 2,
	run_velocity = 5,
	view_range = 15,
	jump = false,
	fly = true,
	fly_in = "air",
	drops = {
		{name = "mobs:meat_raw", chance = 1, min = 1, max = 2},
		{name = "mobs:leather", chance = 2, min = 1, max = 1},
	},
	water_damage = 1,
	lava_damage = 100,
	light_damage = 1,
	fear_height = 0,
	
	animation = {
		stand_start = 1,
		stand_end = 29,
		walk_start = 1,
		walk_end = 29,
		run_start = 1,
		run_end = 29,
		punch_start = 30,
		punch_end = 60,
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





mobs.register_egg("oerkki:oerkki", "Oerkki", "default_obsidian.png", 1)



mobs.alias_mob("mobs_monster:oerkki2", "oerkki:oerkki")

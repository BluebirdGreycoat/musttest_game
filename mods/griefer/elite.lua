
mobs.register_mob("griefer:elite_griefer", {
	description = "Elite Oerkki",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
	pathfinding = 2,
	pathing_radius = 20,
	max_node_dig_level = 2,
	reach = 2,
	damage = 16,
	hp_min = 160,
	hp_max = 260,
	armor = 100,
	armor_level = 2,
	-- Slightly smaller collision box makes mob movement easier.
	collisionbox = {-0.3, -1, -0.3, 0.3, 0.7, 0.3},
	--collisionbox = {-0.4, -1, -0.4, 0.4, 0.9, 0.4},
	visual = "mesh",
	mesh = "griefer_elite.b3d",
	textures = {
		{"griefer_griefer3.png"},
	},
	makes_footstep_sound = false,
	sounds = {
		random = "griefer_elite",
	},
	walk_velocity = 1,
	run_velocity = 3,
	view_range = 20,
	jump = true,

	drops = {
	},

	water_damage = 0,
	lava_damage = 4,
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
})



mobs.register_egg("griefer:elite_griefer", "Elite Griefer", "default_gold_block.png", 1)

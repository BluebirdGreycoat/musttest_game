
if not minetest.global_exists("golem") then golem = {} end
golem.modpath = minetest.get_modpath("golem")



mobs.register_mob("golem:stone_golem", {
	type = "monster",
	description = "Giant Stone Golem",
	reach = 3,
	damage = 6*500,
	damage_group = "crush",
	attack_type = "dogfight",
	hp_min = 62*500,
	hp_max = 72*500,
	armor = 100,
	collisionbox = {-0.6, 0, -0.6, 0.6, 2.5, 0.6},
	visual = "mesh",
	mesh = "golem_golem.b3d",
	textures = {
		{"golem_stone_golem.png"},
	},
	blood_texture = "default_stone.png",
	visual_size = {x=0.9, y=0.9},
	makes_footstep_sound = true,
	walk_velocity = 0.5,
	run_velocity = 1,
	jump = true,
    jump_chance = 100,
    walk_chance = 10,
	drops = {
		{name = "whitestone:stone", chance = 10, min = 5, max = 15},
	},
	water_damage = 0,
	lava_damage = 2*500,
	makes_bones_in_lava = false,
	light_damage = 1*500,
	fall_damage = 0,
	fear_height = 3,
	view_range = 14,
	animation = {
		speed_normal = 10,
		speed_run = 14,
		walk_start = 46,
		walk_end = 66,
		stand_start = 1,
		stand_end = 20,
		run_start = 46,
		run_end = 66,
		punch_start = 20,
		punch_end = 45,
	},
})





mobs.register_egg("golem:stone_golem", "Stone Golem", "default_stone.png", 1)


mobs.register_mob("dirtleaf:dirtleaf", {
	description = "Stitch Goblin",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
  group_attack = true,

	-- Require at least steel sword to get any drops.
	armor_level = 1,

	pathfinding = 3,
	pathing_radius = 20,
	max_node_dig_level = 1,

	-- This node decays after a while if no regular trees around.
	place_node = "basictrees:tree_leaves",

	visual_size = {x = 0.8, y = 0.8},

	reach = 2,
	damage = 3*500,
	damage_min = 2*500,
	damage_max = 5*500,
	damage_group = "crumbly",
	hp_min = 12*500,
	hp_max = 25*500,
	armor = 80,
	collisionbox = {-0.3, -0.8, -0.3, 0.3, 0.5, 0.3},
	visual = "mesh",
	mesh = "mobs_tree_monster.b3d",
	textures = {
		{"mobs_tree_monster.png"},
		{"mobs_tree_monster2.png"},
		{"mobs_tree_monster3.png"},
		{"mobs_tree_monster4.png"},
	},
	makes_footstep_sound = true,
	blood_texture = "default_wood.png",
	sounds = {
		random = "mobs_treemonster",
		death = "mobs_treemonster",
		attack = "mobs_treemonster",
    distance = 20,
	},
	walk_velocity = 1.5,
	run_velocity = 2.8,
	jump = true,
  jump_chance = 1,
  walk_chance = 1,
	floats = 0,
	view_range = 10,
	drops = {
		{name = "default:dirt", chance = 1, min = 1, max = 2},
		{name = "default:apple", chance = 2, min = 1, max = 3},
		{name = "farming:string", chance = 2, min = 1, max = 1},
	},
	water_damage = 1*500,
	lava_damage = 100*500,
  makes_bones_in_lava = false,
	animation = {
		speed_normal = 15,
		speed_run = 15,
		stand_start = 0,
		stand_end = 24,
		walk_start = 25,
		walk_end = 47,
		run_start = 48,
		run_end = 62,
		punch_start = 48,
		punch_end = 62,
	},
})

mobs.register_egg("dirtleaf:dirtleaf", "Dirtleaf", "default_leaves.png", 1)

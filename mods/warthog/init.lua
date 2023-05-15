
if not minetest.global_exists("warthog") then warthog = {} end
warthog.modpath = minetest.get_modpath("warthog")



-- Warthog by KrupnoPavel. Modified for Enyekala by MustTest.
mobs.register_mob("warthog:warthog", {
	description = "Nether Swinepig",
	type = "animal",
	passive = false,

	-- Mob should defend itself but does not attack first.
	attack_players = false,
	attack_npcs = false,

	attack_type = "dogfight",
	group_attack = true,
	reach = 2,
	pathfinding = 1,
	pathfinding_chance = 20,
	damage = 10*500,
	damage_group = "snappy",
	hp_min = 35*500,
	hp_max = 65*500,
	armor = 50,
	armor_level = 2,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
	visual = "mesh",
	mesh = "warthog_warthog.x",
	textures = {
		{"warthog_warthog.png"},
	},
	makes_footstep_sound = true,
	sounds = {
		random = "warthog_warthog",
		attack = "warthog_warthog_angry",
	},
	walk_velocity = 0.5,
	run_velocity = 3,
	jump = true,
	view_range = 30,
	drops = {
		{name = "mobs:meat_raw_pork", chance = 1, min = 1, max = 2},
		{name = "mobs:leather", chance = 2, min = 1, max = 1},
	},
	water_damage = 1*500,
	lava_damage = 5*500,
	light_damage = 0,
	fear_height = 3,
	animation = {
		speed_normal = 15,
		stand_start = 25,
		stand_end = 55,
		walk_start = 70,
		walk_end = 100,
		punch_start = 70,
		punch_end = 100,
	},
  makes_bones_in_lava = true,
})





mobs.register_egg("warthog:warthog", "Warthog", "rackstone_rackstone.png", 1)





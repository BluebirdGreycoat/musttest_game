
mobs.register_mob("dm:dm", {
	description = "Dungeon Master",
	type = "monster",
	passive = false,
	damage = 4,
	attack_type = "dogshoot",
	dogshoot_switch = 1,
	dogshoot_count_max = 10,
	reach = 3,
	shoot_interval = 2.5,
	arrow = "dm:fireball",
	shoot_offset = 1,
	hp_min = 12,
	hp_max = 32,
	armor = 60,
	collisionbox = {-0.7, -1, -0.7, 0.7, 1.6, 0.7},
	visual = "mesh",
	mesh = "dm_dm.b3d",
	textures = {
		{"dm_dm1.png"},
		{"dm_dm2.png"},
		{"dm_dm3.png"},
	},
	makes_footstep_sound = true,
	sounds = {
		random = "dm_dm",
		shoot_attack = "dm_fireball",
	},
	walk_velocity = 1,
	run_velocity = 3,
	jump = true,
	view_range = 30,
	drops = {
		{name = "default:mese_crystal_fragment", chance = 1, min = 1, max = 10},
		{name = "default:diamond", chance = 4, min = 1, max = 20},
		{name = "default:mese_crystal", chance = 2, min = 1, max = 9},
		{name = "default:diamondblock", chance = 30, min = 1, max = 4},
		{name = "default:mese", chance = 30, min = 1, max = 4},
	},
	water_damage = 5,
	lava_damage = 1,
	light_damage = 0,
	fear_height = 3,
	animation = {
		stand_start = 0,
		stand_end = 19,
		walk_start = 20,
		walk_end = 35,
		punch_start = 36,
		punch_end = 48,
		shoot_start = 36,
		shoot_end = 48,
		speed_normal = 15,
		speed_run = 15,
	},
  makes_bones_in_lava = false,
})



mobs.register_spawn({
	name = "dm:dm",
	nodes = {
    "default:stone",
    "cavestuff:cobble_with_moss",
    "cavestuff:cobble_with_lichen",
    "cavestuff:cobble_with_algae",
  },
	min_light = 0,
	max_light = 2,
	interval = 360,
	chance = 14000,
	mob_limit = 1,
	mob_range = 80,
	max_height = -2048,
	min_count = 1,
	max_count = 2,
	player_min_range = 30,
	player_max_range = 100,
})



mobs.register_spawn({
	name = "dm:dm",
	nodes = {
    "rackstone:rackstone",
    "rackstone:redrack",
    "rackstone:mg_rackstone",
    "rackstone:mg_redrack",
  },
	min_light = 0,
	max_light = 4,
	interval = 360,
	chance = 10000,
	mob_limit = 1,
	mob_range = 100,
	max_height = -25000,
	player_max_range = 100,
})



mobs.register_arrow("dm:fireball", {
	visual = "sprite",
	visual_size = {x = 1, y = 1},
	textures = {"dm_fireball.png"},
	velocity = 8,

	-- Direct hit, no fire ... just plenty of pain.
	hit_player = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 8},
		}, nil)
	end,

	hit_mob = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 8},
		}, nil)
	end,

	-- Node hit, bursts into flame.
	hit_node = function(self, pos, node)
		-- The tnt explosion function respects protection perfectly (MustTest).
		tnt.boom(pos, {
			radius = 2,
			ignore_protection = false,
			ignore_on_blast = false,
			damage_radius = 3,
			disable_drops = true,
			mob = "dm:dm", -- Launched by this mob type. Thus blast will not damage mobs of this type.
		})
	end
})



mobs.register_egg("dm:dm", "Dungeon Master", "fire_basic_flame.png", 1, true)



mobs.alias_mob("mobs:dungeon_master",           "dm:dm")
mobs.alias_mob("mobs_monster:dungeon_master",   "dm:dm")


mobs.register_mob("iceman:iceman", {
	description = "Iceland Native",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
  group_attack = true,

	pathfinding = 2,
	instance_pathfinding_chance = {10, 100},
	place_node = "default:snowblock",
  despawns_in_dark_caves = true,
	daytime_despawn = true,

	reach = 2,
	damage = 3,
	hp_min = 12,
	hp_max = 25,
	armor = 80,
	collisionbox = {-0.3, -1, -0.3, 0.3, 0.7, 0.3},
	visual = "mesh",
	mesh = "mobs_stone_monster.b3d",
	textures = {
		{"mobs_ice_monster.png"},
	},
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_dirtmonster",
		death = "mobs_dirtmonster",
    distance = 10,
	},
	walk_velocity = 1.5,
	run_velocity = 2.8,
	jump = true,
  jump_chance = 30,
  walk_chance = 5,
	floats = 0,
	view_range = 20,
	drops = {
		-- Drop mossycobble sometimes. By MustTest
		{name = "default:mossycobble", chance = 3, min = 3, max = 12},
		{name = "default:snow", chance = 4, min = 1, max = 2},
    {name = "bones:bones_type2", chance = 2, min = 1, max = 1},
	},
	water_damage = 1,
	lava_damage = 100,
  makes_bones_in_lava = false,
	light_damage = 2,
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

	on_despawn = function(self)
		local pos = self.object:get_pos()
		ambiance.sound_play("teleport", pos, 1.0, 20)
		preload_tp.spawn_particles(pos)
		self.object:remove()
	end,
})





mobs.register_egg("iceman:iceman", "Iceman", "default_ice.png", 1)



mobs.alias_mob("mobs_monster:ice_native", "iceman:iceman")




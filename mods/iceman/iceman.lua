
mobs.register_mob("iceman:iceman", {
	description = "Iceland Native",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
  group_attack = true,

	-- Require at least steel sword to get any drops.
	armor_level = 1,

	pathfinding = 1,
	pathfinding_chance = 10,
	place_node = "default:snowblock",
  despawns_in_dark_caves = true,
	daytime_despawn = true,

	reach = 2,
	damage = 3*500,
	damage_min = 2*500,
	damage_max = 5*500,
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
	water_damage = 1*500,
	lava_damage = 100*500,
  makes_bones_in_lava = false,
	light_damage = 2*500,
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

		-- Note: cannot call object:remove()!
		--self.object:remove()

		-- We must do this instead: mark object for removal by the mob API.
		self.mkrm = true
	end,
})





mobs.register_egg("iceman:iceman", "Iceman", "default_ice.png", 1)



mobs.alias_mob("mobs_monster:ice_native", "iceman:iceman")




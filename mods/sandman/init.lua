 
-- custom particle effects
local effect = function(pos, amount, texture, min_size, max_size, radius, gravity, glow)

	radius = radius or 2
	min_size = min_size or 0.5
	max_size = max_size or 1
	gravity = gravity or -10
	glow = glow or 0

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = -radius, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = -20, y = gravity, z = 15},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end


-- Sand Monster by PilzAdam

mobs.register_mob("sandman:sandman", {
	description = "Sand Native",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
  group_attack = true,

	-- Require at least steel sword to get any drops.
	armor_level = 1,
  despawns_in_dark_caves = true,
	daytime_despawn = true,

	reach = 2,
	damage = 1,
	damage_min = 0,
	damage_max = 3,
	hp_min = 8,
	hp_max = 30,
	armor = 100,
	collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
	visual = "mesh",
	mesh = "mobs_sand_monster.b3d",
	textures = {
		{"mobs_sand_monster.png"},
	},
	blood_texture = "default_desert_sand.png",
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_sand_monster",
	},
	walk_velocity = 1.5,
	run_velocity = 4,
	view_range = 20, --15
	jump = true,
	floats = 0,
	drops = {
    {name = "bones:bones_type2", chance = 2, min = 1, max = 1},
		{name = "default:desert_sandstone", chance = 4, min = 1, max = 2},
		{name = "default:dry_shrub", chance = 2, min = 1, max = 1},
	},
	water_damage = 3,
	lava_damage = 4,
	light_damage = 1,
	fear_height = 4,
	animation = {
		speed_normal = 15,
		speed_run = 15,
		stand_start = 0,
		stand_end = 39,
		walk_start = 41,
		walk_end = 72,
		run_start = 74,
		run_end = 105,
		punch_start = 74,
		punch_end = 105,
	},
	immune_to = {
		{"default:shovel_wood", 3}, -- shovels deal more damage to sand monster
		{"default:shovel_stone", 3},
		{"default:shovel_bronze", 4},
		{"default:shovel_steel", 4},
		{"default:shovel_mese", 5},
		{"default:shovel_diamond", 7},
	},

	on_die = function(self, pos)
		pos.y = pos.y + 0.5
		effect(pos, 30, "mobs_sand_particles.png", 0.1, 2, 3, 5)
		pos.y = pos.y + 0.25
		effect(pos, 30, "mobs_sand_particles.png", 0.1, 2, 3, 5)
	end,

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

mobs.register_egg("sandman:sandman", "Jarkati Sand Native", "default_desert_sand.png", 1)


-- Dirt Monster by PilzAdam

mobs.register_mob("sandman:stoneman", {
	description = "Dirty Cave Dweller",
	type = "monster",
	passive = false,
	attack_type = "dogfight",
  group_attack = true,
	reach = 2,
	damage = 2,
	damage_min = 2,
	damage_max = 3,
	hp_min = 30,
	hp_max = 60,
	armor = 100,
	-- Require at least steel sword to get any drops.
	armor_level = 1,

	collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.b3d",
	textures = {
		{"mobs_dirt_monster.png"},
	},
	blood_texture = "default_dirt.png",
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_dirtmonster",
	},
	view_range = 20,
	walk_velocity = 1,
	run_velocity = 3,
	jump = true,
	drops = {
		{name = "default:silver_sandstone", chance = 2, min = 0, max = 3},
		{name = "default:desert_cobble", chance = 3, min = 0, max = 2},
	},
	water_damage = 1,
	lava_damage = 5,
	light_damage = 3,
	fear_height = 4,
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
})


mobs.register_egg("sandman:stoneman", "Jarkati Cave Dweller", "default_dirt.png", 1)

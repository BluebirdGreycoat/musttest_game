
mobs.register_mob("obsidianmonster:obsidianmonster", {
	type = "monster",
	passive = false,
	damage = 3,
	attack_type = "shoot",
	shoot_interval = 1.0,
	arrow = "obsidianmonster:arrow",
	shoot_offset = 2,
	hp_min = 10,
	hp_max = 25,
	armor = 80,
	armor_level = 3,
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "mesh",
	mesh = "obsidianmonster_obsidianmonster.x",
	textures = {
		{"obsidianmonster_obsidianmonster.png"},
	},
	blood_texture = "default_obsidian_shard.png",
	makes_footstep_sound = false,
	sounds = {
		random = "obsidianmonster_obsidianmonster",
	},
	view_range = 16,
	walk_velocity = 0.5,
	run_velocity = 2,
	jump = false,
	fly = true,
	--jump_height = 8,
	fall_damage = 0,
	fall_speed = -6,
	stepheight = 2.1,
	drops = {
		{name = "default:obsidian", chance = 2, min = 1, max = 6},
		{name = "default:obsidian_shard", chance = 2, min = 1, max = 9},
	},
	water_damage = 1,
	lava_damage = 1,
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
})





mobs.register_egg("obsidianmonster:obsidianmonster", "Obsidian Monster", "default_obsidian.png", 1)



mobs.alias_mob("mobs:mese_monster",             "obsidianmonster:obsidianmonster")
mobs.alias_mob("mobs_monster:mese_monster",     "obsidianmonster:obsidianmonster")



mobs.register_arrow("obsidianmonster:arrow", {
	visual = "sprite",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"default_obsidian_shard.png"},
	velocity = 10,

	hit_player = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 2},
		}, nil)
		ambiance.sound_play("default_punch", player:get_pos(), 1.0, 20)
	end,

	hit_mob = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 2},
		}, nil)
		ambiance.sound_play("default_punch", player:get_pos(), 1.0, 20)
	end,

	hit_node = function(self, pos, node)
		pos = vector.round(pos)
		if minetest.test_protection(pos, "") then
			return
		end

		local realnode = minetest.get_node(pos)
		-- Do not destroy bones.
		if realnode.name == "bones:bones" or realnode.name == "ignore" then
			return
		end
		minetest.add_node(pos, {name="fire:basic_flame"})
	end
})

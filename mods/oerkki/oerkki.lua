
-- That flying thing. NOT supposed to be an oerkki, but not changing name now
-- due to long usage.
mobs.register_mob("oerkki:oerkki", {
	type = "monster",
	description = "Flying Menace",
	passive = false,
	attack_type = "dogfight",
	reach = 2,
	punch_reach = 3,
	damage = 3*500,
	damage_group = "snappy",
	hp_min = 8*500,
	hp_max = 34*500,
	armor = 100,
	armor_level = 2,
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
	water_damage = 1*500,
	lava_damage = 100*500,
	light_damage = 1*500,
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

	-- Throw player off things.
	punch_target = function(self, object, attack)
		if attack and attack:is_player() then
			local p1 = object:get_pos()
			local p2 = attack:get_pos()
			p1.y = p2.y
			local vel = vector.subtract(p2, p1)

			-- Quick hack to fix problems with null vectors.
			if vector.length(vel) < 0.01 then
				vel.x = 1
			end

			vel = vector.normalize(vel)
			vel = vector.add(vel, {x=0, y=0.5, z=0})
			vel = vector.multiply(vel, 7)

			-- The player needs to be kicked up 1 node manually, because otherwise
			-- the collision box of the menace prevents them from being thrown, very
			-- often.
			p2.y = p2.y + 1
			p1.y = p1.y - 1
			object:set_pos(p1)
			attack:set_pos(p2)

			minetest.after(0.3, function()
				attack:add_player_velocity(vel)
			end)
		end
	end,
})





mobs.register_egg("oerkki:oerkki", "Oerkki", "default_obsidian.png", 1)



mobs.alias_mob("mobs_monster:oerkki2", "oerkki:oerkki")


local SCALE = 500

mobs.register_mob("nssm:morde", {
	type = "monster",
	description = "Morde",
	hp_max = 47*SCALE,
	hp_min = 37*SCALE,
	collisionbox = {-0.4, -0.1, -0.4, 0.4, 1.6, 0.4},
	visual = "mesh",
	rotate= 270,
	mesh = "morde.x",
	textures = {{"morde.png"}},
	visual_size = {x=8, y=8},
	makes_footstep_sound = true,
	view_range = 20,
	walk_velocity = 0.5,
	reach =3.0,
	run_velocity = 3.5,
	damage = 6*SCALE,
	jump = true,
	sounds = {
		random = "morde",
		attack = "morde",
	},
	drops = {
		{name = "default:flint", chance = 1, min = 2, max = 4},
		{name = "default:obsidian_shard", chance = 3, min = 1, max = 1},
	},
	armor = 60,
	drawtype = "front",
	water_damage = 0,
	fear_height = 4,
	floats = 1,
	lava_damage = 0,
	light_damage = 0,
	group_attack=true,
	attack_animals=true,
	knock_back=1,
	blood_texture="morparticle.png",
	stepheight=1.1,
	on_rightclick = nil,
	attack_type = "dogfight",
	animation = {
		speed_normal = 15,
		speed_run = 25,
		stand_start = 10,
		stand_end = 40,
		walk_start = 50,
		walk_end = 90,
		run_start = 100,
		run_end = 120,
		punch_start = 130,
		punch_end = 160,
	},

	custom_attack = function(self)
		self.morde_timer = (self.morde_timer or os.time())
		if (os.time() - self.morde_timer) > 1 then
			self.morde_timer = os.time()

			local s = self.object:get_pos()
			local p = self.attack:get_pos()

			mobs.set_animation(self, "punch")

			self.health = self.health + (self.damage*2)
			local m = 3

			if minetest.line_of_sight({x = p.x, y = p.y +1.5, z = p.z}, {x = s.x, y = s.y +1.5, z = s.z}) == true then
				-- play attack sound
				if self.sounds.attack then
					minetest.sound_play(self.sounds.attack, {
						object = self.object,
						max_hear_distance = self.sounds.distance
					})
				end

				-- punch player
				self.attack:punch(self.object, 1.0,  {
					full_punch_interval=1.0,
					damage_groups = {snappy=self.damage}
				}, nil)

				minetest.add_particlespawner({
					amount = 6, --amount
					time = 1, --time
					minpos = {x=p.x-0.5, y=p.y-0.5, z=p.z-0.5}, --minpos
					maxpos = {x=p.x+0.5, y=p.y+0.5, z=p.z+0.5}, --maxpos
					minvel = {x=(s.x-p.x)*m, y=(s.y-p.y+1)*m, z=(s.z-p.z)*m}, --minvel
					maxvel = {x=(s.x-p.x)*m, y=(s.y-p.y+1)*m, z=(s.z-p.z)*m}, --maxvel
					minacc = {x=s.x-p.x, y=s.y-p.y+1, z=s.z-p.z}, --minacc
					maxacc = {x=s.x-p.x, y=s.y-p.y+1, z=s.z-p.z}, --maxacc
					minexptime = 0.2, --minexptime
					maxexptime = 0.3, --maxexptime
					minsize = 2, --minsize
					maxsize = 3, --maxsize
					collisiondetection = false, --collisiondetection
					texture = "morparticle.png", --texture
				})
			end
		end
	end,

	on_die = function(self)
		local pos = self.object:get_pos()
		minetest.add_entity(pos, "nssm:mortick")
	end,
})

mobs.register_egg("nssm:morde", "Morde", "default_obsidian.png", 1)

minetest.register_entity("nssm:mortick", {
	textures = {"mortick.png"},
	hp_min = 10000,
	hp_max = 10000,
	armor = 1,
	visual = "mesh",
	mesh = "mortick.x",
	visual_size = {x=3, y=3},

	-- Thus much damage is a nuisance if the player is healthy, but can quickly
	-- overwhelm them if they become so damaged that passive healing can no longer
	-- keep up.
	damage = 1*SCALE,

	on_step = function(self, dtime)
		self.mortick_timer = self.mortick_timer or os.time()
		self.timer = self.timer or 0
		self.timer = self.timer + dtime
		local s = self.object:get_pos()
		local s1 = vector.round({x=s.x, y = s.y, z = s.z})

		-- The mortick dies when he finds himself in the water.
		-- It has to be *really* water (group level 3).
		local name = minetest.get_node(s1).name
		if minetest.get_item_group(name, "water") == 3 then
			self.object:remove()
			return
		end

		-- Find player to attack, if we don't have a target named already.
		if not self.attack or self.attack == "" then
			-- Chose target for the first time, once only.
			local objects = minetest.get_objects_inside_radius(s, 8)
			for _, obj in ipairs(objects) do
				if obj:is_player() and not gdac.player_is_admin(obj) then
					-- Note: this is player's name! Do not store player reference.
					self.attack = obj:get_player_name()
					break
				end
			end
		end

		-- If found a player follow him.
		if self.attack and self.attack ~= "" then
			local target = minetest.get_player_by_name(self.attack)
			if target then
				-- Attach to target if not currently attached.
				if not self.object:get_attach() then
					self.object:set_attach(target, "", {x=0, y=9, z=-4}, {x=0, y=90, z=0})
				end

				-- Damage player every ten seconds:
				if self.timer > 10 then
					self.timer = 0
					utility.damage_player(target, "poison", self.damage)
				end
			end
		end
	end
})

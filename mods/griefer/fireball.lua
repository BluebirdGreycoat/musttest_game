
mobs.register_arrow(":griefer:fireball", {
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

	hit_mob = function(self, target)
		local puncher

		if self.owner_obj and self.owner_obj:get_pos() then
			puncher = self.owner_obj
		else
			puncher = self.object
		end

		target:punch(puncher, 1.0, {
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
			mob = "griefer:elite_griefer",
		})
	end
})

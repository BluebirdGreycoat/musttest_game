
local function murdertusk_despawn(self)
	local pos = vector.round(self.object:get_pos())
	local nodeabove = minetest.get_node_or_nil(pos)
	local nodeunder = minetest.get_node_or_nil(vector.offset(pos, 0, -1, 0))
	if nodeabove and nodeunder then
		if nodeabove.name == "air" and nodeunder.name ~= "air" then
			minetest.set_node(pos, {name="default:dry_grass_" .. math.random(1, 5), param2=2})
			minetest.check_for_falling(pos)
		end
	end

	-- Mark object for removal by the mob API.
	self.mkrm = true
end

-- Warthog by KrupnoPavel. Modified for Enyekala by MustTest.
mobs.register_mob("animalworld:murdertusk", {
	stepheight = 2,
	type = "animal",
	description = "Murdertusk",
	passive = false,
	attack_type = "dogfight",
	group_attack = true,

	attack_players = true,
	attack_npcs = false,
	pathfinding = 1,

	reach = 2,
	damage = 10*500,
	damage_group = "snappy",
	hp_min = 20*500,
	hp_max = 40*500,
	armor = 50,
	collisionbox = {-0.5, -0.01, -0.5, 0.5, 0.95, 0.5},
	visual = "mesh",
	mesh = "mobs_pumba.b3d",
	visual_size = {x = 1.2, y = 1.2},
	textures = {
		{"animalworld_suboar2.png"},
	},
	sounds = {
		random = "animalworld_suboar",
		attack = "animalworld_suboar",
	},
	makes_footstep_sound = true,
	walk_velocity = 1.5,
	run_velocity = 3.5,
	jump = true,
	drops = {
		{name = "mobs:meat_raw_pork", chance = 2, min = 1, max = 1},
		{name = "mobs:leather", chance = 10, min = 1, max = 1},
	},
	water_damage = 0,
	lava_damage = 4*500,
	light_damage = 0,
	fear_height = 3,
	animation = {
		speed_normal = 15,
		stand_start = 25,
		stand_end = 55,
		walk_start = 70,
		walk_end = 100,
		run_start = 70,
		run_end = 100,
		run_speed = 30,
		punch_start = 70,
		punch_end = 100,
	},
	view_range = 50,
  makes_bones_in_lava = true,
  daytime_despawn = true,
  on_despawn = murdertusk_despawn,
})

mobs.register_egg("animalworld:murdertusk", "Murdertusk", "default_dirt.png", 1)

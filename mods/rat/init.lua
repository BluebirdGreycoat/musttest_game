
rat = rat or {}
rat.modpath = minetest.get_modpath("rat")



-- Rat by PilzAdam. Modified for MustTest by MustTest.
mobs.register_mob("rat:rat", {
	type = "animal",
	passive = true,
	hp_min = 1,
	hp_max = 4,
	armor = 200,
	collisionbox = {-0.2, -1, -0.2, 0.2, -0.8, 0.2},
	visual = "mesh",
	mesh = "rat_rat.b3d",
	textures = {
		{"rat_rat1.png"},
		{"rat_rat2.png"},
	},
	makes_footstep_sound = false,
	sounds = {
		random = "rat_rat",
	},
	walk_velocity = 1,
	run_velocity = 2,
	runaway = true,
	jump = true,
	water_damage = 0,
	lava_damage = 4,
    makes_bones_in_lava = false,
	light_damage = 0,
	fear_height = 2,
    
	on_rightclick = function(self, clicker)
		mobs.capture_mob(self, clicker, 96, 100, 100, true, nil)
	end,
})





-- Obtainable by players.
mobs.register_egg("rat:rat", "Rat", "rat_inventory_rat.png", 0)



minetest.register_craftitem("rat:rat_cooked", {
	description = "Cooked Rat",
	inventory_image = "rat_inventory_cooked_rat.png",
	on_use = minetest.item_eat(3),
})



minetest.register_craft({
	type = "cooking",
	output = "rat:rat_cooked",
	recipe = "rat:rat",
	cooktime = 5,
})

minetest.register_craft({
	type = "cooking",
	output = "rat:rat_cooked",
	recipe = "rat:rat_set",
	cooktime = 5,
})



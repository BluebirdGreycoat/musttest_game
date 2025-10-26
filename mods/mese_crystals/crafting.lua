
if not mese_crystals.crafts_registered then
	minetest.register_craft({
		output = "mese_crystals:mese_crystal_seed 2",
		recipe = {
			{'mese_crystals:zentamine','mese_crystals:zentamine','mese_crystals:zentamine'},
			{'mese_crystals:zentamine','rackstone:bluerack','mese_crystals:zentamine'},
			{'mese_crystals:zentamine','mese_crystals:zentamine','mese_crystals:zentamine'},
		}
	})

	minetest.register_craft({
		output = "mese_crystals:crystaline_bell",
		recipe = {
			{'default:diamond'},
			{'default:glass'},
			{'group:stick'},
		}
	})

	minetest.register_craft({
	  type = "cooking",
  	output = "mese_crystals:zentamine",
		recipe = "default:mese_crystal_fragment",
		cooktime = 20,
	})

	minetest.register_craft({
		type = "alloying",
		output = "mese_crystals:obsidian_zentamine",
		recipe = {"default:mese_crystal_fragment", "default:obsidian_shard"},
		time = 15,
	})

	minetest.register_craft({
		type = "alloying",
		output = "mese_crystals:fertile_fragment",
		recipe = {"mese_crystals:obsidian_zentamine", "glowstone:glowing_dust 2"},
		time = 15,
	})

	minetest.register_craft({
	  type = "cooking",
  	output = "default:mese_crystal",
		recipe = "mese_crystals:fertile_fragment 9",
		cooktime = 10,
	})

	mese_crystals.crafts_registered = true
end

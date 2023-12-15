
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
			{'default:stick'},
		}
	})

	minetest.register_craft({
	  type = "cooking",
  	output = "mese_crystals:zentamine",
		recipe = "default:mese_crystal_fragment",
		cooktime = 2,
	})


	mese_crystals.crafts_registered = true
end

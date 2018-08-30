
if not mese_crystals.crafts_registered then
	minetest.register_craft({
		output = "mese_crystals:mese_crystal_seed 2",
		recipe = {
			{'default:mese_crystal_fragment','default:mese_crystal_fragment','default:mese_crystal_fragment'},
			{'default:mese_crystal_fragment','rackstone:bluerack','default:mese_crystal_fragment'},
			{'default:mese_crystal_fragment','default:mese_crystal_fragment','default:mese_crystal_fragment'},
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
  	output = "default:mese_crystal_fragment",
		recipe = "mese_crystals:zentamine",
		cooktime = 2,
	})


	mese_crystals.crafts_registered = true
end

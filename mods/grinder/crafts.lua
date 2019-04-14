
if not grinder.crafts_registered then
	if minetest.get_modpath("default") then
		minetest.register_craft({
      type = "grinding",
			output = 'default:gravel',
			recipe = 'default:cobble',
			time = 10,
		})

		minetest.register_craft({
      type = "grinding",
			output = 'default:dirt',
			recipe = 'default:gravel',
			time = 10,
		})

		minetest.register_craft({
      type = "grinding",
			output = 'default:sand 4',
			recipe = 'default:stone',
			time = 10,
		})

    minetest.register_craft({
      type = "grinding",
      output = 'default:desert_sand 4',
      recipe = 'default:desert_stone',
      time = 10,
    })

    minetest.register_craft({
      type = "grinding",
      output = "default:sand 2",
      recipe = "default:sandstone",
      time = 10,
    })

    minetest.register_craft({
      type = "grinding",
      output = "default:desert_sand 2",
      recipe = "default:desert_sandstone",
      time = 10,
    })

    minetest.register_craft({
      type = "grinding",
      output = "sand:sand_with_ice_crystals 2",
      recipe = "default:silver_sandstone",
      time = 10,
    })

    minetest.register_craft({
      type = "grinding",
      output = 'farming:flour 2',
      recipe = 'farming:seed_wheat',
      time = 5,
    })

    -- Recipes for desert stone & cobble.
		--[[
    minetest.register_craft({
        output = "default:desert_cobble 4",
        recipe = {
            {"",                "default:cobble",       ""              },
            {"default:cobble",  "dusts:copper",  "default:cobble"},
            {"",                "default:cobble",       ""              },
        }
    })
		--]]
		minetest.register_craft({
			type = "alloying",
			output = "default:desert_cobble 4",
			recipe = {"default:cobble 4", "dusts:copper"},
			time = 6,
		})

	end

  minetest.register_craft({
    output = 'grind2:lv_inactive',
    recipe = {
      {'default:stonebrick', 'default:diamond',        'default:stonebrick'},
      {'default:stonebrick', 'techcrafts:machine_casing', 'default:stonebrick'},
      {'morerocks:granite',      'techcrafts:electric_motor',       'morerocks:granite'},
    }
  })

	minetest.register_craft({
		output = 'grind2:mv_inactive',
		recipe = {
			{'stainless_steel:ingot', 'grind2:lv_inactive',     'stainless_steel:ingot'},
			{'techcrafts:electric_motor',              'transformer:mv', 'techcrafts:machine_casing'},
			{'stainless_steel:ingot', 'cb2:mv',       'stainless_steel:ingot'},
		}
	})

	grinder.crafts_registered = true
end


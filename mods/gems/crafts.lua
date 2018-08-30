
--        --
--Crafting--
--        --

--
--Crafting>Blocks
--

minetest.register_craft({
	output = 'gems:ruby_block',
	recipe = {
		{'gems:ruby_gem','gems:ruby_gem','gems:ruby_gem',},
		{'gems:ruby_gem','gems:ruby_gem','gems:ruby_gem',},
		{'gems:ruby_gem','gems:ruby_gem','gems:ruby_gem',},
	}
})

minetest.register_craft({
	output = 'gems:amethyst_block',
	recipe = {
		{'gems:amethyst_gem','gems:amethyst_gem','gems:amethyst_gem',},
		{'gems:amethyst_gem','gems:amethyst_gem','gems:amethyst_gem',},
		{'gems:amethyst_gem','gems:amethyst_gem','gems:amethyst_gem',},
	}
})

minetest.register_craft({
	output = 'gems:emerald_block',
	recipe = {
		{'gems:emerald_gem', 'gems:emerald_gem', 'gems:emerald_gem'},
		{'gems:emerald_gem', 'gems:emerald_gem', 'gems:emerald_gem'},
		{'gems:emerald_gem', 'gems:emerald_gem', 'gems:emerald_gem'},
	}
})

minetest.register_craft({
	output = 'gems:sapphire_block',
	recipe = {
		{'gems:sapphire_gem', 'gems:sapphire_gem', 'gems:sapphire_gem'},
		{'gems:sapphire_gem', 'gems:sapphire_gem', 'gems:sapphire_gem'},
		{'gems:sapphire_gem', 'gems:sapphire_gem', 'gems:sapphire_gem'},
	}
})



local register_shovel = function(mt, nv, sv)
  minetest.register_craft({
    output = nv,
    recipe = {
      {mt},
      {'default:stick'},
      {'default:stick'},
    }
  })
  minetest.register_craft({
    output = sv,
    recipe = {
      {mt},
      {'default:steel_ingot'},
      {'default:steel_ingot'},
    }
  })
end

local register_sword = function(mt, nv, sv)
  minetest.register_craft({
    output = nv,
    recipe = {
      {mt},
      {mt},
      {'default:stick'},
    }
  })
  minetest.register_craft({
    output = sv,
    recipe = {
      {mt},
      {mt},
      {'default:steel_ingot'},
    }
  })
end

local register_pick = function(mt, nv, sv)
  minetest.register_craft({
    output = nv,
    recipe = {
      {mt, mt, mt},
      {'', 'default:stick', ''},
      {'', 'default:stick', ''},
    }
  })
  minetest.register_craft({
    output = sv,
    recipe = {
      {mt, mt, mt},
      {'', 'default:steel_ingot', ''},
      {'', 'default:steel_ingot', ''},
    }
  })
end

local register_axe = function(mt, nv, sv)
  minetest.register_craft({
    output = nv,
    recipe = {
      {mt, mt, ''},
      {mt, 'default:stick', ''},
      {'', 'default:stick', ''},
    }
  })
  minetest.register_craft({
    output = nv,
    recipe = {
      {'', mt, mt},
      {'', 'default:stick', mt},
      {'', 'default:stick', ''},
    }
  })
  minetest.register_craft({
    output = sv,
    recipe = {
      {mt, mt, ''},
      {mt, 'default:steel_ingot', ''},
      {'', 'default:steel_ingot', ''},
    }
  })
  minetest.register_craft({
    output = sv,
    recipe = {
      {'', mt, mt},
      {'', 'default:steel_ingot', mt},
      {'', 'default:steel_ingot', ''},
    }
  })
end

--
--Crafting>Shovels
--

register_shovel('gems:ruby_gem', 'gems:shovel_ruby', 'gems:stone_shovel_ruby')
register_shovel('gems:emerald_gem', 'gems:shovel_emerald', 'gems:stone_shovel_emerald')
register_shovel('gems:sapphire_gem', 'gems:shovel_sapphire', 'gems:stone_shovel_sapphire')
register_shovel('gems:amethyst_gem', 'gems:shovel_amethyst', 'gems:stone_shovel_amethyst')

--
--Crafting>Swords
--

register_sword('gems:ruby_gem', 'gems:sword_ruby', 'gems:stone_sword_ruby')
register_sword('gems:amethyst_gem', 'gems:sword_amethyst', 'gems:stone_sword_amethyst')
register_sword('gems:emerald_gem', 'gems:sword_emerald', 'gems:stone_sword_emerald')
register_sword('gems:sapphire_gem', 'gems:sword_sapphire', 'gems:stone_sword_sapphire')

--
--Crafting>Picks
--

register_pick('gems:ruby_gem', 'gems:pick_ruby', 'gems:stone_pick_ruby')
register_pick('gems:amethyst_gem', 'gems:pick_amethyst', 'gems:stone_pick_amethyst')
register_pick('gems:emerald_gem', 'gems:pick_emerald', 'gems:stone_pick_emerald')
register_pick('gems:sapphire_gem', 'gems:pick_sapphire', 'gems:stone_pick_sapphire')

--
--Crafting>Axes
--

register_axe('gems:ruby_gem', 'gems:axe_ruby', 'gems:stone_axe_ruby')
register_axe('gems:amethyst_gem', 'gems:axe_amethyst', 'gems:stone_axe_amethyst')
register_axe('gems:emerald_gem', 'gems:axe_emerald', 'gems:stone_axe_emerald')
register_axe('gems:sapphire_gem', 'gems:axe_sapphire', 'gems:stone_axe_sapphire')

--
--Crafting>Gems
--

minetest.register_craft({
        output = 'gems:amethyst_gem 9',
        type = 'shapeless',
        recipe = {'gems:amethyst_block'},
})

minetest.register_craft({
        output = 'gems:ruby_gem 9',
        type = 'shapeless',
        recipe = {'gems:ruby_block'},
})

minetest.register_craft({
        output = 'gems:emerald_gem 9',
        type = 'shapeless',
        recipe = {'gems:emerald_block'},
})

minetest.register_craft({
        output = 'gems:sapphire_gem 9',
        type = 'shapeless',
        recipe = {'gems:sapphire_block'},
})

--
--Crafting>Stone Rod 
--
--minetest.register_craft({
--  output = 'gems:stone_rod 4',
--  recipe = {
--    {'default:steel_ingot'},
--    {'default:stone'},
--    {'default:stone'},
--  }
--})

minetest.register_craft({
  type = "cutting",
  output = 'gems:ruby_gem',
  recipe = 'gems:raw_ruby',
  hardness = 20,
})

minetest.register_craft({
  type = "cutting",
  output = 'gems:emerald_gem',
  recipe = 'gems:raw_emerald',
  hardness = 15,
})

minetest.register_craft({
  type = "cutting",
  output = 'gems:sapphire_gem',
  recipe = 'gems:raw_sapphire',
  hardness = 18,
})

minetest.register_craft({
  type = "cutting",
  output = 'gems:amethyst_gem',
  recipe = 'gems:raw_amethyst',
  hardness = 12,
})

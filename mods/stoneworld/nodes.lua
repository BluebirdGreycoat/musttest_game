
minetest.register_node("stoneworld:meat_rock", {
  description = "Basaltic Rubble With Unidentified Meat",
  tiles = {"darkage_basalt_rubble.png^rackstone_meat.png"},
  groups = utility.dig_groups("cobble"),
  sounds = default.node_sound_stone_defaults(),
  drop = "mobs:naraxen_meat",
	silverpick_drop = true,
	place_param2 = 10,
})

minetest.register_node("stoneworld:meat_stone", {
  description = "Basaltic Stone With Unidentified Meat",
  tiles = {"darkage_basalt.png^rackstone_meat.png"},
  groups = utility.dig_groups("stone"),
  sounds = default.node_sound_stone_defaults(),
  drop = "mobs:naraxen_meat_raw",
	silverpick_drop = true,
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_gold", {
	description = "Gold Ore",
	tiles = {"darkage_basalt.png^default_mineral_gold.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = "default:gold_lump",
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_diamond", {
	description = "Diamond Deposit",
	tiles = {"darkage_basalt.png^default_mineral_diamond.png"},
	groups = utility.dig_groups("hardmineral"),
	drop = "default:diamond",
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_mese", {
	description = "Mese Ore",
	tiles = {"darkage_basalt.png^default_mineral_mese.png"},
	groups = utility.dig_groups("hardmineral", {melts = 1}),
	drop = {
		max_items = 2,
		items = {
			{items = {'mobs:flame_bolt'}, rarity = 16},
			{items = {'default:mese_crystal'}}
		}
	},
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),

	-- Mese in stone reacts badly to lava.
	on_melt = function(pos, other)
		minetest.after(0, function()
      tnt.boom(pos, {
        radius = 4,
        ignore_protection = false,
        ignore_on_blast = false,
        damage_radius = 6,
        disable_drops = true,
      })
		end)
	end,
})

minetest.register_node("stoneworld:basalt_with_iron", {
	description = "Iron Ore",
	tiles = {"darkage_basalt.png^default_mineral_iron.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'default:iron_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_coal", {
	description = "Coal Deposit",
	tiles = {"darkage_basalt.png^stoneworld_mineral_coal.png"},
  -- Cannot be flammable (although I would like it to be)
  -- because that interferes with TNT mining (the TNT replaces
  -- all coal with flame instead of dropping it).
	groups = utility.dig_groups("mineral"),
	drop = 'default:coal_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_dauth", {
	description = "Dauth Deposit",
	tiles = {"darkage_basalt.png^stoneworld_mineral_coal.png"},
  -- Cannot be flammable (although I would like it to be)
  -- because that interferes with TNT mining (the TNT replaces
  -- all coal with flame instead of dropping it).
	groups = utility.dig_groups("mineral"),
	drop = 'rackstone:dauth_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_copper", {
	description = "Copper Ore",
	tiles = {"darkage_basalt.png^default_mineral_copper.png"},
	groups = utility.dig_groups("mineral", {ore = 1}),
	drop = 'default:copper_lump',
	silverpick_drop = true,
	sounds = default.node_sound_stone_defaults(),
	place_param2 = 10,
})

minetest.register_node("stoneworld:basalt_with_tin", {
  description = "Tin Ore",
	tiles = {"darkage_basalt.png^moreores_mineral_tin2.png"},
  groups = utility.dig_groups("mineral", {ore=1}),
  sounds = default.node_sound_stone_defaults(),
  drop = "moreores:tin_lump",
	silverpick_drop = true,
	place_param2 = 10,
})

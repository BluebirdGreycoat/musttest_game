-- Flowers by DragonsVolcanoDance.
--
-- Message to DVD: you gave me this code in an *.odt file.
-- This remark forever marks your utter noobishness. :p
-- Also, you forgot some } and ).

flowers.aradonia_flowers_list = {
	{node="aradonia:caveflower6"},
	{node="aradonia:caveflower8"},
	{node="aradonia:caveflower9"},
	{node="aradonia:caveflower10"},
	{node="aradonia:caveflower11"},
	{node="aradonia:caveflower12"},
	{node="aradonia:caveflower13"},
}

-- Giant Luminous Flower
minetest.register_node(':aradonia:caveflower6', {
	description = 'Midnight Sun',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_luminousflower.png'},
	inventory_image = 'dvd_luminousflower.png',
	paramtype = "light",
	light_source = 6,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Fairy Flower
minetest.register_node(':aradonia:caveflower8', {
	description = 'Fairy Flower',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_fairyflower2.png'},
	inventory_image = 'dvd_fairyflower2.png',
	paramtype = "light",
	light_source = 5,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Weeping Sunset Flower
minetest.register_node(':aradonia:caveflower9', {
	description = 'Weeping Sunset',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_weepingsunset.png'},
	inventory_image = 'dvd_weepingsunset.png',
	paramtype = "light",
	light_source = 4,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Weeping Sunrise Flower
minetest.register_node(':aradonia:caveflower10', {
	description = 'Weeping Sunrise',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_weepingsunrise.png'},
	inventory_image = 'dvd_weepingsunrise.png',
	paramtype = "light",
	light_source = 4,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Fiery Lantern
minetest.register_node(':aradonia:caveflower11', {
	description = 'Fiery Lantern',
	drawtype = "plantlike",
	visual_scale =  2.0,
	walkable = false,
	tiles = {'dvd_fierylantern.png'},
	inventory_image = 'dvd_fierylantern.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	light_source = 5,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Fireflowers
minetest.register_node(':aradonia:caveflower12', {
	description = 'Fireflowers',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_fireflowers.png'},
	inventory_image = 'dvd_fireflowers.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 10,
	light_source = 2,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})

-- Fiery Thorns
minetest.register_node(':aradonia:caveflower13', {
	description = 'Fiery Thorns',
	drawtype = "plantlike",
	visual_scale =  1.0,
	walkable = false,
	tiles = {'dvd_fierythorns.png'},
	inventory_image = 'dvd_fierythorns.png',
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 3+32,
	light_source = 1,
	groups = {level = 1, snappy = 3, oddly_breakable_by_hand = 1, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

	damage_per_second = 2*500,
  _damage_per_second_type = "snappy",
	_death_message = {
		"The firethorns got <player>.",
		"<player> was pierced by firethorns.",
	},
})

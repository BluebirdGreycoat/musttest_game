
doors.register_trapdoor("doors:trapdoor", {
	description = "Wooden Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
	groups = utility.dig_groups("door_wood", {flammable = 2, door = 1}),
})

doors.register_trapdoor("doors:trapdoor_locked", {
	description = "Locked Wooden Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
    protected = true,
	groups = utility.dig_groups("door_wood", {flammable = 2, door = 1}),
})

doors.register_trapdoor("doors:trapdoor_steel", {
	description = "Iron Trapdoor",
	inventory_image = "doors_trapdoor_steel.png",
	wield_image = "doors_trapdoor_steel.png",
	tile_front = "doors_trapdoor_steel.png",
	tile_side = "doors_trapdoor_steel_side.png",
	protected = true,
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
})

doors.register_trapdoor("doors:trapdoor_iron_locked", {
	description = "Locked Wrought Iron Trapdoor",
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	tile_front = "doors_trapdoor_iron.png",
	tile_side = "doors_trapdoor_iron_side.png",
	protected = true,
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
})

doors.register_trapdoor("doors:trapdoor_iron", {
	description = "Wrought Iron Trapdoor",
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	tile_front = "doors_trapdoor_iron.png",
	tile_side = "doors_trapdoor_iron_side.png",
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
})

minetest.register_craft({
	output = 'doors:trapdoor 2',
	recipe = {
		{'default:wood', 'default:wood', 'default:wood'},
		{'default:wood', 'default:wood', 'default:wood'},
		{'', '', ''},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_locked',
	recipe = {
		{'default:wood', 'default:padlock', 'default:wood'},
		{'default:wood', 'default:wood',        'default:wood'},
		{'', '', ''},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_steel',
	recipe = {
		{'', 'default:padlock'},
		{'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_iron',
	recipe = {
		{'default:iron_lump', 'default:iron_lump', 'default:iron_lump'},
		{'default:iron_lump', 'default:iron_lump', 'default:iron_lump'},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_iron_locked',
	recipe = {
		{'default:iron_lump', 'default:padlock', 'default:iron_lump'},
		{'default:iron_lump', 'default:iron_lump',   'default:iron_lump'},
	}
})

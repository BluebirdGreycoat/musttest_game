
doors.register_trapdoor("trapdoor", {
	description = "Wooden Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
	groups = utility.dig_groups("door_wood", {flammable = 2, door = 1}),
	recipeitem = "default:wood",
	recipehinge = "techcrafts:hinge_wood",
})

doors.register_trapdoor("trapdoor_locked", {
	description = "Locked Wooden Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
	protected = true,
	groups = utility.dig_groups("door_wood", {flammable = 2, door = 1}),
	recipeitem = "default:wood",
	recipehinge = "techcrafts:hinge_wood",
})

doors.register_trapdoor("trapdoor_steel", {
	description = "Locked Iron Trapdoor",
	inventory_image = "doors_trapdoor_steel.png",
	wield_image = "doors_trapdoor_steel.png",
	tile_front = "doors_trapdoor_steel.png",
	tile_side = "doors_trapdoor_steel_side.png",
	protected = true,
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
	recipeitem = "default:steel_ingot",
})

doors.register_trapdoor("trapdoor_steel_unlocked", {
	description = "Iron Trapdoor",
	inventory_image = "doors_trapdoor_steel.png",
	wield_image = "doors_trapdoor_steel.png",
	tile_front = "doors_trapdoor_steel.png",
	tile_side = "doors_trapdoor_steel_side.png",
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
	recipeitem = "default:steel_ingot",
})

-- No locked version. Use for camo.
doors.register_trapdoor("trapdoor_stone", {
	description = "Stone Trapdoor",
	inventory_image = "doors_trapdoor_stone.png",
	wield_image = "doors_trapdoor_stone.png",
	tile_front = "doors_trapdoor_stone.png",
	tile_side = "doors_trapdoor_stone_side.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:stone",
})

-- No locked version. Use for camo.
doors.register_trapdoor("trapdoor_desertstone", {
	description = "Desert Stone Trapdoor",
	inventory_image = "doors_trapdoor_redstone.png",
	wield_image = "doors_trapdoor_redstone.png",
	tile_front = "doors_trapdoor_redstone.png",
	tile_side = "doors_trapdoor_redstone_side.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:desert_stone",
})

-- No locked version. Use for camo.
doors.register_trapdoor("trapdoor_rackstone", {
	description = "Rackstone Trapdoor",
	inventory_image = "doors_trapdoor_rackstone.png",
	wield_image = "doors_trapdoor_rackstone.png",
	tile_front = "doors_trapdoor_rackstone.png",
	tile_side = "doors_trapdoor_rackstone_side.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "rackstone:rackstone",
})

doors.register_trapdoor("trapdoor_iron_locked", {
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
	recipeitem = "default:iron_lump",
})

doors.register_trapdoor("trapdoor_iron", {
	description = "Wrought Iron Trapdoor",
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	tile_front = "doors_trapdoor_iron.png",
	tile_side = "doors_trapdoor_iron_side.png",
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
	recipeitem = "default:iron_lump",
})

doors.register_trapdoor("trapdoor_sandstone", {
	description = "Sandstone Trapdoor",
	inventory_image = "doors_trapdoor_sandstone.png",
	wield_image = "doors_trapdoor_sandstone.png",
	tile_front = "doors_trapdoor_sandstone.png",
	tile_side = "doors_trapdoor_sandstone_side.png",
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:sandstone",
})

doors.register_trapdoor("trapdoor_sandstone_locked", {
	description = "Locked Sandstone Trapdoor",
	inventory_image = "doors_trapdoor_sandstone.png",
	wield_image = "doors_trapdoor_sandstone.png",
	tile_front = "doors_trapdoor_sandstone.png",
	tile_side = "doors_trapdoor_sandstone_side.png",
	protected = true,
	sounds = default.node_sound_stone_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:sandstone",
})

doors.register_trapdoor("trapdoor_glass", {
	description = "Glass Trapdoor",
	inventory_image = "default_glass.png",
	wield_image = "default_glass.png",
	tile_front = "default_glass.png",
	tile_side = "default_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:glass",
	sunlight_propagates = true,
})

doors.register_trapdoor("trapdoor_glass_locked", {
	description = "Locked Glass Trapdoor",
	inventory_image = "default_glass.png",
	wield_image = "default_glass.png",
	tile_front = "default_glass.png",
	tile_side = "default_glass.png",
	protected = true,
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:glass",
	sunlight_propagates = true,
})

doors.register_trapdoor("trapdoor_obsidian_glass", {
	description = "Obsidian Glass Trapdoor",
	inventory_image = "default_obsidian_glass.png",
	wield_image = "default_obsidian_glass.png",
	tile_front = "default_obsidian_glass.png",
	tile_side = "default_obsidian_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:obsidian_glass",
	sunlight_propagates = true,
})

doors.register_trapdoor("trapdoor_obsidian_glass_locked", {
	description = "Locked Obsidian Glass Trapdoor",
	inventory_image = "default_obsidian_glass.png",
	wield_image = "default_obsidian_glass.png",
	tile_front = "default_obsidian_glass.png",
	tile_side = "default_obsidian_glass.png",
	protected = true,
	sounds = default.node_sound_glass_defaults(),
	groups = utility.dig_groups("door_stone", {door = 1}),
	recipeitem = "default:obsidian_glass",
	sunlight_propagates = true,
})

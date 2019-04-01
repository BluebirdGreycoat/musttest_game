


chest_api.register_chest("morechests:woodchest_public", {
	description = "Unlocked Darkwood Chest",
	tiles = { "morechests_woodchest_public.png" },
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("chest", {chest = 1}),
})

chest_api.register_chest("morechests:woodchest_locked", {
	description = "Locked Darkwood Chest",
	tiles = { "morechests_woodchest_locked.png" },
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("chest", {chest = 1}),
	protected = true,
})

minetest.register_alias("morechests:woodchest", "morechests:woodchest_public_closed")
minetest.register_alias("morechests:woodchest_locked", "morechests:woodchest_locked_closed")
minetest.register_alias("morechests:woodchest_public", "morechests:woodchest_public_closed")



chest_api.register_chest("morechests:copperchest_public", {
	description = "Unlocked Copper-Plated Chest",
	tiles = { "morechests_copper_public.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
})

chest_api.register_chest("morechests:copperchest_locked", {
	description = "Locked Copper-Plated Chest",
	tiles = { "morechests_copper_locked.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
	protected = true,
})

minetest.register_alias("morechests:copperchest_public", "morechests:copperchest_public_closed")
minetest.register_alias("morechests:copperchest_locked", "morechests:copperchest_locked_closed")



chest_api.register_chest("morechests:ironchest_public", {
	description = "Unlocked Ironside Chest",
	tiles = { "morechests_iron_public.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
})

chest_api.register_chest("morechests:ironchest_locked", {
	description = "Locked Ironside Chest",
	tiles = { "morechests_iron_locked.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
	protected = true,
})

minetest.register_alias("morechests:ironchest_public", "morechests:ironchest_public_closed")
minetest.register_alias("morechests:ironchest_locked", "morechests:ironchest_locked_closed")



chest_api.register_chest("morechests:goldchest_public", {
	description = "Unlocked Gold-Plated Chest",
	tiles = { "morechests_gold_public.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
})

chest_api.register_chest("morechests:goldchest_locked", {
	description = "Locked Gold-Plated Chest",
	tiles = { "morechests_gold_locked.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
	protected = true,
})

minetest.register_alias("morechests:goldchest_public", "morechests:goldchest_public_closed")
minetest.register_alias("morechests:goldchest_locked", "morechests:goldchest_locked_closed")



chest_api.register_chest("morechests:silverchest_public", {
	description = "Unlocked Silver Chest",
	tiles = { "morechests_silver_public.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
})

chest_api.register_chest("morechests:silverchest_locked", {
	description = "Locked Silver Chest\n\nCan be shared directly, without requiring use of a key.",
	tiles = { "morechests_silver_locked.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
	protected = true,
})

minetest.register_alias("morechests:silverchest_public", "morechests:silverchest_public_closed")
minetest.register_alias("morechests:silverchest_locked", "morechests:silverchest_locked_closed")



chest_api.register_chest("morechests:mithrilchest_public", {
	description = "Unlocked Mithril Chest",
	tiles = { "morechests_mithril_public.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
})

chest_api.register_chest("morechests:mithrilchest_locked", {
	description = "Locked Mithril Chest",
	tiles = { "morechests_mithril_locked.png" },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = utility.dig_groups("metalchest", {chest = 1}),
	protected = true,
})

minetest.register_alias("morechests:mithrilchest_public", "morechests:mithrilchest_public_closed")
minetest.register_alias("morechests:mithrilchest_locked", "morechests:mithrilchest_locked_closed")



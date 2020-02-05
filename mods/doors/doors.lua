
doors.register("door_wood", {
    tiles = {{ name = "doors_door_wood.png", backface_culling = true }},
    description = "Wooden Door",
    inventory_image = "doors_item_wood.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:stick"},
        {"group:wood_light", "group:wood_light"},
        {"group:wood_light", "group:wood_light"},
    }
})

minetest.register_craft({
  output = "doors:door_wood",
  recipe = {
    {"firetree:firewood", "group:stick"},
    {"firetree:firewood", "firetree:firewood"},
    {"firetree:firewood", "firetree:firewood"},
  },
})

minetest.register_craft({
  output = "doors:door_wood_locked",
  recipe = {
    {"firetree:firewood", "group:stick", ""},
    {"firetree:firewood", "firetree:firewood", "default:padlock"},
    {"firetree:firewood", "firetree:firewood", ""},
  },
})

doors.register("door_wood_locked", {
    tiles = {{ name = "doors_door_wood.png", backface_culling = true }},
    description = "Locked Wooden Door",
    inventory_image = "doors_item_wood.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:stick", ""},
        {"group:wood_light", "group:wood_light", "default:padlock"},
        {"group:wood_light", "group:wood_light", ""},
    }
})

doors.register("door_steel", {
    tiles = {{name = "doors_door_steel.png", backface_culling = true}},
    description = "Locked Iron Door",
    inventory_image = "doors_item_steel.png",
    protected = true,
    groups = utility.dig_groups("door_metal"),
    sounds = default.node_sound_metal_defaults(),
    sound_open = "doors_steel_door_open",
    sound_close = "doors_steel_door_close",
    recipe = {
        {"default:steel_ingot", "default:steel_ingot", ""},
        {"default:steel_ingot", "default:steel_ingot", "default:padlock"},
        {"default:steel_ingot", "default:steel_ingot", ""},
    }
})

doors.register("door_steel_unlocked", {
    tiles = {{name = "doors_door_steel.png", backface_culling = true}},
    description = "Iron Door",
    inventory_image = "doors_item_steel.png",
    groups = utility.dig_groups("door_metal"),
    sounds = default.node_sound_metal_defaults(),
    sound_open = "doors_steel_door_open",
    sound_close = "doors_steel_door_close",
    recipe = {
        {"default:steel_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot"},
    }
})

doors.register("door_iron", {
		tiles = {{name = "doors_door_iron.png", backface_culling = true}},
		description = "Wrought Iron Door",
		inventory_image = "doors_item_iron.png",
		groups = utility.dig_groups("door_metal"),
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_iron_door_open",
		sound_close = "doors_iron_door_close",
		recipe = {
			{"default:iron_lump", "default:iron_lump"},
			{"default:iron_lump", "default:iron_lump"},
			{"default:iron_lump", "default:iron_lump"},
		}
})

doors.register("door_iron_locked", {
		tiles = {{name = "doors_door_iron.png", backface_culling = true}},
		description = "Locked Wrought Iron Door",
		inventory_image = "doors_item_iron.png",
        protected = true,
		groups = utility.dig_groups("door_metal"),
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_iron_door_open",
		sound_close = "doors_iron_door_close",
		recipe = {
			{"default:iron_lump", "default:iron_lump", ""},
			{"default:iron_lump", "default:iron_lump", "default:padlock"},
			{"default:iron_lump", "default:iron_lump", ""},
		}
})

doors.register("door_glass", {
		tiles = {"doors_door_glass.png"},
		description = "Glass Door",
		inventory_image = "doors_item_glass.png",
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:glass", "default:glass"},
			{"default:glass", "default:glass"},
			{"default:glass", "default:glass"},
		}
})

doors.register("door_glass_locked", {
		tiles = {"doors_door_glass.png"},
		description = "Locked Glass Door",
		inventory_image = "doors_item_glass.png",
        protected = true,
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:glass", "default:glass", ""},
			{"default:glass", "default:glass", "default:padlock"},
			{"default:glass", "default:glass", ""},
		}
})

doors.register("door_obsidian_glass", {
		tiles = {"doors_door_obsidian_glass.png"},
		description = "Obsidian Glass Door",
		inventory_image = "doors_item_obsidian_glass.png",
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
		},
})

doors.register("door_obsidian_glass_locked", {
    tiles = {"doors_door_obsidian_glass.png"},
    description = "Locked Obsidian Glass Door",
    inventory_image = "doors_item_obsidian_glass.png",
    protected = true,
    groups = utility.dig_groups("door_glass"),
    sounds = default.node_sound_glass_defaults(),
    sound_open = "doors_glass_door_open",
    sound_close = "doors_glass_door_close",
    recipe = {
        {"default:obsidian_glass", "default:obsidian_glass", ""},
        {"default:obsidian_glass", "default:obsidian_glass", "default:padlock"},
        {"default:obsidian_glass", "default:obsidian_glass", ""},
    },
})

doors.register("door_wood_solid", {
    tiles = {"doors_door_woodsolid.png"},
    description = "Solid Wood Door",
    inventory_image = "doors_item_woodsolid.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:wood_light"},
        {"group:wood_light", "group:wood_light"},
        {"group:wood_light", "group:wood_light"},
    },
})

doors.register("door_wood_solid_locked", {
    tiles = {"doors_door_woodsolid.png"},
    description = "Locked Solid Wood Door",
    inventory_image = "doors_item_woodsolid.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:wood_light", ""},
        {"group:wood_light", "group:wood_light", "default:padlock"},
        {"group:wood_light", "group:wood_light", ""},
    },
})

doors.register("door_steel_glass", {
    tiles = {{name="doors_door_steelglass.png", backface_culling = true}},
    description = "Fancy Glass/Iron Door",
    inventory_image = "doors_item_steelglass.png",
    groups = utility.dig_groups("door_metal"),
    recipe = {
        {"default:steel_ingot", "default:glass"},
        {"default:glass", "default:steel_ingot"},
        {"default:steel_ingot", "default:glass"},
    },
})

doors.register("door_steel_glass_locked", {
    tiles = {{name="doors_door_steelglass.png", backface_culling = true}},
    description = "Locked Fancy Glass/Iron Door",
    inventory_image = "doors_item_steelglass.png",
    protected = true,
    groups = utility.dig_groups("door_metal"),
    recipe = {
        {"default:steel_ingot", "default:glass", ""},
        {"default:glass", "default:steel_ingot", "default:padlock"},
        {"default:steel_ingot", "default:glass", ""},
    },
})

doors.register("door_wood_glass", {
    tiles = {{name="doors_door_woodglass.png", backface_culling = true}},
    description = "Fancy Glass/Darkwood Door",
    inventory_image = "doors_item_woodglass.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass"},
        {"default:glass", "group:wood_dark"},
        {"group:wood_dark", "default:glass"},
    },
})

doors.register("door_wood_glass_locked", {
    tiles = {{name="doors_door_woodglass.png", backface_culling = true}},
    description = "Locked Fancy Glass/Darkwood Door",
    inventory_image = "doors_item_woodglass.png",
    protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass", ""},
        {"default:glass", "group:wood_dark", "default:padlock"},
        {"group:wood_dark", "default:glass", ""},
    },
})

doors.register("door_lightwood_glass", {
    tiles = {{name="doors_door_lightwoodglass.png", backface_culling = true}},
    description = "Fancy Glass/Wood Door",
    inventory_image = "doors_item_lightwoodglass.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass"},
        {"default:glass", "group:wood_light"},
        {"group:wood_light", "default:glass"},
    },
})

doors.register("door_lightwood_glass_locked", {
    tiles = {{name="doors_door_lightwoodglass.png", backface_culling = true}},
    description = "Locked Fancy Glass/Wood Door",
    inventory_image = "doors_item_lightwoodglass.png",
    protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass", ""},
        {"default:glass", "group:wood_light", "default:padlock"},
        {"group:wood_light", "default:glass", ""},
    },
})

doors.register("door_fancy_ext1", {
    tiles = {{name="doors_door_ext_fancy1.png", backface_culling = true}},
    description = "Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy1.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass"},
        {"group:wood_light", "default:glass"},
        {"group:wood_light", "group:wood_light"},
    },
})

doors.register("door_fancy_ext1_locked", {
    tiles = {{name="doors_door_ext_fancy1.png", backface_culling = true}},
    description = "Locked Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy1.png",
		protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass", ""},
        {"group:wood_light", "default:glass", "default:padlock"},
        {"group:wood_light", "group:wood_light", ""},
    },
})

doors.register("door_fancy_ext2", {
    tiles = {{name="doors_door_ext_fancy2.png", backface_culling = true}},
    description = "Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy2.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass"},
        {"group:wood_dark", "brass:ingot"},
        {"group:wood_dark", "group:wood_dark"},
    },
})

doors.register("door_fancy_ext2_locked", {
    tiles = {{name="doors_door_ext_fancy2.png", backface_culling = true}},
    description = "Locked Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy2.png",
		protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass", ""},
        {"group:wood_dark", "brass:ingot", "default:padlock"},
        {"group:wood_dark", "group:wood_dark", ""},
    },
})

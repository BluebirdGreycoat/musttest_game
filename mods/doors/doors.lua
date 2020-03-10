
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

-- Supplementary recipe for wood door.
minetest.register_craft({
  output = "doors:door_wood",
  recipe = {
    {"firetree:firewood", "group:stick"},
    {"firetree:firewood", "firetree:firewood"},
    {"firetree:firewood", "firetree:firewood"},
  },
})

-- Supplementary recipe for wood door.
minetest.register_craft({
  output = "doors:door_wood_locked",
  recipe = {
    {"firetree:firewood", "group:stick", ""},
    {"firetree:firewood", "firetree:firewood", "default:padlock"},
    {"firetree:firewood", "firetree:firewood", ""},
  },
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

doors.register("door_wood2", {
    tiles = {{ name = "doors_door_wood2.png", backface_culling = true }},
    description = "Wooden Door",
    inventory_image = "doors_item_wood2.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:tree_wood"},
        {"basictrees:tree_wood", "basictrees:tree_wood"},
        {"basictrees:tree_wood", "basictrees:tree_wood"},
    }
})

doors.register("door_wood2_locked", {
    tiles = {{ name = "doors_door_wood2.png", backface_culling = true }},
    description = "Locked Wooden Door",
    inventory_image = "doors_item_wood2.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:tree_wood", ""},
        {"basictrees:tree_wood", "basictrees:tree_wood", "default:padlock"},
        {"basictrees:tree_wood", "basictrees:tree_wood", ""},
    }
})

doors.register("door_obsidian_glass2", {
		tiles = {"doors_door_obsidian_glass2.png"},
		description = "Obsidian Glass Door",
		inventory_image = "doors_item_obsidian_glass2.png",
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:obsidian_shard", "default:obsidian_shard"},
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
		},
})

doors.register("door_obsidian_glass2_locked", {
    tiles = {"doors_door_obsidian_glass2.png"},
    description = "Locked Obsidian Glass Door",
    inventory_image = "doors_item_obsidian_glass2.png",
    protected = true,
    groups = utility.dig_groups("door_glass"),
    sounds = default.node_sound_glass_defaults(),
    sound_open = "doors_glass_door_open",
    sound_close = "doors_glass_door_close",
    recipe = {
        {"default:obsidian_shard", "default:obsidian_shard", ""},
        {"default:obsidian_glass", "default:obsidian_glass", "default:padlock"},
        {"default:obsidian_glass", "default:obsidian_glass", ""},
    },
})

doors.register("door_steel2", {
    tiles = {{name = "doors_door_steel2.png", backface_culling = true}},
    description = "Cast Iron Door",
    inventory_image = "doors_item_steel2.png",
    groups = utility.dig_groups("door_metal"),
    sounds = default.node_sound_metal_defaults(),
    sound_open = "doors_steel_door_open",
    sound_close = "doors_steel_door_close",
    recipe = {
        {"cast_iron:ingot", "cast_iron:ingot"},
        {"cast_iron:ingot", "cast_iron:ingot"},
        {"cast_iron:ingot", "cast_iron:ingot"},
    }
})

doors.register("door_steel2_locked", {
    tiles = {{name = "doors_door_steel2.png", backface_culling = true}},
    description = "Locked Cast Iron Door",
    inventory_image = "doors_item_steel2.png",
    protected = true,
    groups = utility.dig_groups("door_metal"),
    sounds = default.node_sound_metal_defaults(),
    sound_open = "doors_steel_door_open",
    sound_close = "doors_steel_door_close",
    recipe = {
        {"cast_iron:ingot", "cast_iron:ingot", ""},
        {"cast_iron:ingot", "cast_iron:ingot", "default:padlock"},
        {"cast_iron:ingot", "cast_iron:ingot", ""},
    }
})

doors.register("door_acacia", {
    tiles = {{ name = "doors_door_acacia.png", backface_culling = true }},
    description = "Acacia Door",
    inventory_image = "doors_item_acacia.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:acacia_wood"},
        {"basictrees:acacia_wood", "basictrees:acacia_wood"},
        {"basictrees:acacia_wood", "basictrees:acacia_wood"},
    }
})

doors.register("door_acacia_locked", {
    tiles = {{ name = "doors_door_acacia.png", backface_culling = true }},
    description = "Locked Acacia Door",
    inventory_image = "doors_item_acacia.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:acacia_wood", ""},
        {"basictrees:acacia_wood", "basictrees:acacia_wood", "default:padlock"},
        {"basictrees:acacia_wood", "basictrees:acacia_wood", ""},
    }
})

doors.register("door_pine", {
    tiles = {{ name = "doors_door_pine.png", backface_culling = true }},
    description = "Pine Door",
    inventory_image = "doors_item_pine.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:pine_wood"},
        {"basictrees:pine_wood", "basictrees:pine_wood"},
        {"basictrees:pine_wood", "basictrees:pine_wood"},
    }
})

doors.register("door_pine_locked", {
    tiles = {{ name = "doors_door_pine.png", backface_culling = true }},
    description = "Locked Pine Door",
    inventory_image = "doors_item_pine.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:pine_wood", ""},
        {"basictrees:pine_wood", "basictrees:pine_wood", "default:padlock"},
        {"basictrees:pine_wood", "basictrees:pine_wood", ""},
    }
})

doors.register("door_jungle", {
    tiles = {{ name = "doors_door_jungle.png", backface_culling = true }},
    description = "Jungle Wood Door",
    inventory_image = "doors_item_jungle.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:jungletree_wood"},
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood"},
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood"},
    }
})

doors.register("door_jungle_locked", {
    tiles = {{ name = "doors_door_jungle.png", backface_culling = true }},
    description = "Locked Jungle Wood Door",
    inventory_image = "doors_item_jungle.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:jungletree_wood", ""},
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood", "default:padlock"},
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood", ""},
    }
})

doors.register("door_aspen", {
    tiles = {{ name = "doors_door_aspen.png", backface_culling = true }},
    description = "Aspen Door",
    inventory_image = "doors_item_aspen.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:aspen_wood"},
        {"basictrees:aspen_wood", "basictrees:aspen_wood"},
        {"basictrees:aspen_wood", "basictrees:aspen_wood"},
    }
})

doors.register("door_aspen_locked", {
    tiles = {{ name = "doors_door_aspen.png", backface_culling = true }},
    description = "Locked Aspen Door",
    inventory_image = "doors_item_aspen.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "basictrees:aspen_wood", ""},
        {"basictrees:aspen_wood", "basictrees:aspen_wood", "default:padlock"},
        {"basictrees:aspen_wood", "basictrees:aspen_wood", ""},
    }
})

doors.register("door_woodsteel", {
    tiles = {{ name = "doors_door_woodsteel.png", backface_culling = true }},
    description = "Steel-Bound Door",
    inventory_image = "doors_item_woodsteel.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood"},
        {"default:steel_ingot", "default:steel_ingot"},
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood"},
    }
})

doors.register("door_woodsteel_locked", {
    tiles = {{ name = "doors_door_woodsteel.png", backface_culling = true }},
    description = "Locked Steel-Bound Door",
    inventory_image = "doors_item_woodsteel.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood", ""},
        {"default:steel_ingot", "default:steel_ingot", "default:padlock"},
        {"basictrees:jungletree_wood", "basictrees:jungletree_wood", ""},
    }
})

doors.register("door_wood3", {
    tiles = {{ name = "doors_door_wood3.png", backface_culling = true }},
    description = "Wooden Door",
    inventory_image = "doors_item_wood3.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "group:stick"},
        {"basictrees:tree_wood", "basictrees:tree_wood"},
        {"basictrees:tree_wood", "basictrees:tree_wood"},
    }
})

doors.register("door_wood3_locked", {
    tiles = {{ name = "doors_door_wood3.png", backface_culling = true }},
    description = "Locked Wooden Door",
    inventory_image = "doors_item_wood3.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:stick", "group:stick", ""},
        {"basictrees:tree_wood", "basictrees:tree_wood", "default:padlock"},
        {"basictrees:tree_wood", "basictrees:tree_wood", ""},
    }
})

-- No locked version. This is intentional,
-- you only use it for camouflage.
doors.register("door_desertstone", {
    tiles = {{ name = "doors_door_redstone.png", backface_culling = true }},
    description = "Desert Stone Door",
    inventory_image = "doors_item_redstone.png",
    groups = utility.dig_groups("door_stone"),
    recipe = {
        {"default:desert_stone", "default:desert_stone"},
        {"default:desert_stone", "default:desert_stone"},
        {"default:desert_stone", "default:desert_stone"},
    }
})


default.register_fence("default:fence_iron", {
	description = "Wrought Iron Fence",
	texture = "default_fence_iron.png",
	inventory_image = "default_fence_overlay.png^default_fence_iron.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_fence_iron.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal", {fence = 1}),
	sounds = default.node_sound_metal_defaults()
})

default.register_fence("default:fence_bronze", {
	description = "Bronze Fence",
	texture = "default_fence_bronze.png",
	inventory_image = "default_fence_overlay.png^default_fence_bronze.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_fence_bronze.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal", {fence = 1}),
	sounds = default.node_sound_metal_defaults()
})

default.register_fence("default:fence_wood", {
	description = "Wooden Fence",
	texture = "default_fence_wood.png",
	inventory_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults(),
})

default.register_fence("default:fence_acacia_wood", {
	description = "Acacia Wood Fence",
	texture = "default_fence_acacia_wood.png",
	inventory_image = "default_fence_overlay.png^default_acacia_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_acacia_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_junglewood", {
	description = "Jungle Wood Fence",
	texture = "default_fence_junglewood.png",
	inventory_image = "default_fence_overlay.png^default_junglewood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_junglewood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_pine_wood", {
	description = "Pine Wood Fence",
	texture = "default_fence_pine_wood.png",
	inventory_image = "default_fence_overlay.png^default_pine_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_pine_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("default:fence_aspen_wood", {
	description = "Aspen Wood Fence",
	texture = "default_fence_aspen_wood.png",
	inventory_image = "default_fence_overlay.png^default_aspen_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_aspen_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})



default.register_fence_rail("default:fence_rail_iron", {
	description = "Iron Fence Rail",
	texture = "default_fence_iron.png",
	inventory_image = "default_fence_rail_overlay.png^default_fence_iron.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_fence_iron.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal", {fence = 1}),
	sounds = default.node_sound_metal_defaults()
})

default.register_fence_rail("default:fence_rail_bronze", {
	description = "Bronze Fence Rail",
	texture = "default_fence_bronze.png",
	inventory_image = "default_fence_rail_overlay.png^default_fence_bronze.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_fence_bronze.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal", {fence = 1}),
	sounds = default.node_sound_metal_defaults()
})

default.register_fence_rail("default:fence_rail_wood", {
	description = "Wood Fence Rail",
	texture = "default_fence_rail_wood.png",
	inventory_image = "default_fence_rail_overlay.png^default_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence_rail("default:fence_rail_acacia_wood", {
	description = "Acacia Wood Fence Rail",
	texture = "default_fence_rail_acacia_wood.png",
	inventory_image = "default_fence_rail_overlay.png^default_acacia_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_acacia_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence_rail("default:fence_rail_junglewood", {
	description = "Jungle Wood Fence Rail",
	texture = "default_fence_rail_junglewood.png",
	inventory_image = "default_fence_rail_overlay.png^default_junglewood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_junglewood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence_rail("default:fence_rail_pine_wood", {
	description = "Pine Wood Fence Rail",
	texture = "default_fence_rail_pine_wood.png",
	inventory_image = "default_fence_rail_overlay.png^default_pine_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_pine_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

default.register_fence_rail("default:fence_rail_aspen_wood", {
	description = "Aspen Wood Fence Rail",
	texture = "default_fence_rail_aspen_wood.png",
	inventory_image = "default_fence_rail_overlay.png^default_aspen_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_rail_overlay.png^default_aspen_wood.png^" ..
				"default_fence_rail_overlay.png^[makealpha:255,126,126",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2, fence = 1}),
	sounds = default.node_sound_wood_defaults()
})

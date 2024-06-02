
--
-- Mese post registration helper
--

function default.register_mesepost(mod, variant, name, def)
  local nodename = mod .. ":" .. variant .. "_" .. name

  local ingot = ""
  if variant == "mese" then
    ingot = "default:mese_crystal"
  elseif variant == "talinite" then
    ingot = "talinite:ingot"
  end

	minetest.register_craft({
		output = nodename .. " 4",
		recipe = {
			{'', 'default:glass', ''},
			{ingot, ingot, ingot},
			{'', def.material, ''},
		}
	})

	local post_texture = def.texture .. "^default_" .. variant .. "_post_light_side.png^[makealpha:0,0,0"
	local post_texture_dark = def.texture .. "^default_" .. variant .. "_post_light_side_dark.png^[makealpha:0,0,0"
	-- Allow almost everything to be overridden
	local default_fields = {
		--wield_image = post_texture,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-2 / 16, -8 / 16, -2 / 16, 2 / 16, 8 / 16, 2 / 16},
			},
		},
		paramtype = "light",
		tiles = {def.texture, def.texture, post_texture_dark, post_texture_dark, post_texture, post_texture},
		use_texture_alpha = "opaque",
		light_source = default.LIGHT_MAX - 1,
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {},
		sounds = default.node_sound_wood_defaults(),
	}
	for k, v in pairs(default_fields) do
		if def[k] == nil then
			def[k] = v
		end
	end

	def.texture = nil
	def.material = nil

	minetest.register_node(nodename, def)
end



default.register_mesepost("mese_post", "mese", "post_iron", {
	description = "Iron Mese Post",
	texture = "default_fence_iron.png",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal"),
	sounds = default.node_sound_metal_defaults(),
})

default.register_mesepost("mese_post", "mese", "post_bronze", {
	description = "Bronze Mese Post",
	texture = "default_fence_bronze.png",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal"),
	sounds = default.node_sound_metal_defaults(),
})

default.register_mesepost("mese_post", "mese", "post_light", {
	description = "Wood Mese Post",
	texture = "default_fence_wood.png",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "mese", "post_acacia_wood", {
	description = "Acacia Wood Mese Post",
	texture = "default_fence_acacia_wood.png",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "mese", "post_junglewood", {
	description = "Jungle Wood Mese Post",
	texture = "default_fence_junglewood.png",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "mese", "post_pine_wood", {
	description = "Pine Wood Mese Post",
	texture = "default_fence_pine_wood.png",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "mese", "post_aspen_wood", {
	description = "Aspen Wood Mese Post",
	texture = "default_fence_aspen_wood.png",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})



default.register_mesepost("mese_post", "talinite", "post_iron", {
	description = "Iron Talinite Post",
	texture = "default_fence_iron.png",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal"),
	sounds = default.node_sound_metal_defaults(),
})

default.register_mesepost("mese_post", "talinite", "post_bronze", {
	description = "Bronze Talinite Post",
	texture = "default_fence_bronze.png",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal"),
	sounds = default.node_sound_metal_defaults(),
})

default.register_mesepost("mese_post", "talinite", "post_light", {
	description = "Wood Talinite Post",
	texture = "default_fence_wood.png",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "talinite", "post_acacia_wood", {
	description = "Acacia Wood Talinite Post",
	texture = "default_fence_acacia_wood.png",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "talinite", "post_junglewood", {
	description = "Jungle Wood Talinite Post",
	texture = "default_fence_junglewood.png",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "talinite", "post_pine_wood", {
	description = "Pine Wood Talinite Post",
	texture = "default_fence_pine_wood.png",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

default.register_mesepost("mese_post", "talinite", "post_aspen_wood", {
	description = "Aspen Wood Talinite Post",
	texture = "default_fence_aspen_wood.png",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

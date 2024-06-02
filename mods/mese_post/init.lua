
--
-- Mese post registration helper
--

function default.register_mesepost(name, def)
	minetest.register_craft({
		output = name .. " 4",
		recipe = {
			{'', 'default:glass', ''},
			{'default:mese_crystal', 'default:mese_crystal', 'default:mese_crystal'},
			{'', def.material, ''},
		}
	})

	local post_texture = def.texture .. "^default_mese_post_light_side.png^[makealpha:0,0,0"
	local post_texture_dark = def.texture .. "^default_mese_post_light_side_dark.png^[makealpha:0,0,0"
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
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
		sounds = default.node_sound_wood_defaults(),
	}
	for k, v in pairs(default_fields) do
		if def[k] == nil then
			def[k] = v
		end
	end

	def.texture = nil
	def.material = nil

	minetest.register_node(name, def)
end



default.register_mesepost("mese_post:mese_post_iron", {
	description = "Iron Mese Post",
	texture = "default_fence_iron.png",
	material = "default:steel_ingot",
})

default.register_mesepost("mese_post:mese_post_bronze", {
	description = "Bronze Mese Post",
	texture = "default_fence_bronze.png",
	material = "default:bronze_ingot",
})

default.register_mesepost("mese_post:mese_post_light", {
	description = "Wood Mese Post",
	texture = "default_fence_wood.png",
	material = "default:wood",
})

default.register_mesepost("mese_post:mese_post_acacia_wood", {
	description = "Acacia Wood Mese Post",
	texture = "default_fence_acacia_wood.png",
	material = "default:acacia_wood",
})

default.register_mesepost("mese_post:mese_post_junglewood", {
	description = "Jungle Wood Mese Post",
	texture = "default_fence_junglewood.png",
	material = "default:junglewood",
})

default.register_mesepost("mese_post:mese_post_pine_wood", {
	description = "Pine Wood Mese Post",
	texture = "default_fence_pine_wood.png",
	material = "default:pine_wood",
})

default.register_mesepost("mese_post:mese_post_aspen_wood", {
	description = "Aspen Wood Mese Post",
	texture = "default_fence_aspen_wood.png",
	material = "default:aspen_wood",
})

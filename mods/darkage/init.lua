
-- Mod is to be reloadable.
if not minetest.global_exists("darkage") then darkage = {} end
darkage.modpath = minetest.get_modpath("darkage")

-- Functions.
dofile(darkage.modpath .. "/functions.lua")



if not darkage.run_once then
	-- Craftitems.
	minetest.register_craftitem("darkage:chalk_powder", {
		description = "Chalk Powder",
		inventory_image = "darkage_chalk_powder.png",
	})

	minetest.register_craftitem("darkage:mud_lump", {
		description = "Mud Lump",
		inventory_image = "darkage_mud_lump.png",
	})

	minetest.register_craftitem("darkage:silt_lump", {
		description = "Silt Lump",
		inventory_image = "darkage_silt_lump.png",
	})

	minetest.register_craftitem("darkage:iron_stick", {
		description = "Wrought Iron Rod\n\nCan be used to test protection.\nAlso updates infotext names.",
		inventory_image = "darkage_iron_stick.png",
		on_use = default.strike_protection,
	})

	-- Nodes.
	minetest.register_node("darkage:straw_bale", {
		description = "Straw Bale",
		tiles = {"darkage_straw_bale.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("straw", {flammable=4, falling_node=1}),
		sounds = default.node_sound_leaves_defaults(),
	})

	minetest.register_node("darkage:glass", {
		description = "Clean Medieval Glass",
		drawtype = "glasslike",
		tiles = {"darkage_glass.png"},
		use_texture_alpha = true,
		paramtype = "light",
		sunlight_propagates = true,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_glass_defaults(),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:milk_glass", {
		description = "Milky Medieval Glass",
		drawtype = "glasslike",
		tiles = {"darkage_milk_glass.png"},
		use_texture_alpha = true,
		paramtype = "light",
		sunlight_propagates = true,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_glass_defaults(),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:glow_glass", {
		description = "Medieval Glow Glass",
		drawtype = "glasslike",
		tiles = {"darkage_glass.png"},
		use_texture_alpha = true,
		paramtype = "light",
		sunlight_propagates = true,
		light_source = 12,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_glass_defaults(),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
				{
					items = {"xdecor:lantern"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:glass_round", {
		description = "Round Glass",
		drawtype = "glasslike",
		tiles = {"darkage_glass_round.png"},
		paramtype = "light",
		use_texture_alpha = true,
		sunlight_propagates = true,
		sounds = default.node_sound_glass_defaults(),
		groups = utility.dig_groups("glass"),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:milk_glass_round", {
		description = "Milky Medieval Round Glass",
		drawtype = "glasslike",
		tiles = {"darkage_milk_glass_round.png"},
		use_texture_alpha = true,
		paramtype = "light",
		sunlight_propagates = true,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_glass_defaults(),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:glass_square", {
		description = "Square Glass",
		drawtype = "glasslike",
		tiles = {"darkage_glass_square.png"},
		paramtype = "light",
		use_texture_alpha = true,
		sunlight_propagates = true,
		sounds = default.node_sound_glass_defaults(),
		groups = utility.dig_groups("glass"),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:milk_glass_square", {
		description = "Milky Medieval Square Glass",
		drawtype = "glasslike",
		tiles = {"darkage_milk_glass_square.png"},
		use_texture_alpha = true,
		paramtype = "light",
		sunlight_propagates = true,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_glass_defaults(),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments"},
					rarity = 1,
				},
				{
					items = {"default:steel_ingot"},
					rarity = 3,
				},
			}
		},
	})

	minetest.register_node("darkage:lamp", {
		description = "Lamp Lattice",
		tiles = {"darkage_lamp.png"},
		paramtype = "light",
		light_source = default.LIGHT_MAX - 2,
		groups = utility.dig_groups("bigitem", {flammable=1}),
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node("darkage:wood_frame", {
		description = "Wood Framed Glass",
		drawtype = "glasslike_framed",
		tiles = {"darkage_wood_frame.png"},
		is_ground_content = false,
		paramtype = "light",
		sunlight_propagates = true,
		groups = utility.dig_groups("glass"),
		sounds = default.node_sound_stone_defaults(),
		silverpick_drop = true,

		drop = {
			max_items = 2,
			items = {
				{
					items = {"vessels:glass_fragments", "default:stick"},
					rarity = 1,
				},
			}
		},
	})

	minetest.register_node("darkage:stone_brick", {
		description = "Stone Masonry",
		tiles = {"darkage_stone_brick.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:chalk", {
		description = "Chalk",
		tiles = {"darkage_chalk.png"},
		drop = 'darkage:chalk_powder 4',
		groups = utility.dig_groups("clay", {falling_node=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:chalked_bricks", {
		description = "Chalked Brick",
		tiles = {"darkage_chalked_bricks.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults(),
	})

	minetest.register_node("darkage:adobe", {
		description = "Adobe",
		tiles = {"darkage_adobe.png"},
		groups = utility.dig_groups("hardclay"),
		sounds = default.node_sound_sand_defaults(),
	})

	minetest.register_node("darkage:cobble_with_plaster", {
		description = "Cobblestone With Plaster",
		tiles = {
			"darkage_chalk.png^(default_cobble.png^[mask:darkage_plaster_mask_D.png)",
			"darkage_chalk.png^(default_cobble.png^[mask:darkage_plaster_mask_B.png)", 
			"darkage_chalk.png^(default_cobble.png^[mask:darkage_plaster_mask_C.png)",
			"darkage_chalk.png^(default_cobble.png^[mask:darkage_plaster_mask_A.png)", 
			"default_cobble.png",
			"darkage_chalk.png",
		},
		paramtype2 = "facedir",
		drop = 'default:cobble',
		groups = utility.dig_groups("cobble"),
		sounds = default.node_sound_stone_defaults(),
	})

	minetest.register_node("darkage:chalked_bricks_with_plaster", {
		description = "Chalked Bricks With Plaster",
		tiles = {
			"darkage_chalk.png^(darkage_chalked_bricks.png^[mask:darkage_plaster_mask_D.png)",
			"darkage_chalk.png^(darkage_chalked_bricks.png^[mask:darkage_plaster_mask_B.png)",
			"darkage_chalk.png^(darkage_chalked_bricks.png^[mask:darkage_plaster_mask_C.png)",
			"darkage_chalk.png^(darkage_chalked_bricks.png^[mask:darkage_plaster_mask_A.png)", 
			"darkage_chalked_bricks.png", 
			"darkage_chalk.png",
		},
		paramtype2 = "facedir",
		drop = 'default:cobble',
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults(),
	})

	-- Sterile dirt does not grow plants. This soil is useless for farming.
	minetest.register_node("darkage:darkdirt", {
		description = "Coarse Sterile Dirt",
		tiles = {"darkage_darkdirt.png"},
		groups = utility.dig_groups("dirt", {dirt_type = 1, sterile_dirt_type = 1, raw_dirt_type = 1, falling_node = 1}),
		sounds = default.node_sound_dirt_defaults(),
	})

	minetest.register_node("darkage:mud", {
		description = "Mud",
		tiles = {"darkage_mud_up.png", "darkage_mud.png"},
		groups = utility.dig_groups("mud", {falling_node=1}),
		drop = 'darkage:mud_lump 4',
		sounds = default.node_sound_dirt_defaults(),
	})

	minetest.register_node("darkage:silt", {
		description = "Silt",
		tiles = {"darkage_silt.png"},
		groups = utility.dig_groups("mud", {falling_node=1}),
		drop = 'darkage:silt_lump 4',
		sounds = default.node_sound_dirt_defaults(),
	})

	minetest.register_node("darkage:schist", {
		description = "Schist",
		tiles = {"darkage_schist.png"},
		groups = utility.dig_groups("softstone"),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:gneiss", {
		description = "Gneiss",
		tiles = {"darkage_gneiss.png"},
		groups = utility.dig_groups("softstone", {stone=1}),
		drop = "darkage:gneiss_rubble",
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:gneiss_rubble", {
		description = "Gneiss Rubble",
		tiles = {"darkage_gneiss_rubble.png"},
		groups = utility.dig_groups("cobble", {stone=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:gneiss_brick", {
		description = "Gneiss Brick",
		tiles = {"darkage_gneiss_brick.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {stone=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:gneiss_block", {
		description = "Gneiss Block",
		tiles = {"darkage_gneiss_block.png"},
		groups = utility.dig_groups("block", {stone=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:marble", {
		description = "White Serpentine",
		tiles = {"darkage_marble.png"},
		groups = utility.dig_groups("hardstone", {stone=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:marble_tile", {
		description = "White Serpentine Tile",
		tiles = {"darkage_marble_tile.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("stone", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:slate", {
		description = "Slate",
		tiles = {"darkage_slate.png", "darkage_slate.png", "darkage_slate_side.png"},
		drop = 'darkage:slate_rubble',
		groups = utility.dig_groups("softstone"),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:slate_rubble", {
		description = "Slate Rubble",
		tiles = {"darkage_slate_rubble.png"},
		groups = utility.dig_groups("softcobble"),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:slate_tile", {
		description = "Slate Tile",
		tiles = {"darkage_slate_tile.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("cobble"),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:slate_block", {
		description = "Slate Block",
		tiles = {"darkage_slate_block.png"},
		groups = utility.dig_groups("block", {block=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:slate_brick", {
		description = "Slate Brick",
		tiles = {"darkage_slate_brick.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:shale", {
		description = "Shale",
		tiles = {"darkage_shale.png", "darkage_shale.png", "darkage_shale_side.png"},
		groups = utility.dig_groups("softstone"),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:ors", {
		description = "Old Red Sandstone",
		tiles = {"darkage_ors.png"},
		drop = "darkage:ors_rubble",
		groups = utility.dig_groups("stone"),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:ors_rubble", {
		description = "Old Red Sandstone Rubble",
		tiles = {"darkage_ors_rubble.png"},
		groups = utility.dig_groups("softcobble", {stone = 1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:ors_brick", {
		description = "Old Red Sandstone Brick",
		tiles = {"darkage_ors_brick.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:ors_block", {
		description = "Old Red Sandstone Block",
		tiles = {"darkage_ors_block.png"},
		groups = utility.dig_groups("block", {stone = 2}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:tuff", {
		description = "Tuff",
		tiles = {"darkage_tuff.png"},
		groups = utility.dig_groups("cobble", {stone = 1}),
		drop = 'darkage:tuff_rubble',
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:tuff_bricks", {
		description = "Tuff Bricks",
		tiles = {"darkage_tuff_bricks.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:tuff_rubble", {
		description = "Tuff Rubble",
		tiles = {"darkage_tuff_rubble.png"},
		groups = utility.dig_groups("cobble", {falling_node = 1}),
		sounds = default.node_sound_gravel_defaults(),
	})

	minetest.register_node("darkage:old_tuff_bricks", {
		description = "Old Tuff Bricks",
		tiles = {"darkage_old_tuff_bricks.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:rhyolitic_tuff", {
		description = "Rhyolitic Tuff",
		tiles = {"darkage_rhyolitic_tuff.png"},
		groups = utility.dig_groups("cobble", {stone = 1}),
		drop = 'darkage:rhyolitic_tuff_rubble',
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:rhyolitic_tuff_rubble", {
		description = "Rhyolitic Tuff Rubble",
		tiles = {"darkage_rhyolitic_tuff_rubble.png"},
		groups = utility.dig_groups("softcobble", {falling_node = 1}),
		sounds = default.node_sound_gravel_defaults(),
	})

	minetest.register_node("darkage:rhyolitic_tuff_bricks", {
		description = "Rhyolitic Tuff Bricks",
		tiles = {"darkage_rhyolitic_tuff_bricks.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:basaltic", {
		description = "Dark Basaltic Rock",
		tiles = {"darkage_basalt.png"},
		drop = "darkage:basaltic_rubble",
		groups = utility.dig_groups("hardstone", {stone = 1}),
		sounds = default.node_sound_stone_defaults(),
		movement_speed_multiplier = default.ROAD_SPEED,
	})

	minetest.register_node("darkage:basaltic_rubble", {
		description = "Dark Basaltic Rubble",
		tiles = {"darkage_basalt_rubble.png"},
		groups = utility.dig_groups("cobble", {stone = 1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:basaltic_brick", {
		description = "Dark Basaltic Brick",
		tiles = {"darkage_basalt_brick.png"},
		paramtype2 = "facedir",
		groups = utility.dig_groups("brick", {brick=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:basaltic_block", {
		description = "Dark Basaltic Block",
		tiles = {"darkage_basalt_block.png"},
		groups = utility.dig_groups("block", {block=1}),
		sounds = default.node_sound_stone_defaults()
	})

	minetest.register_node("darkage:box", {
		description = "Wooden Box",
		tiles = {
			"darkage_box_top.png",
			"darkage_box_top.png",
			"darkage_box.png",
		},
		groups = utility.dig_groups("furniture"),
		sounds = default.node_sound_wood_defaults(),

		on_rightclick = function(...)
			return darkage.on_rightclick(...)
		end,

		on_construct = function(...)
			return darkage.on_construct(...)
		end,

		after_place_node = function(...)
			return darkage.after_place_node(...)
		end,

		can_dig = function(...)
			return darkage.can_dig(...)
		end,

		allow_metadata_inventory_move = function(...)
			return darkage.allow_metadata_inventory_move(...)
		end,

		allow_metadata_inventory_put = function(...)
			return darkage.allow_metadata_inventory_put(...)
		end,

		allow_metadata_inventory_take = function(...)
			return darkage.allow_metadata_inventory_take(...)
		end,

		on_metadata_inventory_move = function(...)
			return darkage.on_metadata_inventory_move(...)
		end,

		on_metadata_inventory_put = function(...)
			return darkage.on_metadata_inventory_put(...)
		end,

		on_metadata_inventory_take = function(...)
			return darkage.on_metadata_inventory_take(...)
		end,

		on_blast = function(...)
			return darkage.on_blast(...)
		end,
	})

	minetest.register_node("darkage:wood_shelves", {
		description = "Wooden Shelf",
		tiles = {
			"darkage_shelves.png",
			"darkage_shelves.png",
			"darkage_shelves.png",
			"darkage_shelves.png",
			"darkage_shelves.png",
			"darkage_shelves_front.png",
		},
		paramtype2 = "facedir",
		groups = utility.dig_groups("furniture"),
		sounds = default.node_sound_wood_defaults(),

		on_rightclick = function(...)
			return darkage.on_rightclick(...)
		end,

		on_construct = function(...)
			return darkage.on_construct(...)
		end,

		after_place_node = function(...)
			return darkage.after_place_node(...)
		end,

		can_dig = function(...)
			return darkage.can_dig(...)
		end,

		allow_metadata_inventory_move = function(...)
			return darkage.allow_metadata_inventory_move(...)
		end,

		allow_metadata_inventory_put = function(...)
			return darkage.allow_metadata_inventory_put(...)
		end,

		allow_metadata_inventory_take = function(...)
			return darkage.allow_metadata_inventory_take(...)
		end,

		on_metadata_inventory_move = function(...)
			return darkage.on_metadata_inventory_move(...)
		end,

		on_metadata_inventory_put = function(...)
			return darkage.on_metadata_inventory_put(...)
		end,

		on_metadata_inventory_take = function(...)
			return darkage.on_metadata_inventory_take(...)
		end,

		on_blast = function(...)
			return darkage.on_blast(...)
		end,
	})

	minetest.register_on_player_receive_fields(function(...)
		return darkage.on_player_receive_fields(...)
	end)

	-- Register mod as reloadable.
	local c = "darkage:core"
	local f = darkage.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	darkage.run_once = true
end


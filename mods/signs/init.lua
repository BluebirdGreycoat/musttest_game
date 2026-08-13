
if not minetest.global_exists("signs") then signs = {} end
signs.modpath = minetest.get_modpath("signs")
signs.player_contexts = signs.player_contexts or {}
reload.install_simple_signals(signs)

dofile(signs.modpath .. "/functions.lua")
dofile(signs.modpath .. "/log.lua")

if not signs.run_once then
	local function register_sign(material, desc, def)
		minetest.register_node("signs:sign_wall_" .. material, {
			description = desc,
			drawtype = "nodebox",
			tiles = {"default_sign_wall_" .. material .. ".png"},
			inventory_image = "default_sign_" .. material .. ".png",
			wield_image = "default_sign_" .. material .. ".png",
			paramtype = "light",
			paramtype2 = "wallmounted",
			sunlight_propagates = true,
			is_ground_content = false,
			walkable = false,
			floodable = true,
			node_box = {
				type = "wallmounted",
				wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
				wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
				wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
			},
			groups = def.groups,
			legacy_wallmounted = true,
			sounds = def.sounds,

			on_construct = function(...)
				return signs.on_construct(...)
			end,

			on_rightclick = function(...)
				return signs.on_rightclick(...)
			end,

			on_punch = function(...)
				return signs.on_punch(...)
			end,
		})
	end

	register_sign("wood", "Wooden Sign", {
		sounds = default.node_sound_wood_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1, flammable = 2})
	})

	register_sign("steel", "Iron Plate", {
		sounds = default.node_sound_metal_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	register_sign("tin", "Tin Plate", {
		sounds = default.node_sound_metal_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	register_sign("brass", "Brass Plaque", {
		sounds = default.node_sound_metal_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	register_sign("bronze", "Bronze Plaque", {
		sounds = default.node_sound_metal_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	register_sign("stone", "Rune Slab", {
		sounds = default.node_sound_stone_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	minetest.register_craft({
		output = 'signs:sign_wall_steel 3',
		recipe = {
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_tin 3',
		recipe = {
			{'moreores:tin_ingot', 'moreores:tin_ingot', 'moreores:tin_ingot'},
			{'moreores:tin_ingot', 'moreores:tin_ingot', 'moreores:tin_ingot'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_wood 3',
		recipe = {
			{'group:wood', 'group:wood', 'group:wood'},
			{'group:wood', 'group:wood', 'group:wood'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_brass 3',
		recipe = {
			{'brass:ingot', 'brass:ingot', 'brass:ingot'},
			{'brass:ingot', 'brass:ingot', 'brass:ingot'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_bronze 3',
		recipe = {
			{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
			{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_stone',
		recipe = {
			{'default:stone', 'default:stone', 'default:stone'},
			{'default:stone', 'default:stone', 'default:stone'},
			{'', 'engraver:chisel', ''},
		}
	})

	minetest.register_alias("default:sign_wall_wood", "signs:sign_wall_wood")
	minetest.register_alias("default:sign_wall_steel", "signs:sign_wall_steel")

	minetest.register_on_player_receive_fields(function(...)
		return signs.on_player_receive_fields(...) end)

	local c = "signs:core"
	local f = signs.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	signs.run_once = true
end



-- Mod global namespace

map = map or {}
map.modpath = minetest.get_modpath("map")



-- Update HUD flags
-- Global to allow overriding

function map.update_hud_flags(player)
	local has_kit = player:get_inventory():contains_item("main", "map:mapping_kit")

	local minimap_enabled = has_kit
  local radar_enabled = false

	-- TODO: Provide way for player to enable radar (ability to disable radar comes after 0.5.0).
	-- Could be something like a radio device, maybe.

	player:hud_set_flags({
		minimap = minimap_enabled,
		minimap_radar = radar_enabled,
	})
end



function map.cyclic_update()
	local players = minetest.get_connected_players()
	for _, player in ipairs(players) do
		map.update_hud_flags(player)
	end
	minetest.after(5.3, function() map.cyclic_update() end)
end



function map.on_use(itemstack, user, pointed_thing)
	map.update_hud_flags(user)
end



-- Set HUD flags 'on joinplayer'
if not map.run_once then
	minetest.register_on_joinplayer(function(player)
		map.update_hud_flags(player)
	end)


	-- Cyclic update of HUD flags.
	minetest.after(5.3, function() map.cyclic_update() end)


	-- Mapping kit item.
	minetest.register_node("map:mapping_kit", {
		tiles = {"map_mapping_kit_tile.png"},
		wield_image = "map_mapping_kit.png",
		description = "Mapping Kit\n\nAllows viewing a map of your surroundings.\nUse with 'Minimap' key.",
		inventory_image = "map_mapping_kit.png",
		paramtype = 'light',
		paramtype2 = "wallmounted",
		drawtype = "nodebox",
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "wallmounted",
			wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
			wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
			wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
		},
		selection_box = {type = "wallmounted"},
		stack_max = 1,
		groups = {level = 1, dig_immediate = 2, flammable = 3, attached_node = 1},
		sounds = default.node_sound_leaves_defaults(),

		on_use = function(...)
			return map.on_use(...)
		end,
	})


	-- Crafting.

	minetest.register_craft({
		output = "map:mapping_kit",
		recipe = {
			{"default:glass", "default:paper", "default:stick"},
			{"default:steel_ingot", "default:paper", "default:steel_ingot"},
			{"group:wood", "default:paper", "dye:black"},
		}
	})


	-- Fuel.

	minetest.register_craft({
		type = "fuel",
		recipe = "map:mapping_kit",
		burntime = 5,
	})

	local c = "map:core"
	local f = map.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	map.run_once = true
end


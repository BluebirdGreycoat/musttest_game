-- Mod global namespace

map = map or {}
map.modpath = minetest.get_modpath("map")



function map.on_player_inventory_action(player, action, inventory, info)
	minetest.chat_send_player("MustTest", "# Server: Inventory action! " .. action)
end



-- Update HUD flags
-- Global to allow overriding

-- May be called with player object or player name.
-- Return 'true' if the minimap is ENABLED.
function map.update_hud_flags(player)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	if not player or not player:is_player() then
		return
	end

	local has_kit = map.has_mapping_kit(player)

	local minimap_enabled = has_kit
  local radar_enabled = false

	-- Map & radar combined into same device.
	player:hud_set_flags({
		minimap = minimap_enabled,
		minimap_radar = minimap_enabled,
	})

	if minimap_enabled then
		return true
	end
end

-- May be called with either a player object or a player name.
function map.has_mapping_kit(pname_or_pref)
	local player = pname_or_pref
	if type(pname_or_pref) == "string" then
		player = minetest.get_player_by_name(pname_or_pref)
	end
	if not player or not player:is_player() then
		return
	end
	if player:get_wielded_item():get_name() == "map:mapping_kit" then
		return true
	end
	return false
end

-- Use from /lua command, mainly.
function map.query(pname)
	if map.has_mapping_kit(pname) then
		minetest.chat_send_player("MustTest", "# Server: Player <" .. rename.gpn(pname) .. "> has a mapping kit!")
	else
		minetest.chat_send_player("MustTest", "# Server: Player <" .. rename.gpn(pname) .. "> does not have a mapping kit.")
	end
end



function map.update_player(pname)
	if map.update_hud_flags(pname) then
		minetest.after(1, function() map.update_player(pname) end)
	end
end

function map.on_use(itemstack, user, pointed_thing)
	map.update_player(user:get_player_name())
end



-- Set HUD flags 'on joinplayer'
if not map.run_once then
	-- Mapping kit item.
	minetest.register_node("map:mapping_kit", {
		tiles = {"map_mapping_kit_tile.png"},
		wield_image = "map_mapping_kit.png",
		description = "Mapping Kit\n\nAllows viewing a map of your surroundings.\nUse (punch) and press the 'minimap' key.\nMust be wielded to continue using.",
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
		groups = utility.dig_groups("bigitem", {flammable = 3, attached_node = 1}),
		sounds = default.node_sound_leaves_defaults(),

		on_use = function(...)
			return map.on_use(...)
		end,
	})


	-- Crafting.

	minetest.register_craft({
		output = "map:mapping_kit",
		recipe = {
			{"default:glass", "default:paper", "group:stick"},
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


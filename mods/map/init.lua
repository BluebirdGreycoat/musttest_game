-- Mod global namespace

map = map or {}
map.modpath = minetest.get_modpath("map")
map.players = map.players or {}



-- Shall be called shortly after player joins game, to create the initial cache.
-- Shall also be called whenever inventory is modified in such a way that a mapping kit is moved/added/removed.
-- The cache shall be cleared whenever the player dies.
-- Shall also be called whenever the player modifies their inventory in a way that a mapping kit is changed.
function map.update_inventory_info(pname)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then
		return
	end

	if not map.players[pname] then
		map.players[pname] = {has_kit = false, indices={}}
	end

	local inv = player:get_inventory()
	if not inv then
		return
	end

	-- Reset list ID indices array.
	map.players[pname].indices = {}

	if inv:contains_item("main", "map:mapping_kit") then
		local list = inv:get_list("main")
		for k, v in ipairs(list) do
			if not v:is_empty() then
				if v:get_name() == "map:mapping_kit" then
					table.insert(map.players[pname].indices, k)
				end
			end
		end
	end

	if #(map.players[pname].indices) > 0 then
		-- At least one inventory slot has a mapping kit.
		-- Need to check if there's one in the hotbar.
		local has_kit = false
		local barmax = 8
		if minetest.check_player_privs(pname, "big_hotbar") then
			barmax = 16
		end
		for k, v in ipairs(map.players[pname].indices) do
			if v >= 1 and v <= barmax then
				has_kit = true
				break
			end
		end
		map.players[pname].has_kit = has_kit
	else
		map.players[pname].has_kit = false
	end

	-- Finally, update the HUD flags on the client.
	map.update_hud_flags(player)
end



-- Called from bones code, mainly.
function map.clear_inventory_info(pname)
	map.players[pname] = {has_kit = false, indices={}}
end



-- Not called when player digs or places node, or if player picks up a dropped item.
-- Is called when an item is dropped/taken from ground, or is moved/taken from chest, etc.
-- Specifically, NOT called when inventory is modified by a process the player did not initiate.
function map.on_player_inventory_action(player, action, inventory, info)
	---[[
	if action == "take" or action == "put" then
		minetest.chat_send_player("MustTest",
			"# Server: " .. action .. " in " .. info.index .. ", " .. info.stack:get_name() .. " " .. info.stack:get_count())
	end
	--]]

	if action == "put" or action == "take" then
		local name = info.stack:get_name()
		if name == "map:mapping_kit" then
			local pname = player:get_player_name()
			map.update_inventory_info(pname)
		end
	elseif action == "move" then
		local pname = player:get_player_name()
		if not map.players[pname] then
			map.update_inventory_info(pname)
		end
		if info.from_list == "main" or info.to_list == "main" then
			local from = info.from_index
			local to = info.to_index
			-- If the moved from/to slot was listed as holding a mapping kit, need to refresh the cache.
			for k, v in ipairs(map.players[pname].indices) do
				if from == v or to == v then
					map.update_inventory_info(pname)
					break
				end
			end
		end
	end
end



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
	local pname = pname_or_pref
	if type(pname) ~= "string" then
		pname = pname_or_pref:get_player_name()
	end
	-- If data doesn't exist yet, create the cache.
	if not map.players[pname] then
		map.update_inventory_info(pname)
	end
	return map.players[pname].has_kit
end



-- Use from /lua command, mainly.
function map.query(pname)
	if map.has_mapping_kit(pname) then
		minetest.chat_send_player("MustTest", "# Server: Player <" .. rename.gpn(pname) .. "> has a mapping kit!")
	else
		minetest.chat_send_player("MustTest", "# Server: Player <" .. rename.gpn(pname) .. "> does not have a mapping kit.")
	end
end



function map.on_use(itemstack, user, pointed_thing)
	map.update_inventory_info(user:get_player_name())
end



function map.on_joinplayer(player)
	local pname = player:get_player_name()
	minetest.after(3, function()
		map.update_inventory_info(pname)
	end)
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



	minetest.register_on_player_inventory_action(function(...)
		return map.on_player_inventory_action(...) end)

	minetest.register_on_joinplayer(function(...)
		return map.on_joinplayer(...) end)

	local c = "map:core"
	local f = map.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	map.run_once = true
end


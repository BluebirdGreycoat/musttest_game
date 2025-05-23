-- Mod global namespace

if not minetest.global_exists("map") then map = {} end
map.modpath = minetest.get_modpath("map")
map.players = map.players or {}
map.time_step = 10
map.charge_time = 60*60 -- 1 hour of continuous use.

-- Localize for performance.
local math_floor = math.floor



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

	if inv:contains_item("main", "map:mapping_kit") or inv:contains_item("main", "map:mapping_tool") then
		local list = inv:get_list("main")
		for k, v in ipairs(list) do
			if not v:is_empty() then
				if map.is_mapping_kit(v:get_name()) then
					local wear = v:get_wear()
					-- If wear is 0, the tool is not charged, and has never been charged.
					-- Ignore discharged mapping kits/tools.
					if wear > 0 and wear < 65534 then
						table.insert(map.players[pname].indices, k)
					elseif wear == 0 and v:get_name() == "map:mapping_kit" then
						-- Treat mapping kit as if it is a tool with full charge.
						-- The item will be upgraded by the function that actually handles charge draining.
						table.insert(map.players[pname].indices, k)
					end
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
	map.update_hud_flags(pname)
end




function map.consume_charge()
	for name, data in pairs(map.players) do
		if data.has_kit and #data.indices > 0 then
			local player = minetest.get_player_by_name(name)
			if player and player:is_player() then
				local inv = player:get_inventory()
				if inv then
					local idx = inv:get_size("main") + 1
					-- Find first mapping kit.
					for _, index in ipairs(data.indices) do
						if index < idx then
							idx = index
						end
					end
					if idx ~= 0 then
						local stack = inv:get_stack("main", idx)
						local sn = stack:get_name()
						if map.is_mapping_kit(sn) then
							local depleted = false

							-- Convert nodes to tools.
							if sn == "map:mapping_kit" then
								stack = ItemStack("map:mapping_tool")
								stack:set_wear(1) -- Give full charge.
							end

							-- Use up charge.
							-- Note: we assume the tool has charge, if not, it should not have been in the cache!
							local wear = stack:get_wear()
							local increment = (65535 / map.charge_time)
							wear = wear + (increment * map.time_step)
							-- Don't let wear reach max or tool will be destroyed.
							if wear >= 65534 then
								wear = 65534
								depleted = true
							end
							stack:set_wear(math_floor(wear))
							inv:set_stack("main", idx, stack)

							-- If this mapping tool has no charge left, update the cache info.
							if depleted then
								map.update_inventory_info(name)
							end
						end
					end
				end
			end
		end
	end

	-- Call recursively.
	minetest.after(map.time_step, function() map.consume_charge() end)
end



-- Not called when player digs or places node, or if player picks up a dropped item.
-- Is called when an item is dropped/taken from ground, or is moved/taken from chest, etc.
-- Specifically, NOT called when inventory is modified by a process the player did not initiate.
function map.on_player_inventory_action(player, action, inventory, info)
	if action == "put" or action == "take" then
		local name = info.stack:get_name()
		if map.is_mapping_kit(name) then
			local pname = player:get_player_name()
			map.update_inventory_info(pname)
		end
	elseif action == "move" then
		local pname = player:get_player_name()
		if not map.players[pname] then
			map.update_inventory_info(pname)
		end
		if info.from_list == "main" then
			local from = info.from_index
			-- If the moved from slot was listed as holding a mapping kit, need to refresh the cache.
			for k, v in ipairs(map.players[pname].indices) do
				if from == v then
					map.update_inventory_info(pname)
					break
				end
			end
		end
		if info.to_list == "main" then
			-- This is only called when player moves from player-inv to another player-inv.
			-- We have to check what item was added.
			local stack = inventory:get_stack("main", info.to_index)
			if map.is_mapping_kit(stack:get_name()) then
				map.update_inventory_info(pname)
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



function map.on_use(itemstack, user, pointed_thing)
	map.update_inventory_info(user:get_player_name())
end



function map.on_joinplayer(player)
	local pname = player:get_player_name()
	minetest.after(3, function()
		map.update_inventory_info(pname)
	end)
end



function map.on_leaveplayer(player, timeout)
	-- Cleanup.
	map.players[player:get_player_name()] = nil
end



function map.is_mapping_kit(name)
	if name == "map:mapping_kit" or name == "map:mapping_tool" then
		return true
	end

	return false
end



function map.on_place(itemstack, placer, pt)
	if not placer or not placer:is_player() then
		return
	end
	if pt.type ~= "node" then
		return
	end

	local pname = placer:get_player_name()

	local node = minetest.get_node(pt.under)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return
	end

	if ndef.on_rightclick and not placer:get_player_control().sneak then
		return ndef.on_rightclick(pt.under, node, placer, itemstack, pt) or itemstack
	end

	local fakestack = ItemStack("map:mapping_kit")

	local retstack, success, position = minetest.item_place(fakestack, placer, pt)
	if success then
		-- Store wear level in the node.
		local meta = minetest.get_meta(position)
		meta:set_int("wear", itemstack:get_wear())

		itemstack:take_item()
		if itemstack:get_count() == 0 then
			-- Must take action *after* 'on_place' completes.
			minetest.after(0, function() map.update_inventory_info(pname) end)
		end
		return itemstack
	end
end



function map.on_dig(pos, node, digger)
	if not digger or not digger:is_player() then
		return minetest.node_dig(pos, node, digger)
	end
	if minetest.is_protected(pos, digger:get_player_name()) then
		return false
	end

	local meta = minetest.get_meta(pos)
	local wear = meta:get_int("wear")

	local inv = digger:get_inventory()
	if inv then
		local stack = ItemStack("map:mapping_tool")
		stack:set_wear(wear)

		local leftover = inv:add_item("main", stack)
		minetest.item_drop(leftover, nil, pos)
		minetest.remove_node(pos)

		return true
	end

	-- In case of any failure, just dig normally.
	return minetest.node_dig(pos, node, digger)
end



-- Set HUD flags 'on joinplayer'
if not map.run_once then
	local desc = "Stone Mapper Uplink\n\nAllows viewing a map of your surroundings.\nKeep in your hotbar and use with the 'minimap' key (default F9).\nMust be charged to operate."

	-- Mapping kit item.
	minetest.register_node("map:mapping_kit", {
		tiles = {"map_mapping_kit_tile.png"},
		wield_image = "map_mapping_kit.png",
		description = desc,
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
		drop = "map:mapping_tool",

		on_use = function(...)
			return map.on_use(...)
		end,

		on_dig = function(...)
			return map.on_dig(...)
		end,
	})

	-- Tool item is required in order for wear-bar to work.
	minetest.register_tool("map:mapping_tool", {
		description = desc,
		inventory_image = "map_mapping_kit.png",

		wear_represents = "eu_charge",
		groups = {not_repaired_by_anvil = 1, disable_repair = 1},

		on_use = function(...)
			return map.on_use(...)
		end,

		on_place = function(...)
			return map.on_place(...)
		end,
	})



	-- Crafting.
	minetest.register_craft({
		output = "map:mapping_tool",
		recipe = {
			{"default:glass", "plastic:plastic_sheeting", "default:obsidian_shard"},
			{"default:steel_ingot", "techcrafts:control_logic_unit", "default:steel_ingot"},
			{"fine_wire:silver", "battery:battery", "dusts:diamond"},
		}
	})



	-- Fuel.
	minetest.register_craft({
		type = "fuel",
		recipe = "map:mapping_tool",
		burntime = 5,
	})



	minetest.register_on_player_inventory_action(function(...)
		return map.on_player_inventory_action(...) end)

	minetest.register_on_joinplayer(function(...)
		return map.on_joinplayer(...) end)

	minetest.register_on_leaveplayer(function(...)
		return map.on_leaveplayer(...) end)

	minetest.after(map.time_step, function() map.consume_charge() end)

	local c = "map:core"
	local f = map.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	map.run_once = true
end


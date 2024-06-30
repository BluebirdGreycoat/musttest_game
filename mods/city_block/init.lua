-- Minetest mod "City block"
-- City block disables use of water/lava buckets and also sends aggressive players to jail
-- 2016.02 - improvements suggested by rnd. removed spawn_jailer support. some small fixes and improvements.

-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

if not minetest.global_exists("city_block") then city_block = {} end
city_block.blocks = city_block.blocks or {}
city_block.filename = minetest.get_worldpath() .. "/city_blocks.txt"
city_block.modpath = minetest.get_modpath("city_block")
city_block.formspecs = city_block.formspecs or {}

-- Cityblocks take 6 hours to become "active".
-- This prevents certain classes of exploits (such as using them offensively
-- during PvP). This also strongly discourages constantly moving them around
-- for trivial reasons.
city_block.CITYBLOCK_DELAY_TIME = 60*60*6

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME

function city_block.time_active(t1, t2)
	return (math.abs(t2 - t1) > CITYBLOCK_DELAY_TIME)
end

local time_active = city_block.time_active

dofile(city_block.modpath .. "/beacon.lua")
dofile(city_block.modpath .. "/formspec.lua")
dofile(city_block.modpath .. "/queries.lua")
dofile(city_block.modpath .. "/functions.lua")
dofile(city_block.modpath .. "/file.lua")
dofile(city_block.modpath .. "/pvp.lua")
dofile(city_block.modpath .. "/inv.lua")



function city_block.on_punch(pos, node, puncher, pt)
	if not pos or not node or not puncher or not pt then
		return
	end

	local pname = puncher:get_player_name()

	local wielded = puncher:get_wielded_item()
	if wielded:get_name() == "rosestone:head" and wielded:get_count() >= 8 then
		-- Only if area is not protected against this player.
		if not minetest.test_protection(pos, pname) then
			for i, v in ipairs(city_block.blocks) do
				if vector_equals(v.pos, pos) then
					if not v.is_jail then
						local p1 = vector_add(pos, {x=-1, y=0, z=-1})
						local p2 = vector_add(pos, {x=1, y=0, z=1})
						local positions, counts = minetest.find_nodes_in_area(p1, p2, "griefer:grieferstone")

						if counts["griefer:grieferstone"] == 8 then
							v.is_jail = true
							local meta = minetest.get_meta(pos)
							local infotext = meta:get_string("infotext")
							infotext = infotext .. "\nJail Marker"
							meta:set_string("infotext", infotext)

							city_block:save()

							wielded:take_item(8)
							puncher:set_wielded_item(wielded)

							minetest.chat_send_player(pname, "# Server: Jail position marked!")
							return
						end
					end
				end
			end
		end
	end

	-- Duel activation.
	-- Can be done even if player doesn't have access to protection.
	if wielded:get_name() == "default:gold_ingot" and wielded:get_count() > 0 then
		local targetpos = pos

		-- Check for config device, and try to use that.
		-- Note: configured target pos might not be valid.
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local inv = meta:get_inventory()
		local config = inv:get_stack("config", 1)

		if config:get_name() == "cfg:dev" and config:get_count() == 1 then
			local cmeta = config:get_meta()
			local s1 = cmeta:get_string("p1")
			local p1 = minetest.string_to_pos(s1)
			if s1 and s1 ~= "" and p1 then
				p1 = vector_round(p1)
				if vector_distance(p1, pos) <= armor.DUEL_MAX_RADIUS then
					targetpos = p1
				else
					minetest.chat_send_player(pname, "# Server: Target too far.")
					return
				end
			else
				minetest.chat_send_player(pname, "# Server: Invalid configuration.")
				return
			end
		end

		local block = city_block.get_block(targetpos)
		if block and block.pvp_arena then
			local target_meta = minetest.get_meta(targetpos)
			local target_owner = target_meta:get_string("owner")
			if target_owner == owner then
				if armor.is_valid_arena(targetpos) then
					if armor.add_dueling_player(puncher, targetpos) then
						wielded:take_item()
						puncher:set_wielded_item(wielded)
					else
						if armor.dueling_players[pname] then
							minetest.chat_send_player(pname, "# Server: You are already in a duel!")
						end
					end
				else
					minetest.chat_send_player(pname, "# Server: This is not a working dueling arena! You need city blocks, protection, and at least 2 public beds.")
				end
			else
				minetest.chat_send_player(pname, "# Server: Invalid configuration.")
			end
		else
			minetest.chat_send_player(pname, "# Server: Target is not an arena marker.")
		end
	end
end



function city_block.on_rightclick(pos, node, clicker, itemstack)
	if not clicker or not clicker:is_player() then
		return
	end

	local pname = clicker:get_player_name()
	local meta = minetest.get_meta(pos)

	-- Player must be owner of city block.
	if meta:get_string("owner") ~= pname then
		return
	end

	-- Create formspec context.
	city_block.formspecs[pname] = pos
	local blockdata = city_block.get_block(pos)

	local formspec = city_block.create_formspec(pos, pname, blockdata)
	minetest.show_formspec(pname, "city_block:main", formspec)
end



function city_block.on_leaveplayer(player, timed_out)
	city_block.disable_beacons_for_player(player:get_player_name())
end



if not city_block.run_once then
	city_block:load()

	minetest.register_on_player_receive_fields(function(...)
		return city_block.on_receive_fields(...) end)

	minetest.register_node("city_block:cityblock", {
		description = "Lawful Zone Marker [Marks a 45x45x45 area as a city.]\n\nSaves your bed respawn position, if someone killed you within the city area.\nMurderers and trespassers will be sent to jail if caught in a city.\nPrevents the use of ore leeching equipment within 100 meters radius.\nPrevents mining with TNT nearby.",
		tiles = {"moreblocks_circle_stone_bricks.png^default_tool_mesepick.png"},
		is_ground_content = false,
		groups = utility.dig_groups("obsidian", {
			immovable=1,
		}),
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),
		stack_max = 1,

		on_rightclick = function(...)
			return city_block.on_rightclick(...)
		end,

		after_place_node = function(...)
			return city_block.after_place_node(...)
		end,

		-- We don't need an `on_blast` func because TNT calls `on_destruct` properly!
		on_destruct = function(...)
			return city_block.on_destruct(...)
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(...)
			return city_block._on_update_infotext(...)
		end,

		on_punch = function(...)
			return city_block.on_punch(...)
		end,

		allow_metadata_inventory_move = function(...)
			return city_block.allow_metadata_inventory_move(...)
		end,

		allow_metadata_inventory_put = function(...)
			return city_block.allow_metadata_inventory_put(...)
		end,

		allow_metadata_inventory_take = function(...)
			return city_block.allow_metadata_inventory_take(...)
		end,

		on_metadata_inventory_move = function(...)
			return city_block.on_metadata_inventory_move(...)
		end,

		on_metadata_inventory_put = function(...)
			return city_block.on_metadata_inventory_put(...)
		end,

		on_metadata_inventory_take = function(...)
			return city_block.on_metadata_inventory_take(...)
		end,
	})

	minetest.register_craft({
		output = 'city_block:cityblock',
		recipe = {
			{'default:pick_mese', 'farming:hoe_mese', 'default:sword_diamond'},
			{'chests:chest_locked', 'default:goldblock', 'default:sandstone'},
			{'default:obsidianbrick', 'default:mese', 'cobble_furnace:inactive'},
		}
	})

	minetest.register_privilege("disable_pvp", {
		description = "Players cannot damage players with this priv by punching.",
		give_to_singleplayer = false,
	})

	minetest.register_on_punchplayer(function(...)
		return city_block.on_punchplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return city_block.on_leaveplayer(...)
	end)

	city_block.update_beacons()

	local c = "city_block:core"
	local f = city_block.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	city_block.run_once = true
end


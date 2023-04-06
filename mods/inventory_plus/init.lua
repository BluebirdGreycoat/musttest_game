--------------------------------------------------------------------------------
-- Inventory Plus for Minetest
--
-- Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
-- Source Code: https://github.com/cornernote/minetest-inventory_plus
-- License: BSD-3-Clause https://raw.github.com/cornernote/minetest-inventory_plus/master/LICENSE
--
-- Edited by TenPlus1 (23rd March 2016)
-- Edited and packaged for MTS (Must Test Survival) by GoldFireUn (5th September 2018)
--------------------------------------------------------------------------------

-- Expose API.
if not minetest.global_exists("inventory_plus") then inventory_plus = {} end
inventory_plus.modpath = minetest.get_modpath("inventory_plus")

-- Define buttons.
inventory_plus.buttons = inventory_plus.buttons or {}

-- Register button. Buttons are stored globally, NOT per-player.
function inventory_plus.register_button(button, label)
	inventory_plus.buttons[button] = label
end

-- Set inventory formspec.
function inventory_plus.set_inventory_formspec(player, formspec)
	 -- Error checking.
	if not player or not formspec then
		return
	end

	player:set_inventory_formspec(formspec)
end

-- Get player formspec.
function inventory_plus.get_formspec()
	-- Default inventory page.
	local formspec = "size[8,8.5]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "list[current_player;main;0,4.25;8,1;]"
		.. "list[current_player;main;0,5.5;8,3;8]"
		.. default.get_hotbar_bg(0, 4.25)

	-- Obtain hooks into the trash mod's trash slot inventory.
	local ltrash, mtrash = trash.get_listname()
	local itrash = trash.get_iconname()

	formspec = formspec
		.. "list[current_player;craft;3,0.5;3,3;]"
		.. "list[current_player;craftpreview;7,1.5;1,1;]"
		.. "image[6,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"
		.. "listring[current_name;craft]"
		.. "listring[current_player;main]"
		-- Trash icon.
		.. "list[" .. ltrash .. ";" .. mtrash .. ";7,0.5;1,1;]"
		.. "image[7,0.5;1,1;" .. itrash .. "]"
	
	-- Positions for individual buttons.
	local positions = {
		armor = {0, 1},
		bags = {1, 1},
		skins = {0, 0},
		zcg = {1, 0},
	}
	local ox, oy = 0.0, 0.5

	-- Install buttons.
	local buttons = inventory_plus.buttons
	for k, v in pairs(buttons) do
		-- 'k' is element name, 'v' is display label.

		if positions[k] then
			local x, y = ox + positions[k][1], oy + positions[k][2]

			formspec = formspec .. "image_button[" .. x .. "," .. y ..
				";1,1;inventory_plus_" .. k .. ".png;" .. k .. ";]" ..
				"tooltip[" .. k .. ";" .. v .. "]" -- Give each button a tooltip.
		end
	end
	
	return formspec
end

function inventory_plus.on_joinplayer(player)
	inventory_plus.set_inventory_formspec(player,
		inventory_plus.get_formspec())
end

function inventory_plus.on_receive_fields(player, formname, fields)
	-- Main. This button should exist in any formspec that replaces this one.
	-- Otherwise, players will not be able to navigate back!
	if fields.main then
		inventory_plus.set_inventory_formspec(player,
			inventory_plus.get_formspec())
		return
	end
end

-- This piece of code just rebuilds the inventory formspecs whenever the mod is
-- reloaded. This helps with formspec/code development.
local function rebuild_all()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		inventory_plus.set_inventory_formspec(v,
			inventory_plus.get_formspec())
	end
end

-- Execute!
rebuild_all()

if not inventory_plus.registered then
	minetest.register_on_joinplayer(function(...)
		return inventory_plus.on_joinplayer(...)
	end)

	minetest.register_on_player_receive_fields(function(...)
		return inventory_plus.on_receive_fields(...)
	end)

	local c = "inventory_plus:core"
	local f = inventory_plus.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	inventory_plus.registered = true
end

--[[
Easy Vending Machines [easyvend]
Copyright (C) 2012 Bad_Command, 2016 Wuzzy

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
]]

easyvend = {}
easyvend.VERSION = {}
easyvend.VERSION.MAJOR = 0
easyvend.VERSION.MINOR = 3
easyvend.VERSION.PATCH = 0
easyvend.VERSION.STRING = easyvend.VERSION.MAJOR .. "." .. easyvend.VERSION.MINOR .. "." .. easyvend.VERSION.PATCH

-- Set item which is used as payment for vending and depositing machines
--[[
easyvend.currency = minetest.setting_get("easyvend_currency")
if easyvend.currency == nil or minetest.registered_items[easyvend.currency] == nil then
	-- Default currency
	easyvend.currency = "default:gold_ingot"
end
easyvend.currency_desc = minetest.registered_items[easyvend.currency].description
if easyvend.currency_desc == nil or easyvend.currency_desc == "" then
	easyvend.currency_desc = easyvend.currency
end
--]]

easyvend.traversable_node_types = {
	["easyvend:vendor"] = true,
	["easyvend:depositor"] = true,
	["easyvend:vendor_on"] = true,
	["easyvend:depositor_on"] = true,
}

easyvend.registered_chests = {}
dofile(minetest.get_modpath("easyvend") .. "/ads.lua")


if minetest.get_modpath("reload") then
    reload.register_file("vending:core", minetest.get_modpath("easyvend") .. "/easyvend.lua")
else
    dofile(minetest.get_modpath("easyvend") .. "/easyvend.lua")
end



if minetest.get_modpath("chests") ~= nil then
	easyvend.register_chest("chests:chest_locked_closed", "main", "owner")
  easyvend.register_chest("chests:chest_locked_open", "main", "owner")
end



local sounds
local soundsplus = {
	place = { name = "easyvend_disable", gain = 1 },
	dug = { name = "easyvend_disable", gain = 1 }, }
if minetest.get_modpath("coresounds") ~= nil then
	sounds = default.node_sound_wood_defaults(soundsplus)
else
	sounds = soundsplus
end

local machine_template = {
	paramtype2 = "facedir",
	groups = utility.dig_groups("furniture", {vending=1}),

	after_place_node = function(...) return easyvend.after_place_node(...) end,
	can_dig = function(...) return easyvend.can_dig(...) end,
	on_receive_fields = function(...) return easyvend.on_receive_fields(...) end,
	sounds = sounds,

	allow_metadata_inventory_put = function(...) return easyvend.allow_metadata_inventory_put(...) end,
	allow_metadata_inventory_take = function(...) return easyvend.allow_metadata_inventory_take(...) end,
	allow_metadata_inventory_move = function(...) return easyvend.allow_metadata_inventory_move(...) end,
	on_punch = function(...) return easyvend.machine_check(...) end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local dname = rename.gpn(owner)

		meta:set_string("rename", dname)
		easyvend.machine_check(pos, minetest.get_node(pos))
	end,
}

if minetest.get_modpath("screwdriver") ~= nil then
	machine_template.on_rotate = screwdriver.rotate_simple
end

local vendor_on = table.copy(machine_template)
vendor_on.description = "Vending Machine"
vendor_on.tiles ={"easyvend_vendor_bottom.png", "easyvend_vendor_bottom.png", "easyvend_vendor_side.png",
	"easyvend_vendor_side.png", "easyvend_vendor_side.png", "easyvend_vendor_front_on.png"}
vendor_on.groups.not_in_creative_inventory = 1
vendor_on.groups.not_in_doc = 1
vendor_on.drop = "easyvend:vendor"

local vendor_off = table.copy(machine_template)
vendor_off.description = vendor_on.description
vendor_off.tiles = table.copy(vendor_on.tiles)
vendor_off.tiles[6] = "easyvend_vendor_front_off.png"

local depositor_on = table.copy(machine_template)
depositor_on.description = "Depositing Machine"
depositor_on.tiles ={"easyvend_depositor_bottom.png", "easyvend_depositor_bottom.png", "easyvend_depositor_side.png",
	"easyvend_depositor_side.png", "easyvend_depositor_side.png", "easyvend_depositor_front_on.png"}
depositor_on.groups.not_in_creative_inventory = 1
depositor_on.groups.not_in_doc = 1
depositor_on.drop = "easyvend:depositor"

local depositor_off = table.copy(machine_template)
depositor_off.description = depositor_on.description
depositor_off.tiles = table.copy(depositor_on.tiles)
depositor_off.tiles[6] = "easyvend_depositor_front_off.png"

minetest.register_node("easyvend:vendor", vendor_off)
minetest.register_node("easyvend:vendor_on", vendor_on)
minetest.register_node("easyvend:depositor", depositor_off)
minetest.register_node("easyvend:depositor_on", depositor_on)

minetest.register_craft({
	output = 'easyvend:vendor',
	recipe = {
								{'group:wood', 'group:wood', 'group:wood'},
								{'group:wood', 'techcrafts:control_logic_unit', 'group:wood'},
								{'group:wood', 'default:steel_ingot', 'group:wood'},
				}
})

minetest.register_craft({
	output = 'easyvend:depositor',
	recipe = {
								{'group:wood', 'default:steel_ingot', 'group:wood'},
								{'group:wood', 'techcrafts:control_logic_unit', 'group:wood'},
								{'group:wood', 'group:wood', 'group:wood'},
				}
})


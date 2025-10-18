
if not minetest.global_exists("fortress") then fortress = {} end
fortress.modpath = minetest.get_modpath("fortress")
fortress.worldpath = minetest.get_worldpath()

if fortress.debug_layout == nil then
	fortress.debug_layout = false
end

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_random = math.random

-- Default fortress definition.
dofile(fortress.modpath .. "/functions.lua")
dofile(fortress.modpath .. "/default.lua")
dofile(fortress.modpath .. "/loot.lua")
dofile(fortress.modpath .. "/oldgen.lua")
dofile(fortress.modpath .. "/newfort.lua")
dofile(fortress.modpath .. "/fortgen.lua")

if not fortress.run_once then
	minetest.register_chatcommand("spawn_fortress", {
		params = "",
		description = "Spawn a fortress starting at your current location.",
		privs = {server=true},

		func = function(...)
			fortress.chat_command(...)
			return true
		end,
	})

	minetest.register_chatcommand("gen_wfc_fort", {
		params = "",
		description = "Spawn a fortress starting at your current location.",
		privs = {server=true},

		func = function(...)
			fortress.chat_command_wfc(...)
			return true
		end,
	})

	local c = "fortress:core"
	local f = fortress.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	fortress.run_once = true
end

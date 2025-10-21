
if not minetest.global_exists("fortress") then fortress = {} end
fortress.modpath = minetest.get_modpath("fortress")
fortress.worldpath = minetest.get_worldpath()

-- Only affects fortgen V1.
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

-- Experimental (and broken) implementation reserved for reference!
--dofile(fortress.modpath .. "/newfort.lua")
--dofile(fortress.modpath .. "/fortgen.lua")

-- Shiny new Wave Function Collapse (TM) algorithm.
-- These files implement a *BETTER* constraint-rule based dungeon generator.
dofile(fortress.modpath .. "/gen.v2.main.lua")
dofile(fortress.modpath .. "/gen.v2.data.lua")
dofile(fortress.modpath .. "/gen.v2.core.lua")
dofile(fortress.modpath .. "/gen.v2.init.lua")
dofile(fortress.modpath .. "/gen.v2.util.lua")
dofile(fortress.modpath .. "/gen.v2.chat.lua")



if not fortress.run_once then
	minetest.register_chatcommand("spawn_fortress", {
		params = "",
		description = "Spawn a v1 fortress (smelly mess) at your location.",
		privs = {server=true},

		func = function(...)
			fortress.chat_command(...)
			return true
		end,
	})

	minetest.register_chatcommand("genfort", {
		params = fortress.v2.get_chat_command_params_desc(),
		description = "Spawn a v2 fortress (rule-constrained) at your location.",
		privs = {server=true},

		func = function(...)
			fortress.v2.chat_command(...)
			return true
		end,
	})

	local c = "fortress:core"
	local f = fortress.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	fortress.run_once = true
end

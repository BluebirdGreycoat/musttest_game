
command_tokens = command_tokens or {}
command_tokens.modpath = minetest.get_modpath("command_tokens")

local path = command_tokens.modpath
dofile(path.."/crafts.lua")
dofile(path.."/mark_token.lua")
dofile(path.."/mute_token.lua")
dofile(path.."/jail_token.lua")



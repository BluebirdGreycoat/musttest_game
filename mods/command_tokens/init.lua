
command_tokens = command_tokens or {}
command_tokens.modpath = minetest.get_modpath("command_tokens")

local path = command_tokens.modpath
dofile(path .. "/crafts.lua")

reload.register_file("command_tokens:mark", path .. "/mark_token.lua", true)
reload.register_file("command_tokens:mute", path .. "/mute_token.lua", true)
reload.register_file("command_tokens:jail", path .. "/jail_token.lua", true)


